import { ObjectId, type Db, type Filter } from "mongodb";
import type { ConversaDocumento, MensagemDocumento, PapelChat, UsuarioAutenticado } from "./tipos.js";
import { gerarPrevia } from "./validacao.js";
import { ladoDoUsuario } from "./acesso.js";

/**
 * 6.4 Envia uma mensagem em uma conversa existente:
 * 1. Insere o documento da mensagem na coleção "mensagens" com remetenteId, remetenteTipo e criadoEm.
 * 2. Atualiza a conversa com $set de ultimaMensagem (texto com previa, remetenteId, remetenteTipo, criadoEm),
 *    ultimaMensagemEm e o ponteiro leituras.<lado> do próprio lado (ladoDoUsuario).
 * 3. Se a atualização da conversa falhar após a inserção da mensagem, registra no console.error e segue com sucesso.
 */
export async function enviarMensagem(
    db: Db,
    conversa: ConversaDocumento,
    usuario: UsuarioAutenticado,
    texto: string
): Promise<{ mensagemId: string; criadoEm: Date }> {
    const agora = new Date();
    const remetenteId = new ObjectId(usuario.id);
    const remetenteTipo = usuario.papel;

    const mensagemDoc: MensagemDocumento = {
        _id: new ObjectId(),
        conversaId: conversa._id,
        remetenteId,
        remetenteTipo,
        texto,
        criadoEm: agora
    };

    await db.collection<MensagemDocumento>("mensagens").insertOne(mensagemDoc);

    const previa = gerarPrevia(texto);
    const lado = ladoDoUsuario(conversa, usuario);

    const camposSet: Record<string, unknown> = {
        ultimaMensagem: {
            texto: previa,
            remetenteId,
            remetenteTipo,
            criadoEm: agora
        },
        ultimaMensagemEm: agora
    };

    if (lado) {
        camposSet[`leituras.${lado}`] = agora;
    }

    try {
        await db.collection<ConversaDocumento>("conversas").updateOne(
            { _id: conversa._id },
            { $set: camposSet }
        );
    } catch (erro) {
        console.error("Erro ao atualizar conversa após inserção da mensagem:", erro);
    }

    return {
        mensagemId: mensagemDoc._id.toHexString(),
        criadoEm: agora
    };
}

export interface MensagemFormatada {
    _id: ObjectId;
    conversaId: ObjectId;
    texto: string;
    criadoEm: Date;
    remetente: {
        usuarioId: string;
        nome: string;
        papel: PapelChat;
    };
    minha: boolean;
}

export interface OpcoesListarMensagens {
    depois?: string | null;
    antes?: string | null;
    limite: number;
}

/**
 * 6.5 Lista mensagens de uma conversa com paginação por cursor (_id).
 * - Filtro por conversaId.
 * - depois: _id > depois.
 * - antes: _id < antes.
 * - sem depois: busca as últimas "limite" mensagens (ordem decrescente, limit e depois inverte).
 * - sempre devolve em ordem crescente de _id.
 * - Busca os nomes dos remetentes em uma única consulta a usuarios.
 */
export async function listarMensagens(
    db: Db,
    conversa: ConversaDocumento,
    usuario: UsuarioAutenticado,
    opcoes: OpcoesListarMensagens
): Promise<MensagemFormatada[]> {
    const { depois, antes, limite } = opcoes;
    const colecao = db.collection<MensagemDocumento>("mensagens");

    const filtro: Filter<MensagemDocumento> = {
        conversaId: conversa._id
    };

    const condicaoId: Record<string, ObjectId> = {};
    if (depois) {
        condicaoId.$gt = new ObjectId(depois);
    }
    if (antes) {
        condicaoId.$lt = new ObjectId(antes);
    }
    if (depois || antes) {
        filtro._id = condicaoId;
    }

    let docs: MensagemDocumento[];

    if (depois) {
        docs = await colecao
            .find(filtro)
            .sort({ _id: 1 })
            .limit(limite)
            .toArray();
    } else {
        docs = (
            await colecao
                .find(filtro)
                .sort({ _id: -1 })
                .limit(limite)
                .toArray()
        ).reverse();
    }

    if (docs.length === 0) {
        return [];
    }

    const remetenteIdsSet = new Set<string>();
    for (const doc of docs) {
        remetenteIdsSet.add(doc.remetenteId.toHexString());
    }

    const mapaNomes = new Map<string, string>();
    if (remetenteIdsSet.size > 0) {
        const ids = Array.from(remetenteIdsSet).map(id => new ObjectId(id));
        const usuariosDocs = await db
            .collection<{ _id: ObjectId; nome?: string }>("usuarios")
            .find({ _id: { $in: ids } }, { projection: { _id: 1, nome: 1 } })
            .toArray();

        for (const u of usuariosDocs) {
            mapaNomes.set(u._id.toHexString().toLowerCase(), typeof u.nome === "string" ? u.nome : "");
        }
    }

    const usuarioIdHex = usuario.id.toLowerCase();

    return docs.map(m => {
        const remetenteHex = m.remetenteId.toHexString().toLowerCase();
        const nome = mapaNomes.get(remetenteHex) ?? "";
        const minha = remetenteHex === usuarioIdHex;

        return {
            _id: m._id,
            conversaId: m.conversaId,
            texto: m.texto,
            criadoEm: m.criadoEm,
            remetente: {
                usuarioId: m.remetenteId.toHexString(),
                nome,
                papel: m.remetenteTipo
            },
            minha
        };
    });
}

