import "dotenv/config";
import { randomBytes } from "node:crypto";
import { conectarBanco, obterBanco, obterCliente } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";
import { ObjectId } from "mongodb";

async function redefinirSenha() {
    const email =  "pedro.enfermeiro@petcare.com";

    await conectarBanco();

    const banco = obterBanco();
    const usuarios = banco.collection("usuarios");

    // Procura a conta da Beatriz
    const usuario = await usuarios.findOne({
        email,
        tipo: "ENFERMEIRO",
        ativo: true
    });

    if (!usuario) {
        throw new Error("Conta do Pedro não encontrada.");
    }

    // Confirma que a conta pertence à veterinária correta
    // Confirma que a conta pertence ao enfermeiro Pedro
    const enfermeiro = await banco.collection<{
        _id: string;
        usuarioId: ObjectId;
        ativo: boolean;
    }>("enfermeiros").findOne({
        _id: "ENF002",
        usuarioId: usuario._id,
        ativo: true
    });

    if (!enfermeiro) {
        throw new Error("Conta não vinculada ao enfermeiro Pedro.");
    }

    // Gera uma nova senha temporária
    const senhaTemporaria = randomBytes(24).toString("base64url");

    // Solicita ao Java o hash da nova senha
    const respostaJava = await enviarComandoJava(
        "GERAR_HASH_SENHA",
        { senha: senhaTemporaria }
    );

    if (
        respostaJava.status !== "OK" ||
        !respostaJava.dados?.hash
    ) {
        throw new Error("Não foi possível gerar o hash da senha.");
    }

    // Atualiza apenas o hash da senha
    const resultado = await usuarios.updateOne(
        {
            _id: usuario._id,
            tipo: "ENFERMEIRO",
            ativo: true
        },
        {
            $set: {
                senhaHash: respostaJava.dados.hash
            }
        }
    );

    if (resultado.modifiedCount !== 1) {
        throw new Error("Não foi possível atualizar a senha.");
    }

    console.log("Senha redefinida com sucesso!");
    console.log("Email:", email);
    console.log("Nova senha temporária:", senhaTemporaria);
}

redefinirSenha()
    .catch((erro) => {
        console.error("Erro ao redefinir senha:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        await obterCliente().close();
    });