import { ObjectId, type Db, type Filter } from "mongodb";
import {
    LIMITE_CONVERSAS,
    PAPEL_SECRETARIA,
    type ConversaDocumento,
    type MensagemDocumento,
    type PapelChat,
    type TipoConversa,
    type UltimaMensagem,
    type UsuarioAutenticado
} from "./tipos.js";
import { chaveSecretaria, chaveDireta } from "./chaves.js";
import { normalizarTipoUsuario } from "./papeis.js";
import { podeAcessarConversa, ladoDoUsuario, montarFiltroNaoLidas } from "./acesso.js";
import { ehObjectIdHex } from "./validacao.js";
import type { Contato } from "./contatos.js";

/**
 * Abre ou reaproveita a caixa de conversa compartilhada de um usuário com a Secretaria.
 * Realiza updateOne com upsert e $setOnInsert sobre a chave única ("secretaria:<usuarioId>").
 * Em caso de corrida com erro de chave duplicada (código 11000), repete o findOne.
 *
 * O documento criado possui:
 * - tipo: "secretaria"
 * - usuarioId: ObjectId do usuário dono da caixa (tutor, veterinário ou enfermeiro)
 * - criadoEm: Date
 * - ultimaMensagemEm: null
 * - ultimaMensagem: null
 * - leituras: {}
 */
export async function abrirCaixaSecretaria(
    db: Db,
    usuarioId: ObjectId
): Promise<{ conversa: ConversaDocumento; criada: boolean }> {
    const colecao = db.collection<ConversaDocumento>("conversas");
    const chave = chaveSecretaria(usuarioId.toHexString());
    const agora = new Date();

    try {
        const resultado = await colecao.updateOne(
            { chave },
            {
                $setOnInsert: {
                    chave,
                    tipo: "secretaria",
                    usuarioId,
                    criadoEm: agora,
                    ultimaMensagemEm: null,
                    ultimaMensagem: null,
                    leituras: {}
                }
            },
            { upsert: true }
        );

        const criada = resultado.upsertedCount > 0;
        const conversa = await colecao.findOne({ chave });
        if (!conversa) {
            throw new Error("Falha ao recuperar a conversa da secretaria após upsert.");
        }

        return { conversa, criada };
    } catch (erro: unknown) {
        const erroMongo = erro as { code?: number; codeName?: string };
        if (erroMongo && (erroMongo.code === 11000 || erroMongo.codeName === "DuplicateKey")) {
            const conversa = await colecao.findOne({ chave });
            if (!conversa) {
                throw erro;
            }
            return { conversa, criada: false };
        }
        throw erro;
    }
}

/**
 * Abre ou reaproveita uma conversa direta entre dois usuários.
 * Realiza updateOne com upsert e $setOnInsert sobre a chave única ("direta:<idMenor>:<idMaior>").
 * Em caso de corrida com erro de chave duplicada (código 11000), repete o findOne.
 *
 * O documento criado possui:
 * - tipo: "direta"
 * - participantes: [a, b] em ordem alfabética do hex
 * - criadoEm: Date
 * - ultimaMensagemEm: null
 * - ultimaMensagem: null
 * - leituras: {}
 */
export async function abrirDireta(
    db: Db,
    a: ObjectId,
    b: ObjectId
): Promise<{ conversa: ConversaDocumento; criada: boolean }> {
    const colecao = db.collection<ConversaDocumento>("conversas");
    const aHex = a.toHexString();
    const bHex = b.toHexString();
    const chave = chaveDireta(aHex, bHex);
    const participantes = aHex < bHex ? [a, b] : [b, a];
    const agora = new Date();

    try {
        const resultado = await colecao.updateOne(
            { chave },
            {
                $setOnInsert: {
                    chave,
                    tipo: "direta",
                    participantes,
                    criadoEm: agora,
                    ultimaMensagemEm: null,
                    ultimaMensagem: null,
                    leituras: {}
                }
            },
            { upsert: true }
        );

        const criada = resultado.upsertedCount > 0;
        const conversa = await colecao.findOne({ chave });
        if (!conversa) {
            throw new Error("Falha ao recuperar a conversa direta após upsert.");
        }

        return { conversa, criada };
    } catch (erro: unknown) {
        const erroMongo = erro as { code?: number; codeName?: string };
        if (erroMongo && (erroMongo.code === 11000 || erroMongo.codeName === "DuplicateKey")) {
            const conversa = await colecao.findOne({ chave });
            if (!conversa) {
                throw erro;
            }
            return { conversa, criada: false };
        }
        throw erro;
    }
}

