export interface ConfiguracaoLembrete {
    rotulo: string;
    antecedenciaMin: number;
    toleranciaMin: number;
}

/**
 * Janelas padrão de lembrete pré-consulta configuradas no PetCare:
 * - 24 horas antes com tolerância de 3 horas (dispara entre 1440 e 1261 minutos antes)
 * - 2 horas antes com tolerância de 30 minutos (dispara entre 120 e 91 minutos antes)
 */
export const LEMBRETES_CONSULTA: readonly ConfiguracaoLembrete[] = [
    { rotulo: "24h", antecedenciaMin: 1440, toleranciaMin: 180 },
    { rotulo: "2h", antecedenciaMin: 120, toleranciaMin: 30 }
] as const;

const DESLOCAMENTO_UTC3_MS = -3 * 60 * 60 * 1000;

/**
 * Interpreta e normaliza datas vindas do banco de dados legado ou requisições.
 * - Aceita instâncias válidas de Date.
 * - Aceita texto ISO sem fuso (ex.: '2026-10-20T14:00:00'), interpretado como horário de Brasília (UTC-3).
 * - Aceita texto ISO com fuso 'Z' ou deslocamento numérico ('+HH:MM' / '-HH:MM').
 * - Rejeita datas de calendário impossíveis (ex.: '2026-02-31T10:00:00') e textos livres, números ou null -> retorna null.
 */
export function interpretarDataHora(valor: unknown): Date | null {
    if (valor instanceof Date) {
        return Number.isNaN(valor.getTime()) ? null : new Date(valor.getTime());
    }

    if (typeof valor !== "string") {
        return null;
    }

    const texto = valor.trim();
    if (!texto) {
        return null;
    }

    // Padrão ISO: YYYY-MM-DDTHH:mm[:ss][.sss][fuso]
    const regexISO = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?(?:\.(\d+))?(Z|[+-]\d{2}(?::?\d{2})?)?$/i;
    const correspondencia = texto.match(regexISO);

    if (!correspondencia) {
        return null;
    }

    const anoStr = correspondencia[1];
    const mesStr = correspondencia[2];
    const diaStr = correspondencia[3];
    const horaStr = correspondencia[4];
    const minutoStr = correspondencia[5];
    const segundoStr = correspondencia[6] ?? "0";
    const fuso = correspondencia[8];

    if (!anoStr || !mesStr || !diaStr || !horaStr || !minutoStr) {
        return null;
    }

    const ano = parseInt(anoStr, 10);
    const mes = parseInt(mesStr, 10);
    const dia = parseInt(diaStr, 10);
    const hora = parseInt(horaStr, 10);
    const minuto = parseInt(minutoStr, 10);
    const segundo = parseInt(segundoStr, 10);

    // Validação estrita de calendário (evita que 31 de fevereiro transborde para março)
    const dataVerificacao = new Date(Date.UTC(ano, mes - 1, dia, hora, minuto, segundo));
    if (
        dataVerificacao.getUTCFullYear() !== ano ||
        dataVerificacao.getUTCMonth() + 1 !== mes ||
        dataVerificacao.getUTCDate() !== dia ||
        dataVerificacao.getUTCHours() !== hora ||
        dataVerificacao.getUTCMinutes() !== minuto ||
        dataVerificacao.getUTCSeconds() !== segundo
    ) {
        return null;
    }

    if (!fuso) {
        // Sem fuso: a data/hora recebida representa o horário local da clínica (UTC-3).
        // Para obter o instante absoluto em UTC, subtrai o deslocamento negativo (-3h), somando 3 horas ao UTC.
        return new Date(dataVerificacao.getTime() - DESLOCAMENTO_UTC3_MS);
    }

    const dataFinal = new Date(texto);
    return Number.isNaN(dataFinal.getTime()) ? null : dataFinal;
}

/**
 * Avalia se um lembrete deve ser disparado no instante atual.
 * A condição respeita a fórmula da especificação:
 * minutosAte = (inicio - agora) / 60000
 * minutosAte > 0 && minutosAte <= antecedenciaMin && minutosAte > (antecedenciaMin - toleranciaMin)
 */
export function lembreteDevido(
    agora: Date,
    inicio: Date,
    l: { antecedenciaMin: number; toleranciaMin: number }
): boolean {
    if (
        !(agora instanceof Date) || Number.isNaN(agora.getTime()) ||
        !(inicio instanceof Date) || Number.isNaN(inicio.getTime())
    ) {
        return false;
    }

    const minutosAte = (inicio.getTime() - agora.getTime()) / 60000;

    return (
        minutosAte > 0 &&
        minutosAte <= l.antecedenciaMin &&
        minutosAte > l.antecedenciaMin - l.toleranciaMin
    );
}
