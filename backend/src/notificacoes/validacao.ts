import { ObjectId } from "mongodb";
import { ehObjectIdHex } from "../chat/validacao.js";
import type { Resultado, NotificacaoNova, TipoNotificacao } from "./tipos.js";
import {
    TIPOS_NOTIFICACAO,
    LIMITE_TITULO,
    LIMITE_MENSAGEM
} from "./tipos.js";
import { validarLimite, lerCursorObjectId } from "./paginacao.js";

export interface ParametrosListagem {
    limite: number;
    antes: ObjectId | null;
    depois: ObjectId | null;
    somenteNaoLidas: boolean;
}

/**
 * Valida a entrada para cadastro de uma nova notificação no sistema.
 * Garante que destinatário, tipo, título e mensagem estejam dentro das regras da especificação.
 */
export function validarNotificacaoNova(entrada: unknown): Resultado<NotificacaoNova> {
    if (!entrada || typeof entrada !== "object" || Array.isArray(entrada)) {
        return {
            ok: false,
            mensagem: "Dados da notificação devem ser um objeto."
        };
    }

    const obj = entrada as Record<string, unknown>;

    // 1. Destinatário (obrigatório, ObjectId)
    let destinatarioId: ObjectId;
    if (obj.destinatarioId instanceof ObjectId) {
        destinatarioId = obj.destinatarioId;
    } else if (ehObjectIdHex(obj.destinatarioId)) {
        destinatarioId = new ObjectId(obj.destinatarioId);
    } else {
        return {
            ok: false,
            mensagem: "ID do destinatário inválido."
        };
    }

    // 2. Remetente (opcional, ObjectId ou null)
    let remetenteId: ObjectId | null = null;
    if (obj.remetenteId !== undefined && obj.remetenteId !== null && obj.remetenteId !== "") {
        if (obj.remetenteId instanceof ObjectId) {
            remetenteId = obj.remetenteId;
        } else if (ehObjectIdHex(obj.remetenteId)) {
            remetenteId = new ObjectId(obj.remetenteId);
        } else {
            return {
                ok: false,
                mensagem: "ID do remetente inválido."
            };
        }
    }

    // 3. Tipo (obrigatório, pertencente a TIPOS_NOTIFICACAO)
    if (
        typeof obj.tipo !== "string" ||
        !(TIPOS_NOTIFICACAO as readonly string[]).includes(obj.tipo)
    ) {
        return {
            ok: false,
            mensagem: "Tipo de notificação inválido."
        };
    }
    const tipo = obj.tipo as TipoNotificacao;

    // 4. Título (obrigatório, 1 a 100 caracteres)
    if (typeof obj.titulo !== "string") {
        return {
            ok: false,
            mensagem: "Título deve ser um texto."
        };
    }
    const titulo = obj.titulo.trim();
    if (titulo.length === 0) {
        return {
            ok: false,
            mensagem: "Título não pode ser vazio."
        };
    }
    if (titulo.length > LIMITE_TITULO) {
        return {
            ok: false,
            mensagem: `Título não pode exceder ${LIMITE_TITULO} caracteres.`
        };
    }

    // 5. Mensagem (obrigatória, 1 a 500 caracteres)
    if (typeof obj.mensagem !== "string") {
        return {
            ok: false,
            mensagem: "Mensagem deve ser um texto."
        };
    }
    const mensagem = obj.mensagem.trim();
    if (mensagem.length === 0) {
        return {
            ok: false,
            mensagem: "Mensagem não pode ser vazia."
        };
    }
    if (mensagem.length > LIMITE_MENSAGEM) {
        return {
            ok: false,
            mensagem: `Mensagem não pode exceder ${LIMITE_MENSAGEM} caracteres.`
        };
    }

    // 6. PetId (opcional, texto legado ou null)
    let petId: string | null = null;
    if (obj.petId !== undefined && obj.petId !== null) {
        if (typeof obj.petId !== "string") {
            return {
                ok: false,
                mensagem: "ID do pet deve ser um texto."
            };
        }
        const aparado = obj.petId.trim();
        petId = aparado.length > 0 ? aparado : null;
    }

    // 7. ConsultaId (opcional, texto legado ou null)
    let consultaId: string | null = null;
    if (obj.consultaId !== undefined && obj.consultaId !== null) {
        if (typeof obj.consultaId !== "string") {
            return {
                ok: false,
                mensagem: "ID da consulta deve ser um texto."
            };
        }
        const aparado = obj.consultaId.trim();
        consultaId = aparado.length > 0 ? aparado : null;
    }

    // 8. Chave (opcional, texto ou null)
    let chave: string | null = null;
    if (obj.chave !== undefined && obj.chave !== null) {
        if (typeof obj.chave !== "string") {
            return {
                ok: false,
                mensagem: "Chave deve ser um texto."
            };
        }
        const aparado = obj.chave.trim();
        chave = aparado.length > 0 ? aparado : null;
    }

    return {
        ok: true,
        valor: {
            destinatarioId,
            remetenteId,
            tipo,
            titulo,
            mensagem,
            petId,
            consultaId,
            chave
        }
    };
}

/**
 * Valida os parâmetros de busca para listagem de notificações do usuário.
 * Reusa a lógica de paginação para limite (1-50) e cursores antes/depois (ObjectId).
 * Restringe 'somenteNaoLidas' estritamente a "true" ou "false" (ou ausente).
 */
export function validarListagem(query: unknown): Resultado<ParametrosListagem> {
    const q = (query && typeof query === "object" && !Array.isArray(query))
        ? (query as Record<string, unknown>)
        : {};

    // 1. Limite (1 a 50, padrão 20)
    const resultadoLimite = validarLimite(q.limite);
    if (!resultadoLimite.ok) {
        return resultadoLimite;
    }

    // 2. Cursor 'antes' (ObjectId hex de 24 caracteres ou null)
    const resultadoAntes = lerCursorObjectId(q.antes);
    if (!resultadoAntes.ok) {
        return resultadoAntes;
    }

    // 3. Cursor 'depois' (ObjectId hex de 24 caracteres ou null)
    const resultadoDepois = lerCursorObjectId(q.depois);
    if (!resultadoDepois.ok) {
        return resultadoDepois;
    }

    // 4. Filtro 'somenteNaoLidas' (estritamente 'true' ou 'false', default false)
    let somenteNaoLidas = false;
    const valorNaoLidas = q.somenteNaoLidas;

    if (valorNaoLidas !== undefined && valorNaoLidas !== null && valorNaoLidas !== "") {
        if (valorNaoLidas === "true" || valorNaoLidas === true) {
            somenteNaoLidas = true;
        } else if (valorNaoLidas === "false" || valorNaoLidas === false) {
            somenteNaoLidas = false;
        } else {
            return {
                ok: false,
                mensagem: "Parâmetro 'somenteNaoLidas' deve ser 'true' ou 'false'."
            };
        }
    }

    return {
        ok: true,
        valor: {
            limite: resultadoLimite.valor,
            antes: resultadoAntes.valor,
            depois: resultadoDepois.valor,
            somenteNaoLidas
        }
    };
}
