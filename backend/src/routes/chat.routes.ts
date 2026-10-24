import { Router } from "express";
import type { Response } from "express";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { montarUsuarioAutenticado } from "../chat/sessao.js";
import { validarBusca } from "../chat/paginacao.js";
import { listarContatos } from "../chat/contatos.js";
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

/**
 * 6.1 GET /chat/contatos
 * Lista contatos permitidos para o usuário autenticado, com filtro opcional por busca (query param `busca`).
 */
router.get("/contatos", async (req, res) => {
    const usuario = obterUsuario(res);
    if (!usuario) {
        return res.status(403).json({
            mensagem: "Seu tipo de usuário não tem acesso ao chat."
        });
    }

    const validacaoBusca = validarBusca(req.query.busca);
    if (!validacaoBusca.ok) {
        return res.status(400).json({ mensagem: validacaoBusca.mensagem });
    }

    try {
        const db = obterBanco();
        const contatos = await listarContatos(db, usuario, validacaoBusca.valor);
        return res.status(200).json({
            mensagem: "Contatos listados com sucesso!",
            contatos
        });
    } catch (erro) {
        console.error("Erro ao listar contatos do chat:", erro);
        return res.status(500).json({
            mensagem: "Erro interno no servidor."
        });
    }
});

export default router;

