import { Router } from "express";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { ObjectId, MongoServerError } from "mongodb";

const router = Router();

router.patch(
    "/:id/confirmar-chegada",
    autenticar,
    permitirFuncoes("SECRETARIA"),
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            const banco = obterBanco();

            // Os IDs das consultas são strings, como "C001".
            const consultas = banco.collection<{ _id: string; status: string }>(
                "consultas"
            );

            const resultado = await consultas.updateOne(
                {
                    _id: id,
                    status: "agendada"
                },
                {
                    $set: {
                        status: "chegada_confirmada"
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada ou não está agendada."
                });
            }

            return res.status(200).json({
                mensagem: "Chegada do paciente confirmada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao confirmar chegada:", erro);

            return res.status(500).json({
                mensagem: "Erro ao confirmar chegada do paciente."
            });
        }
    }
);

router.patch(
    "/:id/iniciar-triagem",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            const banco = obterBanco();

            const consultas = banco.collection<{
                _id: string;
                status: string;
            }>("consultas");

            const resultado = await consultas.updateOne(
                {
                    _id: id,
                    status: "chegada_confirmada"
                },
                {
                    $set: {
                        status: "em_triagem"
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada ou não está aguardando triagem."
                });
            }

            return res.status(200).json({
                mensagem: "Triagem iniciada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao iniciar triagem:", erro);

            return res.status(500).json({
                mensagem: "Erro ao iniciar triagem."
            });
        }
    }
);

router.post(
    "/:id/triagem",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const { id } = req.params;
            const { peso, temperatura, sintomas, observacoes } = req.body;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            // Verifica se os dados obrigatórios foram informados
            if (
                typeof peso !== "number" ||
                !Number.isFinite(peso) ||
                peso <= 0 ||
                typeof temperatura !== "number" ||
                !Number.isFinite(temperatura) ||
                typeof sintomas !== "string" ||
                !sintomas.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe peso, temperatura e sintomas válidos."
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

            const consultas = banco.collection<{
                _id: string;
                status: string;
                petId: string;
            }>("consultas");

            // A triagem só pode ser registrada se estiver em andamento
            const consulta = await consultas.findOne({
                _id: id,
                status: "em_triagem"
            });

            if (!consulta) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada ou não está em triagem."
                });
            }

            const triagens = banco.collection("triagens");

            // Evita cadastrar uma segunda triagem para a mesma consulta
            const triagemExistente = await triagens.findOne({
                consultaId: id
            });

            if (triagemExistente) {
                return res.status(409).json({
                    mensagem: "Esta consulta já possui uma triagem registrada."
                });
            }

            const resultado = await triagens.insertOne({
                consultaId: id,
                petId: consulta.petId,
                enfermeiroUsuarioId: res.locals.usuarioId,
                peso,
                temperatura,
                sintomas: sintomas.trim(),
                observacoes: observacoes?.trim() ?? "",
                dataHora: new Date()
            });

            return res.status(201).json({
                mensagem: "Triagem registrada com sucesso!",
                triagemId: resultado.insertedId
            });


        } catch (erro) {
            if (erro instanceof MongoServerError && erro.code === 11000) {
                return res.status(409).json({
                    mensagem: "Esta consulta já possui uma triagem registrada."
            });
            console.error("Erro ao registrar triagem:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar triagem."
            });
        }
    }
});

router.patch(
    "/:id/finalizar-triagem",
    autenticar,
    permitirFuncoes("ENFERMEIRO"),
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            const banco = obterBanco();

            const consultas = banco.collection<{
                _id: string;
                status: string;
            }>("consultas");

            const triagens = banco.collection("triagens");

            // Verifica se a triagem foi registrada
            const triagem = await triagens.findOne({
                consultaId: id
            });

            if (!triagem) {
                return res.status(409).json({
                    mensagem: "É necessário registrar a triagem antes de finalizá-la."
                });
            }

            // Só finaliza uma consulta que está em triagem
            const resultado = await consultas.updateOne(
                {
                    _id: id,
                    status: "em_triagem"
                },
                {
                    $set: {
                        status: "aguardando_veterinario",
                        triagemFinalizadaEm: new Date()
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada ou não está em triagem."
                });
            }

            return res.status(200).json({
                mensagem: "Triagem finalizada! Paciente aguardando veterinário."
            });

        } catch (erro) {
            console.error("Erro ao finalizar triagem:", erro);

            return res.status(500).json({
                mensagem: "Erro ao finalizar triagem."
            });
        }
    }
);

