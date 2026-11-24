// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarTarefaClinica } from "../notificacoes/eventos.js";

const router = Router();

// cadastra uma tarefa clínica
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os dados enviados no corpo da requisição
            const {
                petId,
                descricao,
                enfermeiroId,
                prazo,
                observacoes
            } = req.body;

            // verifica os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof descricao !== "string" || !descricao.trim() ||
                typeof enfermeiroId !== "string" || !enfermeiroId.trim() ||
                typeof prazo !== "string" || !prazo.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Preencha os campos obrigatórios."
                });
            }

            if (
                observacoes !== undefined &&
                typeof observacoes !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
            }

            // verifica se o prazo é uma data válida
            const dataPrazo = new Date(prazo);

            if (isNaN(dataPrazo.getTime())) {
                return res.status(400).json({
                    mensagem: "Prazo inválido."
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

            // aceita ids antigos em texto e objectids
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

            // verifica se o enfermeiro responsável existe
            const enfermeiro = await banco.collection<{
                _id: string;
                ativo: boolean;
            }>("enfermeiros").findOne({
                _id: enfermeiroId.trim(),
                ativo: true
            });

            if (!enfermeiro) {
                return res.status(404).json({
                    mensagem: "Enfermeiro não encontrado ou inativo."
                });
            }

            // registra a tarefa clínica
            const resultado = await banco
                .collection("tarefasClinicas")
                .insertOne({
                    petId: pet._id,
                    veterinarioId: veterinario._id,
                    enfermeiroId: enfermeiro._id,
                    descricao: descricao.trim(),
                    prazo: dataPrazo,
                    observacoes: observacoes?.trim() ?? "",
                    status: "pendente",
                    dataCriacao: new Date(),
                    dataConclusao: null
                });

            await notificarTarefaClinica(
                banco,
                {
                    _id: resultado.insertedId,
                    petId: pet._id,
                    enfermeiroId: enfermeiro._id,
                    descricao: descricao.trim()
                },
                new ObjectId(res.locals.usuarioId)
            );

            // confirma o cadastro e devolve os dados do registro criado
            return res.status(201).json({
                mensagem: "Tarefa clínica cadastrada com sucesso!",
                tarefaId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao cadastrar tarefa clínica:", erro);

            return res.status(500).json({
                mensagem: "Erro ao cadastrar tarefa clínica."
            });
        }
    }
);

// permite que o enfermeiro conclua uma tarefa clínica
router.patch(
    "/:id/concluir",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const id = String(req.params.id);
            // separa os campos enviados no corpo da requisição
            const { observacoesConclusao } = req.body ?? {};

            // verifica se o id da tarefa é válido
            if (!ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID da tarefa inválido."
                });
            }

            // verifica se as observações são um texto
            if (
                observacoesConclusao !== undefined &&
                typeof observacoesConclusao !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
            }

            const banco = obterBanco();

            // identifica o enfermeiro logado
            const enfermeiro = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("enfermeiros").findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!enfermeiro) {
                return res.status(403).json({
                    mensagem: "Enfermeiro não encontrado ou inativo."
                });
            }

            // busca a tarefa clínica
            const tarefa = await banco
                .collection("tarefasClinicas")
                .findOne({
                    _id: new ObjectId(id)
                });

            if (!tarefa) {
                return res.status(404).json({
                    mensagem: "Tarefa clínica não encontrada."
                });
            }

            // apenas o enfermeiro responsável pode concluir
            if (tarefa.enfermeiroId !== enfermeiro._id) {
                return res.status(403).json({
                    mensagem: "Você não é o enfermeiro responsável por esta tarefa."
                });
            }

            // atualiza somente se a tarefa ainda estiver pendente
            const resultado = await banco
                .collection("tarefasClinicas")
                .updateOne(
                    {
                        _id: new ObjectId(id),
                        status: "pendente"
                    },
                    {
                        $set: {
                            status: "concluida",
                            dataConclusao: new Date(),
                            observacoesConclusao:
                                observacoesConclusao?.trim() ?? ""
                        }
                    }
                );

            // confere se a operação encontrou ou alterou o registro esperado
            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Esta tarefa não está pendente."
                });
            }

            return res.status(200).json({
                mensagem: "Tarefa clínica concluída com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao concluir tarefa clínica:", erro);

            return res.status(500).json({
                mensagem: "Erro ao concluir tarefa clínica."
            });
        }
    }
);

// lista as tarefas clínicas de um pet
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

            // aceita ids antigos e objectids do mongodb
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // confirma se o pet existe
            const pet = await banco
                .collection<{ _id: string | ObjectId; nome: string }>("pets")
                .findOne({
                    _id: { $in: idsPet }
                });
                
            // interrompe a operação se o pet não foi encontrado
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // busca as tarefas do pet
            const tarefas = await banco
                .collection("tarefasClinicas")
                .find({
                    petId: { $in: idsPet }
                })
                // coloca os registros mais recentes primeiro
                .sort({ dataCriacao: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Tarefas clínicas encontradas com sucesso!",
                pet: {
                    id: pet._id,
                    nome: pet.nome
                },
                quantidade: tarefas.length,
                tarefas
            });

        } catch (erro) {
            console.error("Erro ao consultar tarefas clínicas:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar tarefas clínicas."
            });
        }
    }
);

export default router;