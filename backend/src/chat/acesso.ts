import type { TipoConversa, UsuarioAutenticado, PapelChat } from "./tipos.js";
import { LADO_SECRETARIA, PAPEL_SECRETARIA } from "./tipos.js";

export type ConversaParaAcesso = {
    tipo: TipoConversa;
    usuarioId?: { toString(): string };
    participantes?: { toString(): string }[];
};

/**
 * Determina a chave do "lado" do usuário na conversa:
 * - Em conversa compartilhada com a secretaria:
 *   - Usuário com papel SECRETARIA -> "SECRETARIA"
 *   - O usuário dono da caixa (usuarioId igual ao id dele) -> id do usuário em minúsculas
 *   - Qualquer outro usuário -> null
 * - Em conversa direta:
 *   - Participante da conversa -> id do usuário em minúsculas
 *   - Não participante -> null
 */
export function ladoDoUsuario(
    conversa: ConversaParaAcesso,
    usuario: UsuarioAutenticado
): string | null {
    const idUsuarioMin = usuario.id.toLowerCase();

    if (conversa.tipo === "secretaria") {
        if (usuario.papel === PAPEL_SECRETARIA) {
            return LADO_SECRETARIA;
        }

        if (conversa.usuarioId && conversa.usuarioId.toString().toLowerCase() === idUsuarioMin) {
            return idUsuarioMin;
        }

        return null;
    }

    if (conversa.tipo === "direta") {
        if (Array.isArray(conversa.participantes)) {
            const ehParticipante = conversa.participantes.some(
                p => p && p.toString().toLowerCase() === idUsuarioMin
            );
            if (ehParticipante) {
                return idUsuarioMin;
            }
        }
        return null;
    }

    return null;
}

/**
 * Verifica se o usuário tem permissão para visualizar e interagir com a conversa.
 * Retorna true se ele possui um lado válido na conversa; false caso contrário.
 */
export function podeAcessarConversa(
    conversa: ConversaParaAcesso,
    usuario: UsuarioAutenticado
): boolean {
    return ladoDoUsuario(conversa, usuario) !== null;
}

/**
 * Identifica se uma determinada mensagem foi enviada pelo lado especificado da conversa.
 * - Em conversa de secretaria:
 *   - O lado "SECRETARIA" é dono das mensagens cujo remetenteTipo é SECRETARIA
 *   - O lado do usuário é dono das demais mensagens
 * - Em conversa direta:
 *   - O dono é o remetente cujo remetenteId seja igual ao lado (hex minúsculo)
 */
export function mensagemEhDoLado(
    tipo: TipoConversa,
    mensagem: { remetenteId: { toString(): string }; remetenteTipo: PapelChat },
    lado: string
): boolean {
    if (tipo === "secretaria") {
        if (lado === LADO_SECRETARIA) {
            return mensagem.remetenteTipo === PAPEL_SECRETARIA;
        }
        return mensagem.remetenteTipo !== PAPEL_SECRETARIA;
    }

    if (tipo === "direta") {
        return mensagem.remetenteId.toString().toLowerCase() === lado.toLowerCase();
    }

    return false;
}
