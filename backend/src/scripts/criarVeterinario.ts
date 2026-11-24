// Alinne Monteiro de Melo | RA: 24801649

import "dotenv/config";
import { randomBytes } from "node:crypto";
import { ObjectId } from "mongodb";
import { conectarBanco, obterBanco, obterCliente } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";

// cria a conta e vincula ao cadastro da equipe
async function criarFuncionario() {
    // define os dados da conta e o id do cadastro profissional
    const email = "beatriz.veterinaria@petcare.com";
    const nome = "Dra. Beatriz Lima";
    const tipo = "VETERINARIO";
    const funcionarioId = "VET002";

    // senha temporária gerada automaticamente
    const senhaTemporaria = randomBytes(24).toString("base64url");

    await conectarBanco();

    const banco = obterBanco();
    const usuarios = banco.collection("usuarios");
    // abre a coleção onde está o cadastro profissional
    const veterinarios = banco.collection<{
        _id: string;
        nome: string;
        ativo: boolean;
        usuarioId?: ObjectId;
    }>("veterinarios");

    // verifica se o funcionário existe
    const funcionario = await veterinarios.findOne({
        _id: funcionarioId
    });

    if (!funcionario) {
        throw new Error("Veterinário não encontrado.");
    }

    // confere se o nome bate com o cadastro encontrado
    if (funcionario.nome !== nome) {
    throw new Error(
        "O nome da conta não corresponde ao funcionário."
    );
}

    // só cria conta para quem está ativo
    if (funcionario.ativo !== true) {
        throw new Error(
            "Não é possível criar uma conta para um funcionário inativo."
        );
    }

    // confere se o cadastro já tem uma conta vinculada
    if (funcionario.usuarioId) {
        throw new Error("Este veterinário já possui uma conta vinculada.");
    }

    // evita cadastrar o mesmo email novamente
    const usuarioExistente = await usuarios.findOne({ email });

    if (usuarioExistente) {
        throw new Error("Este email já está cadastrado.");
    }

    // solicita ao java um hash seguro da senha
    const respostaJava = await enviarComandoJava(
        "GERAR_HASH_SENHA",
        { senha: senhaTemporaria }
    );

    // interrompe o cadastro se o serviço java não devolver o hash
    if (
        respostaJava.status !== "OK" ||
        !respostaJava.dados?.hash
    ) {
        throw new Error("Não foi possível gerar o hash da senha.");
    }

    // cria o id da conta antes de salvar para usar no vínculo
    const usuarioId = new ObjectId();
    const cliente = obterCliente();
    const sessao = cliente.startSession();

    try {
        // salva os dois documentos na mesma transação
        await sessao.withTransaction(async () => {
            // salva a conta ativa com o hash da senha temporária
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

            // vincula a conta somente se o cadastro ainda estiver sem usuário
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

            // se o vínculo falhar, a transação também desfaz a criação da conta
            if (resultado.modifiedCount !== 1) {
                throw new Error("Não foi possível vincular o veterinário.");
            }
        });

        // mostra os dados de acesso depois que a transação termina
        console.log("Funcionário criado com sucesso!");
        console.log("Email:", email);
        console.log("Senha temporária:", senhaTemporaria);
        console.log("ID da conta:", usuarioId.toString());

    } finally {
        // encerra a sessão mesmo se der erro
        await sessao.endSession();
    }
}

criarFuncionario()
    .catch((erro) => {
        // registra a falha e indica que o script terminou com erro
        console.error("Erro ao criar funcionário:", erro);
        process.exitCode = 1;
    })
    .finally(async () => {
        // fecha a conexão com o banco ao terminar o script
        await obterCliente().close();
    });
