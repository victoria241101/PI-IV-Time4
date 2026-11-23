import { Router } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { enviarComandoJava } from "../javaClient.js";
import { notificarVacinaAplicada } from "../notificacoes/eventos.js";

const router = Router();

router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const {
                petId,
                internacaoId,
                tipo,
                nome,
                observacoes,
                intervaloDias,
                dataAplicacao
            } = req.body;

            // Valida os campos obrigatórios
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

            const tipoNormalizado = typeof tipo === "string"
                ? tipo.trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
                : "";
            const ehVacina = tipoNormalizado === "vacina" || tipoNormalizado === "vacinacao" || tipoNormalizado.startsWith("vacina");

            let intervaloDiasValido: number | undefined = undefined;
            let dataAplicacaoValida: string | undefined = undefined;

            if (ehVacina) {
                if (intervaloDias !== undefined && intervaloDias !== null && intervaloDias !== "") {
                    if (
                        (typeof intervaloDias !== "number" && typeof intervaloDias !== "string") ||
                        (typeof intervaloDias === "string" && !/^\d+$/.test(intervaloDias.trim()))
                    ) {
                        return res.status(400).json({
                            mensagem: "O intervalo de dias deve ser um número inteiro entre 1 e 3650."
                        });
                    }

                    const num = Number(intervaloDias);
                    if (!Number.isInteger(num) || num < 1 || num > 3650) {
                        return res.status(400).json({
                            mensagem: "O intervalo de dias deve ser um número inteiro entre 1 e 3650."
                        });
                    }

                    intervaloDiasValido = num;
                }

                const hojeSP = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo" }).format(new Date());

                if (dataAplicacao !== undefined && dataAplicacao !== null && dataAplicacao !== "") {
                    if (typeof dataAplicacao !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(dataAplicacao.trim())) {
                        return res.status(400).json({
                            mensagem: "Data de aplicação inválida. Use o formato yyyy-MM-dd."
                        });
                    }

                    const dataStr = dataAplicacao.trim();
                    const partes = dataStr.split("-").map(Number);
                    const ano = partes[0] ?? 0;
                    const mes = partes[1] ?? 0;
                    const dia = partes[2] ?? 0;
                    const dataObj = new Date(Date.UTC(ano, mes - 1, dia));

                    if (
                        dataObj.getUTCFullYear() !== ano ||
                        dataObj.getUTCMonth() !== mes - 1 ||
                        dataObj.getUTCDate() !== dia
                    ) {
                        return res.status(400).json({
                            mensagem: "Data de aplicação inválida."
                        });
                    }

                    if (dataStr > hojeSP) {
                        return res.status(400).json({
                            mensagem: "A data de aplicação não pode ser futura."
                        });
                    }

                    dataAplicacaoValida = dataStr;
                } else {
                    dataAplicacaoValida = hojeSP;
                }
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

            // Aceita os IDs antigos e os novos ObjectIds
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            const pet = await banco.collection<{
                _id: string | ObjectId;
                nome?: string;
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

            // Verifica a internação, caso tenha sido informada
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

            const procedimentoId = resultado.insertedId;
            let notificacaoVacina: string | undefined = undefined;

            if (ehVacina) {
                if (intervaloDiasValido === undefined) {
                    notificacaoVacina = "ignorada: intervaloDias nao informado";
                } else {
                    try {
                        const respostaJava = await enviarComandoJava("CALCULAR_STATUS_VACINA", {
                            dataUltimaAplicacao: dataAplicacaoValida,
                            intervaloDias: intervaloDiasValido
                        });

                        const dados = respostaJava?.dados as { dataProximaDose?: string } | undefined;

                        if (respostaJava?.status === "OK" && dados?.dataProximaDose) {
                            const dataProximaDose = dados.dataProximaDose;

                            await banco.collection("procedimentos").updateOne(
                                { _id: procedimentoId },
                                {
                                    $set: {
                                        intervaloDias: intervaloDiasValido,
                                        dataAplicacao: dataAplicacaoValida,
                                        dataProximaDose
                                    }
                                }
                            );

                            await notificarVacinaAplicada(banco, {
                                petId,
                                nomePet: pet.nome ?? null,
                                procedimentoId,
                                dataProximaDose,
                                remetenteId: usuarioId
                            });

                            notificacaoVacina = "enviada";
                        } else {
                            console.warn("Aviso: cálculo de vacina pelo Java retornou status diferente de OK.");
                            notificacaoVacina = "ignorada: retorno do calculo invalido";
                        }
                    } catch {
                        console.warn("Aviso: falha na comunicação com o servidor Java para cálculo de vacina.");
                        notificacaoVacina = "ignorada: falha no servidor de calculo";
                    }
                }
            }

            const respostaJson: Record<string, any> = {
                mensagem: "Procedimento registrado com sucesso!",
                procedimentoId
            };

            if (notificacaoVacina !== undefined) {
                respostaJson.notificacaoVacina = notificacaoVacina;
            }

            return res.status(201).json(respostaJson);

        } catch (erro) {
            console.error("Erro ao registrar procedimento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar procedimento."
            });
        }
    }
);

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