import type { TipoNotificacao } from "./tipos.js";
import { LIMITE_TITULO, LIMITE_MENSAGEM } from "./tipos.js";

const DESLOCAMENTO_UTC3_MS = -3 * 60 * 60 * 1000;

export interface ContextoTexto {
    nomePet?: string;
    nomeTutor?: string;
    nomeRemetente?: string;
    dataHora?: Date;
    motivo?: string;
    nomeCampanha?: string;
    rotuloLembrete?: string;
}

/**
 * Formata um objeto Date no padrão brasileiro (dd/MM/yyyy HH:mm)
 * fixado no fuso horário de Brasília (UTC-3), tratando corretamente viradas de dia.
 */
export function formatarDataHoraBR(data: Date): string {
    if (!(data instanceof Date) || Number.isNaN(data.getTime())) {
        return "";
    }

    const dataUTC3 = new Date(data.getTime() + DESLOCAMENTO_UTC3_MS);
    const dia = String(dataUTC3.getUTCDate()).padStart(2, "0");
    const mes = String(dataUTC3.getUTCMonth() + 1).padStart(2, "0");
    const ano = String(dataUTC3.getUTCFullYear());
    const hora = String(dataUTC3.getUTCHours()).padStart(2, "0");
    const minuto = String(dataUTC3.getUTCMinutes()).padStart(2, "0");

    return `${dia}/${mes}/${ano} ${hora}:${minuto}`;
}

/**
 * Remove quebras de linha, colapsa espaços em branco e limita o tamanho do texto.
 */
function sanitizar(valor: unknown, maxLen = 80): string | undefined {
    if (typeof valor !== "string") {
        return undefined;
    }

    const limpo = valor
        .replace(/[\r\n]+/g, " ")
        .replace(/\s+/g, " ")
        .trim();

    if (limpo.length === 0) {
        return undefined;
    }

    if (limpo.length > maxLen) {
        return limpo.slice(0, maxLen).trim();
    }

    return limpo;
}

function cortar(texto: string, max: number): string {
    if (texto.length <= max) {
        return texto;
    }
    return texto.slice(0, max).trim();
}

/**
 * Monta o título e a mensagem de uma notificação a partir de seu tipo e contexto.
 * - Substitui campos ausentes por textos genéricos e acolhedores.
 * - Corta campos de texto para evitar estouro dos limites máximos.
 * - Remove quebras de linha vindas de dados do usuário.
 * - Garante que nunca apareçam 'undefined', 'null' ou '[object Object]'.
 */
