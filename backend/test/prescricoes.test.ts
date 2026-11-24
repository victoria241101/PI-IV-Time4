// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: vínculos de pet/atendimento/veterinário, permissões e reenvios.
import assert from 'node:assert/strict';
import test, { type TestContext } from 'node:test';
import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import express from 'express';
import { ObjectId, MongoServerError, type Db, type Document } from 'mongodb';
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/teste_sem_conexao';
process.env.JWT_SECRET = 'a'.repeat(64);
const { criarRotasPrescricoes } = await import('../src/routes/prescricoes.routes.ts');

const igual = (a: unknown, b: unknown) => a instanceof ObjectId && b instanceof ObjectId ? a.equals(b) : a === b;
const corresponde = (doc: Document, filtro: Document) => Object.entries(filtro).every(([k, v]) =>
    v?.$in ? v.$in.some((id: unknown) => igual(doc[k], id)) : v && typeof v === 'object' && '$ne' in v ? !igual(doc[k], v.$ne) : igual(doc[k], v));
async function ambiente(t: TestContext, legado = false) {
    const usuario = new ObjectId();
    const vet: Document = { _id: legado ? 'VET1' : new ObjectId(), usuarioId: usuario, ativo: true };
    const enf: Document = { _id: legado ? 'ENF1' : new ObjectId(), usuarioId: new ObjectId(), ativo: true };
    const pet: Document = { _id: legado ? 'P1' : new ObjectId(), ativo: true };
    const atendimento: Document = { _id: legado ? 'A1' : new ObjectId(), petId: pet._id, veterinarioId: vet._id };
    const registros: Document[] = [];
    let notificacoes = 0;
    const tabelas: Record<string, Document[]> = { veterinarios: [vet], enfermeiros: [enf], pets: [pet], atendimentos: [atendimento], prescricoes: registros };
    const db = { collection(nome: string) {
        const docs = tabelas[nome]; assert.ok(docs, `Coleção inesperada: ${nome}`);
        return {
            async findOne(filtro: Document) { return docs.find(d => corresponde(d, filtro)) ?? null; },
            async insertOne(doc: Document) {
                const _id = doc._id ?? new ObjectId();
                if (docs.some(d => igual(d._id, _id))) throw new MongoServerError({ code: 11000, message: 'Duplicado' });
                docs.push({ ...doc, _id }); return { insertedId: _id };
            },
            find(filtro: Document) { return { sort() { return { async toArray() { return docs.filter(d => corresponde(d, filtro)); } }; } }; }
        };
    }};
    const app = express(); app.use(express.json());
    app.use('/prescricoes', criarRotasPrescricoes({ obterBanco: () => db as unknown as Db,
        autenticar(req, res, next) {
            if (!req.headers['x-usuario']) return res.sendStatus(401);
            res.locals.usuarioId = req.headers['x-usuario']; res.locals.usuarioTipo = req.headers['x-perfil']; next();
        },
        async notificarDosePrescrita() { notificacoes++; }
    }));
    const servidor = await new Promise<Server>(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    t.after(() => new Promise<void>((resolve, reject) => servidor.close(e => e ? reject(e) : resolve())));
    const dados = { petId: String(pet._id), atendimentoId: String(atendimento._id), medicamento: 'Medicamento de teste', dose: 'Dose prescrita', frequencia: 'Frequência prescrita', duracao: 'Duração prescrita', orientacoes: 'Orientação', solicitacaoId: String(new ObjectId()) };
    return { vet, enf, pet, atendimento, dados, registros, notificacoes: () => notificacoes,
        async pedir(metodo: string, corpo?: Document, perfil = 'VETERINARIO', id: unknown = usuario) {
            const headers: Record<string, string> = { 'content-type': 'application/json', 'x-perfil': perfil };
            if (id) headers['x-usuario'] = String(id);
            const r = await fetch(`http://127.0.0.1:${(servidor.address() as AddressInfo).port}/prescricoes${metodo === 'GET' ? '/pet/' + pet._id : ''}`, { method: metodo, headers, ...(corpo ? { body: JSON.stringify(corpo) } : {}) });
            const texto = await r.text(); return { status: r.status, texto };
        }
    };
}
for (const legado of [false, true]) {
    test(`Prescrição usa os vínculos ${legado ? 'legados' : 'ObjectId'} e pode ser lida pela enfermagem`, async t => {
        const a = await ambiente(t, legado);
        assert.equal((await a.pedir('POST', a.dados)).status, 201);
        assert.ok(igual(a.registros[0]!.petId, a.pet._id));
        assert.ok(igual(a.registros[0]!.atendimentoId, a.atendimento._id));
        assert.ok(igual(a.registros[0]!.veterinarioId, a.vet._id));
        const leitura = await a.pedir('GET', undefined, 'ENFERMEIRO', a.enf.usuarioId);
        assert.equal(leitura.status, 200);
        assert.equal(JSON.parse(leitura.texto).prescricoes.length, 1);
        assert.equal(a.notificacoes(), 1);
    });
}
test('Reenvios simultâneos e sequenciais geram uma prescrição e uma notificação', async t => {
    const a = await ambiente(t);
    const respostas = await Promise.all([a.pedir('POST', a.dados), a.pedir('POST', a.dados)]);
    assert.deepEqual(respostas.map(r => r.status).sort(), [200, 201]);
    assert.equal((await a.pedir('POST', a.dados)).status, 200);
    assert.equal(a.registros.length, 1); assert.equal(a.notificacoes(), 1);
    assert.equal((await a.pedir('POST', { ...a.dados, dose: 'outra dose' })).status, 409);
    assert.equal(a.registros[0]!.dose, a.dados.dose);
});
test('Cliente anterior pode prescrever sem chave de solicitação', async t => {
    const a = await ambiente(t); const { solicitacaoId, ...dados } = a.dados;
    assert.equal((await a.pedir('POST', dados)).status, 201);
});
test('Pet, atendimento e veterinário precisam corresponder; nenhum registro é criado na recusa', async t => {
    const a = await ambiente(t);
    assert.equal((await a.pedir('POST', { ...a.dados, petId: 'outro-pet' })).status, 404);
    assert.equal((await a.pedir('POST', { ...a.dados, atendimentoId: 'outro-atendimento' })).status, 404);
    a.atendimento.veterinarioId = 'outro-vet';
    assert.equal((await a.pedir('POST', a.dados)).status, 404);
    assert.equal(a.registros.length, 0);
});
test('Somente veterinário cadastra; enfermeiro ativo pode ler; demais perfis são recusados', async t => {
    const a = await ambiente(t);
    assert.equal((await a.pedir('POST', a.dados, 'VETERINARIO', null)).status, 401);
    for (const perfil of ['ENFERMEIRO', 'SECRETARIA', 'USUARIO']) assert.equal((await a.pedir('POST', a.dados, perfil, a.enf.usuarioId)).status, 403);
    for (const perfil of ['SECRETARIA', 'USUARIO']) assert.equal((await a.pedir('GET', undefined, perfil)).status, 403);
    a.enf.ativo = false;
    assert.equal((await a.pedir('GET', undefined, 'ENFERMEIRO', a.enf.usuarioId)).status, 403);
    a.vet.ativo = false;
    assert.equal((await a.pedir('POST', a.dados)).status, 403);
    assert.equal(a.registros.length, 0);
});
test('Campos obrigatórios e chave inválida são recusados antes da gravação', async t => {
    const a = await ambiente(t);
    for (const campo of ['medicamento', 'dose', 'frequencia', 'duracao', 'solicitacaoId']) {
        assert.equal((await a.pedir('POST', { ...a.dados, [campo]: '' })).status, 400);
    }
    assert.equal(a.registros.length, 0);
});
