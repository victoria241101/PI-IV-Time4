/*
 * Aluna: Victoria Beatriz Nobre Andrade
 * RA: 2516398
 */
import { Router } from "express";
import { randomBytes, createHash } from "node:crypto";
import nodemailer from "nodemailer";
import { ObjectId, MongoServerError } from "mongodb";

import { enviarComandoJava } from "../javaClient.js";
import { obterBanco, obterCliente } from "../database.js";
import { gerarToken } from "../jwtService.js";
import { autenticar } from "../middlewares/auth.middleware.js";

const router = Router();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const NOME_REGEX = /^[\p{L}\s'-]+$/u;
const PRAZO_RECUPERACAO_MS = 15 * 60 * 1000;

function calcularDigito(cpf: string, quantidade: number): number {
    let soma = 0;

    for (let i = 0; i < quantidade; i++) {
        soma += Number(cpf[i]) * (quantidade + 1 - i);
    }

    const resultado = 11 - (soma % 11);
    return resultado >= 10 ? 0 : resultado;
}

// confere os dois dígitos verificadores do cpf
function validarCPF(cpf: string): boolean {
    if (!/^\d{11}$/.test(cpf) || /^(\d)\1{10}$/.test(cpf)) {
        return false;
    }

    return (
        calcularDigito(cpf, 9) === Number(cpf[9]) &&
        calcularDigito(cpf, 10) === Number(cpf[10])
    );
}

function normalizarEmail(email: string): string {
    return email.trim().toLowerCase();
}

// gera o hash do token para guardar e consultar no banco
function hashToken(token: string): string {
    return createHash("sha256").update(token).digest("hex");
}

// pede ao serviço java para gerar o hash da senha
async function gerarHashSenha(senha: string): Promise<string> {
    const resposta = await enviarComandoJava("GERAR_HASH_SENHA", { senha });

    if (resposta.status !== "OK" || !resposta.dados?.hash) {
        throw new Error("Serviço de geração de hash indisponível.");
    }

    return resposta.dados.hash;
}

// pede ao serviço java para conferir a senha com o hash salvo
async function verificarSenha(senha: string, hash: string): Promise<boolean> {
    const resposta = await enviarComandoJava("VERIFICAR_SENHA", {
        senha,
        hash
    });

    if (
        resposta.status !== "OK" ||
        typeof resposta.dados?.valida !== "boolean"
    ) {
        throw new Error("Serviço de verificação de senha indisponível.");
    }

    return resposta.dados.valida;
}

// configura o envio de e-mail com as variáveis de ambiente
function configurarEmail() {
    const host = process.env.SMTP_HOST;
    const porta = Number(process.env.SMTP_PORT || "587");
    const usuario = process.env.SMTP_USER;
    const senha = process.env.SMTP_PASS;
    const remetente = process.env.SMTP_FROM;

    if (!host || !usuario || !senha || !remetente || !Number.isInteger(porta)) {
        throw new Error("Configuração SMTP incompleta.");
    }

    return {
        transporte: nodemailer.createTransport({
            host,
            port: porta,
            secure: porta === 465,
            auth: { user: usuario, pass: senha }
        }),
        remetente
    };
}

// cadastro de usuário e, opcionalmente, do primeiro pet
router.post("/cadastro", async (req, res) => {
    try {
        // separa os dados enviados no corpo da requisição
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

        if (!NOME_REGEX.test(nome.trim())) {
            return res.status(400).json({
                mensagem: "O nome deve conter apenas letras."
            });
        }

        if (senha.length < 8) {
            return res.status(400).json({
                mensagem: "A senha deve conter pelo menos 8 caracteres."
            });
        }

        if (typeof confirmarSenha !== "string" || senha !== confirmarSenha) {
            return res.status(400).json({
                mensagem: "As senhas não coincidem."
            });
        }

        if (typeof possuiPet !== "boolean") {
            return res.status(400).json({
                mensagem: "Informe se possui um pet."
            });
        }

        if (
            possuiPet &&
            (
                !pet ||
                typeof pet.nome !== "string" || !pet.nome.trim() ||
                typeof pet.especie !== "string" || !pet.especie.trim() ||
                typeof pet.raca !== "string" || !pet.raca.trim() ||
                typeof pet.sexo !== "string" || !pet.sexo.trim()
            )
        ) {
            return res.status(400).json({
                mensagem: "Preencha todos os dados do pet."
            });
        }

        // padroniza o e-mail antes de usar no cadastro ou na busca
        const emailNormalizado = normalizarEmail(email);
        // remove a formatação antes de validar o cpf
        const cpfNormalizado = cpf.replace(/\D/g, "");

        if (!EMAIL_REGEX.test(emailNormalizado)) {
            return res.status(400).json({
                mensagem: "Informe um e-mail válido."
            });
        }

        if (
            !/^\d{11}$|^\d{3}\.\d{3}\.\d{3}-\d{2}$/.test(cpf) ||
            !validarCPF(cpfNormalizado)
        ) {
            return res.status(400).json({
                mensagem: "CPF inválido."
            });
        }

        const banco = obterBanco();
        const usuarios = banco.collection("usuarios");

        if (await usuarios.findOne({ email: emailNormalizado })) {
            return res.status(409).json({
                mensagem: "Este e-mail já está cadastrado."
            });
        }

        if (await usuarios.findOne({ cpf: cpfNormalizado })) {
            return res.status(409).json({
                mensagem: "Este CPF já está cadastrado."
            });
        }

        const usuarioId = new ObjectId();
        // gera o hash que vai ser salvo no lugar da senha
        const senhaHash = await gerarHashSenha(senha);

        const novoUsuario = {
            _id: usuarioId,
            nome: nome.trim(),
            email: emailNormalizado,
            cpf: cpfNormalizado,
            senhaHash,
            tipo: "USUARIO",
            ativo: true
        };

        const tutorId = new ObjectId();
        const novoTutor = possuiPet
            ? { _id: tutorId, usuarioId }
            : null;

        const novoPet = possuiPet
            ? {
                _id: new ObjectId(),
                tutorId,
                nome: pet.nome.trim(),
                especie: pet.especie.trim(),
                raca: pet.raca.trim(),
                sexo: pet.sexo.trim(),
                ativo: true
            }
            : null;

        const sessao = obterCliente().startSession();

        try {
            // salva a conta e os cadastros vinculados na mesma transação
            await sessao.withTransaction(async () => {
                await usuarios.insertOne(novoUsuario, { session: sessao });

                if (novoTutor && novoPet) {
                    await banco.collection("tutores").insertOne(
                        novoTutor,
                        { session: sessao }
                    );

                    await banco.collection("pets").insertOne(
                        novoPet,
                        { session: sessao }
                    );
                }
            });
        } finally {
            await sessao.endSession();
        }

        return res.status(201).json({
            mensagem: "Cadastro realizado com sucesso!"
        });
    } catch (erro) {
        if (erro instanceof MongoServerError && erro.code === 11000) {
            return res.status(409).json({
                mensagem: "E-mail ou CPF já cadastrado."
            });
        }

        console.error("Erro ao realizar cadastro:", erro);

        return res.status(503).json({
            mensagem: "Não foi possível concluir o cadastro. Tente novamente."
        });
    }
});

// login existente, mantendo a verificação de senha pelo java
router.post("/login", async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { email, senha } = req.body ?? {};

        if (
            typeof email !== "string" || !email.trim() ||
            typeof senha !== "string" || !senha
        ) {
            return res.status(400).json({
                mensagem: "E-mail e senha são obrigatórios."
            });
        }

        const usuario = await obterBanco()
            .collection("usuarios")
            .findOne({ email: normalizarEmail(email) });

        if (!usuario || typeof usuario.senhaHash !== "string") {
            return res.status(401).json({
                mensagem: "E-mail ou senha inválidos."
            });
        }

        if (!await verificarSenha(senha, usuario.senhaHash)) {
            return res.status(401).json({
                mensagem: "E-mail ou senha inválidos."
            });
        }

        if (usuario.ativo !== true) {
            return res.status(403).json({
                mensagem: "Esta conta está desativada."
            });
        }

        const token = await gerarToken(usuario._id.toString());

        return res.status(200).json({
            mensagem: "Login realizado com sucesso.",
            token
        });
    } catch (erro) {
        console.error("Erro ao processar login:", erro);

        return res.status(500).json({
            mensagem: "Erro interno ao processar login."
        });
    }
});

