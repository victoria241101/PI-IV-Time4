import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// Cadastra uma tarefa clínica
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                descricao,
                enfermeiroId,
                prazo,
                observacoes
            } = req.body;

            // Verifica os campos obrigatórios
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

            // Verifica se o prazo é uma data válida
            const dataPrazo = new Date(prazo);

            if (isNaN(dataPrazo.getTime())) {
                return res.status(400).json({
                    mensagem: "Prazo inválido."
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

            // Aceita IDs antigos em texto e ObjectIds
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

            // Verifica se o enfermeiro responsável existe
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

            // Registra a tarefa clínica
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

// Permite que o enfermeiro conclua uma tarefa clínica
router.patch(
    "/:id/concluir",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const id = String(req.params.id);
            const { observacoesConclusao } = req.body ?? {};

            // Verifica se o ID da tarefa é válido
            if (!ObjectId.isValid(id)) {
                return res.status(400).json({
                    mensagem: "ID da tarefa inválido."
                });
            }

            // Verifica se as observações são um texto
            if (
                observacoesConclusao !== undefined &&
                typeof observacoesConclusao !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
            }

            const banco = obterBanco();

            // Identifica o enfermeiro logado
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

            // Busca a tarefa clínica
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

            // Apenas o enfermeiro responsável pode concluir
            if (tarefa.enfermeiroId !== enfermeiro._id) {
                return res.status(403).json({
                    mensagem: "Você não é o enfermeiro responsável por esta tarefa."
                });
            }

            // Atualiza somente se a tarefa ainda estiver pendente
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

// Lista as tarefas clínicas de um pet
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

            // Aceita IDs antigos e ObjectIds do MongoDB
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Confirma se o pet existe
            const pet = await banco
                .collection<{ _id: string | ObjectId; nome: string }>("pets")
                .findOne({
                    _id: { $in: idsPet }
                });
                
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Busca as tarefas do pet
            const tarefas = await banco
                .collection("tarefasClinicas")
                .find({
                    petId: { $in: idsPet }
                })
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