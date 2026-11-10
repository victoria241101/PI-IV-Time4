import { Router, type RequestHandler } from "express";
import { ObjectId, type Db, type Document, type Filter } from "mongodb";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";

// A conexão e a autenticação são recebidas aqui para permitir testes isolados.
// Na aplicação, ambas são as mesmas usadas pelas demais rotas.
export function criarRotasLeituraConsultas(dependencias: {
    obterBanco: () => Db;
    autenticar: RequestHandler;
}) {
    const router = Router();
    router.get("/", dependencias.autenticar,
        permitirFuncoes("SECRETARIA", "ENFERMEIRO", "VETERINARIO"),
        async (req, res) => {
            const data = req.query.data;
            if (typeof data !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(data) ||
                !Number.isFinite(Date.parse(`${data}T00:00:00Z`)) ||
                new Date(`${data}T00:00:00Z`).toISOString().slice(0, 10) !== data) {
                return res.status(400).json({ mensagem: "Informe uma data válida no formato AAAA-MM-DD." });
            }
            const paginaTexto = req.query.pagina ?? "1";
            if (typeof paginaTexto !== "string" || !/^[1-9]\d{0,3}$/.test(paginaTexto)) {
                return res.status(400).json({ mensagem: "Informe uma página entre 1 e 9999." });
            }
            const pagina = Number(paginaTexto);
            const limite = 50;
            try {
                const banco = dependencias.obterBanco();
                // Agendamentos guardam a data/hora civil da clínica, sem fuso.
                const filtro: Filter<Document> = {
                    dataHora: { $gte: `${data}T00:00:00`, $lte: `${data}T23:59:59.999` }
                };
                if (res.locals.usuarioTipo === "ENFERMEIRO") {
                    filtro.status = { $in: ["chegada_confirmada", "em_triagem"] };
                }
                if (res.locals.usuarioTipo === "VETERINARIO") {
                    const usuarioId = String(res.locals.usuarioId ?? "");
                    if (!ObjectId.isValid(usuarioId)) {
                        return res.status(403).json({ mensagem: "Veterinário ativo não encontrado." });
                    }
                    const profissional = await banco.collection("veterinarios").findOne({
                        usuarioId: new ObjectId(usuarioId), ativo: true
                    });
                    if (!profissional) {
                        return res.status(403).json({ mensagem: "Veterinário ativo não encontrado." });
                    }
                    const id = String(profissional._id);
                    filtro.veterinarioId = { $in: ObjectId.isValid(id) ? [id, new ObjectId(id)] : [id] };
                }
                const registros = await banco.collection("consultas").find(filtro, {
                    projection: { _id: 1, petId: 1, tutorId: 1, veterinarioId: 1,
                        dataHora: 1, duracaoMinutos: 1, tipo: 1, status: 1, enfermeiroUsuarioId: 1 }
                }).sort({ dataHora: 1, _id: 1 }).skip((pagina - 1) * limite).limit(limite + 1).toArray();
                const consultas = registros.slice(0, limite).map(item => ({
                    id: String(item._id),
                    petId: item.petId == null ? null : String(item.petId),
                    tutorId: item.tutorId == null ? null : String(item.tutorId),
                    veterinarioId: item.veterinarioId == null ? null : String(item.veterinarioId),
                    dataHora: item.dataHora, duracaoMinutos: item.duracaoMinutos,
                    tipo: item.tipo, status: item.status,
                    enfermeiroUsuarioId: item.enfermeiroUsuarioId == null ? null : String(item.enfermeiroUsuarioId),
                    podeIniciarTriagem: res.locals.usuarioTipo === "ENFERMEIRO" && item.status === "chegada_confirmada",
                    podeContinuarTriagem: res.locals.usuarioTipo === "ENFERMEIRO" && item.status === "em_triagem" &&
                        item.enfermeiroUsuarioId != null && String(item.enfermeiroUsuarioId) === res.locals.usuarioId
                }));
                return res.json({ consultas, pagina, limite, temMais: registros.length > limite });
            } catch {
                return res.status(503).json({ mensagem: "Não foi possível consultar a agenda. Tente novamente." });
            }
        });
    return router;
}
