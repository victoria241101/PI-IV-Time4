// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import {
    autenticar,
    autenticarOpcional
} from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarCampanha } from "../notificacoes/eventos.js";
import {
    PAPEIS_GESTAO_CAMPANHAS,
    ehEquipe,
    validarMeta,
    validarTitulo,
    validarDescricao,
    validarImagemCapa,
    validarDatasCampanha,
    formatarCampanha,
    obterProgresso,
    type CampanhaDocumento
} from "../campanhasUtil.js";

const router = Router();

// permite que a secretaria crie uma campanha
router.post(
    "/",
    autenticar,
    permitirFuncoes(...PAPEIS_GESTAO_CAMPANHAS),
    async (req, res) => {
        try {
            // separa os dados enviados no corpo da requisição
            const {
                titulo,
                descricao,
                metaValor,
                imagemCapa,
                dataInicio,
                dataFim
            } = req.body ?? {};

            const validacaoTitulo = validarTitulo(titulo);
            if (!validacaoTitulo.ok) {
                return res.status(400).json({ mensagem: validacaoTitulo.mensagem });
            }

            const validacaoDescricao = validarDescricao(descricao);
            if (!validacaoDescricao.ok) {
                return res.status(400).json({ mensagem: validacaoDescricao.mensagem });
            }

            const validacaoMeta = validarMeta(metaValor);
            if (!validacaoMeta.ok) {
                return res.status(400).json({ mensagem: validacaoMeta.mensagem });
            }

            const validacaoImagem = validarImagemCapa(imagemCapa);
            if (!validacaoImagem.ok) {
                return res.status(400).json({ mensagem: validacaoImagem.mensagem });
            }

            const validacaoDatas = validarDatasCampanha(dataInicio, dataFim);
            if (!validacaoDatas.ok) {
                return res.status(400).json({ mensagem: validacaoDatas.mensagem });
            }

            // pega o id que a autenticação colocou na resposta
            const usuarioId = res.locals.usuarioId;
            if (!usuarioId || !ObjectId.isValid(usuarioId)) {
                return res.status(401).json({ mensagem: "Usuário autenticado inválido." });
            }

            const novaCampanha: CampanhaDocumento = {
                _id: new ObjectId(),
                criadoPorId: new ObjectId(usuarioId),
                titulo: validacaoTitulo.valor,
                descricao: validacaoDescricao.valor,
                metaValor: validacaoMeta.valor,
                valorArrecadado: 0,
                status: "ativa",
                imagemCapa: validacaoImagem.valor,
                dataInicio: validacaoDatas.valor.dataInicio,
                dataFim: validacaoDatas.valor.dataFim,
                criadoEm: new Date()
            };

            const banco = obterBanco();
            await banco.collection<CampanhaDocumento>("campanhas").insertOne(novaCampanha);

            return res.status(201).json({
                mensagem: "Campanha criada com sucesso!",
                campanhaId: novaCampanha._id.toString()
            });

        } catch (erro) {
            console.error("Erro ao criar campanha:", erro);
            return res.status(500).json({
                mensagem: "Erro ao criar campanha."
            });
        }
    }
);

// lista as campanhas
router.get("/", autenticarOpcional, async (req, res) => {
    try {
        const banco = obterBanco();

        const campanhas = await banco
            .collection<CampanhaDocumento>("campanhas")
            .find({ status: "ativa" })
            // coloca os registros mais recentes primeiro
            .sort({ criadoEm: -1 })
            .limit(50)
            .toArray();

        // prepara os dados das campanhas para a resposta
        const campanhasFormatadas = await Promise.all(
            campanhas.map(async (campanha) => {
                // busca o progresso a partir dos valores da campanha
                const progresso = await obterProgresso(campanha);

                return formatarCampanha(
                    campanha,
                    progresso,
                    false
                );
            })
        );

        return res.status(200).json({
            mensagem: "Campanhas listadas com sucesso!",
            campanhas: campanhasFormatadas
        });

    } catch (erro) {
        console.error("Erro ao listar campanhas:", erro);

        return res.status(500).json({
            mensagem: "Erro ao listar campanhas."
        });
    }
});

// busca uma campanha pelo id
router.get("/:id", autenticarOpcional, async (req, res) => {
    try {
        const id = req.params.id;

        if (typeof id !== "string" || !ObjectId.isValid(id)) {
            return res.status(400).json({
                mensagem: "ID da campanha inválido."
            });
        }

        const banco = obterBanco();

        const campanha = await banco
            .collection<CampanhaDocumento>("campanhas")
            .findOne({
                _id: new ObjectId(id),
                status: "ativa"
            });

        if (!campanha) {
            return res.status(404).json({
                mensagem: "Campanha não encontrada."
            });
        }

        // busca o progresso a partir dos valores da campanha
        const progresso = await obterProgresso(campanha);

        return res.status(200).json({
            mensagem: "Campanha encontrada com sucesso!",
            campanha: formatarCampanha(
                campanha,
                progresso,
                false
            )
        });

    } catch (erro) {
        console.error("Erro ao buscar campanha:", erro);

        return res.status(500).json({
            mensagem: "Erro ao buscar campanha."
        });
    }
});

// permite que a secretaria encerre uma campanha
router.patch(
    "/:id/encerrar",
    autenticar,
    permitirFuncoes(...PAPEIS_GESTAO_CAMPANHAS),
    async (req, res) => {
        try {
            const id = req.params.id;

            if (typeof id !== "string" || !ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID da campanha inválido."
                });
            }

            const banco = obterBanco();
            const campanhas = banco.collection<CampanhaDocumento>("campanhas");

            const campanhaExistente = await campanhas.findOne({
                _id: new ObjectId(id)
            });

            if (!campanhaExistente) {
                return res.status(404).json({
                    mensagem: "Campanha não encontrada."
                });
            }

            if (campanhaExistente.status === "encerrada") {
                return res.status(409).json({
                    mensagem: "Esta campanha já está encerrada."
                });
            }

            // encerra a campanha só se ela ainda estiver ativa
            const resultado = await campanhas.updateOne(
                { _id: new ObjectId(id), status: "ativa" },
                { $set: { status: "encerrada" } }
            );

            // confere se a operação encontrou ou alterou o registro esperado
            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Esta campanha já está encerrada."
                });
            }

            // confere se a operação encontrou ou alterou o registro esperado
            if (resultado.modifiedCount === 1) {
                await notificarCampanha(
                    banco,
                    "campanha_encerrada",
                    { ...campanhaExistente, status: "encerrada" },
                    new ObjectId(res.locals.usuarioId)
                );
            }

            return res.status(200).json({
                mensagem: "Campanha encerrada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao encerrar campanha:", erro);
            return res.status(500).json({
                mensagem: "Erro ao encerrar campanha."
            });
        }
    }
);

export default router;