export interface ConversaResumo {
    _id: ObjectId;
    tipo: TipoConversa;
    outro: Contato;
    ultimaMensagem: UltimaMensagem | null;
    ultimaMensagemEm: Date | null;
    naoLidas: number;
}

/**
 * 6.3 Listar conversas do usuário autenticado.
 * - Não-secretária: caixas com usuarioId igual ao dele e diretas em que ele participa (inclusive vazias).
 * - Secretária: todas as caixas que já tenham mensagem (ultimaMensagemEm diferente de null).
 * Ordenadas por ultimaMensagemEm decrescente (as sem mensagem por último) e limitadas a LIMITE_CONVERSAS.
 * Busca nomes e tipos dos participantes em uma única consulta à coleção usuarios.
 */
export async function listarConversas(
    db: Db,
    usuario: UsuarioAutenticado
): Promise<ConversaResumo[]> {
    const colecaoConversas = db.collection<ConversaDocumento>("conversas");

    let filtro: Filter<ConversaDocumento>;

    if (usuario.papel === PAPEL_SECRETARIA) {
        filtro = {
            tipo: "secretaria",
            ultimaMensagemEm: { $ne: null }
        };
    } else {
        const usuarioObjectId = new ObjectId(usuario.id);
        filtro = {
            $or: [
                { tipo: "secretaria", usuarioId: usuarioObjectId },
                { tipo: "direta", participantes: usuarioObjectId }
            ]
        };
    }

    const conversas = await colecaoConversas
        .find(filtro)
        .sort({ ultimaMensagemEm: -1, _id: -1 })
        .limit(LIMITE_CONVERSAS)
        .toArray();

    if (conversas.length === 0) {
        return [];
    }

    const idsOutrosUsuarios: ObjectId[] = [];
    const ehSecretaria = usuario.papel === PAPEL_SECRETARIA;
    const usuarioIdHex = usuario.id.toLowerCase();

    for (const c of conversas) {
        if (c.tipo === "secretaria") {
            if (ehSecretaria && c.usuarioId) {
                idsOutrosUsuarios.push(c.usuarioId);
            }
        } else if (c.tipo === "direta" && Array.isArray(c.participantes)) {
            const outroId = c.participantes.find(
                p => p.toHexString().toLowerCase() !== usuarioIdHex
            );
            if (outroId) {
                idsOutrosUsuarios.push(outroId);
            }
        }
    }

    const mapaUsuarios = new Map<string, { nome: string; papel: PapelChat }>();

    if (idsOutrosUsuarios.length > 0) {
        const usuariosDocs = await db
            .collection<{ _id: ObjectId; nome?: string; tipo?: string }>("usuarios")
            .find(
                { _id: { $in: idsOutrosUsuarios } },
                { projection: { _id: 1, nome: 1, tipo: 1 } }
            )
            .toArray();

        for (const doc of usuariosDocs) {
            const papelNorm = normalizarTipoUsuario(doc.tipo);
            if (papelNorm) {
                mapaUsuarios.set(doc._id.toHexString().toLowerCase(), {
                    nome: typeof doc.nome === "string" ? doc.nome : "",
                    papel: papelNorm
                });
            }
        }
    }

    const contagens = await Promise.allSettled(
        conversas.map(c => contarNaoLidas(db, c, usuario))
    );

    const resultado: ConversaResumo[] = [];

    for (let i = 0; i < conversas.length; i++) {
        const c = conversas[i];
        if (!c) continue;
        let outro: Contato;

        if (c.tipo === "secretaria") {
            if (!ehSecretaria) {
                outro = {
                    tipo: "secretaria",
                    nome: "Secretaria"
                };
            } else {
                const outroHex = c.usuarioId ? c.usuarioId.toHexString().toLowerCase() : "";
                const usuarioInfo = mapaUsuarios.get(outroHex);
                outro = {
                    tipo: "usuario",
                    usuarioId: c.usuarioId ? c.usuarioId.toHexString() : "",
                    nome: usuarioInfo ? usuarioInfo.nome : "",
                    papel: usuarioInfo ? usuarioInfo.papel : "USUARIO"
                };
            }
        } else {
            // direta
            const outroId = Array.isArray(c.participantes)
                ? c.participantes.find(p => p.toHexString().toLowerCase() !== usuarioIdHex)
                : undefined;
            const outroHex = outroId ? outroId.toHexString().toLowerCase() : "";
            const usuarioInfo = mapaUsuarios.get(outroHex);
            outro = {
                tipo: "usuario",
                usuarioId: outroId ? outroId.toHexString() : "",
                nome: usuarioInfo ? usuarioInfo.nome : "",
                papel: usuarioInfo ? usuarioInfo.papel : "USUARIO"
            };
        }

        let naoLidas = 0;
        const contagem = contagens[i];
        if (contagem && contagem.status === "fulfilled") {
            naoLidas = contagem.value;
        } else if (contagem && contagem.status === "rejected") {
            console.error("Erro ao contar mensagens não lidas:", contagem.reason);
        }

        resultado.push({
            _id: c._id,
            tipo: c.tipo,
            outro,
            ultimaMensagem: c.ultimaMensagem ?? null,
            ultimaMensagemEm: c.ultimaMensagemEm ?? null,
            naoLidas
        });
    }

    return resultado;
}