export function montarTexto(
    tipo: TipoNotificacao,
    ctx: ContextoTexto = {}
): { titulo: string; mensagem: string } {
    const pet = sanitizar(ctx.nomePet, 50);
    const tutor = sanitizar(ctx.nomeTutor, 50);
    const remetente = sanitizar(ctx.nomeRemetente, 50);
    const motivo = sanitizar(ctx.motivo, 100);
    const campanha = sanitizar(ctx.nomeCampanha, 60);
    const rotulo = sanitizar(ctx.rotuloLembrete, 20);
    const dataHora = ctx.dataHora instanceof Date && !Number.isNaN(ctx.dataHora.getTime())
        ? formatarDataHoraBR(ctx.dataHora)
        : undefined;

    let titulo = "";
    let mensagem = "";

    switch (tipo) {
        case "chegada_paciente":
            titulo = pet ? `Chegada de paciente: ${pet}` : "Chegada de paciente";
            if (pet && tutor) {
                mensagem = `O paciente ${pet}, acompanhado pelo(a) tutor(a) ${tutor}, chegou à clínica para atendimento.`;
            } else if (pet) {
                mensagem = `O paciente ${pet} chegou à clínica para atendimento.`;
            } else if (tutor) {
                mensagem = `O(A) tutor(a) ${tutor} chegou à clínica com um paciente para atendimento.`;
            } else {
                mensagem = "Um paciente chegou à clínica e aguarda atendimento.";
            }
            break;

        case "triagem_concluida":
            titulo = pet ? `Triagem concluída: ${pet}` : "Triagem concluída";
            if (pet && remetente) {
                mensagem = `A triagem de ${pet} foi concluída por ${remetente}. O paciente aguarda atendimento.`;
            } else if (pet) {
                mensagem = `A triagem de ${pet} foi concluída. O paciente aguarda atendimento.`;
            } else if (remetente) {
                mensagem = `A triagem foi concluída por ${remetente}. O paciente aguarda atendimento.`;
            } else {
                mensagem = "A triagem de um paciente foi concluída e está aguardando atendimento veterinário.";
            }
            break;

        case "tarefa_clinica_criada":
            titulo = pet ? `Nova tarefa clínica: ${pet}` : "Nova tarefa clínica";
            if (pet && motivo) {
                mensagem = `Nova tarefa clínica para ${pet}: ${motivo}.`;
            } else if (pet) {
                mensagem = `Uma nova tarefa clínica foi atribuída para o pet ${pet}.`;
            } else if (motivo) {
                mensagem = `Nova tarefa clínica atribuída: ${motivo}.`;
            } else {
                mensagem = "Uma nova tarefa clínica foi atribuída a você.";
            }
            break;

        case "dose_prescrita":
            titulo = pet ? `Nova dose prescrita: ${pet}` : "Nova dose prescrita";
            if (pet && motivo) {
                mensagem = `Nova dose prescrita para ${pet}: ${motivo}.`;
            } else if (pet) {
                mensagem = `Uma nova prescrição foi registrada para o pet ${pet}.`;
            } else if (motivo) {
                mensagem = `Nova dose prescrita para paciente em tratamento: ${motivo}.`;
            } else {
                mensagem = "Uma nova dose foi prescrita para um paciente em tratamento.";
            }
            break;

        case "consulta_agendada":
            titulo = pet ? `Consulta agendada: ${pet}` : "Consulta agendada";
            if (pet && dataHora) {
                mensagem = `Consulta agendada para ${pet} em ${dataHora}.`;
            } else if (pet) {
                mensagem = `Uma nova consulta foi agendada para ${pet}.`;
            } else if (dataHora) {
                mensagem = `Uma nova consulta foi agendada para ${dataHora}.`;
            } else {
                mensagem = "Uma nova consulta veterinária foi agendada.";
            }
            break;

        case "consulta_remarcada":
            titulo = pet ? `Consulta remarcada: ${pet}` : "Consulta remarcada";
            if (pet && dataHora) {
                mensagem = `A consulta de ${pet} foi remarcada para ${dataHora}.`;
            } else if (pet) {
                mensagem = `A consulta de ${pet} foi remarcada para uma nova data.`;
            } else if (dataHora) {
                mensagem = `Uma consulta foi remarcada para ${dataHora}.`;
            } else {
                mensagem = "Uma consulta foi remarcada para uma nova data e horário.";
            }
            break;

        case "consulta_cancelada":
            titulo = pet ? `Consulta cancelada: ${pet}` : "Consulta cancelada";
            if (pet && dataHora) {
                mensagem = `A consulta de ${pet} agendada para ${dataHora} foi cancelada.`;
            } else if (pet) {
                mensagem = `A consulta agendada para ${pet} foi cancelada.`;
            } else if (dataHora) {
                mensagem = `A consulta agendada para ${dataHora} foi cancelada.`;
            } else {
                mensagem = "Uma consulta agendada foi cancelada.";
            }
            break;

        case "alta_orientacoes":
            titulo = pet ? `Alta e orientações: ${pet}` : "Alta e orientações";
            if (pet) {
                mensagem = `O pet ${pet} recebeu alta hospitalar. Confira as orientações de cuidados e pós-atendimento.`;
            } else {
                mensagem = "Seu pet recebeu alta hospitalar. Confira as orientações de cuidados e pós-atendimento.";
            }
            break;

        case "campanha_encerrada":
            titulo = "Campanha encerrada";
            if (campanha) {
                mensagem = `A campanha "${campanha}" foi encerrada.`;
            } else {
                mensagem = "Uma campanha de arrecadação foi encerrada.";
            }
            break;

        case "campanha_meta_atingida":
            titulo = "Meta de campanha atingida!";
            if (campanha) {
                mensagem = `A meta da campanha "${campanha}" foi atingida com sucesso!`;
            } else {
                mensagem = "A meta de uma campanha de arrecadação foi atingida com sucesso!";
            }
            break;

        case "lembrete_consulta":
            titulo = pet ? `Lembrete de consulta: ${pet}` : "Lembrete de consulta";
            if (pet && dataHora && rotulo) {
                mensagem = `Lembrete: consulta de ${pet} agendada para ${dataHora} (em ${rotulo}).`;
            } else if (pet && dataHora) {
                mensagem = `Lembrete: consulta de ${pet} agendada para ${dataHora}.`;
            } else if (pet) {
                mensagem = `Lembrete: você possui uma consulta veterinária agendada para ${pet}.`;
            } else if (dataHora) {
                mensagem = `Lembrete: você possui uma consulta agendada para ${dataHora}.`;
            } else {
                mensagem = "Lembrete: você possui uma consulta veterinária agendada em breve.";
            }
            break;

        case "lembrete_vacina":
            titulo = pet ? `Lembrete de vacina: ${pet}` : "Lembrete de vacina";
            if (pet && motivo) {
                mensagem = `Lembrete: vacinação de ${pet} contra ${motivo} prevista em breve.`;
            } else if (pet) {
                mensagem = `Lembrete: vacinação prevista para ${pet} em breve.`;
            } else if (motivo) {
                mensagem = `Lembrete: vacinação contra ${motivo} prevista em breve.`;
            } else {
                mensagem = "Lembrete: seu pet possui uma vacina com aplicação prevista em breve.";
            }
            break;
    }

    return {
        titulo: cortar(titulo, LIMITE_TITULO),
        mensagem: cortar(mensagem, LIMITE_MENSAGEM)
    };
}
