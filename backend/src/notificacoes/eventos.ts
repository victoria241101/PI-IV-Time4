import { ObjectId, type Db } from "mongodb";
import { ehObjectIdHex } from "../chat/validacao.js";
import { montarTexto, type ContextoTexto } from "./modelos.js";
import { interpretarDataHora } from "./janelas.js";
import {
    variantesId,
    resolverUsuarioDoVeterinario,
    resolverUsuarioDoEnfermeiro,
    resolverUsuarioDoTutor,
    resolverUsuarioDoTutorDoPet,
    listarUsuariosPorTipo
} from "./destinatarios.js";
import { criarParaVarios } from "./criar.js";

type DocLegado = { _id: string | ObjectId; [chave: string]: any };

/**
 * Função PURA: formata a chave base de deduplicação para um determinado evento.
 * Garante o padrão <prefixo>:<idPrincipal>[:<variacao>].
 */
export function montarChaveEvento(
    prefixo: string,
    idPrincipal: unknown,
    variacao?: unknown
): string {
    const parteId = idPrincipal !== undefined && idPrincipal !== null
        ? String(idPrincipal).trim()
        : "";
    const parteVariacao = variacao !== undefined && variacao !== null
        ? String(variacao).trim()
        : "";

    if (parteVariacao.length > 0) {
        return `${prefixo}:${parteId}:${parteVariacao}`;
    }
    return `${prefixo}:${parteId}`;
}

/**
 * Função PURA: filtra e deduplica a lista de candidatos a destinatário.
 * - Remove valores nulos ou que não sejam instâncias de ObjectId.
 * - Remove o destinatário se ele for idêntico ao remetente da ação.
 * - Deduplica por valor hexadecimal minúsculo.
 */
export function filtrarDestinatarios(
    candidatos: (ObjectId | null | undefined)[],
    remetenteId?: ObjectId | null
): ObjectId[] {
    const mapa = new Map<string, ObjectId>();

    for (const c of candidatos) {
        if (!c || !(c instanceof ObjectId)) {
            continue;
        }

        if (remetenteId && c.equals(remetenteId)) {
            continue;
        }

        mapa.set(c.toHexString().toLowerCase(), c);
    }

    return Array.from(mapa.values());
}

/**
 * Função PURA: decide os destinatários de eventos de agendamento/remarcação/cancelamento de consulta.
 * Notifica tutor e veterinário, excluindo o usuário remetente da ação.
 */
export function escolherDestinatariosConsulta(
    tutorUsuarioId: ObjectId | null | undefined,
    veterinarioUsuarioId: ObjectId | null | undefined,
    remetenteId?: ObjectId | null
): ObjectId[] {
    return filtrarDestinatarios([tutorUsuarioId, veterinarioUsuarioId], remetenteId);
}

/**
 * Função PURA: decide a lista de enfermeiros destinatários para evento de prescrição.
 * - Só notifica se o pet possuir internação ativa (temInternacaoAtiva === true).
 * - Se houver enfermeiro responsável pela internação, notifica apenas ele.
 * - Se não houver enfermeiro na internação, notifica todos os enfermeiros ativos da clínica.
 * - Exclui o remetente da ação em ambos os casos.
 */
export function escolherDestinatariosDose(
    temInternacaoAtiva: boolean,
    enfermeiroInternacaoId: ObjectId | null | undefined,
    todosEnfermeirosIds: ObjectId[],
    remetenteId?: ObjectId | null
): ObjectId[] {
    if (!temInternacaoAtiva) {
        return [];
    }
    if (enfermeiroInternacaoId) {
        return filtrarDestinatarios([enfermeiroInternacaoId], remetenteId);
    }
    return filtrarDestinatarios(todosEnfermeirosIds, remetenteId);
}

/**
 * Converte de forma segura o remetente recebido em ObjectId ou null.
 */
function normalizarRemetenteId(remetente: unknown): ObjectId | null {
    if (!remetente) {
        return null;
    }
    if (remetente instanceof ObjectId) {
        return remetente;
    }
    if (typeof remetente === "string" && ehObjectIdHex(remetente)) {
        return new ObjectId(remetente);
    }
    return null;
}

