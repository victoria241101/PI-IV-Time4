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

    /*const usuarios = banco.collection("usuarios");

    await usuarios.createIndex(
        { email: 1 },
        { unique: true }
    );

    await usuarios.createIndex(
        { cpf: 1 },
        { unique: true }
    );
    */
    console.log("Conectado ao MongoDB Atlas!");

    return banco;
}

export function obterBanco(): Db {
    if (!banco) {
        throw new Error("O banco de dados ainda não foi conectado.");
    }

    return banco;
}
