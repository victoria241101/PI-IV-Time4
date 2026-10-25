import { ObjectId, type Db } from "mongodb";
import type { ConversaDocumento } from "./tipos.js";
import { chaveSecretaria } from "./chaves.js";

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