// consulta do perfil autenticado
router.get("/perfil", autenticar, async (_req, res) => {
    try {
        const banco = obterBanco();

        const usuario = await banco
            .collection("usuarios")
            .findOne(
                { _id: new ObjectId(res.locals.usuarioId) },
                {
                    projection: {
                        nome: 1,
                        email: 1,
                        cpf: 1,
                        tipo: 1
                    }
                }
            );

        if (!usuario) {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }

        const colecoesProfissionais: Record<string, string> = {
            SECRETARIA: "secretaria",
            ENFERMEIRO: "enfermeiros",
            VETERINARIO: "veterinarios"
        };
        const colecao = colecoesProfissionais[String(usuario.tipo).toUpperCase()];
        if (colecao) {
            const profissional = await banco.collection(colecao).findOne(
                { usuarioId: { $in: [usuario._id, usuario._id.toString()] }, ativo: true },
                { projection: { telefone: 1, cpf: 1 } }
            );
            usuario.telefone = profissional?.telefone ?? null;
            usuario.cpf = usuario.cpf ?? profissional?.cpf ?? null;
        }

        // Verifica se existe um cadastro de tutor vinculado ao usuário.
        const tutor = await banco
            .collection("tutores")
            .findOne({
                usuarioId: usuario._id
            });

        return res.status(200).json({
            mensagem: "Perfil encontrado com sucesso!",
            usuario,
            ehTutor: tutor !== null
        });

    } catch (erro) {
        console.error("Erro ao buscar perfil:", erro);

        return res.status(500).json({
            mensagem: "Erro ao buscar perfil do usuário."
        });
    }
});

