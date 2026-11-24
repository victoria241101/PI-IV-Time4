// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarAlta } from "../notificacoes/eventos.js";

const router = Router();

// registra a internação do pet
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os campos enviados no corpo da requisição
            const { petId, motivo, leito, observacoes } = req.body;

            // verifica os campos obrigatórios
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
            // pega o id que a autenticação colocou na resposta
            const usuarioId = new ObjectId(res.locals.usuarioId);

            // identifica o veterinário logado
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

            // aceita pets antigos com id em texto
            // e pets novos com objectid
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

            const internacoes = banco.collection("internacoes");

            // impede que o pet tenha duas internações ativas
            const internacaoAtiva = await internacoes.findOne({
                petId: { $in: idsPet },
                status: "ativa"
            });

            if (internacaoAtiva) {
                return res.status(409).json({
                    mensagem: "Este pet já possui uma internação ativa."
                });
            }

            // verifica se o leito já está ocupado
            const leitoOcupado = await internacoes.findOne({
                leito: leito.trim(),
                status: "ativa"
            });

            if (leitoOcupado) {
                return res.status(409).json({
                    mensagem: "Este leito já está ocupado."
                });
            }

            // registra a internação
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

            // confirma o cadastro e devolve os dados do registro criado
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

// registra a alta da internação
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

            // aceita ids antigos em texto e ids novos do mongodb
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

            // a atualização só acontece se a internação estiver ativa
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

            // confere se a operação encontrou ou alterou o registro esperado
            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem:
                        "Internação não está ativa, não existe ou pertence a outro veterinário."
                });
            }

            const internacao = await banco.collection<{
                _id: string | ObjectId;
                petId: unknown;
            }>("internacoes").findOne({
                _id: { $in: idsInternacao }
            });

            if (internacao) {
                await notificarAlta(banco, {
                    petId: internacao.petId,
                    veterinarioUsuarioId: new ObjectId(res.locals.usuarioId),
                    referenciaId: id
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

// lista as internações de um pet
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

            // aceita ids antigos e objectids do mongodb
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // busca todas as internações do pet
            const internacoes = await banco
                .collection("internacoes")
                .find({
                    petId: { $in: idsPet }
                })
                // coloca os registros mais recentes primeiro
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