// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: acesso autorizado aos dados e ID do atendimento.
import test, { type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { ObjectId, type Db, type Document } from 'mongodb';
import { criarLeituraProntuario } from '../src/consultas/prontuarioClinico.ts';

async function ambiente(t: TestContext, papel = 'VETERINARIO', ativo = true, atendimento: Document | null = null) {
    const chamadas: { colecao: string; filtro: Document; opcoes?: Document }[] = [];
    const banco = { collection(colecao: string) { return {
        async findOne(filtro: Document, opcoes?: Document) {
            chamadas.push({ colecao, filtro, ...(opcoes ? { opcoes } : {}) });
            if (colecao === 'consultas') return { _id: 'C1', veterinarioId: 'VET1' };
            if (['veterinarios', 'enfermeiros'].includes(colecao)) return ativo ? { _id: 'VET1' } : null;
            if (colecao === 'triagens') return { peso: 10, temperatura: 38, sintomas: 'Coceira' };
            if (colecao === 'atendimentos' && atendimento) {
                return Object.fromEntries(Object.entries(atendimento).filter(([campo]) => opcoes?.projection?.[campo] === 1));
            }
            return null;
        }
    }; } };
    const app = express();
    app.use('/consultas', criarLeituraProntuario(() => banco as unknown as Db, (_req, res, next) => {
        if (papel === '') return res.sendStatus(401);
        res.locals.usuarioTipo = papel;
        res.locals.usuarioId = '507f1f77bcf86cd799439011';
        next();
    }));
    const servidor = await new Promise<Server>(resolve => {
        const s = app.listen(0, '127.0.0.1', () => resolve(s));
    });
    t.after(() => new Promise<void>((resolve, reject) => servidor.close(e => e ? reject(e) : resolve())));
    const resposta = await fetch(`http://127.0.0.1:${(servidor.address() as AddressInfo).port}/consultas/C1/dados-clinicos`);
    return { resposta, chamadas };
}

test('Prontuário consulta o veterinário responsável antes de ler registros', async t => {
    const { resposta, chamadas } = await ambiente(t);
    assert.equal(resposta.status, 200);
    assert.deepEqual(await resposta.json(), { triagem: { peso: 10, temperatura: 38, sintomas: 'Coceira' }, atendimento: null });
    const profissional = chamadas.find(c => c.colecao === 'veterinarios')!;
    assert.deepEqual(profissional.filtro._id, { $in: ['VET1'] });
    assert.ok(profissional.filtro.usuarioId instanceof ObjectId);
    assert.equal(profissional.filtro.ativo, true);
    const triagem = chamadas.find(c => c.colecao === 'triagens')!;
    assert.deepEqual(triagem.filtro, { consultaId: 'C1' });
    assert.deepEqual(triagem.opcoes?.projection, { _id: 0, peso: 1, temperatura: 1, sintomas: 1, observacoes: 1 });
});
test('Prontuário exige enfermeiro ativo e recusa profissional sem vínculo', async t => {
    assert.equal((await ambiente(t, 'ENFERMEIRO')).resposta.status, 200);
    for (const papel of ['ENFERMEIRO', 'VETERINARIO']) {
        const { resposta, chamadas } = await ambiente(t, papel, false);
        assert.equal(resposta.status, 403);
        assert.equal(chamadas.some(c => c.colecao === 'triagens'), false);
    }
});
test('Tutor, secretária e visitante não acessam a nova rota clínica', async t => {
    for (const papel of ['USUARIO', 'SECRETARIA', '']) {
        const { resposta, chamadas } = await ambiente(t, papel);
        assert.equal(resposta.status, papel ? 403 : 401);
        assert.equal(chamadas.length, 0);
    }
});

test('Leitura retorna o ID do atendimento para retomar vínculos sem expor campos extras', async t => {
    const id = new ObjectId();
    const { resposta, chamadas } = await ambiente(t, 'VETERINARIO', true, {
        _id: id, anamnese: 'Teste', diagnostico: 'Teste', campoInterno: 'não retornar'
    });
    assert.equal(resposta.status, 200);
    const dados = await resposta.json() as { atendimento: Document };
    assert.deepEqual(dados.atendimento, { _id: String(id), anamnese: 'Teste', diagnostico: 'Teste' });
    const leitura = chamadas.find(c => c.colecao === 'atendimentos')!;
    assert.deepEqual(leitura.filtro, { consultaId: 'C1' });
    assert.equal(leitura.opcoes?.projection._id, 1);
});
