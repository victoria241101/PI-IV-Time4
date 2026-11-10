import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { ObjectId } from 'mongodb';
import { criarRotasLeituraConsultas } from '../src/consultas/leitura.routes.ts';
import { obterFiltroConsulta } from '../src/consultas/identificadoresConsultas.ts';

const usuarioId = '507f1f77bcf86cd799439011';
async function chamar(t, { papel = 'SECRETARIA', autenticado = true, query = '?data=2026-11-09', registros = [], profissional = { _id: 'VET001' }, falhar = false } = {}) {
    const chamadas = {};
    const banco = { collection(nome) {
        chamadas.colecao = nome;
        return {
            async findOne(filtro) { chamadas.profissional = filtro; return profissional; },
            find(filtro, opcoes) {
                if (falhar) throw new Error('Banco indisponível');
                chamadas.filtro = filtro; chamadas.opcoes = opcoes;
                return {
                    sort(ordem) { chamadas.ordem = ordem; return this; },
                    skip(n) { chamadas.pular = n; return this; },
                    limit(n) { chamadas.limite = n; return this; },
                    async toArray() { return registros; }
                };
            }
        };
    }};
    const app = express();
    app.use('/consultas', criarRotasLeituraConsultas({ obterBanco: () => banco, autenticar(req, res, next) {
        if (!autenticado) return res.sendStatus(401);
        res.locals.usuarioId = usuarioId; res.locals.usuarioTipo = papel; next();
    }}));
    const servidor = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    t.after(() => new Promise(resolve => servidor.close(resolve)));
    const resposta = await fetch(`http://127.0.0.1:${servidor.address().port}/consultas${query}`);
    const corpo = resposta.headers.get('content-type')?.includes('json') ? await resposta.json() : null;
    return { status: resposta.status, corpo, chamadas };
}

test('identificador aceita texto legado e as duas representações MongoDB', () => {
    assert.deepEqual(obterFiltroConsulta('C002'), { _id: { $in: ['C002'] } });
    const ids = obterFiltroConsulta(usuarioId)._id.$in;
    assert.equal(ids[0], usuarioId);
    assert.ok(ids[1] instanceof ObjectId);
    assert.equal(ids[1].toHexString(), usuarioId);
});
test('secretária consulta somente o dia solicitado, com campos limitados', async t => {
    const { status, corpo, chamadas } = await chamar(t, { registros: [{ _id: new ObjectId(usuarioId), petId: 'P1', status: 'agendada', segredo: 'não enviar' }] });
    assert.equal(status, 200);
    assert.deepEqual(chamadas.filtro, { dataHora: { $gte: '2026-11-09T00:00:00', $lte: '2026-11-09T23:59:59.999' } });
    assert.equal(corpo.consultas[0].id, usuarioId);
    assert.equal('segredo' in corpo.consultas[0], false);
    assert.equal(chamadas.opcoes.projection.status, 1);
    assert.deepEqual(chamadas.ordem, { dataHora: 1, _id: 1 });
});
test('enfermagem pede somente consultas da fila de triagem', async t => {
    const r = await chamar(t, { papel: 'ENFERMEIRO' });
    assert.equal(r.status, 200);
    assert.deepEqual(r.chamadas.filtro.status, { $in: ['chegada_confirmada', 'em_triagem'] });
});
test('veterinário consulta somente sua agenda vinculada à conta', async t => {
    const r = await chamar(t, { papel: 'VETERINARIO' });
    assert.equal(r.status, 200);
    assert.deepEqual(r.chamadas.filtro.veterinarioId, { $in: ['VET001'] });
    assert.equal(r.chamadas.profissional.usuarioId.toHexString(), usuarioId);
    assert.equal(r.chamadas.profissional.ativo, true);
});
test('veterinário sem cadastro ativo não consulta agenda', async t => {
    assert.equal((await chamar(t, { papel: 'VETERINARIO', profissional: null })).status, 403);
});
test('outros perfis e visitantes são bloqueados antes do banco', async t => {
    for (const opcoes of [{ papel: 'USUARIO' }, { autenticado: false }]) {
        const r = await chamar(t, opcoes);
        assert.equal(r.status, opcoes.autenticado === false ? 401 : 403);
        assert.deepEqual(r.chamadas, {});
    }
});
test('datas e páginas inválidas são recusadas antes do banco', async t => {
    for (const query of ['', '?data=2026-02-30', '?data=x', '?data=2026-11-09&pagina=0', '?data=2026-11-09&pagina=1.5', '?data=2026-11-09&data=2026-11-10']) {
        const r = await chamar(t, { query });
        assert.equal(r.status, 400, query); assert.deepEqual(r.chamadas, {});
    }
});
test('pagina resultados em grupos de cinquenta e informa se há mais', async t => {
    const r = await chamar(t, { query: '?data=2026-11-09&pagina=2', registros: Array.from({ length: 51 }, (_, i) => ({ _id: `C${i}` })) });
    assert.equal(r.chamadas.pular, 50); assert.equal(r.chamadas.limite, 51);
    assert.equal(r.corpo.consultas.length, 50); assert.equal(r.corpo.temMais, true);
});
test('agenda vazia e falha de banco são respostas diferentes', async t => {
    const vazio = await chamar(t);
    assert.deepEqual(vazio.corpo.consultas, []); assert.equal(vazio.corpo.temMais, false);
    assert.equal((await chamar(t, { falhar: true })).status, 503);
});

test('fila é compartilhada, mas continuar só é permitido para o responsável', async t => {
    const registros = [
        { _id: 'C1', status: 'chegada_confirmada' },
        { _id: 'C2', status: 'em_triagem', enfermeiroUsuarioId: usuarioId },
        { _id: 'C3', status: 'em_triagem', enfermeiroUsuarioId: 'outro-enfermeiro' },
        { _id: 'C4', status: 'em_triagem' }
    ];
    const r = await chamar(t, { papel: 'ENFERMEIRO', registros });
    assert.equal(r.corpo.consultas.length, 4);
    assert.equal(r.chamadas.filtro.enfermeiroUsuarioId, undefined);
    assert.deepEqual(r.corpo.consultas.map(c => [c.podeIniciarTriagem, c.podeContinuarTriagem]), [
        [true, false], [false, true], [false, false], [false, false]
    ]);
    const secretaria = await chamar(t, { registros });
    assert.ok(secretaria.corpo.consultas.every(c => !c.podeIniciarTriagem && !c.podeContinuarTriagem));
});
