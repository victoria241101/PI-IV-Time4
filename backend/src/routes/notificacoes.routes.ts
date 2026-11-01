import { Router } from "express";
import { ObjectId, type Filter } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { obterBanco } from "../database.js";
import { ehObjectIdHex } from "../chat/validacao.js";
import { validarListagem } from "../notificacoes/validacao.js";
import type {
    NotificacaoDocumento,
    TipoNotificacao
} from "../notificacoes/tipos.js";

const router = Router();

// Todas as rotas de notificações exigem autenticação (qualquer papel)
router.use(autenticar);

/**
 * Interface padronizada para retorno de notificações pela API.
 * Não expõe destinatarioId, remetenteId, chave nem campos de e-mail.
 */
export interface NotificacaoResposta {
    id: string;
    tipo: TipoNotificacao;
    titulo: string;
    mensagem: string;
    petId: string | null;
    consultaId: string | null;
    lida: boolean;
    lidaEm: Date | null;
    criadoEm: Date;
}

/**
 * Função PURA: serializa um documento do MongoDB para o formato de resposta da API.
 * Garante que lida seja booleano derivado de lidaEm e que campos internos/privados não vazem.
 */
export function serializarNotificacao(doc: NotificacaoDocumento): NotificacaoResposta {
    return {
        id: doc._id.toHexString(),
        tipo: doc.tipo,
        titulo: doc.titulo,
        mensagem: doc.mensagem,
        petId: doc.petId ?? null,
        consultaId: doc.consultaId ?? null,
        lida: Boolean(doc.lidaEm),
        lidaEm: doc.lidaEm ?? null,
        criadoEm: doc.criadoEm
    };
}

/**
 * GET /notificacoes/contagem
 * Retorna apenas o número de notificações não lidas do usuário autenticado.
 * Rota leve destinada ao polling periódico (~15 s) no app.
 */
router.get("/contagem", async (_req, res) => {
    try {
        const usuarioIdHex = res.locals.usuarioId;
        if (!ehObjectIdHex(usuarioIdHex)) {
            return res.status(401).json({
                mensagem: "Usuário autenticado inválido."
            });
        }
        const destinatarioId = new ObjectId(usuarioIdHex);

        const banco = obterBanco();
        const colecao = banco.collection<NotificacaoDocumento>("notificacoes");

        const naoLidas = await colecao.countDocuments({
            destinatarioId,
            lidaEm: null
        });

        return res.status(200).json({ naoLidas });
    } catch (erro) {
        console.error("Erro ao obter contagem de notificações:", erro);
        return res.status(500).json({
            mensagem: "Erro ao obter contagem de notificações."
        });
    }
});

/**
 * GET /notificacoes
 * Lista notificações do usuário autenticado, mais novas primeiro.
 * Suporta paginação por cursor (antes/depois), limite (1 a 50) e filtro somenteNaoLidas.
 * Resposta: { notificacoes: [...], naoLidas: n }
 */
router.get("/", async (req, res) => {
    try {
        const usuarioIdHex = res.locals.usuarioId;
        if (!ehObjectIdHex(usuarioIdHex)) {
            return res.status(401).json({
                mensagem: "Usuário autenticado inválido."
            });
        }
        const destinatarioId = new ObjectId(usuarioIdHex);

        const validacao = validarListagem(req.query);
        if (!validacao.ok) {
            return res.status(400).json({
                mensagem: validacao.mensagem
            });
        }

        const { limite, antes, depois, somenteNaoLidas } = validacao.valor;

        const filtro: Filter<NotificacaoDocumento> = {
            destinatarioId
        };

        if (somenteNaoLidas) {
            filtro.lidaEm = null;
        }

        if (antes || depois) {
            const filtroId: Record<string, ObjectId> = {};
            if (antes) {
                filtroId.$lt = antes;
            }
            if (depois) {
                filtroId.$gt = depois;
            }
            filtro._id = filtroId;
        }

        const banco = obterBanco();
        const colecao = banco.collection<NotificacaoDocumento>("notificacoes");

        const [documentos, naoLidas] = await Promise.all([
            colecao
                .find(filtro)
                .sort({ criadoEm: -1, _id: -1 })
                .limit(limite)
                .toArray(),
            colecao.countDocuments({
                destinatarioId,
                lidaEm: null
            })
        ]);

        const notificacoes = documentos.map(serializarNotificacao);

        return res.status(200).json({
            notificacoes,
            naoLidas
        });
    } catch (erro) {
        console.error("Erro ao listar notificações:", erro);
        return res.status(500).json({
            mensagem: "Erro ao consultar notificações."
        });
    }
});

export default router;