// solicitação de alteração de nome e/ou e-mail
router.patch("/perfil", autenticar, async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { nome, email, cpf, tipo, ativo, senhaHash } = req.body ?? {};

        // impede alterações em campos que não fazem parte desta operação
        if (
            cpf !== undefined ||
            tipo !== undefined ||
            ativo !== undefined ||
            senhaHash !== undefined
        ) {
            return res.status(400).json({
                mensagem: "Somente nome e e-mail podem ser alterados."
            });
        }

        if (nome === undefined && email === undefined) {
            return res.status(400).json({
                mensagem: "Informe pelo menos uma alteração."
            });
        }

        const alteracoes: { nome?: string; email?: string } = {};

        if (nome !== undefined) {
            if (
                typeof nome !== "string" ||
                !nome.trim() ||
                !NOME_REGEX.test(nome.trim())
            ) {
                return res.status(400).json({
                    mensagem: "Informe um nome válido."
                });
            }

            alteracoes.nome = nome.trim();
        }

        if (email !== undefined) {
            if (typeof email !== "string") {
                return res.status(400).json({
                    mensagem: "Informe um e-mail válido."
                });
            }

            // padroniza o e-mail antes de usar no cadastro ou na busca
            const emailNormalizado = normalizarEmail(email);

            if (!EMAIL_REGEX.test(emailNormalizado)) {
                return res.status(400).json({
                    mensagem: "Informe um e-mail válido."
                });
            }

            alteracoes.email = emailNormalizado;
        }

        const banco = obterBanco();
        const usuarios = banco.collection("usuarios");
        // pega o id que a autenticação colocou na resposta
        const usuarioId = new ObjectId(res.locals.usuarioId);

        const usuario = await usuarios.findOne({
            _id: usuarioId,
            ativo: true
        });

        if (!usuario) {
            return res.status(404).json({
                mensagem: "Usuário ativo não encontrado."
            });
        }

        // evita solicitar um e-mail que já pertence a outra conta
        if (alteracoes.email) {
            const emailExistente = await usuarios.findOne({
                email: alteracoes.email,
                _id: { $ne: usuarioId }
            });

            if (emailExistente) {
                return res.status(409).json({
                    mensagem: "Este e-mail já está cadastrado."
                });
            }

            if (alteracoes.email === usuario.email) {
                delete alteracoes.email;
            }
        }

        if (
            alteracoes.nome === usuario.nome &&
            alteracoes.email === undefined
        ) {
            return res.status(400).json({
                mensagem: "Nenhuma alteração foi identificada."
            });
        }

        // gera um token temporário para confirmação
        const token = randomBytes(32).toString("hex");
        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);
        // define até quando o link pode ser usado
        const expiraEm = new Date(Date.now() + PRAZO_RECUPERACAO_MS);

        const pendentes = banco.collection("alteracoesPendentes");

        // uma nova solicitação invalida a anterior
        await pendentes.deleteMany({ usuarioId, tipo: "PERFIL" });

        // guarda a alteração enquanto ela espera confirmação
        await pendentes.insertOne({
            usuarioId,
            tipo: "PERFIL",
            tokenHash,
            alteracoes,
            expiraEm,
            criadoEm: new Date()
        });

        try {
            const urlBase = process.env.FRONTEND_URL;

            if (!urlBase || !/^https?:\/\//.test(urlBase)) {
                throw new Error("FRONTEND_URL não configurada corretamente.");
            }

            // monta o link com o token que será enviado por e-mail
            const link = new URL("/", urlBase);
            link.searchParams.set("tipo", "confirmar-alteracao");
            link.searchParams.set("token", token);

            const { transporte, remetente } = configurarEmail();

            await transporte.sendMail({
                from: remetente,
                to: usuario.email,
                subject: "PetCare - Confirmação de alteração do perfil",
                text:
                    "Recebemos uma solicitação de alteração no seu perfil.\n\n" +
                    `Acesse o link para confirmar: ${link.toString()}\n\n` +
                    "O link expira em 15 minutos e só pode ser usado uma vez.\n" +
                    "Se você não solicitou essa alteração, ignore esta mensagem."
            });
        } catch (erro) {
            // remove o pedido se o envio do e-mail falhar
            await pendentes.deleteOne({ tokenHash });
            throw erro;
        }

        return res.status(200).json({
            mensagem: "Enviamos um link de confirmação para seu e-mail cadastrado."
        });

    } catch (erro) {
        console.error("Erro ao solicitar alteração de perfil:", erro);

        return res.status(503).json({
            mensagem: "Não foi possível solicitar a alteração do perfil."
        });
    }
});