router.patch(
    "/:id/iniciar-atendimento",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            const banco = obterBanco();

            const consultas = banco.collection<{
                _id: string;
                status: string;
                veterinarioId: string;
            }>("consultas");

            const veterinarios = banco.collection<{
                _id: string;
                usuarioId?: ObjectId;
                ativo: boolean;
            }>("veterinarios");

            // Identifica o veterinário que está logado
            const veterinario = await veterinarios.findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            // Apenas o veterinário responsável pode iniciar o atendimento
            const resultado = await consultas.updateOne(
                {
                    _id: id,
                    veterinarioId: veterinario._id,
                    status: "aguardando_veterinario"
                },
                {
                    $set: {
                        status: "em_consulta",
                        atendimentoIniciadoEm: new Date()
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada, não está aguardando atendimento ou pertence a outro veterinário."
                });
            }

            return res.status(200).json({
                mensagem: "Atendimento veterinário iniciado com sucesso!"
            });

        } catch (erro) {
            if (erro instanceof MongoServerError && erro.code === 11000) {
                return res.status(409).json({
                    mensagem: "Esta consulta já possui um atendimento registrado."
            });
}
            console.error("Erro ao iniciar atendimento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao iniciar atendimento veterinário."
            });
        }
    }
);

router.post(
    "/:id/atendimento",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const { id } = req.params;
            const {
                diagnostico,
                tratamento,
                observacoes,
                anamnese,
                exameFisico,
                prognostico,
                codigoICDVet
            } = req.body;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            // Verifica os dados obrigatórios
            if (
                typeof diagnostico !== "string" ||
                !diagnostico.trim() ||
                typeof tratamento !== "string" ||
                !tratamento.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe diagnóstico e tratamento válidos."
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

            // Valida os campos do prontuário clínico
            if (
                typeof anamnese !== "string" ||
                !anamnese.trim() ||
                typeof exameFisico !== "string" ||
                !exameFisico.trim() ||
                typeof prognostico !== "string" ||
                !prognostico.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe anamnese, exame físico e prognóstico válidos."
                });
            }

            // O código ICD-Vet pode ser informado quando disponível
            if (
                codigoICDVet !== undefined &&
                (
                    typeof codigoICDVet !== "string" ||
                    !codigoICDVet.trim()
                )
            ) {
                return res.status(400).json({
                    mensagem: "O código ICD-Vet deve ser um texto válido."
                });
            }

            const banco = obterBanco();

            const veterinarios = banco.collection<{
                _id: string;
                usuarioId?: ObjectId;
                ativo: boolean;
            }>("veterinarios");

            // Identifica o veterinário logado
            const veterinario = await veterinarios.findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            const consultas = banco.collection<{
                _id: string;
                petId: string;
                veterinarioId: string;
                status: string;
            }>("consultas");

            // Verifica se a consulta está em andamento
            // e pertence ao veterinário logado
            const consulta = await consultas.findOne({
                _id: id,
                veterinarioId: veterinario._id,
                status: "em_consulta"
            });

            if (!consulta) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada, não está em andamento ou pertence a outro veterinário."
                });
            }

            const atendimentos = banco.collection("atendimentos");

            // Evita registrar dois atendimentos para a mesma consulta
            const atendimentoExistente = await atendimentos.findOne({
                consultaId: id
            });

            if (atendimentoExistente) {
                return res.status(409).json({
                    mensagem: "Esta consulta já possui um atendimento registrado."
                });
            }

            const resultado = await atendimentos.insertOne({
                consultaId: id,
                petId: consulta.petId,
                veterinarioId: veterinario._id,

                // Informações do prontuário clínico
                anamnese: anamnese.trim(),
                exameFisico: exameFisico.trim(),
                diagnostico: diagnostico.trim(),
                prognostico: prognostico.trim(),
                codigoICDVet: codigoICDVet?.trim() ?? "",
                tratamento: tratamento.trim(),
                observacoes: observacoes?.trim() ?? "",

                dataHora: new Date()
            });

            return res.status(201).json({
                mensagem: "Atendimento registrado com sucesso!",
                atendimentoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao registrar atendimento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar atendimento veterinário."
            });
        }
    }
);

router.patch(
    "/:id/finalizar-atendimento",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    mensagem: "Código da consulta não informado."
                });
            }

            const banco = obterBanco();

            const veterinarios = banco.collection<{
                _id: string;
                usuarioId?: ObjectId;
                ativo: boolean;
            }>("veterinarios");

            // Identifica o veterinário logado
            const veterinario = await veterinarios.findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            const consultas = banco.collection<{
                _id: string;
                status: string;
                veterinarioId: string;
            }>("consultas");

            const atendimentos = banco.collection("atendimentos");

            // Verifica se o atendimento clínico foi registrado
            const atendimento = await atendimentos.findOne({
                consultaId: id,
                veterinarioId: veterinario._id
            });

            if (!atendimento) {
                return res.status(409).json({
                    mensagem: "É necessário registrar o atendimento antes de finalizar."
                });
            }

            // Finaliza somente a consulta do veterinário responsável
            const resultado = await consultas.updateOne(
                {
                    _id: id,
                    veterinarioId: veterinario._id,
                    status: "em_consulta"
                },
                {
                    $set: {
                        status: "finalizada",
                        atendimentoFinalizadoEm: new Date()
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem: "Consulta não encontrada, não está em andamento ou pertence a outro veterinário."
                });
            }

            return res.status(200).json({
                mensagem: "Consulta finalizada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao finalizar atendimento:", erro);

            return res.status(500).json({
                mensagem: "Erro ao finalizar atendimento veterinário."
            });
        }
    }
);

export default router;