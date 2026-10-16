import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";


const router = Router();

router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                atendimentoId,
                medicamento,
                dose,
                frequencia,
                duracao,
                orientacoes
            } = req.body;

            // Verifica os campos obrigatórios
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

            const banco = obterBanco();

            // Identifica o veterinário logado
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

            // Procura o pet (IDs antigos ou ObjectId)
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

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Procura o atendimento informado
            const idsAtendimento: (string | ObjectId)[] = [atendimentoId];

            if (ObjectId.isValid(atendimentoId)) {
                idsAtendimento.push(new ObjectId(atendimentoId));
            }

            const atendimento = await banco.collection<{
                _id: string | ObjectId;
                petId: string | ObjectId;
                veterinarioId: string;
            }>("atendimentos").findOne({
                _id: { $in: idsAtendimento },
                petId: { $in: idsPet },
                veterinarioId: veterinario._id
            });

            if (!atendimento) {
                return res.status(404).json({
                    mensagem:
                        "Atendimento não encontrado para este pet e veterinário."
                });
            }

            // Salva a prescrição
            const resultado = await banco
                .collection("prescricoes")
                .insertOne({
                    petId: pet._id,
                    atendimentoId: atendimento._id,
                    veterinarioId: veterinario._id,
                    medicamento: medicamento.trim(),
                    dose: dose.trim(),
                    frequencia: frequencia.trim(),
                    duracao: duracao.trim(),
                    orientacoes: orientacoes?.trim() ?? "",
                    dataPrescricao: new Date(),
                    status: "ativa"
                });

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

// Lista as prescrições de um pet
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

            // Aceita IDs antigos em texto e ObjectIds
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Verifica se o profissional está ativo
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

            // Verifica se o pet existe
            const pet = await banco.collection("pets").findOne({
                _id: { $in: idsPet } as any
            });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Busca as prescrições do pet
            const prescricoes = await banco
                .collection("prescricoes")
                .find({
                    petId: { $in: idsPet }
                })
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

export default router;