// confirmação de alteração de nome e/ou e-mail
router.post("/confirmar-alteracao", async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { token } = req.body ?? {};

        if (
            typeof token !== "string" ||
            !/^[a-f0-9]{64}$/.test(token)
        ) {
            return res.status(400).json({
                mensagem: "Token inválido."
            });
        }

        const banco = obterBanco();
        const pendentes = banco.collection("alteracoesPendentes");
        const usuarios = banco.collection("usuarios");

        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);

        // localiza uma solicitação ainda válida
        const solicitacao = await pendentes.findOne({
            tokenHash,
            tipo: "PERFIL",
            expiraEm: { $gt: new Date() }
        });

        if (
            !solicitacao ||
            !(solicitacao.usuarioId instanceof ObjectId)
        ) {
            return res.status(400).json({
                mensagem: "Link inválido ou expirado."
            });
        }

        const usuarioId = solicitacao.usuarioId;
        const alteracoes = solicitacao.alteracoes as {
            nome?: string;
            email?: string;
        };

        // confere novamente se o e-mail continua disponível
        if (alteracoes.email) {
            const emailExistente = await usuarios.findOne({
                email: alteracoes.email,
                _id: { $ne: usuarioId }
            });

            if (emailExistente) {
                return res.status(409).json({
                    mensagem: "Este e-mail já está cadastrado."
                });
            }
        }

        // consome o token de forma atômica para impedir reutilização
        const consumido = await pendentes.findOneAndDelete({
            _id: solicitacao._id,
            tokenHash,
            tipo: "PERFIL",
            expiraEm: { $gt: new Date() }
        });

        if (!consumido) {
            return res.status(400).json({
                mensagem: "Link inválido, expirado ou já utilizado."
            });
        }

        // prepara somente os campos permitidos para atualização
        const camposAtualizados: {
            nome?: string;
            email?: string;
        } = {};

        if (typeof alteracoes.nome === "string") {
            camposAtualizados.nome = alteracoes.nome;
        }

        if (typeof alteracoes.email === "string") {
            camposAtualizados.email = alteracoes.email;
        }

        if (Object.keys(camposAtualizados).length === 0) {
            return res.status(400).json({
                mensagem: "Nenhuma alteração válida foi encontrada."
            });
        }

        const resultado = await usuarios.updateOne(
            { _id: usuarioId, ativo: true },
            { $set: camposAtualizados }
        );

        // confere se a operação encontrou ou alterou o registro esperado
        if (resultado.matchedCount !== 1) {
            return res.status(404).json({
                mensagem: "Usuário ativo não encontrado."
            });
        }

        // atualiza também o nome de registros legados de tutores
        if (camposAtualizados.nome) {
            await banco.collection("tutores").updateMany(
                { usuarioId },
                { $set: { nome: camposAtualizados.nome } }
            );
        }

        return res.status(200).json({
            mensagem: "Perfil atualizado com sucesso!"
        });

    } catch (erro) {
        if (erro instanceof MongoServerError && erro.code === 11000) {
            return res.status(409).json({
                mensagem: "Este e-mail já está cadastrado."
            });
        }

        console.error("Erro ao confirmar alteração de perfil:", erro);

        return res.status(500).json({
            mensagem: "Não foi possível confirmar a alteração do perfil."
        });
    }
});

