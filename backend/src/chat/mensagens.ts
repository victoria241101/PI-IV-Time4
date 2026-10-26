import { ObjectId, type Db } from "mongodb";
import type { ConversaDocumento, MensagemDocumento, UsuarioAutenticado } from "./tipos.js";
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
