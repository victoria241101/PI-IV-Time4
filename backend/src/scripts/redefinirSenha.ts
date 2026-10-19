import "dotenv/config";
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { conectarBanco, obterBanco, obterCliente } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";

async function redefinirSenha(): Promise<void> {
    const email = "juliana.secretaria@petcare.com";

    await conectarBanco();

    const banco = obterBanco();
    const usuarios = banco.collection("usuarios");

    // Localiza somente a conta ativa da secretária Juliana.
    const usuario = await usuarios.findOne({
        email,
        tipo: "SECRETARIA",
        ativo: true
    });

    if (!usuario || !(usuario._id instanceof ObjectId)) {
        throw new Error("Conta ativa da Juliana não encontrada com ObjectId válido.");
    }

    // Confere se a conta está vinculada ao registro profissional correto.
    const secretaria = await banco.collection<{
        _id: string;
        usuarioId: ObjectId;
        ativo: boolean;
    }>("secretaria").findOne({
        _id: "SEC001",
        usuarioId: usuario._id,
        ativo: true
    });

    if (!secretaria) {
        throw new Error("Conta não vinculada à secretária Juliana (SEC001).");
    }

    // Gera uma senha aleatória; nunca reutiliza a senha de outro usuário.
    const senhaTemporaria = randomBytes(24).toString("base64url");

    // O serviço Java gera o hash PBKDF2 utilizado pelo login.
    const respostaJava = await enviarComandoJava("GERAR_HASH_SENHA", {
        senha: senhaTemporaria
    });

    if (respostaJava.status !== "OK" || !respostaJava.dados?.hash) {
        throw new Error("Não foi possível gerar o hash da senha pelo Java.");
    }

    // Altera apenas o hash da conta identificada e validada.
    const resultado = await usuarios.updateOne(
        {
            _id: usuario._id,
            email,
            tipo: "SECRETARIA",
            ativo: true
        },
        {
            $set: {
                senhaHash: respostaJava.dados.hash
            }
        }
    );

    if (resultado.matchedCount !== 1 || resultado.modifiedCount !== 1) {
        throw new Error("Não foi possível atualizar a senha da Juliana.");
    }

    console.log("Senha da Juliana redefinida com sucesso!");
    console.log("E-mail:", email);
    console.log("Nova senha temporária:", senhaTemporaria);
    console.log("Guarde a senha em local seguro e não a compartilhe.");
}

redefinirSenha()
    .catch((erro) => {
        console.error("Erro ao redefinir senha:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        await obterCliente().close();
    });
