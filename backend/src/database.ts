import "dotenv/config";
import { MongoClient, Db } from "mongodb";

const uri = process.env.MONGODB_URI;

if (!uri) {
    throw new Error("A variável MONGODB_URI não foi definida.");
}

const client = new MongoClient(uri);

let banco: Db;

export async function conectarBanco() {
    await client.connect();

    banco = client.db("petcare");

    const usuarios = banco.collection("usuarios");

    await usuarios.createIndex(
        { cpf: 1 },
        {
            unique: true,
            partialFilterExpression: {
                cpf: { $type: "string" }
            }
        }
    );

    const tutores = banco.collection("tutores");

    await tutores.createIndex(
        { usuarioId: 1 },
        {
            unique: true,
            partialFilterExpression: {
                usuarioId: { $type: "objectId" }
            }
        }
    );

    const doacoes = banco.collection("doacoes");

    await doacoes.createIndex({ campanhaId: 1 });

    const conversas = banco.collection("conversas");

    await conversas.createIndex({ chave: 1 }, { unique: true });
    await conversas.createIndex({ participantes: 1 });
    await conversas.createIndex({ usuarioId: 1 });

    const mensagens = banco.collection("mensagens");

    await mensagens.createIndex({ conversaId: 1, _id: 1 });

    const notificacoes = banco.collection("notificacoes");

    await notificacoes.createIndex({ destinatarioId: 1, criadoEm: -1 });
    await notificacoes.createIndex({ destinatarioId: 1, lidaEm: 1 });
    await notificacoes.createIndex(
        { chave: 1 },
        {
            unique: true,
            partialFilterExpression: {
                chave: { $type: "string" }
            }
        }
    );
    await notificacoes.createIndex(
        { emailStatus: 1, criadoEm: 1 },
        {
            partialFilterExpression: {
                emailStatus: "pendente"
            }
        }
    );

    console.log("Conectado ao MongoDB Atlas!");

    return banco;
}

export function obterBanco(): Db {
    if (!banco) {
        throw new Error("O banco de dados ainda não foi conectado.");
    }

    return banco;
}

export function obterCliente(): MongoClient {
    return client;
}
