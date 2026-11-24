// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarAlta } from "../notificacoes/eventos.js";

const router = Router();

// cadastra orientações de alta clínica
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os dados enviados no corpo da requisição
            const {
                petId,
                cuidadosEmCasa,
                medicamentos,
                sinaisAlerta,
                orientacoesRetorno
            } = req.body ?? {};

            // verifica os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof cuidadosEmCasa !== "string" || !cuidadosEmCasa.trim() ||
                typeof medicamentos !== "string" || !medicamentos.trim() ||
                typeof sinaisAlerta !== "string" || !sinaisAlerta.trim() ||
                typeof orientacoesRetorno !== "string" || !orientacoesRetorno.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Preencha todos os campos obrigatórios."
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

            // salva as orientações de alta
            const resultado = await banco
                .collection("orientacoesAlta")
                .insertOne({
                    petId: pet._id,
                    veterinarioId: veterinario._id,
                    cuidadosEmCasa: cuidadosEmCasa.trim(),
                    medicamentos: medicamentos.trim(),
                    sinaisAlerta: sinaisAlerta.trim(),
                    orientacoesRetorno: orientacoesRetorno.trim(),
                    dataRegistro: new Date()
                });

            await notificarAlta(banco, {
                petId: pet._id,
                veterinarioUsuarioId: new ObjectId(res.locals.usuarioId),
                referenciaId: resultado.insertedId
            });

            // confirma o cadastro e devolve os dados do registro criado
            return res.status(201).json({
                mensagem: "Orientações de alta cadastradas com sucesso!",
                orientacaoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao cadastrar orientações de alta:", erro);

            return res.status(500).json({
                mensagem: "Erro ao cadastrar orientações de alta."
            });
        }
    }
);

// lista as orientações de alta de um pet
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

            // aceita ids antigos em texto e objectids
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

            // busca as orientações de alta do pet
            const orientacoes = await banco
                .collection("orientacoesAlta")
                .find({
                    petId: { $in: idsPet }
                })
                // coloca os registros mais recentes primeiro
                .sort({ dataRegistro: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Orientações de alta encontradas com sucesso!",
                pet: {
                    id: pet._id,
                    nome: pet.nome
                },
                quantidade: orientacoes.length,
                orientacoes
            });

        } catch (erro) {
            console.error("Erro ao consultar orientações de alta:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar orientações de alta."
            });
        }
    }
);

// permite que o tutor consulte as orientações de alta do próprio pet
router.get(
    "/tutor/pet/:petId",
    autenticar,
    permitirFuncoes("USUARIO"),
    async (req, res) => {
        try {
            const petId = String(req.params.petId);

            if (!petId.trim()) {
                return res.status(400).json({
                    mensagem: "ID do pet inválido."
                });
            }

            const banco = obterBanco();
            // pega o id que a autenticação colocou na resposta
            const usuarioId = new ObjectId(res.locals.usuarioId);

            // aceita ids antigos em texto e novos objectids
            const idsPossiveis: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPossiveis.push(new ObjectId(petId));
            }

            // busca o pet
            const pet = await banco.collection<{
                _id: string | ObjectId;
                tutorId: string | ObjectId;
                nome: string;
            }>("pets").findOne({
                _id: { $in: idsPossiveis }
            });

            // interrompe a operação se o pet não foi encontrado
            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // verifica se o usuário é o tutor desse pet
            const tutor = await banco.collection<{
                _id: string | ObjectId;
                usuarioId: ObjectId;
            }>("tutores").findOne({
                _id: pet.tutorId,
                usuarioId
            });

            if (!tutor) {
                return res.status(403).json({
                    mensagem: "Você não tem permissão para consultar as orientações deste pet."
                });
            }

            // busca as orientações de alta
            const orientacoes = await banco
                .collection("orientacoesAlta")
                .find({
                    petId: { $in: idsPossiveis }
                })
                // coloca os registros mais recentes primeiro
                .sort({ dataRegistro: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Orientações de alta encontradas com sucesso!",
                pet: {
                    id: pet._id,
                    nome: pet.nome
                },
                quantidade: orientacoes.length,
                orientacoes
            });

        } catch (erro) {
            console.error("Erro ao consultar orientações do tutor:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar orientações de alta."
            });
        }
    }
);

export default router;