import type { ResultadoValidacao } from "./tipos.js";
import {
    LIMITE_PAGINA,
    LIMITE_PAGINA_PADRAO,
    LIMITE_BUSCA
} from "./tipos.js";
import { ehObjectIdHex } from "./validacao.js";

/**
 * Valida o limite para consultas paginadas.
 * - Ausente, nulo ou vazio -> LIMITE_PAGINA_PADRAO (50).
 * - Número inteiro ou texto numérico inteiro entre 1 e LIMITE_PAGINA (100) -> sucesso.
 * - Qualquer outro valor (decimais, fora do intervalo, texto não numérico) -> erro.
 */
export function validarLimite(valor: unknown): ResultadoValidacao<number> {
    if (valor === undefined || valor === null || valor === "") {
        return { ok: true, valor: LIMITE_PAGINA_PADRAO };
    }

    let num: number;

    if (typeof valor === "number") {
        if (!Number.isInteger(valor)) {
            return {
                ok: false,
                mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_PAGINA}.`
            };
        }
        num = valor;
    } else if (typeof valor === "string") {
        const aparado = valor.trim();
        if (!/^\d+$/.test(aparado)) {
            return {
                ok: false,
                mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_PAGINA}.`
            };
        }
        num = Number(aparado);
    } else {
        return {
            ok: false,
            mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_PAGINA}.`
        };
    }

    if (num < 1 || num > LIMITE_PAGINA) {
        return {
            ok: false,
            mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_PAGINA}.`
        };
    }

    return { ok: true, valor: num };
}

/**
 * Valida e extrai cursor de paginação (geralmente id de mensagem).
 * - Ausente, nulo ou vazio -> null.
 * - String com 24 hexadecimais -> o hex normalizado em minúsculas.
 * - Qualquer outro formato -> erro.
 */
export function lerCursor(valor: unknown): ResultadoValidacao<string | null> {
    if (valor === undefined || valor === null || valor === "") {
        return { ok: true, valor: null };
    }

    if (ehObjectIdHex(valor)) {
        return { ok: true, valor: valor.toLowerCase() };
    }

    return {
        ok: false,
        mensagem: "Cursor inválido. Deve ser um ID hexadecimal de 24 caracteres."
    };
}

/**
 * Valida termo de busca para filtros de contatos ou usuários.
 * - Ausente, nulo ou composto apenas por espaços -> null.
 * - Texto de 1 a LIMITE_BUSCA (100) caracteres -> texto com trim.
 * - Não texto ou mais de LIMITE_BUSCA caracteres -> erro.
 */
export function validarBusca(valor: unknown): ResultadoValidacao<string | null> {
    if (valor === undefined || valor === null) {
        return { ok: true, valor: null };
    }

    if (typeof valor !== "string") {
        return { ok: false, mensagem: "Termo de busca deve ser um texto." };
    }

    const aparado = valor.trim();
    if (aparado.length === 0) {
        return { ok: true, valor: null };
    }

    if (aparado.length > LIMITE_BUSCA) {
        return {
            ok: false,
            mensagem: `Termo de busca não pode exceder ${LIMITE_BUSCA} caracteres.`
        };
    }

    return { ok: true, valor: aparado };
}

/**
 * Escapa caracteres com significado especial em expressões regulares para busca segura.
 */
export function escaparRegex(texto: string): string {
    return texto.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
