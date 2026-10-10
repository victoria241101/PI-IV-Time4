import "dotenv/config";
import { MongoClient } from "mongodb";

const uri = process.env.MONGODB_URI;

if (!uri) {
    throw new Error("A variável MONGODB_URI não foi definida.");
}

const client = new MongoClient(uri);

export async function conectarBanco() {
    await client.connect();

    console.log("Conectado ao MongoDB Atlas!");

    return client.db("petcare");
}