/**
 * Monta o objeto ContextoTexto compatível com 'exactOptionalPropertyTypes: true'.
 * Aceita string | null | undefined — filtra apenas valores truthy.
 */
function limparContexto(ctx: {
    nomePet?: string | null | undefined;
    nomeTutor?: string | null | undefined;
    nomeRemetente?: string | null | undefined;
    dataHora?: Date | null | undefined;
    motivo?: string | null | undefined;
    nomeCampanha?: string | null | undefined;
    rotuloLembrete?: string | null | undefined;
}): ContextoTexto {
    const res: ContextoTexto = {};
    if (ctx.nomePet) res.nomePet = ctx.nomePet;
    if (ctx.nomeTutor) res.nomeTutor = ctx.nomeTutor;
    if (ctx.nomeRemetente) res.nomeRemetente = ctx.nomeRemetente;
    if (ctx.dataHora) res.dataHora = ctx.dataHora;
    if (ctx.motivo) res.motivo = ctx.motivo;
    if (ctx.nomeCampanha) res.nomeCampanha = ctx.nomeCampanha;
    if (ctx.rotuloLembrete) res.rotuloLembrete = ctx.rotuloLembrete;
    return res;
}

async function buscarNomePet(db: Db, petId: unknown): Promise<string | undefined> {
    try {
        const vars = variantesId(petId);
        if (vars.length === 0) {
            return undefined;
        }

        const pet = await db.collection<DocLegado>("pets").findOne(
            { _id: { $in: vars } },
            { projection: { nome: 1 } }
        );

        return typeof pet?.nome === "string" && pet.nome.trim()
            ? pet.nome.trim()
            : undefined;
    } catch {
        return undefined;
    }
}

async function buscarNomeTutor(
    db: Db,
    tutorId: unknown,
    petId?: unknown
): Promise<string | undefined> {
    try {
        let tId = tutorId;
        if (!tId && petId) {
            const varsPet = variantesId(petId);
            if (varsPet.length > 0) {
                const pet = await db.collection<DocLegado>("pets").findOne(
                    { _id: { $in: varsPet } },
                    { projection: { tutorId: 1 } }
                );
                tId = pet?.tutorId;
            }
        }

        const usuarioId = await resolverUsuarioDoTutor(db, tId);
        if (!usuarioId) {
            return undefined;
        }

        const usuario = await db.collection<DocLegado>("usuarios").findOne(
            { _id: usuarioId },
            { projection: { nome: 1 } }
        );

        return typeof usuario?.nome === "string" && usuario.nome.trim()
            ? usuario.nome.trim()
            : undefined;
    } catch {
        return undefined;
    }
}

/**
 * Notifica o veterinário da consulta sobre a chegada do paciente na recepção.
 * Chave: chegada:<consultaId>
 */
export async function notificarChegada(
    db: Db,
    consulta: Record<string, any>,
    remetenteUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(remetenteUsuarioId);
        const vetUsuarioId = await resolverUsuarioDoVeterinario(db, consulta.veterinarioId);
        const destinatarios = filtrarDestinatarios([vetUsuarioId], remetenteId);

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, consulta.petId);
        const nomeTutor = await buscarNomeTutor(db, consulta.tutorId, consulta.petId);
        const dataHora = interpretarDataHora(consulta.dataHora) ?? undefined;

        const { titulo, mensagem } = montarTexto(
            "chegada_paciente",
            limparContexto({ nomePet, nomeTutor, dataHora })
        );

        const consultaIdStr = String(consulta._id ?? "");
        const petIdStr = consulta.petId !== undefined && consulta.petId !== null
            ? String(consulta.petId)
            : null;

        const chaveBase = montarChaveEvento("chegada", consultaIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo: "chegada_paciente",
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: consultaIdStr || null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de chegada do paciente.");
    }
}

/**
 * Notifica o veterinário responsável quando a triagem da consulta for finalizada.
 * Chave: triagem:<consultaId>
 */
