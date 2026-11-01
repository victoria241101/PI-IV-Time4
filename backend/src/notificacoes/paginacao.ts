import { ObjectId } from "mongodb";
import { ehObjectIdHex } from "../chat/validacao.js";
import type { Resultado } from "./tipos.js";
import { LIMITE_PADRAO, LIMITE_MAXIMO } from "./tipos.js";

/**
 * Valida o limite de itens em consultas paginadas de notificações.
 * - Ausente, nulo ou vazio -> LIMITE_PADRAO (20).
 * - Número inteiro ou texto numérico inteiro entre 1 e LIMITE_MAXIMO (50) -> sucesso.
 * - Qualquer outro valor (decimais, fora do intervalo, texto não numérico) -> erro.
 */
export function validarLimite(valor: unknown): Resultado<number> {
    if (valor === undefined || valor === null || valor === "") {
        return { ok: true, valor: LIMITE_PADRAO };
    }

    let num: number;

    if (typeof valor === "number") {
        if (!Number.isInteger(valor)) {
            return {
                ok: false,
                mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_MAXIMO}.`
            };
        }
        num = valor;
    } else if (typeof valor === "string") {
        const aparado = valor.trim();
        if (!/^\d+$/.test(aparado)) {
            return {
                ok: false,
                mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_MAXIMO}.`
            };
        }
        num = Number(aparado);
    } else {
        return {
            ok: false,
            mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_MAXIMO}.`
        };
    }

    if (num < 1 || num > LIMITE_MAXIMO) {
        return {
            ok: false,
            mensagem: `Limite deve ser um número inteiro entre 1 e ${LIMITE_MAXIMO}.`
        };
    }

    return { ok: true, valor: num };
}

/**
 * Valida e converte um cursor de paginação em ObjectId.
 * - Ausente, nulo ou vazio -> null.
 * - String com exatamente 24 caracteres hexadecimais -> ObjectId correspondente.
 * - Qualquer outro formato (número, tamanho incorreto, texto inválido) -> erro.
 */
export function lerCursorObjectId(valor: unknown): Resultado<ObjectId | null> {
    if (valor === undefined || valor === null || valor === "") {
        return { ok: true, valor: null };
    }

    if (ehObjectIdHex(valor)) {
        return { ok: true, valor: new ObjectId(valor) };
    }

    return {
        ok: false,
        mensagem: "Cursor inválido. Deve ser um ID hexadecimal de 24 caracteres."
    };
}
