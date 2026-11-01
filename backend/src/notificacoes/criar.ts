import { ObjectId, type Db, MongoServerError } from "mongodb";
import type { NotificacaoNova, NotificacaoDocumento } from "./tipos.js";
import { TIPOS_COM_EMAIL } from "./tipos.js";
import { validarNotificacaoNova } from "./validacao.js";

export interface ResultadoCriacao {
    criada: boolean;
    id: ObjectId | null;
    motivo?: "duplicada" | "invalida" | "erro";
}

/**
 * Função PURA: formata a chave de deduplicação da notificação.
 * Garante que a chave sempre termine com ':<destinatarioId em hexadecimal>',
 * tornando-a única por destinatário.
 */
export function montarChaveNotificacao(
    chaveBase: string | null | undefined,
    destinatarioId: ObjectId
): string | null {
    if (!chaveBase) {
        return null;
    }

    const baseLimpa = chaveBase.trim();
    if (baseLimpa.length === 0) {
        return null;
    }

    const sufixo = `:${destinatarioId.toHexString().toLowerCase()}`;
    if (baseLimpa.toLowerCase().endsWith(sufixo)) {
        return baseLimpa;
    }

    return `${baseLimpa}${sufixo}`;
}

/**
 * Função PURA: monta a estrutura completa do documento para inserção na coleção 'notificacoes'.
 * - Inicializa lidaEm como null e criadoEm com a data/hora atual.
 * - Define emailStatus: 'pendente' e emailTentativas: 0 se o tipo estiver em TIPOS_COM_EMAIL.
 * - Constrói a chave única por destinatário através de montarChaveNotificacao.
 */
export function montarDocumentoNotificacao(
    dados: NotificacaoNova,
    agora: Date = new Date()
): NotificacaoDocumento {
    const temEmail = (TIPOS_COM_EMAIL as readonly string[]).includes(dados.tipo);
    const chave = montarChaveNotificacao(dados.chave, dados.destinatarioId);

    const doc: NotificacaoDocumento = {
        _id: new ObjectId(),
        destinatarioId: dados.destinatarioId,
        remetenteId: dados.remetenteId ?? null,
        tipo: dados.tipo,
        titulo: dados.titulo,
        mensagem: dados.mensagem,
        petId: dados.petId ?? null,
        consultaId: dados.consultaId ?? null,
        chave,
        lidaEm: null,
        criadoEm: agora
    };

    if (temEmail) {
        doc.emailStatus = "pendente";
        doc.emailTentativas = 0;
    }

    return doc;
}

/**
 * Cria uma notificação no MongoDB para o destinatário informado.
 * - Valida a entrada com validarNotificacaoNova.
 * - Não notifica quando destinatarioId for igual a remetenteId.
 * - Trata erro de índice duplicado (11000) como motivo: 'duplicada'.
 * - NUNCA lança erro: retorna { criada: false, id: null, motivo: 'erro' } em falhas.
 */
export async function criarNotificacao(
    db: Db,
    entrada: NotificacaoNova
): Promise<ResultadoCriacao> {
    try {
        const validacao = validarNotificacaoNova(entrada);
        if (!validacao.ok) {
            return { criada: false, id: null, motivo: "invalida" };
        }

        const dados = validacao.valor;

        // Não notifica a si mesmo
        if (dados.remetenteId && dados.destinatarioId.equals(dados.remetenteId)) {
            return { criada: false, id: null };
        }

        const doc = montarDocumentoNotificacao(dados);

        await db.collection("notificacoes").insertOne(doc);

        return { criada: true, id: doc._id };
    } catch (erro: any) {
        if (erro instanceof MongoServerError && erro.code === 11000) {
            return { criada: false, id: null, motivo: "duplicada" };
        }

        if (erro && (erro.code === 11000 || String(erro.message).includes("E11000"))) {
            return { criada: false, id: null, motivo: "duplicada" };
        }

        return { criada: false, id: null, motivo: "erro" };
    }
}

/**
 * Cria notificações para uma lista de destinatários.
 * - Remove destinatários duplicados da lista antes de criar.
 * - Formata a chave para cada destinatário usando chaveBase.
 * - Devolve a quantidade de notificações criadas com sucesso.
 * - Nunca lança erro.
 */
export async function criarParaVarios(
    db: Db,
    destinatarios: ObjectId[],
    base: Omit<NotificacaoNova, "destinatarioId" | "chave">,
    chaveBase?: string
): Promise<number> {
    try {
        if (!Array.isArray(destinatarios) || destinatarios.length === 0) {
            return 0;
        }

        // Deduplica destinatários por hexadecimal
        const mapa = new Map<string, ObjectId>();
        for (const dest of destinatarios) {
            if (dest instanceof ObjectId) {
                mapa.set(dest.toHexString().toLowerCase(), dest);
            }
        }

        let criadas = 0;

        for (const destId of mapa.values()) {
            const res = await criarNotificacao(db, {
                ...base,
                destinatarioId: destId,
                chave: chaveBase ?? null
            });

            if (res.criada) {
                criadas++;
            }
        }

        return criadas;
    } catch {
        return 0;
    }
}
