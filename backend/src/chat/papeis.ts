import type { PapelChat } from "./tipos.js";
import { PAPEL_TUTOR, PAPEL_VETERINARIO, PAPEL_ENFERMEIRO, PAPEL_SECRETARIA } from "./tipos.js";

/**
 * Normaliza o tipo de usuário vindo do banco ou do token.
 * Apara espaços e ignora maiúsculas e minúsculas.
 * "tutor" e "usuario" viram "USUARIO".
 * Qualquer outro valor (ex.: "admin", texto vazio, null, número) vira null.
 */
export function normalizarTipoUsuario(tipo: unknown): PapelChat | null {
    if (typeof tipo !== "string") {
        return null;
    }

    const limpo = tipo.trim().toUpperCase();

    if (limpo === "TUTOR" || limpo === "USUARIO") {
        return PAPEL_TUTOR;
    }
    if (limpo === PAPEL_VETERINARIO) {
        return PAPEL_VETERINARIO;
    }
    if (limpo === PAPEL_ENFERMEIRO) {
        return PAPEL_ENFERMEIRO;
    }
    if (limpo === PAPEL_SECRETARIA) {
        return PAPEL_SECRETARIA;
    }

    return null;
}

/**
 * Retorna os valores brutos possíveis em usuarios.tipo, para usar em { $in: [...] }.
 * Inclui a forma MAIÚSCULA e a minúscula; para USUARIO inclui também "TUTOR" e "tutor".
 */
export function variantesDoPapel(papel: PapelChat): string[] {
    switch (papel) {
        case "USUARIO":
            return ["USUARIO", "usuario", "TUTOR", "tutor"];
        case "VETERINARIO":
            return ["VETERINARIO", "veterinario"];
        case "ENFERMEIRO":
            return ["ENFERMEIRO", "enfermeiro"];
        case "SECRETARIA":
            return ["SECRETARIA", "secretaria"];
    }
}

/**
 * Informa se o papel faz parte da equipe da clínica (VETERINARIO, ENFERMEIRO ou SECRETARIA).
 */
export function ehPapelEquipe(papel: PapelChat): boolean {
    return papel === PAPEL_VETERINARIO || papel === PAPEL_ENFERMEIRO || papel === PAPEL_SECRETARIA;
}
