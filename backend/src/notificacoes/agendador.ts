import type { Db } from "mongodb";
import {
    type ConfiguracaoLembrete,
    LEMBRETES_CONSULTA,
    interpretarDataHora,
    lembreteDevido
} from "./janelas.js";
import { montarTexto } from "./modelos.js";
import { criarNotificacao } from "./criar.js";
import {
    variantesId,
    resolverUsuarioDoTutor,
    resolverUsuarioDoTutorDoPet
} from "./destinatarios.js";
import { formatarEmailLembrete, enviarEmail } from "./email.js";

/**
 * Estrutura descritiva da decisão de criação de um lembrete pré-consulta.
 */
export interface DecisaoLembreteConsulta {
    consultaId: string;
    rotulo: string;
    chave: string;
    dataHora: Date;
    petId: string | null;
    tutorId: unknown;
    consulta: Record<string, any>;
}

/**
 * Função PURA: decide quais lembretes de consulta devem ser criados no ciclo.
 * - Considera estritamente consultas com status === "agendada".
 * - Avalia a dataHora com interpretarDataHora.
 * - Para cada janela em LEMBRETES_CONSULTA, verifica com lembreteDevido.
 * - Deduplica pela chave: 'lembrete_consulta:<consultaId>:<rotulo>'.
 * - Não cria se a chave já constar em chavesExistentes ou se já foi selecionada neste ciclo.
 */
export function decidirLembretesConsulta(
    consultas: Record<string, any>[],
    agora: Date,
    chavesExistentes: Set<string> | readonly string[],
    janelas: readonly ConfiguracaoLembrete[] = LEMBRETES_CONSULTA
): DecisaoLembreteConsulta[] {
    const conjuntoExistente = chavesExistentes instanceof Set
        ? chavesExistentes
        : new Set(chavesExistentes);

    const decisoes: DecisaoLembreteConsulta[] = [];
    const chavesCiclo = new Set<string>();

    for (const consulta of consultas) {
        // Apenas consultas agendadas recebem lembrete
        if (consulta.status !== "agendada") {
            continue;
        }

        const dataInicio = interpretarDataHora(consulta.dataHora);
        if (!dataInicio) {
            continue;
        }

        const consultaIdStr = String(consulta._id ?? "").trim();
        if (!consultaIdStr) {
            continue;
        }

        const petIdStr = consulta.petId !== undefined && consulta.petId !== null
            ? String(consulta.petId).trim()
            : null;

        for (const janela of janelas) {
            if (lembreteDevido(agora, dataInicio, janela)) {
                const chave = `lembrete_consulta:${consultaIdStr}:${janela.rotulo}`;

                if (conjuntoExistente.has(chave) || chavesCiclo.has(chave)) {
                    continue;
                }

                chavesCiclo.add(chave);
                decisoes.push({
                    consultaId: consultaIdStr,
                    rotulo: janela.rotulo,
                    chave,
                    dataHora: dataInicio,
                    petId: petIdStr,
                    tutorId: consulta.tutorId,
                    consulta
                });
            }
        }
    }

    return decisoes;
}

/**
 * Executa um ciclo completo de lembretes e disparo de e-mails pendentes.
 * Retorna contadores das operações realizadas.
 */
