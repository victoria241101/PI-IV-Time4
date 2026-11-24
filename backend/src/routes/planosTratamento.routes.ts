// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// cadastra um plano de tratamento
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os dados enviados no corpo da requisição
            const {
                petId,
                objetivo,
                orientacoes,
                dataInicio,
                dataFim
            } = req.body ?? {};

            // verifica os campos obrigatórios
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

            // verifica se as datas são válidas
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

            // o tratamento não pode terminar antes de começar
            if (fim < inicio) {
                return res.status(400).json({
                    mensagem: "A data final não pode ser anterior à inicial."
                });
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
                    mensagem: "Veterinário não encontrado ou inativo."
                });
            }

            // aceita ids em texto e objectids
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // verifica se o pet existe
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

            // salva o plano de tratamento
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

            // confirma o cadastro e devolve os dados do registro criado
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

// conclui um plano de tratamento
router.patch(
    "/:id/concluir",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const id = String(req.params.id);
            // separa os campos enviados no corpo da requisição
            const { observacoesConclusao } = req.body ?? {};

            // verifica se o id do plano é válido
            if (!ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID do plano inválido."
                });
            }

            // verifica as observações, caso sejam informadas
            if (
                observacoesConclusao !== undefined &&
                typeof observacoesConclusao !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
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
                    mensagem: "Veterinário não encontrado ou inativo."
                });
            }

            // busca o plano de tratamento
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

            // apenas o veterinário responsável pode concluir
            if (plano.veterinarioId !== veterinario._id) {
                return res.status(403).json({
                    mensagem: "Você não é o veterinário responsável por este plano."
                });
            }

            // conclui somente se o plano estiver ativo
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

            // confere se a operação encontrou ou alterou o registro esperado
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

// lista os planos de tratamento de um pet
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

            // aceita ids em texto e objectids do mongodb
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // verifica se o pet existe
            const pet = await banco
                .collection<{
                    _id: string | ObjectId;
                    nome: string;
                }>("pets")
                .findOne({
                    _id: { $in: idsPet }
                });

            // interrompe a operação se o pet não foi encontrado
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // busca os planos de tratamento do pet
            const planos = await banco
                .collection("planosTratamento")
                .find({
                    petId: { $in: idsPet }
                })
                // coloca os registros mais recentes primeiro
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