import type { UsuarioAutenticado } from "./tipos.js";
import { normalizarTipoUsuario } from "./papeis.js";
import { ehObjectIdHex } from "./validacao.js";

/**
 * Monta e valida o objeto UsuarioAutenticado a partir dos dados recebidos da sessão (token/middlewares).
 * - usuarioId deve ser uma string de 24 hexadecimais (convertido para minúsculas).
 * - usuarioTipo deve ser normalizado para um dos papéis válidos do chat.
 * Se algum for inválido, retorna null.
 */
export function montarUsuarioAutenticado(
    usuarioId: unknown,
    usuarioTipo: unknown
): UsuarioAutenticado | null {
    if (!ehObjectIdHex(usuarioId)) {
        return null;
    }

    const papel = normalizarTipoUsuario(usuarioTipo);
    if (!papel) {
        return null;
    }

    return {
        id: usuarioId.toLowerCase(),
        papel
    };
}
