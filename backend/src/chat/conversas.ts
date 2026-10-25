import { ObjectId, type Db } from "mongodb";
import type { ConversaDocumento } from "./tipos.js";
import { chaveSecretaria, chaveDireta } from "./chaves.js";

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