export async function notificarTriagemConcluida(
    db: Db,
    consulta: Record<string, any>,
    enfermeiroUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(enfermeiroUsuarioId);
        const vetUsuarioId = await resolverUsuarioDoVeterinario(db, consulta.veterinarioId);
        const destinatarios = filtrarDestinatarios([vetUsuarioId], remetenteId);

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, consulta.petId);
        const { titulo, mensagem } = montarTexto(
            "triagem_concluida",
            limparContexto({ nomePet })
        );

        const consultaIdStr = String(consulta._id ?? "");
        const petIdStr = consulta.petId !== undefined && consulta.petId !== null
            ? String(consulta.petId)
            : null;

        const chaveBase = montarChaveEvento("triagem", consultaIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo: "triagem_concluida",
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: consultaIdStr || null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de triagem concluida.");
    }
}

/**
 * Notifica o enfermeiro atribuído quando uma tarefa clínica for criada pelo veterinário.
 * Chave: tarefa:<tarefaId>
 */
export async function notificarTarefaClinica(
    db: Db,
    tarefa: Record<string, any>,
    veterinarioUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(veterinarioUsuarioId);
        const enfUsuarioId = await resolverUsuarioDoEnfermeiro(db, tarefa.enfermeiroId);
        const destinatarios = filtrarDestinatarios([enfUsuarioId], remetenteId);

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, tarefa.petId);
        const motivo = typeof tarefa.descricao === "string" ? tarefa.descricao : undefined;

        const { titulo, mensagem } = montarTexto(
            "tarefa_clinica_criada",
            limparContexto({ nomePet, motivo })
        );

        const tarefaIdStr = String(tarefa._id ?? "");
        const petIdStr = tarefa.petId !== undefined && tarefa.petId !== null
            ? String(tarefa.petId)
            : null;

        const chaveBase = montarChaveEvento("tarefa", tarefaIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo: "tarefa_clinica_criada",
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de tarefa clinica criada.");
    }
}

/**
 * Notifica enfermeiros quando uma nova dose for prescrita pelo veterinário.
 * - Só notifica se o pet possuir internação ativa!
 * - Notifica o enfermeiro da internação ativa do pet; se não houver, todos os enfermeiros ativos.
 * Chave: prescricao:<prescricaoId>
 */
export async function notificarDosePrescrita(
    db: Db,
    prescricao: Record<string, any>,
    veterinarioUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(veterinarioUsuarioId);

        if (!prescricao.petId) {
            return;
        }

        // Verifica se o pet possui internação ativa
        const internacao = await db.collection<DocLegado>("internacoes").findOne(
            {
                petId: { $in: variantesId(prescricao.petId) },
                status: "ativa"
            },
            { projection: { enfermeiroId: 1 } }
        );

        const temInternacaoAtiva = internacao !== null;
        if (!temInternacaoAtiva) {
            return;
        }

        let enfInternacaoId: ObjectId | null = null;
        if (internacao.enfermeiroId) {
            enfInternacaoId = await resolverUsuarioDoEnfermeiro(db, internacao.enfermeiroId);
        }

        const todosEnfermeiros = enfInternacaoId
            ? []
            : await listarUsuariosPorTipo(db, ["enfermeiro"]);

        const destinatarios = escolherDestinatariosDose(
            temInternacaoAtiva,
            enfInternacaoId,
            todosEnfermeiros,
            remetenteId
        );

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, prescricao.petId);
        const motivo = typeof prescricao.medicamento === "string"
            ? `${prescricao.medicamento}${prescricao.dose ? ` (${prescricao.dose})` : ""}`
            : undefined;

        const { titulo, mensagem } = montarTexto(
            "dose_prescrita",
            limparContexto({ nomePet, motivo })
        );

        const prescricaoIdStr = String(prescricao._id ?? "");
        const petIdStr = prescricao.petId !== undefined && prescricao.petId !== null
            ? String(prescricao.petId)
            : null;

        const chaveBase = montarChaveEvento("prescricao", prescricaoIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo: "dose_prescrita",
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de dose prescrita.");
    }
}

/**
 * Notifica tutor e veterinário sobre agendamento, remarcação ou cancelamento de consulta.
 * - Exclui o remetente que realizou a ação da lista de destinatários.
 * Chave: <tipo>:<consultaId>:<dataHora ou status>
 */
