import { Router, type RequestHandler } from "express";
import { ObjectId, MongoServerError, type Db, type Document } from "mongodb";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterFiltroConsulta } from "./identificadoresConsultas.js";
import type { notificarTriagemConcluida as NotificarTriagem } from "../notificacoes/eventos.js";

// Usa a sessão real em produção; os testes fornecem apenas substitutos locais.
export function criarRotasTriagem({ obterBanco, autenticar, notificarTriagemConcluida }: {
    obterBanco: () => Db;
    autenticar: RequestHandler;
    notificarTriagemConcluida: typeof NotificarTriagem;
}) {
    const router = Router();

    router.patch(
        "/:id/iniciar-triagem",
        autenticar,
        permitirFuncoes("ENFERMEIRO"),
        async (req, res) => {
            try {
                const id = String(req.params.id ?? "");

                if (!id) {
                    return res.status(400).json({
                        mensagem: "Código da consulta não informado."
                    });
                }

                const banco = obterBanco();
                const consultas = banco.collection<Document>("consultas");

                // A condição e a atribuição são uma única atualização no MongoDB.
                // Se dois enfermeiros tentarem assumir, só o primeiro altera o registro.
                const resultado = await consultas.updateOne(
                    {
                        ...obterFiltroConsulta(id),
                        status: "chegada_confirmada"
                    },
                    {
                        $set: {
                            status: "em_triagem",
                            enfermeiroUsuarioId: res.locals.usuarioId,
                            triagemIniciadaEm: new Date()
                        }
                    }
                );

                if (resultado.modifiedCount === 0) {
                    return res.status(409).json({
                        mensagem: "Consulta indisponível: ela pode já ter sido assumida por outro enfermeiro. Atualize a fila."
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
                const id = String(req.params.id ?? "");
                const { peso, temperatura, sintomas, observacoes } = req.body ?? {};

                if (!id) {
                    return res.status(400).json({
                        mensagem: "Código da consulta não informado."
                    });
                }

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
                const consultas = banco.collection<Document>("consultas");

                const consulta = await consultas.findOne({
                    ...obterFiltroConsulta(id),
                    status: "em_triagem",
                    enfermeiroUsuarioId: res.locals.usuarioId
                });

                if (!consulta) {
                    return res.status(409).json({
                        mensagem: "Consulta indisponível ou triagem não pertence ao enfermeiro conectado."
                    });
                }

                const triagens = banco.collection("triagens");
                const triagemExistente = await triagens.findOne({ consultaId: id });

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
                }

                console.error("Erro ao registrar triagem:", erro);

                return res.status(500).json({
                    mensagem: "Erro ao registrar triagem."
                });
            }
        }
    );

    router.patch(
        "/:id/finalizar-triagem",
        autenticar,
        permitirFuncoes("ENFERMEIRO"),
        async (req, res) => {
            try {
                const id = String(req.params.id ?? "");

                if (!id) {
                    return res.status(400).json({
                        mensagem: "Código da consulta não informado."
                    });
                }

                const banco = obterBanco();
                const consultas = banco.collection<Document>("consultas");
                const triagens = banco.collection("triagens");

                const triagem = await triagens.findOne({
                    consultaId: id, enfermeiroUsuarioId: res.locals.usuarioId
                });

                if (!triagem) {
                    return res.status(409).json({
                        mensagem: "É necessário registrar a triagem antes de finalizá-la."
                    });
                }

                const resultado = await consultas.updateOne(
                    {
                        ...obterFiltroConsulta(id),
                        status: "em_triagem",
                        enfermeiroUsuarioId: res.locals.usuarioId
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
                        mensagem: "Consulta indisponível ou triagem não pertence ao enfermeiro conectado."
                    });
                }

                const consulta = await consultas.findOne(obterFiltroConsulta(id));
                if (consulta) {
                    await notificarTriagemConcluida(
                        banco,
                        consulta,
                        new ObjectId(res.locals.usuarioId)
                    );
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

    return router;
}