export async function executarCicloLembretes(
    db: Db,
    agora: Date = new Date()
): Promise<{
    consultasAvaliadas: number;
    criadas: number;
    emailsEnviados: number;
    emailsFalhos: number;
}> {
    let consultasAvaliadas = 0;
    let criadas = 0;
    let emailsEnviados = 0;
    let emailsFalhos = 0;

    try {
        // 1. Ciclo de consultas: buscar apenas as consultas agendadas
        const consultas = await db
            .collection<Record<string, any>>("consultas")
            .find({ status: "agendada" })
            .toArray();

        consultasAvaliadas = consultas.length;

        if (consultas.length > 0) {
            // Obter chaves de lembretes de consulta já existentes para deduplicação rápida
            const notificacoesExistentes = await db
                .collection<{ chave: string | null }>("notificacoes")
                .find(
                    { tipo: "lembrete_consulta", chave: { $ne: null } },
                    { projection: { chave: 1 } }
                )
                .toArray();

            const chavesExistentes = new Set<string>();
            for (const doc of notificacoesExistentes) {
                if (typeof doc.chave === "string") {
                    chavesExistentes.add(doc.chave);
                    const partes = doc.chave.split(":");
                    if (partes.length >= 3) {
                        chavesExistentes.add(`${partes[0]}:${partes[1]}:${partes[2]}`);
                    }
                }
            }

            const lembretes = decidirLembretesConsulta(consultas, agora, chavesExistentes);

            for (const item of lembretes) {
                try {
                    let tutorUsuarioId = await resolverUsuarioDoTutor(db, item.tutorId);
                    if (!tutorUsuarioId && item.petId) {
                        tutorUsuarioId = await resolverUsuarioDoTutorDoPet(db, item.petId);
                    }

                    if (!tutorUsuarioId) {
                        continue;
                    }

                    let nomePet: string | undefined;
                    if (item.petId) {
                        const pet = await db.collection<{ _id: string | ObjectId; nome?: unknown }>("pets").findOne(
                            { _id: { $in: variantesId(item.petId) } },
                            { projection: { nome: 1 } }
                        );
                        if (typeof pet?.nome === "string" && pet.nome.trim()) {
                            nomePet = pet.nome.trim();
                        }
                    }

                    const contexto: Parameters<typeof montarTexto>[1] = {
                        dataHora: item.dataHora,
                        rotuloLembrete: item.rotulo
                    };
                    if (nomePet) {
                        contexto.nomePet = nomePet;
                    }

                    const { titulo, mensagem } = montarTexto("lembrete_consulta", contexto);

                    const resCriacao = await criarNotificacao(db, {
                        destinatarioId: tutorUsuarioId,
                        tipo: "lembrete_consulta",
                        titulo,
                        mensagem,
                        petId: item.petId,
                        consultaId: item.consultaId,
                        chave: item.chave
                    });

                    if (resCriacao.criada) {
                        criadas++;
                    }
                } catch (erroItem) {
                    console.error("Erro ao processar lembrete de consulta individual:", erroItem);
                }
            }
        }

        // 2. Ciclo de disparo de e-mails pendentes
        const colecaoNotificacoes = db.collection<Record<string, any>>("notificacoes");
        const pendentes = await colecaoNotificacoes
            .find({
                emailStatus: "pendente",
                emailTentativas: { $lt: 3 }
            })
            .limit(50)
            .toArray();

        for (const notif of pendentes) {
            try {
                // Reivindicação atômica para evitar disparo duplicado entre instâncias
                const reivindicado = await colecaoNotificacoes.findOneAndUpdate(
                    {
                        _id: notif._id,
                        emailStatus: "pendente",
                        emailTentativas: notif.emailTentativas ?? 0
                    },
                    {
                        $inc: { emailTentativas: 1 }
                    },
                    { returnDocument: "after" }
                );

                if (!reivindicado) {
                    continue;
                }

                const usuario = await db.collection<Record<string, any>>("usuarios").findOne(
                    { _id: reivindicado.destinatarioId },
                    { projection: { email: 1, nome: 1 } }
                );

                if (!usuario?.email || typeof usuario.email !== "string") {
                    await colecaoNotificacoes.updateOne(
                        { _id: reivindicado._id },
                        { $set: { emailStatus: "falhou" } }
                    );
                    emailsFalhos++;
                    continue;
                }

                const emailFormatado = formatarEmailLembrete(
                    reivindicado.titulo,
                    reivindicado.mensagem,
                    usuario.nome
                );

                const enviado = await enviarEmail(
                    usuario.email,
                    emailFormatado.assunto,
                    emailFormatado.texto
                );

                if (enviado) {
                    await colecaoNotificacoes.updateOne(
                        { _id: reivindicado._id },
                        { $set: { emailStatus: "enviado" } }
                    );
                    emailsEnviados++;
                } else {
                    const tentativasAtuais = (reivindicado.emailTentativas ?? 1);
                    if (tentativasAtuais >= 3) {
                        await colecaoNotificacoes.updateOne(
                            { _id: reivindicado._id },
                            { $set: { emailStatus: "falhou" } }
                        );
                    }
                    emailsFalhos++;
                }
            } catch (erroEmail) {
                console.error("Erro ao processar envio de e-mail da notificação:", erroEmail);
                emailsFalhos++;
            }
        }
    } catch (erro) {
        console.error("Erro no ciclo de lembretes e e-mails:", erro);
    }

    return {
        consultasAvaliadas,
        criadas,
        emailsEnviados,
        emailsFalhos
    };
}

/**
 * Inicia o agendador em segundo plano:
 * - Desligado se process.env.LEMBRETES_ATIVOS === "false".
 * - Primeira execução 30 segundos após subir.
 * - Intervalo de 5 minutos com .unref() para não impedir o encerramento do processo.
 * - Proteção contra ciclos sobrepostos.
 */
export function iniciarAgendador(db: Db): void {
    if (process.env.LEMBRETES_ATIVOS === "false") {
        return;
    }

    let executando = false;

    const executar = async () => {
        if (executando) {
            return;
        }
        executando = true;
        try {
            await executarCicloLembretes(db);
        } catch (erro) {
            console.error("Falha ao executar ciclo do agendador:", erro);
        } finally {
            executando = false;
        }
    };

    const timerInicial = setTimeout(() => {
        void executar();
    }, 30 * 1000);
    timerInicial.unref();

    const intervalo = setInterval(() => {
        void executar();
    }, 5 * 60 * 1000);
    intervalo.unref();
}