// alteração de senha para quem ainda sabe a senha atual
router.patch("/alterar-senha", autenticar, async (req, res) => {
    console.log("[TESTE SENHA] Requisição recebida!");
    try {
        // separa os campos enviados no corpo da requisição
        const { senhaAtual, novaSenha, confirmarSenha } = req.body ?? {};

        if (
            typeof senhaAtual !== "string" || !senhaAtual ||
            typeof novaSenha !== "string" || novaSenha.length < 8 ||
            novaSenha !== confirmarSenha
        ) {
            return res.status(400).json({
                mensagem: "Informe a senha atual, uma nova senha de pelo menos 8 caracteres e a confirmação."
            });
        }

        const banco = obterBanco();
        const usuarios = banco.collection("usuarios");
        // pega o id que a autenticação colocou na resposta
        const usuarioId = new ObjectId(res.locals.usuarioId);
        const usuario = await usuarios.findOne({
            _id: usuarioId,
            ativo: true
        });

        if (!usuario || typeof usuario.senhaHash !== "string") {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }

        if (!await verificarSenha(senhaAtual, usuario.senhaHash)) {
            return res.status(401).json({
                mensagem: "Senha atual incorreta."
            });
        }

        if (senhaAtual === novaSenha) {
            return res.status(400).json({
                mensagem: "A nova senha deve ser diferente da atual."
            });
        }

        // gera o hash que vai ser salvo no lugar da senha
        const novoHash = await gerarHashSenha(novaSenha);

        // gera um token temporário para confirmação
        const token = randomBytes(32).toString("hex");
        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);
        // define até quando o link pode ser usado
        const expiraEm = new Date(Date.now() + PRAZO_RECUPERACAO_MS);

        const pendentes = banco.collection("alteracoesPendentes");

        // invalida apenas solicitações anteriores de alteração de senha
        await pendentes.deleteMany({
            usuarioId,
            tipo: "SENHA"
        });

        // guarda a alteração enquanto ela espera confirmação
        await pendentes.insertOne({
            usuarioId,
            tipo: "SENHA",
            senhaHash: novoHash,
            senhaHashAnterior: usuario.senhaHash,
            tokenHash,
            expiraEm,
            criadoEm: new Date()
        });

        try {
            const urlBase = process.env.FRONTEND_URL;

            if (!urlBase || !/^https?:\/\//.test(urlBase)) {
                throw new Error("FRONTEND_URL não configurada corretamente.");
            }

            // monta o link com o token que será enviado por e-mail
            const link = new URL("/", urlBase);
            link.searchParams.set("tipo", "confirmar-alteracao-senha");
            link.searchParams.set("token", token);

            const { transporte, remetente } = configurarEmail();

            console.log("[TESTE SENHA] Tentando enviar e-mail...");
            await transporte.sendMail({
                from: remetente,
                to: usuario.email,
                subject: "PetCare - Confirmação de alteração de senha",
                text:
                    "Recebemos uma solicitação de alteração da sua senha.\n\n" +
                    `Acesse o link para confirmar: ${link.toString()}\n\n` +
                    "O link expira em 15 minutos e só pode ser usado uma vez.\n" +
                    "Se você não solicitou essa alteração, ignore esta mensagem."
            });
        console.log("[TESTE SENHA] SMTP aceitou o envio!");
        } catch (erro) {
            // remove o pedido se o envio do e-mail falhar
            await pendentes.deleteOne({ tokenHash });
            throw erro;
        }

        return res.status(200).json({
            mensagem: "Enviamos um link de confirmação para seu e-mail cadastrado. Sua senha ainda não foi alterada."
        });

    } catch (erro) {
        console.error("Erro ao alterar senha:", erro);

        return res.status(503).json({
            mensagem: "Não foi possível alterar a senha."
        });
    }
});

