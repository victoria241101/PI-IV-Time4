import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// Cadastra orientações de alta clínica
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                cuidadosEmCasa,
                medicamentos,
                sinaisAlerta,
                orientacoesRetorno
            } = req.body ?? {};

            // Verifica os campos obrigatórios
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

            // Salva as orientações de alta
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

// Lista as orientações de alta de um pet
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

            // Aceita IDs antigos em texto e ObjectIds
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

            // Busca as orientações de alta do pet
            const orientacoes = await banco
                .collection("orientacoesAlta")
                .find({
                    petId: { $in: idsPet }
                })
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

// Permite que o tutor consulte as orientações de alta do próprio pet
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
            const usuarioId = new ObjectId(res.locals.usuarioId);

            // Aceita IDs antigos em texto e novos ObjectIds
            const idsPossiveis: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPossiveis.push(new ObjectId(petId));
            }

            // Busca o pet
            const pet = await banco.collection<{
                _id: string | ObjectId;
                tutorId: string | ObjectId;
                nome: string;
            }>("pets").findOne({
                _id: { $in: idsPossiveis }
            });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            // Verifica se o usuário é o tutor desse pet
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

            // Busca as orientações de alta
            const orientacoes = await banco
                .collection("orientacoesAlta")
                .find({
                    petId: { $in: idsPossiveis }
                })
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