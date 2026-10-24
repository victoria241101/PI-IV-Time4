import type { ResultadoValidacao } from "./tipos.js";
import { LIMITE_TEXTO, LIMITE_PREVIA } from "./tipos.js";

const REGEX_OBJECT_ID_HEX = /^[0-9a-fA-F]{24}$/;

/**
 * Verifica se um valor é uma string contendo exatamente 24 caracteres hexadecimais.
 * Não usa ObjectId.isValid do mongodb porque este aceita strings de 12 bytes/caracteres.
 */
export function ehObjectIdHex(valor: unknown): valor is string {
    if (typeof valor !== "string") {
        return false;
    }
    return REGEX_OBJECT_ID_HEX.test(valor);
}

/**
 * Valida o texto da mensagem: deve ser string e ter entre 1 e LIMITE_TEXTO caracteres após trim.
 */
export function validarTexto(texto: unknown): ResultadoValidacao<string> {
    if (typeof texto !== "string") {
        return { ok: false, mensagem: "Texto da mensagem deve ser uma string." };
    }

    const aparado = texto.trim();

    if (aparado.length < 1) {
        return { ok: false, mensagem: "Texto da mensagem não pode ser vazio." };
    }

    if (aparado.length > LIMITE_TEXTO) {
        return {
            ok: false,
            mensagem: `Texto da mensagem excede o limite de ${LIMITE_TEXTO} caracteres.`
        };
    }

    return { ok: true, valor: aparado };
}

/**
 * Gera a prévia da mensagem para a lista de conversas: apara espaços e corta em LIMITE_PREVIA caracteres.
 */
export function gerarPrevia(texto: string): string {
    const aparado = texto.trim();
    if (aparado.length <= LIMITE_PREVIA) {
        return aparado;
    }
    return aparado.slice(0, LIMITE_PREVIA);
}
