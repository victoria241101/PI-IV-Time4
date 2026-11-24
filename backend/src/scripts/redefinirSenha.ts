// Alinne Monteiro de Melo | RA: 24801649

import "dotenv/config";
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { conectarBanco, obterBanco, obterCliente } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";

// redefine a senha da conta ativa da secretaria indicada no script
async function redefinirSenha(): Promise<void> {
    const email = "juliana.secretaria@petcare.com";

    // abre a conexão antes de consultar a conta
    await conectarBanco();

    const banco = obterBanco();
    const usuarios = banco.collection("usuarios");

    // localiza somente a conta ativa da secretária juliana
    const usuario = await usuarios.findOne({
        email,
        tipo: "SECRETARIA",
        ativo: true
    });

    // interrompe se não encontrou uma conta com id no formato esperado
    if (!usuario || !(usuario._id instanceof ObjectId)) {
        throw new Error("Conta ativa da Juliana não encontrada com ObjectId válido.");
    }

    // confere se a conta está vinculada ao registro profissional correto
    const secretaria = await banco.collection<{
        _id: string;
        usuarioId: ObjectId;
        ativo: boolean;
    }>("secretaria").findOne({
        _id: "SEC001",
        usuarioId: usuario._id,
        ativo: true
    });

    // só continua se a conta estiver ligada ao cadastro profissional
    if (!secretaria) {
        throw new Error("Conta não vinculada à secretária Juliana (SEC001).");
    }

    // gera uma senha aleatória para essa conta
    const senhaTemporaria = randomBytes(24).toString("base64url");

    // o serviço java gera o hash pbkdf2 utilizado pelo login
    const respostaJava = await enviarComandoJava("GERAR_HASH_SENHA", {
        senha: senhaTemporaria
    });

    // interrompe se o serviço java não devolver o hash
    if (respostaJava.status !== "OK" || !respostaJava.dados?.hash) {
        throw new Error("Não foi possível gerar o hash da senha pelo Java.");
    }

    // altera apenas o hash da conta identificada e validada
    const resultado = await usuarios.updateOne(
        {
            _id: usuario._id,
            email,
            tipo: "SECRETARIA",
            ativo: true
        },
        {
            // salva o hash novo no campo usado pelo login
            $set: {
                senhaHash: respostaJava.dados.hash
            }
        }
    );

    // confere se exatamente uma conta foi encontrada e atualizada
    if (resultado.matchedCount !== 1 || resultado.modifiedCount !== 1) {
        throw new Error("Não foi possível atualizar a senha da Juliana.");
    }

    // mostra a senha temporária depois que a atualização termina
    console.log("Senha da Juliana redefinida com sucesso!");
    console.log("E-mail:", email);
    console.log("Nova senha temporária:", senhaTemporaria);
    console.log("Guarde a senha em local seguro e não a compartilhe.");
}

redefinirSenha()
    .catch((erro) => {
        // registra a falha e indica que o script terminou com erro
        console.error("Erro ao redefinir senha:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        // fecha a conexão com o banco mesmo se der erro
        await obterCliente().close();
    });
