// Alinne Monteiro de Melo | RA: 24801649

import { Router, type RequestHandler } from "express";
import { ObjectId, MongoServerError, type Db, type Document } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarDosePrescrita as notificarDosePrescritaPadrao } from "../notificacoes/eventos.js";

export function criarRotasPrescricoes(deps: {
    autenticar: RequestHandler;
    obterBanco: () => Db;
    notificarDosePrescrita: typeof notificarDosePrescritaPadrao;
}) {
const { autenticar, obterBanco, notificarDosePrescrita } = deps;
const router = Router();

// cadastra uma prescrição para o pet
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os dados enviados no corpo da requisição
            const {
                petId,
                atendimentoId,
                medicamento,
                dose,
                frequencia,
                duracao,
                orientacoes,
                solicitacaoId
            } = req.body ?? {};

            // verifica os campos obrigatórios
            const campos = [
                petId,
                atendimentoId,
                medicamento,
                dose,
                frequencia,
                duracao
            ];

            if (
                campos.some(
                    campo =>
                        typeof campo !== "string" ||
                        !campo.trim()
                )
            ) {
                return res.status(400).json({
                    mensagem: "Preencha todos os campos obrigatórios."
                });
            }

            if (
                orientacoes !== undefined &&
                typeof orientacoes !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As orientações devem ser um texto."
                });
            }

            // Opcional para preservar os clientes existentes. O _id já é único no MongoDB.
            if (solicitacaoId !== undefined &&
                (typeof solicitacaoId !== "string" || !/^[a-f\d]{24}$/.test(solicitacaoId))) {
                return res.status(400).json({ mensagem: "Solicitação inválida." });
            }

            const banco = obterBanco();

            // identifica o veterinário logado
            const veterinario = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("veterinarios").findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            // procura o pet (ids antigos ou objectid)
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            const pet = await banco.collection<{
                _id: string | ObjectId;
                ativo?: boolean;
            }>("pets").findOne({
                _id: { $in: idsPet },
                ativo: { $ne: false }
            });

            // interrompe a operação se o pet não foi encontrado
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // procura o atendimento informado
            const idsAtendimento: (string | ObjectId)[] = [atendimentoId];

            if (ObjectId.isValid(atendimentoId)) {
                idsAtendimento.push(new ObjectId(atendimentoId));
            }

            const atendimento = await banco.collection<{
                _id: string | ObjectId;
                petId: string | ObjectId;
                veterinarioId: string | ObjectId;
            }>("atendimentos").findOne({
                _id: { $in: idsAtendimento },
                petId: { $in: idsPet },
                veterinarioId: { $in: [String(veterinario._id), veterinario._id] }
            });

            // interrompe se não encontrou o atendimento para vincular ao registro
            if (!atendimento) {
                return res.status(404).json({
                    mensagem:
                        "Atendimento não encontrado para este pet e veterinário."
                });
            }

            const prescricoes = banco.collection("prescricoes");
            const documento = {
                petId: pet._id,
                atendimentoId: atendimento._id,
                veterinarioId: veterinario._id,
                medicamento: medicamento.trim(),
                dose: dose.trim(),
                frequencia: frequencia.trim(),
                duracao: duracao.trim(),
                orientacoes: orientacoes?.trim() ?? ""
            };
            const idSolicitacao = solicitacaoId ? new ObjectId(solicitacaoId) : null;
            const responderExistente = (existente: Document) => {
                const mesmoPedido = Object.entries(documento).every(([campo, valor]) =>
                    String(existente[campo]) === String(valor));
                return mesmoPedido
                    ? res.status(200).json({ mensagem: "Prescrição cadastrada com sucesso!", prescricaoId: existente._id })
                    : res.status(409).json({ mensagem: "Solicitação já utilizada para outra prescrição." });
            };
            if (idSolicitacao) {
                const existente = await prescricoes.findOne({ _id: idSolicitacao });
                if (existente) return responderExistente(existente);
            }
            let resultado;
            try {
                resultado = await prescricoes.insertOne({
                    ...(idSolicitacao ? { _id: idSolicitacao } : {}),
                    ...documento,
                    dataPrescricao: new Date(),
                    status: "ativa"
                });
            } catch (erro) {
                // Dois envios simultâneos da mesma solicitação também geram um só registro.
                if (idSolicitacao && erro instanceof MongoServerError && erro.code === 11000) {
                    const existente = await prescricoes.findOne({ _id: idSolicitacao });
                    if (existente) return responderExistente(existente);
                }
                throw erro;
            }

            await notificarDosePrescrita(
                banco,
                {
                    _id: resultado.insertedId,
                    petId: pet._id,
                    medicamento: medicamento.trim(),
                    dose: dose.trim()
                },
                new ObjectId(res.locals.usuarioId)
            );

            // confirma o cadastro e devolve os dados do registro criado
            return res.status(201).json({
                mensagem: "Prescrição cadastrada com sucesso!",
                prescricaoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao cadastrar prescrição:", erro);

            return res.status(500).json({
                mensagem: "Erro ao cadastrar prescrição."
            });
        }
    }
);

// lista as prescrições de um pet
router.get(
    "/pet/:petId",
    autenticar,
    permitirFuncoes("VETERINARIO", "ENFERMEIRO"),
    async (req, res) => {
        try {
            const petId = req.params.petId;

            if (typeof petId !== "string" || !petId.trim()) {
                return res.status(400).json({
                    mensagem: "ID do pet inválido."
                });
            }

            const banco = obterBanco();

            // aceita ids antigos em texto e objectids
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // verifica se o profissional está ativo
            const usuarioId = new ObjectId(res.locals.usuarioId);
            const tipo = res.locals.usuarioTipo;

            const colecaoProfissionais =
                tipo === "VETERINARIO"
                    ? "veterinarios"
                    : "enfermeiros";

            const profissional = await banco
                .collection(colecaoProfissionais)
                .findOne({
                    usuarioId,
                    ativo: true
                });

            if (!profissional) {
                return res.status(403).json({
                    mensagem: "Profissional não encontrado ou inativo."
                });
            }

            // verifica se o pet existe
            const pet = await banco.collection("pets").findOne({
                _id: { $in: idsPet } as any
            });

            // interrompe a operação se o pet não foi encontrado
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // busca as prescrições do pet
            const prescricoes = await banco
                .collection("prescricoes")
                .find({
                    petId: { $in: idsPet }
                })
                // coloca os registros mais recentes primeiro
                .sort({ dataPrescricao: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Prescrições encontradas com sucesso!",
                prescricoes
            });

        } catch (erro) {
            console.error("Erro ao consultar prescrições:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar prescrições."
            });
        }
    }
);

return router;
}

export default criarRotasPrescricoes({
    autenticar, obterBanco, notificarDosePrescrita: notificarDosePrescritaPadrao
});
