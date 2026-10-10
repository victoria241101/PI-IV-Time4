import { Router } from "express";
import { enviarComandoJava } from "../javaClient.js";
import { obterBanco } from "../database.js";
import { ObjectId } from "mongodb";


// Calcular dígitos verificadores do CPF
function calcularDigito(cpf: string, quantidade: number): number {
    let soma = 0;

    for (let i = 0; i < quantidade; i++) {
        const digito = Number(cpf[i]);
        const peso = quantidade + 1 - i;

        soma += digito * peso;
    }

    const resto = soma % 11;
    const resultado = 11 - resto;

    return resultado >= 10 ? 0 : resultado;
}

const router = Router();

router.post("/cadastro", async (req, res) => {
    try {
        const {
            nome,
            email,
            cpf,
            senha,
            confirmarSenha,
            possuiPet,
            pet
        } = req.body ?? {};

        if (
            typeof nome !== "string" || !nome.trim() ||
            typeof email !== "string" || !email.trim() ||
            typeof cpf !== "string" || !cpf.trim() ||
            typeof senha !== "string" || !senha.trim()
        ) {
            return res.status(400).json({
                mensagem: "Preencha todos os campos obrigatórios."
            });
        }

        if (!/^[\p{L}\s'-]+$/u.test(nome.trim())) {
            return res.status(400).json({
                mensagem: "O nome deve conter apenas letras."
            });
        }

        if (senha.length < 8) {
        return res.status(400).json({
            mensagem: "A senha deve conter pelo menos 8 caracteres."
        });   
        }   
        if (
            typeof confirmarSenha !== "string" ||
            senha !== confirmarSenha
        ) {
            return res.status(400).json({
                mensagem: "As senhas não coincidem."
            });
        }

        if (typeof possuiPet !== "boolean") {
            return res.status(400).json({
                mensagem: "Informe se possui um pet."
            });
        }

        if (possuiPet) {
            if (
                !pet ||
                typeof pet.nome !== "string" || !pet.nome.trim() ||
                typeof pet.especie !== "string" || !pet.especie.trim() ||
                typeof pet.raca !== "string" || !pet.raca.trim() ||
                typeof pet.sexo !== "string" || !pet.sexo.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Preencha todos os dados do pet."
                });
            }
        }

        const banco = obterBanco();

        const usuarios = banco.collection("usuarios");
        const tutores = banco.collection("tutores");
        const pets = banco.collection("pets");

        const usuarioId = new ObjectId();

        // Verificação email
        const emailNormalizado = email.trim().toLowerCase();

        const usuarioExistente = await usuarios.findOne({
            email: emailNormalizado
        });

        if (usuarioExistente) {
            return res.status(409).json({
                mensagem: "Este e-mail já está cadastrado."
            });
        }

        const formatoEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!formatoEmail.test(emailNormalizado)) {
            return res.status(400).json({
                mensagem: "Informe um e-mail válido."
            });
        }

        // Verificação CPF
        if (!/^\d{11}$|^\d{3}\.\d{3}\.\d{3}-\d{2}$/.test(cpf)) {
            return res.status(400).json({
                mensagem: "Formato de CPF inválido."
            });
        }
        
        const cpfNormalizado = cpf.replace(/\D/g, "");

        const cpfExistente = await usuarios.findOne({
            cpf: cpfNormalizado
        });

        if (cpfExistente) {
            return res.status(409).json({
                mensagem: "Este CPF já está cadastrado."
            });
        }

        if (cpfNormalizado.length !== 11) {
            return res.status(400).json({
                mensagem: "O CPF deve conter 11 dígitos."
            });
        }

        if (/^(\d)\1{10}$/.test(cpfNormalizado)) {
            return res.status(400).json({
                mensagem: "CPF inválido."
            });
        }

        const primeiroDigito = calcularDigito(cpfNormalizado, 9);
        const segundoDigito = calcularDigito(cpfNormalizado, 10);

        if (
            primeiroDigito !== Number(cpfNormalizado[9]) ||
            segundoDigito !== Number(cpfNormalizado[10])
        ) {
            return res.status(400).json({
                mensagem: "CPF inválido."
            });
        }

        // -----------------------------

        const respostaJava = await enviarComandoJava(
            "GERAR_HASH_SENHA",
            { senha }
        );

        if (
            respostaJava.status !== "OK" ||
            !respostaJava.dados?.hash
        ) {
            return res.status(502).json({
                mensagem: "Não foi possível gerar o hash da senha."
            });
        }
        
        const novoUsuario = {
            _id: usuarioId,
            nome: nome.trim(),
            email: emailNormalizado,
            cpf: cpfNormalizado,
            senhaHash: respostaJava.dados.hash,
            tipo: "USUARIO",
            ativo: true
        };

        let novoTutor = null;
        let novoPet = null;

        if (possuiPet) {
            const tutorId = new ObjectId();

            novoTutor = {
                _id: tutorId,
                usuarioId: usuarioId
            };

            novoPet = {
                _id: new ObjectId(),
                tutorId: tutorId,
                nome: pet.nome.trim(),
                especie: pet.especie.trim(),
                raca: pet.raca.trim(),
                sexo: pet.sexo.trim(),
                ativo: true
            };
        }


        res.json({
            mensagem: "Dados recebidos e senha processada com sucesso!",
            nome,
            email
        });

    } catch (erro) {
        console.error("Erro na comunicação com o servidor Java.");

        res.status(503).json({
            mensagem: "Serviço de cadastro temporariamente indisponível."
        });
    }
});

router.post("/login", async (req, res) => {
    try {
        const { email, senha } = req.body ?? {};

        if (
            typeof email !== "string" ||
            !email.trim() ||
            typeof senha !== "string" ||
            !senha
        ) {
            return res.status(400).json({
                mensagem: "E-mail e senha são obrigatórios."
            });
        }

        const emailNormalizado = email.trim().toLowerCase();

        const banco = obterBanco();

        const usuario = await banco.collection("usuarios").findOne({
            email: emailNormalizado
        });

        if (!usuario) {
            return res.status(401).json({
                mensagem: "E-mail ou senha inválidos."
            });
        }

        if (typeof usuario.senhaHash !== "string") {
            return res.status(500).json({
                mensagem: "Não foi possível autenticar o usuário."
            });
        }

        const respostaJava = await enviarComandoJava(
            "VERIFICAR_SENHA",
            {
                senha: senha,
                hash: usuario.senhaHash
            }
        );

        if (
            respostaJava.status !== "OK" ||
            typeof respostaJava.dados?.valida !== "boolean"
        ) {
            return res.status(502).json({
                mensagem: "Não foi possível verificar a senha."
            });
        }

        if (!respostaJava.dados.valida) {
            return res.status(401).json({
                mensagem: "E-mail ou senha inválidos."
            });
        }

        if (usuario.ativo !== true) {
            return res.status(403).json({
                mensagem: "Esta conta está desativada."
            });
        }

        return res.status(200).json({
            mensagem: "Credenciais verificadas com sucesso."
        });

    } catch (erro) {
        console.error("Erro ao processar login:", erro);

        return res.status(500).json({
            mensagem: "Erro interno ao processar login."
        });
    }
});

export default router;