// confirma a alteração de senha por e-mail
router.post("/confirmar-alteracao-senha", async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { token } = req.body ?? {};

        if (typeof token !== "string" || !/^[a-f0-9]{64}$/.test(token)) {
            return res.status(400).json({
                mensagem: "Token inválido ou expirado."
            });
        }

        const banco = obterBanco();
        const pendentes = banco.collection("alteracoesPendentes");
        const usuarios = banco.collection("usuarios");

        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);

        const solicitacao = await pendentes.findOne({
            tokenHash,
            tipo: "SENHA",
            expiraEm: { $gt: new Date() }
        });

        if (
            !solicitacao ||
            !(solicitacao.usuarioId instanceof ObjectId) ||
            typeof solicitacao.senhaHash !== "string" ||
            typeof solicitacao.senhaHashAnterior !== "string"
        ) {
            return res.status(400).json({
                mensagem: "Token inválido ou expirado."
            });
        }

        const consumido = await pendentes.findOneAndDelete({
            _id: solicitacao._id,
            tokenHash,
            tipo: "SENHA",
            expiraEm: { $gt: new Date() }
        });

        if (!consumido) {
            return res.status(400).json({
                mensagem: "Token inválido ou expirado."
            });
        }

        const resultado = await usuarios.updateOne(
            {
                _id: solicitacao.usuarioId,
                senhaHash: solicitacao.senhaHashAnterior,
                ativo: true
            },
            {
                $set: { senhaHash: solicitacao.senhaHash }
            }
        );

        // confere se a operação encontrou ou alterou o registro esperado
        if (resultado.matchedCount !== 1) {
            return res.status(409).json({
                mensagem: "A senha foi alterada em outra operação. Solicite uma nova alteração."
            });
        }

        await pendentes.deleteMany({
            usuarioId: solicitacao.usuarioId,
            tipo: "SENHA"
        });

        return res.status(200).json({
            mensagem: "Senha alterada com sucesso! Faça login novamente."
        });

    } catch (erro) {
        console.error("Erro ao confirmar alteração de senha:", erro);

        return res.status(500).json({
            mensagem: "Erro interno ao confirmar alteração de senha."
        });
    }
});

