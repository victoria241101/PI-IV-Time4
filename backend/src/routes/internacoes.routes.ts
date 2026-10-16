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
            const { petId, motivo, leito, observacoes } = req.body;

            // Verifica os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof motivo !== "string" || !motivo.trim() ||
                typeof leito !== "string" || !leito.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe o pet, o motivo e o leito."
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

            const banco = obterBanco();
            const usuarioId = new ObjectId(res.locals.usuarioId);

            // Identifica o veterinário logado
            const veterinario = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("veterinarios").findOne({
                usuarioId,
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            // Aceita pets antigos com ID em texto
            // e pets novos com ObjectId
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

            const internacoes = banco.collection("internacoes");

            // Impede que o pet tenha duas internações ativas
            const internacaoAtiva = await internacoes.findOne({
                petId: { $in: idsPet },
                status: "ativa"
            });

            if (internacaoAtiva) {
                return res.status(409).json({
                    mensagem: "Este pet já possui uma internação ativa."
                });
            }

            // Verifica se o leito já está ocupado
            const leitoOcupado = await internacoes.findOne({
                leito: leito.trim(),
                status: "ativa"
            });

            if (leitoOcupado) {
                return res.status(409).json({
                    mensagem: "Este leito já está ocupado."
                });
            }

            // Registra a internação
            const resultado = await internacoes.insertOne({
                petId: pet._id,
                veterinarioId: veterinario._id,
                enfermeiroId: null,
                dataEntrada: new Date(),
                dataAlta: null,
                motivo: motivo.trim(),
                status: "ativa",
                leito: leito.trim(),
                observacoes: observacoes?.trim() ?? ""
            });

            return res.status(201).json({
                mensagem: "Internação registrada com sucesso!",
                internacaoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao registrar internação:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar internação."
            });
        }
    }
);

router.patch(
    "/:id/alta",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const id = req.params.id;
            if (typeof id !== "string") {
                return res.status(400).json({
                    mensagem: "ID da internação inválido."
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

            // Aceita IDs antigos em texto e IDs novos do MongoDB
            const idsInternacao: (string | ObjectId)[] = [id];

            if (ObjectId.isValid(id)) {
                idsInternacao.push(new ObjectId(id));
            }

            const internacoes = banco.collection<{
                _id: string | ObjectId;
                veterinarioId: string;
                status: string;
                dataAlta?: Date | null;
            }>("internacoes");

            // A atualização só acontece se a internação estiver ativa
            // e pertencer ao veterinário responsável
            const resultado = await internacoes.updateOne(
                {
                    _id: { $in: idsInternacao },
                    veterinarioId: veterinario._id,
                    status: "ativa"
                },
                {
                    $set: {
                        status: "alta",
                        dataAlta: new Date()
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem:
                        "Internação não está ativa, não existe ou pertence a outro veterinário."
                });
            }

            return res.status(200).json({
                mensagem: "Alta hospitalar registrada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao registrar alta:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar alta hospitalar."
            });
        }
    }
);

// Lista as internações de um pet
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

            // Aceita IDs antigos e ObjectIds do MongoDB
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Busca todas as internações do pet
            const internacoes = await banco
                .collection("internacoes")
                .find({
                    petId: { $in: idsPet }
                })
                .sort({ dataEntrada: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Internações encontradas com sucesso!",
                internacoes
            });

        } catch (erro) {
            console.error("Erro ao consultar internações:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar internações."
            });
        }
    }
);

export default router;