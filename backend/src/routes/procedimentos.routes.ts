// Alinne Monteiro de Melo | RA: 24801649

import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";

const router = Router();

// registra um procedimento do pet
router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            // separa os campos enviados no corpo da requisição
            const { petId, internacaoId, tipo, nome, observacoes } = req.body;

            // valida os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof tipo !== "string" || !tipo.trim() ||
                typeof nome !== "string" || !nome.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe o pet, o tipo e o nome do procedimento."
                });
            }

            if (
                internacaoId !== undefined &&
                (typeof internacaoId !== "string" || !internacaoId.trim())
            ) {
                return res.status(400).json({
                    mensagem: "ID da internação inválido."
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

            // aceita os ids antigos e os novos objectids
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

            // verifica a internação, caso tenha sido informada
            if (internacaoId) {
                const internacao = await banco.collection("internacoes").findOne({
                    _id: internacaoId,
                    petId,
                    status: "ativa"
                });

                if (!internacao) {
                    return res.status(409).json({
                        mensagem: "Internação não encontrada, não está ativa ou não pertence ao pet."
                    });
                }
            }

            // salva o procedimento e o vínculo com o pet
            const resultado = await banco.collection("procedimentos").insertOne({
                petId,
                veterinarioId: veterinario._id,
                internacaoId: internacaoId ?? null,
                tipo: tipo.trim(),
                nome: nome.trim(),
                dataHora: new Date(),
                status: "concluido",
                observacoes: observacoes?.trim() ?? ""
            });

            // confirma o cadastro e devolve os dados do registro criado
            return res.status(201).json({
                mensagem: "Procedimento registrado com sucesso!",
                procedimentoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao registrar procedimento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar procedimento."
            });
        }
    }
);

// lista os procedimentos de um pet
router.get(
    "/pet/:petId",
    autenticar,
    permitirFuncoes("VETERINARIO", "ENFERMEIRO"),
    async (req, res) => {
        try {
            const { petId } = req.params;

            if (typeof petId !== "string" || !petId.trim()) {
                return res.status(400).json({
                    mensagem: "ID do pet inválido."
                });
            }

            const banco = obterBanco();

            const procedimentos = await banco
                .collection("procedimentos")
                .find({ petId })
                // coloca os registros mais recentes primeiro
                .sort({ dataHora: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Procedimentos encontrados com sucesso!",
                procedimentos
            });

        } catch (erro) {
            console.error("Erro ao consultar procedimentos:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar procedimentos."
            });
        }
    }
);

export default router;