// solicitação pública de recuperação de senha
router.post("/esqueci-senha", async (req, res) => {
    const respostaGenerica = {
        mensagem: "Se o e-mail estiver cadastrado, enviaremos instruções de recuperação."
    };

    try {
        // separa os campos enviados no corpo da requisição
        const { email } = req.body ?? {};

        if (typeof email !== "string" || !EMAIL_REGEX.test(normalizarEmail(email))) {
            return res.status(400).json({
                mensagem: "Informe um e-mail válido."
            });
        }

        const banco = obterBanco();
        const usuario = await banco.collection("usuarios").findOne({
            email: normalizarEmail(email),
            ativo: true
        });

        if (!usuario || !(usuario._id instanceof ObjectId)) {
            return res.status(200).json(respostaGenerica);
        }

        const { transporte, remetente } = configurarEmail();
        const urlBase = process.env.FRONTEND_URL;

        if (!urlBase || !/^https?:\/\//.test(urlBase)) {
            throw new Error("FRONTEND_URL não configurada corretamente.");
        }

        const token = randomBytes(32).toString("hex");
        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);
        // define até quando o link pode ser usado
        const expiraEm = new Date(Date.now() + PRAZO_RECUPERACAO_MS);

        // uma solicitação nova invalida os tokens anteriores do usuário
        const recuperacoes = banco.collection("recuperacoesSenha");
        await recuperacoes.deleteMany({ usuarioId: usuario._id });

        // guarda o pedido de recuperação com o prazo de validade
        await recuperacoes.insertOne({
            usuarioId: usuario._id,
            tokenHash,
            expiraEm,
            criadoEm: new Date()
        });

        // monta o link com o token que será enviado por e-mail
        const link = new URL("/redefinir-senha", urlBase);
        link.searchParams.set("token", token);

        try {
            await transporte.sendMail({
                from: remetente,
                to: usuario.email,
                subject: "PetCare - Recuperação de senha",
                text:
                    "Recebemos um pedido para redefinir sua senha.\n\n" +
                    `Acesse o link: ${link.toString()}\n\n` +
                    "O link expira em 15 minutos e só pode ser usado uma vez.\n" +
                    "Se você não solicitou, ignore esta mensagem."
            });
        } catch (erro) {
            // remove o pedido se o envio do e-mail falhar
            await recuperacoes.deleteOne({ tokenHash });
            throw erro;
        }

        return res.status(200).json(respostaGenerica);
    } catch (erro) {
        console.error("Erro ao solicitar recuperação de senha:", erro);

        return res.status(503).json({
            mensagem: "Serviço de recuperação indisponível. Tente novamente mais tarde."
        });
    }
});

// redefinição de senha com token temporário recebido por e-mail
router.post("/redefinir-senha", async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { token, novaSenha, confirmarSenha } = req.body ?? {};

        if (
            typeof token !== "string" || !/^[a-f0-9]{64}$/.test(token) ||
            typeof novaSenha !== "string" || novaSenha.length < 8 ||
            novaSenha !== confirmarSenha
        ) {
            return res.status(400).json({
                mensagem: "Token ou dados da nova senha inválidos."
            });
        }

        const banco = obterBanco();
        const recuperacoes = banco.collection("recuperacoesSenha");
        // usa o hash para lidar com o token no banco
        const tokenHash = hashToken(token);

        const recuperacao = await recuperacoes.findOne({
            tokenHash,
            expiraEm: { $gt: new Date() }
        });

        if (!recuperacao || !(recuperacao.usuarioId instanceof ObjectId)) {
            return res.status(400).json({
                mensagem: "Link inválido ou expirado."
            });
        }

        // gera o hash que vai ser salvo no lugar da senha
        const novoHash = await gerarHashSenha(novaSenha);

        // consome o token de forma atômica, evitando reutilização simultânea
        const consumido = await recuperacoes.findOneAndDelete({
            _id: recuperacao._id,
            tokenHash,
            expiraEm: { $gt: new Date() }
        });

        if (!consumido) {
            return res.status(400).json({
                mensagem: "Link inválido, expirado ou já utilizado."
            });
        }

        const resultado = await banco.collection("usuarios").updateOne(
            { _id: recuperacao.usuarioId, ativo: true },
            { $set: { senhaHash: novoHash } }
        );

        // confere se a operação encontrou ou alterou o registro esperado
        if (resultado.modifiedCount !== 1) {
            return res.status(400).json({
                mensagem: "Não foi possível redefinir a senha."
            });
        }

        await recuperacoes.deleteMany({
            usuarioId: recuperacao.usuarioId
        });

        return res.status(200).json({
            mensagem: "Senha redefinida com sucesso! Faça login novamente."
        });
    } catch (erro) {
        console.error("Erro ao redefinir senha:", erro);

        return res.status(503).json({
            mensagem: "Não foi possível redefinir a senha."
        });
    }
});

export default router;