export async function notificarConsulta(
    db: Db,
    tipo: "consulta_agendada" | "consulta_remarcada" | "consulta_cancelada",
    consulta: Record<string, any>,
    remetenteUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(remetenteUsuarioId);

        const tutorUsuarioId = await resolverUsuarioDoTutor(db, consulta.tutorId);
        const vetUsuarioId = await resolverUsuarioDoVeterinario(db, consulta.veterinarioId);

        const destinatarios = escolherDestinatariosConsulta(
            tutorUsuarioId,
            vetUsuarioId,
            remetenteId
        );

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, consulta.petId);
        const dataHora = interpretarDataHora(consulta.dataHora) ?? undefined;

        const { titulo, mensagem } = montarTexto(
            tipo,
            limparContexto({ nomePet, dataHora })
        );

        const consultaIdStr = String(consulta._id ?? "");
        const petIdStr = consulta.petId !== undefined && consulta.petId !== null
            ? String(consulta.petId)
            : null;

        const identificadorVariacao = tipo === "consulta_cancelada"
            ? (consulta.status || "cancelada")
            : (consulta.dataHora || "sem-data");

        const chaveBase = montarChaveEvento(tipo, consultaIdStr, identificadorVariacao);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo,
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: consultaIdStr || null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de consulta.");
    }
}

/**
 * Notifica o tutor quando o pet recebe alta hospitalar ou tem orientações cadastradas.
 * Chave: alta:<referenciaId>
 */
export async function notificarAlta(
    db: Db,
    params: {
        petId: unknown;
        veterinarioUsuarioId?: ObjectId | string | null;
        referenciaId: unknown;
    }
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(params.veterinarioUsuarioId);
        const tutorUsuarioId = await resolverUsuarioDoTutorDoPet(db, params.petId);
        const destinatarios = filtrarDestinatarios([tutorUsuarioId], remetenteId);

        if (destinatarios.length === 0) {
            return;
        }

        const nomePet = await buscarNomePet(db, params.petId);
        const { titulo, mensagem } = montarTexto(
            "alta_orientacoes",
            limparContexto({ nomePet })
        );

        const petIdStr = params.petId !== undefined && params.petId !== null
            ? String(params.petId)
            : null;
        const refIdStr = String(params.referenciaId ?? "");

        const chaveBase = montarChaveEvento("alta", refIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo: "alta_orientacoes",
                titulo,
                mensagem,
                petId: petIdStr,
                consultaId: null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de alta/orientacoes.");
    }
}

/**
 * Notifica a equipe da clínica sobre encerramento de campanha ou meta atingida.
 * - Destinatários: secretária, veterinário, enfermeiro (menos quem encerrou).
 * Chave: <tipo>:<campanhaId>
 */
export async function notificarCampanha(
    db: Db,
    tipo: "campanha_encerrada" | "campanha_meta_atingida",
    campanha: Record<string, any>,
    remetenteUsuarioId?: ObjectId | string | null
): Promise<void> {
    try {
        const remetenteId = normalizarRemetenteId(remetenteUsuarioId);
        const equipe = await listarUsuariosPorTipo(db, [
            "secretaria",
            "veterinario",
            "enfermeiro"
        ]);

        const destinatarios = filtrarDestinatarios(equipe, remetenteId);
        if (destinatarios.length === 0) {
            return;
        }

        const nomeCampanha = typeof campanha.titulo === "string"
            ? campanha.titulo
            : (typeof campanha.nome === "string" ? campanha.nome : undefined);

        const { titulo, mensagem } = montarTexto(
            tipo,
            limparContexto({ nomeCampanha })
        );

        const campanhaIdStr = String(campanha._id ?? "");
        const chaveBase = montarChaveEvento(tipo, campanhaIdStr);

        await criarParaVarios(
            db,
            destinatarios,
            {
                remetenteId,
                tipo,
                titulo,
                mensagem,
                petId: null,
                consultaId: null
            },
            chaveBase
        );
    } catch {
        console.error("Erro interno ao notificar evento de campanha.");
    }
}
