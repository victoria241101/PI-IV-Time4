import { Router } from "express";
import type { Response } from "express";
import { ObjectId } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { montarUsuarioAutenticado } from "../chat/sessao.js";
import { validarBusca } from "../chat/paginacao.js";
import { listarContatos, type Contato } from "../chat/contatos.js";
import { abrirCaixaSecretaria } from "../chat/conversas.js";
import { ehObjectIdHex } from "../chat/validacao.js";
import { normalizarTipoUsuario } from "../chat/papeis.js";
import { PAPEL_SECRETARIA, type UsuarioAutenticado } from "../chat/tipos.js";

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

/**
 * 6.2 POST /chat/conversas
 * Abre ou reaproveita uma conversa com a secretaria ou outro usuário.
 */
router.post("/conversas", async (req, res) => {
    const usuario = obterUsuario(res);
    if (!usuario) {
        return res.status(403).json({
            mensagem: "Seu tipo de usuário não tem acesso ao chat."
        });
    }

    const body = req.body;
    if (!body || typeof body !== "object") {
        return res.status(400).json({
            mensagem: "Corpo da requisição inválido."
        });
    }

    const temCom = Object.prototype.hasOwnProperty.call(body, "com") && body.com !== undefined;
    const temUsuarioId = Object.prototype.hasOwnProperty.call(body, "usuarioId") && body.usuarioId !== undefined;

    // Exatamente um entre "com" e "usuarioId"; 400 nos demais casos
    if ((temCom && temUsuarioId) || (!temCom && !temUsuarioId)) {
        return res.status(400).json({
            mensagem: "Informe exatamente um dos campos: 'com' ou 'usuarioId'."
        });
    }

    if (temCom) {
        if (typeof body.com !== "string" || body.com !== "secretaria") {
            return res.status(400).json({
                mensagem: "O campo 'com' aceita apenas o valor 'secretaria'."
            });
        }

        if (usuario.papel === PAPEL_SECRETARIA) {
            return res.status(403).json({
                mensagem: "Secretária não pode abrir conversa com a secretaria."
            });
        }

        try {
            const db = obterBanco();
            const usuarioCaixaId = new ObjectId(usuario.id);
            const { conversa, criada } = await abrirCaixaSecretaria(db, usuarioCaixaId);

            const outro: Contato = {
                tipo: "secretaria",
                nome: "Secretaria"
            };

            return res.status(criada ? 201 : 200).json({
                mensagem: criada ? "Conversa criada com sucesso!" : "Conversa aberta com sucesso!",
                conversa: {
                    _id: conversa._id,
                    tipo: conversa.tipo,
                    outro
                }
            });
        } catch (erro) {
            console.error("Erro ao abrir conversa com a secretaria:", erro);
            return res.status(500).json({
                mensagem: "Erro interno no servidor."
            });
        }
    }

    // A partir daqui, temUsuarioId é verdadeiro
    if (!ehObjectIdHex(body.usuarioId)) {
        return res.status(400).json({
            mensagem: "O campo 'usuarioId' deve ser um ID hexadecimal de 24 caracteres."
        });
    }

    if (body.usuarioId.toLowerCase() === usuario.id.toLowerCase()) {
        return res.status(400).json({
            mensagem: "Não é possível abrir uma conversa consigo mesmo."
        });
    }

    try {
        const db = obterBanco();
        const alvoObjectId = new ObjectId(body.usuarioId);
        const alvoDoc = await db.collection<{
            _id: ObjectId;
            tipo?: string;
            ativo?: boolean;
            nome?: string;
        }>("usuarios").findOne({ _id: alvoObjectId });

        if (!alvoDoc || !(alvoDoc._id instanceof ObjectId) || alvoDoc.ativo !== true) {
            return res.status(404).json({
                mensagem: "Usuário alvo não encontrado ou inativo."
            });
        }

        const papelAlvo = normalizarTipoUsuario(alvoDoc.tipo);
        if (!papelAlvo) {
            return res.status(404).json({
                mensagem: "Usuário alvo não encontrado ou possui tipo não reconhecido."
            });
        }

        // Caso (b): Alvo SECRETARIA por quem não é secretária (equivale a "com")
        if (papelAlvo === PAPEL_SECRETARIA) {
            if (usuario.papel === PAPEL_SECRETARIA) {
                return res.status(403).json({
                    mensagem: "Secretária não pode abrir conversa com outra secretária."
                });
            }

            // Equivale a com: "secretaria" (abre a caixa do próprio chamador)
            const usuarioCaixaId = new ObjectId(usuario.id);
            const { conversa, criada } = await abrirCaixaSecretaria(db, usuarioCaixaId);

            const outro: Contato = {
                tipo: "secretaria",
                nome: "Secretaria"
            };

            return res.status(criada ? 201 : 200).json({
                mensagem: criada ? "Conversa criada com sucesso!" : "Conversa aberta com sucesso!",
                conversa: {
                    _id: conversa._id,
                    tipo: conversa.tipo,
                    outro
                }
            });
        }

        // Caso (c): Chamador SECRETARIA com usuário tutor, veterinário ou enfermeiro
        if (usuario.papel === PAPEL_SECRETARIA) {
            const { conversa, criada } = await abrirCaixaSecretaria(db, alvoDoc._id);

            const outro: Contato = {
                tipo: "usuario",
                usuarioId: alvoDoc._id.toHexString(),
                nome: typeof alvoDoc.nome === "string" ? alvoDoc.nome : "",
                papel: papelAlvo
            };

            return res.status(criada ? 201 : 200).json({
                mensagem: criada ? "Conversa criada com sucesso!" : "Conversa aberta com sucesso!",
                conversa: {
                    _id: conversa._id,
                    tipo: conversa.tipo,
                    outro
                }
            });
        }

        // Demais casos (conversa direta)
        return res.status(400).json({
            mensagem: "Conversa direta ainda não disponível."
        });
    } catch (erro) {
        console.error("Erro ao abrir conversa:", erro);
        return res.status(500).json({
            mensagem: "Erro interno no servidor."
        });
    }
});

export default router;


