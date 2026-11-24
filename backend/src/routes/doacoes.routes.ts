// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { notificarCampanha } from "../notificacoes/eventos.js";
import {
    ehEquipe,
    arredondarCentavos,
    validarValorDoacao,
    validarMetodoPagamento,
    deveEncerrarPorMeta,
    formatarCampanha,
    obterProgresso,
    type CampanhaDocumento
} from "../campanhasUtil.js";

interface DoacaoDocumento {
    _id: ObjectId;
    campanhaId: ObjectId;
    doadorId: ObjectId;
    valor: number;
    status: "pendente" | "aprovada" | "recusada";
    metodoPagamento: "pix" | "cartao";
    criadoEm: Date;
}

const router = Router();

// cria uma doação pendente para o usuário logado
router.post("/", autenticar, async (req, res) => {
    try {
        // separa os campos enviados no corpo da requisição
        const { campanhaId, valor, metodoPagamento } = req.body ?? {};

        if (typeof campanhaId !== "string" || !ObjectId.isValid(campanhaId)) {
            return res.status(400).json({
                mensagem: "ID da campanha inválido."
            });
        }

        const validacaoValor = validarValorDoacao(valor);
        if (!validacaoValor.ok) {
            return res.status(400).json({
                mensagem: validacaoValor.mensagem
            });
        }

        const validacaoMetodo = validarMetodoPagamento(metodoPagamento);
        if (!validacaoMetodo.ok) {
            return res.status(400).json({
                mensagem: validacaoMetodo.mensagem
            });
        }

        // pega o id que a autenticação colocou na resposta
        const usuarioId = res.locals.usuarioId;
        if (!usuarioId || !ObjectId.isValid(usuarioId)) {
            return res.status(401).json({
                mensagem: "Usuário autenticado inválido."
            });
        }

        const banco = obterBanco();
        const campanha = await banco.collection<CampanhaDocumento>("campanhas").findOne({
            _id: new ObjectId(campanhaId)
        });

        if (!campanha) {
            return res.status(404).json({
                mensagem: "Campanha não encontrada."
            });
        }

        if (campanha.status === "encerrada") {
            return res.status(409).json({
                mensagem: "Esta campanha já está encerrada."
            });
        }

        if (campanha.dataFim && new Date(campanha.dataFim).getTime() < Date.now()) {
            return res.status(409).json({
                mensagem: "Esta campanha já expirou pelo prazo final."
            });
        }

        const novaDoacao: DoacaoDocumento = {
            _id: new ObjectId(),
            campanhaId: new ObjectId(campanhaId),
            doadorId: new ObjectId(usuarioId),
            valor: validacaoValor.valor,
            status: "pendente",
            metodoPagamento: validacaoMetodo.valor,
            criadoEm: new Date()
        };

        const resultado = await banco.collection<DoacaoDocumento>("doacoes").insertOne(novaDoacao);

        return res.status(201).json({
            mensagem: "Doação registrada com sucesso!",
            doacaoId: resultado.insertedId.toString()
        });

    } catch (erro) {
        console.error("Erro ao registrar doação:", erro);
        return res.status(500).json({
            mensagem: "Erro ao registrar doação."
        });
    }
});

