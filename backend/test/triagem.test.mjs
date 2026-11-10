import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { ObjectId } from 'mongodb';
import { criarRotasTriagem } from '../src/consultas/triagem.routes.ts';

const ana = '507f1f77bcf86cd799439011';
const bia = '507f1f77bcf86cd799439012';
const clara = '507f1f77bcf86cd799439013';
const dados = { peso: 5, temperatura: 38, sintomas: 'Sem apetite' };
// Este substituto reproduz apenas os filtros usados nestas ações, não o MongoDB.
function corresponde(doc, filtro) {
    return doc != null && Object.entries(filtro).every(([campo, valor]) => {
        const igual = esperado => esperado instanceof ObjectId
            ? doc[campo] instanceof ObjectId && esperado.equals(doc[campo])
            : doc[campo] === esperado;
        return valor?.$in ? valor.$in.some(igual) : igual(valor);
    });
}
async function ambiente(t, inicial = {}) {
    const consulta = { _id: 'C001', petId: 'P001', status: 'chegada_confirmada', ...inicial };
    const triagens = [];
    const notificacoes = [];
    const banco = { collection(nome) {
        return nome === 'consultas' ? {
            async findOne(filtro) { return corresponde(consulta, filtro) ? { ...consulta } : null; },
            async updateOne(filtro, alteracao) {
                if (!corresponde(consulta, filtro)) return { modifiedCount: 0 };
                Object.assign(consulta, alteracao.$set);
                return { modifiedCount: 1 };
            }
        } : {
            async findOne(filtro) { return triagens.find(doc => corresponde(doc, filtro)) ?? null; },
            async insertOne(doc) { const _id = new ObjectId(); triagens.push({ ...doc, _id }); return { insertedId: _id }; }
        };
    }};
    const app = express(); app.use(express.json());
    app.use('/consultas', criarRotasTriagem({ obterBanco: () => banco,
        autenticar(req, res, next) {
            if (!req.headers['x-usuario-teste']) return res.sendStatus(401);
            res.locals.usuarioId = req.headers['x-usuario-teste'];
            res.locals.usuarioTipo = req.headers['x-papel-teste'] ?? 'ENFERMEIRO'; next();
        },
        async notificarTriagemConcluida(...args) { notificacoes.push(args); }
    }));
    const servidor = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    t.after(() => new Promise(resolve => servidor.close(resolve)));
    return { consulta, triagens, notificacoes,
        async pedir(usuario, acao, corpo, papel = 'ENFERMEIRO') {
            const headers = { 'content-type': 'application/json', 'x-papel-teste': papel };
            if (usuario) headers['x-usuario-teste'] = usuario;
            const r = await fetch(`http://127.0.0.1:${servidor.address().port}/consultas/${consulta._id}/${acao}`, {
                method: acao === 'triagem' ? 'POST' : 'PATCH', headers,
                ...(corpo === undefined ? {} : { body: JSON.stringify(corpo) })
            });
            await r.text(); return r.status;
        }
    };
}
test('três enfermeiros tentam iniciar: apenas um assume a consulta', async t => {
    const a = await ambiente(t);
    const respostas = await Promise.all([ana, bia, clara].map(id => a.pedir(id, 'iniciar-triagem')));
    assert.equal(respostas.filter(s => s === 200).length, 1);
    assert.equal(respostas.filter(s => s === 409).length, 2);
    assert.equal(a.consulta.enfermeiroUsuarioId, [ana, bia, clara][respostas.indexOf(200)]);
    assert.equal(a.consulta.status, 'em_triagem');
    assert.ok(a.consulta.triagemIniciadaEm instanceof Date);
});
test('só a responsável registra e conclui; a sessão prevalece sobre o corpo do pedido', async t => {
    const a = await ambiente(t);
    assert.equal(await a.pedir(ana, 'iniciar-triagem', { enfermeiroUsuarioId: bia }), 200);
    assert.equal(a.consulta.enfermeiroUsuarioId, ana);
    assert.equal(await a.pedir(bia, 'triagem', { ...dados, enfermeiroUsuarioId: ana }), 409);
    assert.equal(a.triagens.length, 0);
    assert.equal(await a.pedir(ana, 'finalizar-triagem'), 409);
    assert.equal(await a.pedir(ana, 'triagem', dados), 201);
    assert.equal(await a.pedir(ana, 'triagem', dados), 409);
    assert.equal(await a.pedir(bia, 'finalizar-triagem'), 409);
    assert.equal(a.consulta.status, 'em_triagem');
    assert.equal(a.notificacoes.length, 0);
    assert.equal(await a.pedir(ana, 'finalizar-triagem'), 200);
    assert.equal(a.consulta.status, 'aguardando_veterinario');
    assert.equal(a.notificacoes.length, 1);
    assert.equal(await a.pedir(ana, 'finalizar-triagem'), 409);
    assert.equal(a.notificacoes.length, 1);
});
test('consulta não liberada, visitante e outros perfis não iniciam triagem', async t => {
    const a = await ambiente(t, { status: 'agendada' });
    assert.equal(await a.pedir(null, 'iniciar-triagem'), 401);
    assert.equal(await a.pedir(ana, 'iniciar-triagem', undefined, 'SECRETARIA'), 403);
    assert.equal(await a.pedir(ana, 'iniciar-triagem'), 409);
    assert.equal(a.consulta.enfermeiroUsuarioId, undefined);
});
test('registros antigos em triagem sem responsável não são apropriados por outro usuário', async t => {
    const a = await ambiente(t, { status: 'em_triagem' });
    assert.equal(await a.pedir(ana, 'iniciar-triagem'), 409);
    assert.equal(await a.pedir(ana, 'triagem', dados), 409);
    assert.equal(await a.pedir(ana, 'finalizar-triagem'), 409);
});
test('dados inválidos não são salvos e não mudam a responsabilidade', async t => {
    const a = await ambiente(t);
    await a.pedir(ana, 'iniciar-triagem');
    assert.equal(await a.pedir(ana, 'triagem'), 400);
    assert.equal(await a.pedir(ana, 'triagem', { ...dados, peso: -1 }), 400);
    assert.equal(a.triagens.length, 0);
    assert.equal(a.consulta.enfermeiroUsuarioId, ana);
});
