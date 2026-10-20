import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
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

// 6.1 POST /campanhas - Criação de campanha (apenas papéis de gestão: SECRETARIA)
router.post(
    "/",
    autenticar,
    permitirFuncoes(...PAPEIS_GESTAO_CAMPANHAS),
    async (req, res) => {
        try {
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

// 6.2 GET /campanhas - Listagem de campanhas (qualquer autenticado)
router.get("/", autenticar, async (req, res) => {
    try {
        const daEquipe = ehEquipe(res.locals.usuarioTipo);
        const statusParam = req.query.status;

        const filtro: Record<string, unknown> = {};

        if (!daEquipe) {
            // Não-equipe sempre vê apenas campanhas ativas
            filtro.status = "ativa";
        } else {
            if (statusParam === "encerrada") {
                filtro.status = "encerrada";
            } else if (statusParam === "todas") {
                // Sem filtro de status, lista todas
            } else {
                // Padrão: ativas
                filtro.status = "ativa";
            }
        }

        const banco = obterBanco();
        const campanhas = await banco.collection<CampanhaDocumento>("campanhas")
            .find(filtro)
            .sort({ criadoEm: -1 })
            .limit(50)
            .toArray();

        // Cálculo de progresso em paralelo (a falha de um não derruba os demais)
        const campanhasFormatadas = await Promise.all(
            campanhas.map(async (campanha) => {
                const progresso = await obterProgresso(campanha);
                return formatarCampanha(campanha, progresso, daEquipe);
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

// 6.3 GET /campanhas/:id - Consulta de campanha por ID (qualquer autenticado)
router.get("/:id", autenticar, async (req, res) => {
    try {
        const id = req.params.id;

        if (typeof id !== "string" || !ObjectId.isValid(id)) {
            return res.status(400).json({
                mensagem: "ID da campanha inválido."
            });
        }

        const banco = obterBanco();
        const campanha = await banco.collection<CampanhaDocumento>("campanhas").findOne({
            _id: new ObjectId(id)
        });

        if (!campanha) {
            return res.status(404).json({
                mensagem: "Campanha não encontrada."
            });
        }

        const daEquipe = ehEquipe(res.locals.usuarioTipo);

        // Quem não é da equipe e pede uma campanha encerrada recebe 404
        if (!daEquipe && campanha.status === "encerrada") {
            return res.status(404).json({
                mensagem: "Campanha não encontrada."
            });
        }

        const progresso = await obterProgresso(campanha);
        const campanhaFormatada = formatarCampanha(campanha, progresso, daEquipe);

        return res.status(200).json({
            mensagem: "Campanha encontrada com sucesso!",
            campanha: campanhaFormatada
        });

    } catch (erro) {
        console.error("Erro ao buscar campanha:", erro);
        return res.status(500).json({
            mensagem: "Erro ao buscar campanha."
        });
    }
});

// 6.4 PATCH /campanhas/:id/encerrar - Encerramento manual (apenas SECRETARIA)
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

            // Atualização atômica condicional para garantir que ainda está ativa
            const resultado = await campanhas.updateOne(
                { _id: new ObjectId(id), status: "ativa" },
                { $set: { status: "encerrada" } }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Esta campanha já está encerrada."
                });
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