// confirma a doação feita pelo usuário logado
router.patch("/:id/confirmar", autenticar, async (req, res) => {
    try {
        const id = req.params.id;

        if (typeof id !== "string" || !ObjectId.isValid(id)) {
            return res.status(400).json({
                mensagem: "ID da doação inválido."
            });
        }

        // pega o id que a autenticação colocou na resposta
        const usuarioId = res.locals.usuarioId;
        if (!usuarioId || !ObjectId.isValid(usuarioId)) {
            return res.status(401).json({
                mensagem: "Usuário autenticado inválido."
            });
        }

        const banco = obterBanco();
        const doacoes = banco.collection<DoacaoDocumento>("doacoes");
        const campanhas = banco.collection<CampanhaDocumento>("campanhas");

        // confere quem fez a doação e se ela está pendente
        const doacao = await doacoes.findOne({
            _id: new ObjectId(id)
        });

        if (!doacao) {
            return res.status(404).json({
                mensagem: "Doação não encontrada."
            });
        }

        if (doacao.doadorId.toString() !== usuarioId) {
            return res.status(403).json({
                mensagem: "Você não tem permissão para confirmar esta doação."
            });
        }

        if (doacao.status !== "pendente") {
            return res.status(409).json({
                mensagem: `Esta doação não está pendente (status atual: ${doacao.status}).`
            });
        }

        // confirma a doação só se ela ainda estiver pendente
        const doacaoReivindicada = await doacoes.findOneAndUpdate(
            {
                _id: new ObjectId(id),
                doadorId: new ObjectId(usuarioId),
                status: "pendente"
            },
            {
                $set: { status: "aprovada" }
            },
            { returnDocument: "after" }
        );

        if (!doacaoReivindicada) {
            return res.status(409).json({
                mensagem: "Esta doação já foi processada por outra requisição."
            });
        }

        // soma o valor da doação ao total da campanha
        let campanhaAtualizada: CampanhaDocumento | null = null;

        try {
            campanhaAtualizada = await campanhas.findOneAndUpdate(
                {
                    _id: doacaoReivindicada.campanhaId,
                    status: "ativa"
                },
                {
                    $inc: { valorArrecadado: doacaoReivindicada.valor }
                },
                { returnDocument: "after" }
            );
        } catch (erroBanco) {
            console.error("Erro ao somar arrecadação na campanha:", erroBanco);

            // tenta voltar a doação para pendente se a soma falhar
            try {
                await doacoes.updateOne(
                    { _id: doacaoReivindicada._id, status: "aprovada" },
                    { $set: { status: "pendente" } }
                );
            } catch (erroCompensacao) {
                console.error("Erro na compensação do status da doação:", erroCompensacao);
            }

            return res.status(500).json({
                mensagem: "Erro ao processar a doação na campanha."
            });
        }

        // trata o caso em que a campanha não está ativa
        if (!campanhaAtualizada) {
            await doacoes.updateOne(
                { _id: doacaoReivindicada._id },
                { $set: { status: "recusada" } }
            );

            return res.status(409).json({
                mensagem: "A campanha não está mais ativa para receber doações. A doação foi recusada."
            });
        }

        // encerra a campanha quando a meta é atingida
        if (deveEncerrarPorMeta(campanhaAtualizada.valorArrecadado, campanhaAtualizada.metaValor)) {
            const resultadoEncerramento = await campanhas.updateOne(
                { _id: campanhaAtualizada._id, status: "ativa" },
                { $set: { status: "encerrada" } }
            );
            // confere se a operação encontrou ou alterou o registro esperado
            if (resultadoEncerramento.modifiedCount === 1) {
                await notificarCampanha(
                    banco,
                    "campanha_meta_atingida",
                    campanhaAtualizada,
                    new ObjectId(res.locals.usuarioId)
                );
            }
            campanhaAtualizada.status = "encerrada";
        }

        // calcula o progresso da campanha pelo java
        const progresso = await obterProgresso(campanhaAtualizada);

        const daEquipe = ehEquipe(res.locals.usuarioTipo);
        const campanhaFormatada = formatarCampanha(campanhaAtualizada, progresso, daEquipe);

        return res.status(200).json({
            mensagem: "Doação confirmada com sucesso!",
            doacao: {
                _id: doacaoReivindicada._id.toString(),
                campanhaId: doacaoReivindicada.campanhaId.toString(),
                valor: arredondarCentavos(doacaoReivindicada.valor),
                status: "aprovada",
                metodoPagamento: doacaoReivindicada.metodoPagamento,
                criadoEm: doacaoReivindicada.criadoEm
            },
            campanha: campanhaFormatada
        });

    } catch (erro) {
        console.error("Erro ao confirmar doação:", erro);
        return res.status(500).json({
            mensagem: "Erro ao confirmar doação."
        });
    }
});

// lista as doações de uma campanha
router.get("/", autenticar, async (req, res) => {
    try {
        const { campanhaId } = req.query;

        if (typeof campanhaId !== "string" || !ObjectId.isValid(campanhaId)) {
            return res.status(400).json({
                mensagem: "ID da campanha inválido ou não informado."
            });
        }

        // pega o id que a autenticação colocou na resposta
        const usuarioId = res.locals.usuarioId;
        if (!usuarioId || !ObjectId.isValid(usuarioId)) {
            return res.status(401).json({
                mensagem: "Usuário autenticado inválido."
            });
        }

        const banco = obterBanco();
        const campanha = await banco.collection<CampanhaDocumento>("campanhas").findOne({
            _id: new ObjectId(campanhaId)
        });

        if (!campanha) {
            return res.status(404).json({
                mensagem: "Campanha não encontrada."
            });
        }

        const daEquipe = ehEquipe(res.locals.usuarioTipo);

        // a equipe vê todas as doações e o tutor vê apenas as próprias
        const filtro: Record<string, unknown> = {
            campanhaId: new ObjectId(campanhaId)
        };

        if (!daEquipe) {
            filtro.doadorId = new ObjectId(usuarioId);
        }

        const doacoes = await banco.collection<DoacaoDocumento>("doacoes")
            .find(filtro)
            // coloca os registros mais recentes primeiro
            .sort({ criadoEm: -1 })
            .toArray();

        // prepara a lista de doações para a resposta
        const doacoesFormatadas = doacoes.map((doacao) => {
            const formatada: Record<string, unknown> = {
                _id: doacao._id.toString(),
                campanhaId: doacao.campanhaId.toString(),
                valor: arredondarCentavos(doacao.valor),
                status: doacao.status,
                metodoPagamento: doacao.metodoPagamento,
                criadoEm: doacao.criadoEm
            };

            if (daEquipe) {
                formatada.doadorId = doacao.doadorId.toString();
            }

            return formatada;
        });

        return res.status(200).json({
            mensagem: "Doações listadas com sucesso!",
            doacoes: doacoesFormatadas
        });

    } catch (erro) {
        console.error("Erro ao listar doações:", erro);
        return res.status(500).json({
            mensagem: "Erro ao listar doações."
        });
    }
});

export default router;
