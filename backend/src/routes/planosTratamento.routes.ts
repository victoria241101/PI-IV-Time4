import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// Cadastra um plano de tratamento
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                objetivo,
                orientacoes,
                dataInicio,
                dataFim
            } = req.body ?? {};

            // Verifica os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof objetivo !== "string" || !objetivo.trim() ||
                typeof orientacoes !== "string" || !orientacoes.trim() ||
                typeof dataInicio !== "string" || !dataInicio.trim() ||
                typeof dataFim !== "string" || !dataFim.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Preencha os campos obrigatórios."
                });
            }

            // Verifica se as datas são válidas
            const inicio = new Date(dataInicio);
            const fim = new Date(dataFim);

            if (
                isNaN(inicio.getTime()) ||
                isNaN(fim.getTime())
            ) {
                return res.status(400).json({
                    mensagem: "Informe datas válidas."
                });
            }

            // O tratamento não pode terminar antes de começar
            if (fim < inicio) {
                return res.status(400).json({
                    mensagem: "A data final não pode ser anterior à inicial."
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

            // Aceita IDs em texto e ObjectIds
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

            // Salva o plano de tratamento
            const resultado = await banco
                .collection("planosTratamento")
                .insertOne({
                    petId: pet._id,
                    veterinarioId: veterinario._id,
                    objetivo: objetivo.trim(),
                    orientacoes: orientacoes.trim(),
                    dataInicio: inicio,
                    dataFim: fim,
                    status: "ativo",
                    dataCriacao: new Date(),
                    dataConclusao: null
                });

            return res.status(201).json({
                mensagem: "Plano de tratamento cadastrado com sucesso!",
                planoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao cadastrar plano de tratamento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao cadastrar plano de tratamento."
            });
        }
    }
);

// Conclui um plano de tratamento
router.patch(
    "/:id/concluir",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const id = String(req.params.id);
            const { observacoesConclusao } = req.body ?? {};

            // Verifica se o ID do plano é válido
            if (!ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID do plano inválido."
                });
            }

            // Verifica as observações, caso sejam informadas
            if (
                observacoesConclusao !== undefined &&
                typeof observacoesConclusao !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
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

            // Busca o plano de tratamento
            const plano = await banco
                .collection("planosTratamento")
                .findOne({
                    _id: new ObjectId(id)
                });

            if (!plano) {
                return res.status(404).json({
                    mensagem: "Plano de tratamento não encontrado."
                });
            }

            // Apenas o veterinário responsável pode concluir
            if (plano.veterinarioId !== veterinario._id) {
                return res.status(403).json({
                    mensagem: "Você não é o veterinário responsável por este plano."
                });
            }

            // Conclui somente se o plano estiver ativo
            const resultado = await banco
                .collection("planosTratamento")
                .updateOne(
                    {
                        _id: new ObjectId(id),
                        veterinarioId: veterinario._id,
                        status: "ativo"
                    },
                    {
                        $set: {
                            status: "concluido",
                            dataConclusao: new Date(),
                            observacoesConclusao:
                                observacoesConclusao?.trim() ?? ""
                        }
                    }
                );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Este plano não está ativo."
                });
            }

            return res.status(200).json({
                mensagem: "Plano de tratamento concluído com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao concluir plano:", erro);

            return res.status(500).json({
                mensagem: "Erro ao concluir plano de tratamento."
            });
        }
    }
);

// Lista os planos de tratamento de um pet
router.get(
    "/pet/:petId",
    autenticar,
    permitirFuncoes("VETERINARIO", "ENFERMEIRO"),
    async (req, res) => {
        try {
            const petId = String(req.params.petId);

            if (!petId.trim()) {
                return res.status(400).json({
                    mensagem: "Informe o ID do pet."
                });
            }

            const banco = obterBanco();

            // Aceita IDs em texto e ObjectIds do MongoDB
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Verifica se o pet existe
            const pet = await banco
                .collection<{
                    _id: string | ObjectId;
                    nome: string;
                }>("pets")
                .findOne({
                    _id: { $in: idsPet }
                });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Busca os planos de tratamento do pet
            const planos = await banco
                .collection("planosTratamento")
                .find({
                    petId: { $in: idsPet }
                })
                .sort({ dataCriacao: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Planos de tratamento encontrados com sucesso!",
                pet: {
                    id: pet._id,
                    nome: pet.nome
                },
                quantidade: planos.length,
                planos
            });

        } catch (erro) {
            console.error("Erro ao consultar planos de tratamento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar planos de tratamento."
            });
        }
    }
);

export default router;