/**
 * Busca uma conversa pelo _id e verifica se o usuário autenticado tem permissão de acesso.
 * Devolve o documento da conversa se existir e for acessível; caso contrário, devolve null.
 */
export async function buscarConversaAcessivel(
    db: Db,
    conversaId: string,
    usuario: UsuarioAutenticado
): Promise<ConversaDocumento | null> {
    if (!ehObjectIdHex(conversaId)) {
        return null;
    }

    const conversa = await db
        .collection<ConversaDocumento>("conversas")
        .findOne({ _id: new ObjectId(conversaId) });

    if (!conversa) {
        return null;
    }

    if (!podeAcessarConversa(conversa, usuario)) {
        return null;
    }

    return conversa;
}

/**
 * Conta o número de mensagens não lidas para o usuário na conversa.
 * Usa montarFiltroNaoLidas para gerar o filtro e countDocuments para contar.
 */
export async function contarNaoLidas(
    db: Db,
    conversa: ConversaDocumento,
    usuario: UsuarioAutenticado
): Promise<number> {
    const lado = ladoDoUsuario(conversa, usuario);
    if (!lado) return 0;
    const filtro = montarFiltroNaoLidas(conversa, lado);
    return db.collection<MensagemDocumento>("mensagens").countDocuments(filtro);
}

/**
 * Marca a conversa como lida para o usuário, atualizando leituras.<lado> com a data atual.
 */
export async function marcarComoLida(
    db: Db,
    conversa: ConversaDocumento,
    usuario: UsuarioAutenticado
): Promise<void> {
    const lado = ladoDoUsuario(conversa, usuario);
    if (!lado) return;
    await db.collection<ConversaDocumento>("conversas").updateOne(
        { _id: conversa._id },
        { $set: { [`leituras.${lado}`]: new Date() } }
    );
}
