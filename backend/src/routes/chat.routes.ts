import { Router } from "express";
import type { Response } from "express";
import { autenticar } from "../middlewares/auth.middleware.js";
import { montarUsuarioAutenticado } from "../chat/sessao.js";
import type { UsuarioAutenticado } from "../chat/tipos.js";

const router = Router();

// Todas as rotas do chat exigem autenticação
router.use(autenticar);

/**
 * Extrai e valida o usuário autenticado a partir dos dados gravados pelo middleware autenticar.
 * Retorna null se o tipo de usuário não for reconhecido pelo sistema de chat
 * (as rotas devem responder 403 com "Seu tipo de usuário não tem acesso ao chat.").
 */
export function obterUsuario(res: Response): UsuarioAutenticado | null {
    return montarUsuarioAutenticado(res.locals.usuarioId, res.locals.usuarioTipo);
}

export default router;
