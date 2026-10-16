import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// Solicita um exame veterinário
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                atendimentoId,
                tipo,
                nome,
                justificativa
            } = req.body;

            // Verifica os campos obrigatórios
            const campos = [petId, atendimentoId, tipo, nome];

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
                justificativa !== undefined &&
                typeof justificativa !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "A justificativa deve ser um texto."
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
                    mensagem: "Veterinário não encontrado ou inativo."
                });
            }

            // Aceita IDs antigos e ObjectIds do MongoDB
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Verifica se o pet existe
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

            // Verifica o atendimento
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

            // Registra a solicitação do exame
            const resultado = await banco
                .collection("exames")
                .insertOne({
                    petId: pet._id,
                    atendimentoId: atendimento._id,
                    veterinarioId: veterinario._id,
                    tipo: tipo.trim(),
                    nome: nome.trim(),
                    justificativa: justificativa?.trim() ?? "",
                    dataSolicitacao: new Date(),
                    status: "solicitado",
                    resultado: null,
                    dataResultado: null
                });

            return res.status(201).json({
                mensagem: "Exame solicitado com sucesso!",
                exameId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao solicitar exame:", erro);

            return res.status(500).json({
                mensagem: "Erro ao solicitar exame."
            });
        }
    }
);

// Registra o resultado de um exame solicitado
router.patch(
    "/:id/resultado",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const id = req.params.id;
            const { resultado } = req.body;

            // Verifica o ID do exame
            if (typeof id !== "string" || !ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID do exame inválido."
                });
            }

            // Verifica o resultado informado
            if (
                typeof resultado !== "string" ||
                !resultado.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe o resultado do exame."
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
                    mensagem: "Veterinário não encontrado ou inativo."
                });
            }

            const exames = banco.collection("exames");

            // Registra o resultado apenas se o exame
            // estiver solicitado e pertencer ao veterinário
            const atualizacao = await exames.updateOne(
                {
                    _id: new ObjectId(id),
                    veterinarioId: veterinario._id,
                    status: "solicitado"
                },
                {
                    $set: {
                        resultado: resultado.trim(),
                        status: "concluido",
                        dataResultado: new Date()
                    }
                }
            );

            if (atualizacao.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem:
                        "Exame não encontrado, já concluído ou pertence a outro veterinário."
                });
            }

            return res.status(200).json({
                mensagem: "Resultado do exame registrado com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao registrar resultado:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar resultado do exame."
            });
        }
    }
);

// Lista os exames de um pet
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
            const pet = await banco.collection<{
                _id: string | ObjectId;
            }>("pets").findOne({
                _id: { $in: idsPet }
            });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Busca todos os exames do pet
            const exames = await banco
                .collection("exames")
                .find({
                    petId: { $in: idsPet }
                })
                .sort({ dataSolicitacao: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Exames encontrados com sucesso!",
                exames
            });

        } catch (erro) {
            console.error("Erro ao consultar exames:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar exames."
            });
        }
    }
);

export default router;