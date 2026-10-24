import { ehObjectIdHex } from "./validacao.js";

/**
 * Gera a chave única para a conversa compartilhada de um usuário com a Secretaria.
 * Formato: "secretaria:<usuarioId em hex minúsculo>".
 * Lança Error se usuarioId não for uma string com exatamente 24 caracteres hexadecimais.
 */
export function chaveSecretaria(usuarioId: string): string {
    if (!ehObjectIdHex(usuarioId)) {
        throw new Error("ID de usuário inválido para chave da secretaria.");
    }
    return `secretaria:${usuarioId.toLowerCase()}`;
}

/**
 * Gera a chave única para uma conversa direta entre dois usuários.
 * Formato: "direta:<idMenor>:<idMaior>" (em ordem alfabética e hex minúsculo).
 * É estritamente simétrica: chaveDireta(a, b) === chaveDireta(b, a).
 * Lança Error se algum dos IDs não for um hex de 24 caracteres ou se os IDs forem iguais.
 */
export function chaveDireta(a: string, b: string): string {
    if (!ehObjectIdHex(a) || !ehObjectIdHex(b)) {
        throw new Error("IDs inválidos para chave de conversa direta.");
    }

    const aMin = a.toLowerCase();
    const bMin = b.toLowerCase();

    if (aMin === bMin) {
        throw new Error("Os participantes de uma conversa direta devem ser diferentes.");
    }

    const [menor, maior] = aMin < bMin ? [aMin, bMin] : [bMin, aMin];
    return `direta:${menor}:${maior}`;
}
