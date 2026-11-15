import { Router, type RequestHandler } from 'express';
import { ObjectId, type Db } from 'mongodb';
import { permitirFuncoes } from '../middlewares/permissoes.middleware.js';
import { obterFiltroConsulta } from './identificadoresConsultas.js';

// Mesmas regras de acesso do PDF: veterinário responsável ou enfermeiro ativo.
export function criarLeituraProntuario(obterBanco: () => Db, autenticar: RequestHandler) {
    const router = Router();
    router.get('/:id/dados-clinicos', autenticar, permitirFuncoes('ENFERMEIRO', 'VETERINARIO'), async (req, res) => {
        try {
            const usuarioId = String(res.locals.usuarioId ?? '');
            if (!ObjectId.isValid(usuarioId)) return res.status(401).json({ mensagem: 'Sessão inválida.' });
            const banco = obterBanco();
            const consulta = await banco.collection('consultas').findOne(obterFiltroConsulta(String(req.params.id)));
            if (!consulta) return res.status(404).json({ mensagem: 'Consulta não encontrada.' });
            const veterinario = res.locals.usuarioTipo === 'VETERINARIO';
            const profissional = await banco.collection(veterinario ? 'veterinarios' : 'enfermeiros').findOne({
                ...(veterinario ? obterFiltroConsulta(String(consulta.veterinarioId)) : {}),
                usuarioId: new ObjectId(usuarioId), ativo: true
            });
            if (!profissional) return res.status(403).json({ mensagem: 'Acesso negado ao prontuário.' });
            const filtro = { consultaId: String(consulta._id) };
            const [triagem, atendimento] = await Promise.all([
                banco.collection('triagens').findOne(filtro, { projection: {
                    _id: 0, peso: 1, temperatura: 1, sintomas: 1, observacoes: 1
                } }),
                banco.collection('atendimentos').findOne(filtro, { projection: {
                    _id: 0, anamnese: 1, exameFisico: 1, diagnostico: 1,
                    prognostico: 1, tratamento: 1, observacoes: 1
                } })
            ]);
            return res.json({ triagem, atendimento });
        } catch {
            return res.status(503).json({ mensagem: 'Não foi possível carregar o prontuário.' });
        }
    });
    return router;
}
