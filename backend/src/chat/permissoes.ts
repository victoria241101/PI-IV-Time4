import type { PapelChat } from "./tipos.js";
import {
    PAPEL_TUTOR,
    PAPEL_VETERINARIO,
    PAPEL_ENFERMEIRO,
    PAPEL_SECRETARIA
} from "./tipos.js";

/**
 * Verifica se um usuário com o papel especificado pode abrir uma caixa de conversa compartilhada com a Secretaria.
 * Verdadeiro para USUARIO, VETERINARIO e ENFERMEIRO; falso para SECRETARIA (a equipe não abre caixa consigo mesma).
 */
export function podeAbrirCaixaSecretaria(papelDoOutro: PapelChat): boolean {
    return papelDoOutro !== PAPEL_SECRETARIA;
}

/**
 * Verifica se dois usuários podem conversar de forma direta individual (exatamente 2 participantes).
 * Verdadeiro somente para:
 * - USUARIO ↔ VETERINARIO (desde que temVinculo seja verdadeiro)
 * - VETERINARIO ↔ ENFERMEIRO (em qualquer caso)
 * Em qualquer ordem de participantes. Todos os demais pares são bloqueados.
 */
export function podeConversarDireta(a: PapelChat, b: PapelChat, temVinculo: boolean): boolean {
    if ((a === PAPEL_TUTOR && b === PAPEL_VETERINARIO) || (a === PAPEL_VETERINARIO && b === PAPEL_TUTOR)) {
        return Boolean(temVinculo);
    }

    if ((a === PAPEL_VETERINARIO && b === PAPEL_ENFERMEIRO) || (a === PAPEL_ENFERMEIRO && b === PAPEL_VETERINARIO)) {
        return true;
    }

    return false;
}
