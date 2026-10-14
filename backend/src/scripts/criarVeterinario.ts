
import "dotenv/config";
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { conectarBanco, obterBanco, obterCliente } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";

async function criarFuncionario() {
    const email = "beatriz.veterinaria@petcare.com";
    const nome = "Dra. Beatriz Lima";
    const tipo = "VETERINARIO";
    const funcionarioId = "VET002";

    // Senha temporária gerada automaticamente
    const senhaTemporaria = randomBytes(24).toString("base64url");

    await conectarBanco();

    const banco = obterBanco();
    const usuarios = banco.collection("usuarios");
    const veterinarios = banco.collection<{
        _id: string;
        nome: string;
        ativo: boolean;
        usuarioId?: ObjectId;
    }>("veterinarios");

    // Verifica se o funcionário existe
    const funcionario = await veterinarios.findOne({
        _id: funcionarioId
    });

    if (!funcionario) {
        throw new Error("Veterinário não encontrado.");
    }

    if (funcionario.nome !== nome) {
    throw new Error(
        "O nome da conta não corresponde ao funcionário."
    );
}

    if (funcionario.ativo !== true) {
        throw new Error(
            "Não é possível criar uma conta para um funcionário inativo."
        );
    }

    if (funcionario.usuarioId) {
        throw new Error("Este veterinário já possui uma conta vinculada.");
    }

    // Evita cadastrar o mesmo email novamente
    const usuarioExistente = await usuarios.findOne({ email });

    if (usuarioExistente) {
        throw new Error("Este email já está cadastrado.");
    }

    // Solicita ao Java um hash seguro da senha
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

    const usuarioId = new ObjectId();
    const cliente = obterCliente();
    const sessao = cliente.startSession();

    try {
        // Salva os dois documentos na mesma transação
        await sessao.withTransaction(async () => {
            await usuarios.insertOne(
                {
                    _id: usuarioId,
                    nome,
                    email,
                    senhaHash: respostaJava.dados!.hash,
                    tipo,
                    ativo: true
                },
                { session: sessao }
            );

            const resultado = await veterinarios.updateOne(
                {
                    _id: funcionarioId,
                    usuarioId: { $exists: false }
                },
                {
                    $set: { usuarioId }
                },
                { session: sessao }
            );

            if (resultado.modifiedCount !== 1) {
                throw new Error("Não foi possível vincular o veterinário.");
            }
        });

        console.log("Funcionário criado com sucesso!");
        console.log("Email:", email);
        console.log("Senha temporária:", senhaTemporaria);
        console.log("ID da conta:", usuarioId.toString());

    } finally {
        await sessao.endSession();
    }
}

criarFuncionario()
    .catch((erro) => {
        console.error("Erro ao criar funcionário:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        await obterCliente().close();
    });
