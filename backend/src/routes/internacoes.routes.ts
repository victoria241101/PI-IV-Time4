import { Router } from "express";
import { ObjectId, type Document } from "mongodb";
import { autenticar } from "../middlewares/auth.middleware.js";
import { permitirFuncoes } from "../middlewares/permissoes.middleware.js";
import { obterBanco } from "../database.js";
import { notificarAlta } from "../notificacoes/eventos.js";

export function criarRotasInternacoes(deps = { autenticar, obterBanco, notificarAlta }) {
const { autenticar, obterBanco, notificarAlta } = deps;
const router = Router();
const ids = (id: string) => ObjectId.isValid(id) ? [id, new ObjectId(id)] : [id];
async function profissional(usuarioId: string, perfil: string) {
    return obterBanco().collection(perfil === "VETERINARIO" ? "veterinarios" : "enfermeiros")
        .findOne({ usuarioId: { $in: ids(usuarioId) }, ativo: true });
}

// Lista independente da agenda: internações continuam ativas em outros dias.
router.get("/", autenticar, permitirFuncoes("VETERINARIO", "ENFERMEIRO"), async (_req, res) => {
    try {
        if (!await profissional(res.locals.usuarioId, res.locals.usuarioTipo)) return res.sendStatus(403);
        const banco = obterBanco();
        const registros = await banco.collection("internacoes").find({ status: "ativa" }).sort({ dataEntrada: -1 }).toArray();
        const internacoes = await Promise.all(registros.map(async registro => {
            const pet = await banco.collection<Document & { _id: string | ObjectId }>("pets").findOne({ _id: { $in: ids(String(registro.petId)) } });
            const tutor = pet ? await banco.collection<Document & { _id: string | ObjectId }>("tutores").findOne({ _id: { $in: ids(String(pet.tutorId)) } }) : null;
            const vet = await banco.collection<Document & { _id: string | ObjectId }>("veterinarios").findOne({ _id: { $in: ids(String(registro.veterinarioId)) } });
            return { ...registro, petNome: pet?.nome, especie: pet?.especie, fotoPet: pet?.urlFoto ?? pet?.fotoUrl,
                tutorNome: tutor?.nome, veterinarioNome: vet?.nome };
        }));
        return res.json({ internacoes });
    } catch { return res.status(500).json({ mensagem: "Erro ao listar internações." }); }
});

// Mesmo formulário para os dois perfis; versão impede perda de atualizações concorrentes.
router.patch("/:id/prontuario", autenticar, permitirFuncoes("VETERINARIO", "ENFERMEIRO"), async (req, res) => {
    try {
        const pessoa = await profissional(res.locals.usuarioId, res.locals.usuarioTipo);
        if (!pessoa) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        const { versao, prontuario } = req.body;
        const texto = (v: unknown) => typeof v === "string" && v.length <= 20000;
        const data = (v: unknown) => typeof v === "string" && Number.isFinite(Date.parse(v));
        if (!Number.isInteger(versao) || versao < 0 || !prontuario ||
            ![prontuario.observacoesTriagem, prontuario.descricaoConsulta].every(texto) ||
            ![prontuario.procedimentosInternacao, prontuario.medicacoesInternacao, prontuario.notasInternacao].every(v => Array.isArray(v) && v.length <= 1000)) {
            return res.status(400).json({ mensagem: "Prontuário inválido." });
        }
        const procedimentos = prontuario.procedimentosInternacao;
        const medicacoes = prontuario.medicacoesInternacao;
        const notas = prontuario.notasInternacao;
        if (procedimentos.some((p: any) => !p || !texto(p.nome) || !p.nome.trim() || !texto(p.detalhes) || !data(p.agendadoPara) ||
                (p.concluidoEm !== null && !data(p.concluidoEm)) || !texto(p.detalhesConclusao)) ||
            medicacoes.some((m: any) => !m || ![m.nome, m.dosagem, m.frequencia].every(v => texto(v) && v.trim()) || !texto(m.detalhes) ||
                !Array.isArray(m.administracoes) || m.administracoes.length > 1000 || m.administracoes.some((a: any) => !a || !data(a.realizadaEm) || !texto(a.observacao))) ||
            notas.some((n: any) => !n || !texto(n.texto) || !n.texto.trim())) return res.status(400).json({ mensagem: "Campos do prontuário inválidos." });
        const colecao = obterBanco().collection<Document & { _id: string | ObjectId }>("internacoes");
        const filtro = { _id: { $in: ids(String(req.params.id)) }, status: "ativa" };
        const atual = await colecao.findOne(filtro);
        if (!atual) return res.status(409).json({ mensagem: "Internação não está ativa." });
        if ((atual.versao ?? 0) !== versao) return res.status(409).json({ mensagem: "Outro profissional atualizou o prontuário. Atualize a tela antes de salvar." });
        const vet = res.locals.usuarioTipo === "VETERINARIO";
        if (vet && String(atual.veterinarioId) !== String(pessoa._id)) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        const anterior = atual.prontuario ?? { procedimentosInternacao: [], medicacoesInternacao: [], notasInternacao: [], observacoesTriagem: "", descricaoConsulta: "" };
        const igual = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
        const autor = pessoa.nome ?? String(pessoa._id);
        // Preserva todos os registros anteriores; cada perfil só adiciona ações permitidas.
        if (notas.length < anterior.notasInternacao.length || !anterior.notasInternacao.every((n: any, i: number) => igual(n, notas[i]))) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        if (!vet && (prontuario.observacoesTriagem !== anterior.observacoesTriagem || prontuario.descricaoConsulta !== anterior.descricaoConsulta ||
            procedimentos.length !== anterior.procedimentosInternacao.length || medicacoes.length !== anterior.medicacoesInternacao.length)) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        if (procedimentos.length < anterior.procedimentosInternacao.length || medicacoes.length < anterior.medicacoesInternacao.length) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        for (let i = 0; i < anterior.procedimentosInternacao.length; i++) {
            const a = anterior.procedimentosInternacao[i], b = procedimentos[i];
            if (a.nome !== b.nome || a.agendadoPara !== b.agendadoPara || a.detalhes !== b.detalhes ||
                (a.concluidoEm !== null && !igual(a, b))) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
        }
        for (let i = 0; i < medicacoes.length; i++) {
            const a = anterior.medicacoesInternacao[i], b = medicacoes[i];
            if (!a) { if (!vet || b.administracoes.length) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." }); continue; }
            if (a.nome !== b.nome || a.dosagem !== b.dosagem || a.frequencia !== b.frequencia || a.detalhes !== b.detalhes ||
                b.administracoes.length < a.administracoes.length || !a.administracoes.every((v: any, j: number) => igual(v, b.administracoes[j]))) return res.status(403).json({ mensagem: "Você não tem permissão para alterar este prontuário." });
            for (const dose of b.administracoes.slice(a.administracoes.length)) dose.responsavel = autor;
        }
        for (const nota of notas.slice(anterior.notasInternacao.length)) nota.autor = autor;
        // Apenas campos do formulário; não permite alterar pet, profissional, status ou leito.
        const salvo = { observacoesTriagem: prontuario.observacoesTriagem, descricaoConsulta: prontuario.descricaoConsulta,
            procedimentosInternacao: procedimentos.map((p: any) => ({ nome: p.nome, detalhes: p.detalhes, agendadoPara: p.agendadoPara, concluidoEm: p.concluidoEm, detalhesConclusao: p.detalhesConclusao })),
            medicacoesInternacao: medicacoes.map((m: any) => ({ nome: m.nome, dosagem: m.dosagem, frequencia: m.frequencia, detalhes: m.detalhes,
                administracoes: m.administracoes.map((a: any) => ({ realizadaEm: a.realizadaEm, responsavel: a.responsavel, observacao: a.observacao })) })),
            notasInternacao: notas.map((n: any) => ({ texto: n.texto, autor: n.autor })) };
        const resultado = await colecao.updateOne({ ...filtro, ...(versao === 0 ? { $or: [{ versao: 0 }, { versao: { $exists: false } }] } : { versao }) },
            { $set: { prontuario: salvo }, $inc: { versao: 1 } });
        if (!resultado.modifiedCount) return res.status(409).json({ mensagem: "Prontuário atualizado ou internação encerrada. Recarregue a tela." });
        return res.json({ mensagem: "Prontuário salvo." });
    } catch { return res.status(500).json({ mensagem: "Erro ao salvar prontuário." }); }
});


router.post(
    "/",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const { petId, motivo, leito, observacoes } = req.body;

            // Verifica os campos obrigatórios
            if (
                typeof petId !== "string" || !petId.trim() ||
                typeof motivo !== "string" || !motivo.trim() ||
                typeof leito !== "string" || !leito.trim()
            ) {
                return res.status(400).json({
                    mensagem: "Informe o pet, o motivo e o leito."
                });
            }

            if (
                observacoes !== undefined &&
                typeof observacoes !== "string"
            ) {
                return res.status(400).json({
                    mensagem: "As observações devem ser um texto."
                });
            }

            const banco = obterBanco();
            const usuarioId = new ObjectId(res.locals.usuarioId);

            // Identifica o veterinário logado
            const veterinario = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("veterinarios").findOne({
                usuarioId,
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            // Aceita pets antigos com ID em texto
            // e pets novos com ObjectId
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            const pet = await banco.collection<{
                _id: string | ObjectId;
                ativo?: boolean;
            }>("pets").findOne({
                _id: { $in: idsPet },
                ativo: { $ne: false }
            });

            if (!pet) {
                return res.status(404).json({
                    mensagem: "Pet não encontrado."
                });
            }

            const internacoes = banco.collection("internacoes");

            // Impede que o pet tenha duas internações ativas
            const internacaoAtiva = await internacoes.findOne({
                petId: { $in: idsPet },
                status: "ativa"
            });

            if (internacaoAtiva) {
                return res.status(409).json({
                    mensagem: "Este pet já possui uma internação ativa."
                });
            }

            // Verifica se o leito já está ocupado
            const leitoOcupado = await internacoes.findOne({
                leito: leito.trim(),
                status: "ativa"
            });

            if (leitoOcupado) {
                return res.status(409).json({
                    mensagem: "Este leito já está ocupado."
                });
            }

            // Registra a internação
            const resultado = await internacoes.insertOne({
                petId: pet._id,
                veterinarioId: veterinario._id,
                enfermeiroId: null,
                dataEntrada: new Date(),
                dataAlta: null,
                motivo: motivo.trim(),
                status: "ativa",
                leito: leito.trim(),
                observacoes: observacoes?.trim() ?? ""
            });

            return res.status(201).json({
                mensagem: "Internação registrada com sucesso!",
                internacaoId: resultado.insertedId
            });

        } catch (erro) {
            console.error("Erro ao registrar internação:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar internação."
            });
        }
    }
);

router.patch(
    "/:id/alta",
    autenticar,
    permitirFuncoes("VETERINARIO"),
    async (req, res) => {
        try {
            const id = req.params.id;
            if (typeof id !== "string") {
                return res.status(400).json({
                    mensagem: "ID da internação inválido."
                });
            }

            const banco = obterBanco();

            // Identifica o veterinário logado
            const veterinario = await banco.collection<{
                _id: string;
                usuarioId: ObjectId;
                ativo: boolean;
            }>("veterinarios").findOne({
                usuarioId: new ObjectId(res.locals.usuarioId),
                ativo: true
            });

            if (!veterinario) {
                return res.status(403).json({
                    mensagem: "Veterinário não encontrado."
                });
            }

            // Aceita IDs antigos em texto e IDs novos do MongoDB
            const idsInternacao: (string | ObjectId)[] = [id];

            if (ObjectId.isValid(id)) {
                idsInternacao.push(new ObjectId(id));
            }

            const internacoes = banco.collection<{
                _id: string | ObjectId;
                veterinarioId: string;
                status: string;
                dataAlta?: Date | null;
            }>("internacoes");

            // A atualização só acontece se a internação estiver ativa
            // e pertencer ao veterinário responsável
            const resultado = await internacoes.updateOne(
                {
                    _id: { $in: idsInternacao },
                    veterinarioId: veterinario._id,
                    status: "ativa"
                },
                {
                    $set: {
                        status: "alta",
                        dataAlta: new Date()
                    }
                }
            );

            if (resultado.modifiedCount === 0) {
                return res.status(409).json({
                    mensagem:
                        "Internação não está ativa, não existe ou pertence a outro veterinário."
                });
            }

            const internacao = await banco.collection<{
                _id: string | ObjectId;
                petId: unknown;
            }>("internacoes").findOne({
                _id: { $in: idsInternacao }
            });

            if (internacao) {
                await notificarAlta(banco, {
                    petId: internacao.petId,
                    veterinarioUsuarioId: new ObjectId(res.locals.usuarioId),
                    referenciaId: id
                });
            }

            return res.status(200).json({
                mensagem: "Alta hospitalar registrada com sucesso!"
            });

        } catch (erro) {
            console.error("Erro ao registrar alta:", erro);

            return res.status(500).json({
                mensagem: "Erro ao registrar alta hospitalar."
            });
        }
    }
);

// Lista as internações de um pet
router.get(
    "/pet/:petId",
    autenticar,
    permitirFuncoes("VETERINARIO", "ENFERMEIRO"),
    async (req, res) => {
        try {
            const petId = req.params.petId;

            if (typeof petId !== "string" || !petId.trim()) {
                return res.status(400).json({
                    mensagem: "ID do pet inválido."
                });
            }

            if (!await profissional(res.locals.usuarioId, res.locals.usuarioTipo)) return res.sendStatus(403);
            const banco = obterBanco();

            // Aceita IDs antigos e ObjectIds do MongoDB
            const idsPet: (string | ObjectId)[] = [petId];

            if (ObjectId.isValid(petId)) {
                idsPet.push(new ObjectId(petId));
            }

            // Busca todas as internações do pet
            const internacoes = await banco
                .collection("internacoes")
                .find({
                    petId: { $in: idsPet }
                })
                .sort({ dataEntrada: -1 })
                .toArray();

            return res.status(200).json({
                mensagem: "Internações encontradas com sucesso!",
                internacoes
            });

        } catch (erro) {
            console.error("Erro ao consultar internações:", erro);

            return res.status(500).json({
                mensagem: "Erro ao consultar internações."
            });
        }
    }
);

return router;
}
export default criarRotasInternacoes();