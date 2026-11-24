// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: formatos de IDs, enfermeiro responsável pela tarefa e permissões de tarefas.
import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import test, { type TestContext } from 'node:test';
import express from 'express';
import { ObjectId, type Db, type Document } from 'mongodb';

// Configuração fictícia: não conecta ao MongoDB nem usa credenciais da equipe.
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/teste_sem_conexao';
process.env.JWT_SECRET = 'a'.repeat(64);
const { criarRotasTarefasClinicas } = await import('../src/routes/tarefasClinicas.routes.ts');

// Simula somente os filtros usados nestas rotas, respeitando os tipos do MongoDB.
function igual(a: unknown, b: unknown): boolean {
    return a instanceof ObjectId && b instanceof ObjectId ? a.equals(b) : a === b;
}
function corresponde(doc: Document, filtro: Document): boolean {
    return Object.entries(filtro).every(([campo, valor]) => {
        if (valor?.$in) return valor.$in.some((v: unknown) => igual(doc[campo], v));
        if (valor && typeof valor === 'object' && '$ne' in valor) return !igual(doc[campo], valor.$ne);
        return igual(doc[campo], valor);
    });
}
function copiar(doc: Document): Document {
    return Object.fromEntries(Object.entries(doc).map(([k, v]) =>
        [k, v instanceof ObjectId ? new ObjectId(v.toHexString()) : v]));
}
async function ambiente(t: TestContext, legado = false) {
    const veterinario: Document = {
        _id: legado ? 'VET001' : new ObjectId(),
        usuarioId: legado ? 'V001' : new ObjectId(), ativo: true
    };
    const enfermeiro: Document = {
        _id: legado ? 'ENF001' : new ObjectId(),
        usuarioId: legado ? 'E001' : new ObjectId(), ativo: true
    };
    const outro: Document = {
        _id: legado ? 'ENF002' : new ObjectId(), usuarioId: new ObjectId(), ativo: true
    };
    const pet: Document = { _id: legado ? 'P001' : new ObjectId(), nome: 'Pet Teste', ativo: true };
    const tarefas: Document[] = [];
    const notificacoes: unknown[][] = [];
    const tabelas: Record<string, Document[]> = {
        veterinarios: [veterinario], enfermeiros: [enfermeiro, outro], pets: [pet], tarefasClinicas: tarefas
    };
    const banco = { collection(nome: string) {
        const docs = tabelas[nome];
        assert.ok(docs, `Coleção inesperada: ${nome}`);
        return {
            async findOne(filtro: Document) {
                const doc = docs.find(d => corresponde(d, filtro));
                // Leituras distintas produzem instâncias distintas de ObjectId.
                return doc ? copiar(doc) : null;
            },
            async insertOne(doc: Document) {
                const _id = new ObjectId(); docs.push({ ...doc, _id }); return { insertedId: _id };
            },
            async updateOne(filtro: Document, alteracao: Document) {
                const doc = docs.find(d => corresponde(d, filtro));
                if (!doc) return { modifiedCount: 0 };
                Object.assign(doc, alteracao.$set); return { modifiedCount: 1 };
            },
            find(filtro: Document) {
                return { sort() { return { async toArray() {
                    return docs.filter(d => corresponde(d, filtro)).map(copiar);
                } }; } };
            }
        };
    } };
    const app = express(); app.use(express.json());
    app.use('/tarefas-clinicas', criarRotasTarefasClinicas({
        obterBanco: () => banco as unknown as Db,
        autenticar(req, res, next) {
            if (!req.headers['x-usuario-teste']) return res.sendStatus(401);
            res.locals.usuarioId = req.headers['x-usuario-teste'];
            res.locals.usuarioTipo = req.headers['x-perfil-teste']; next();
        },
        async notificarTarefaClinica(...args) { notificacoes.push(args); }
    }));
    const servidor = await new Promise<Server>(resolve => {
        const s = app.listen(0, '127.0.0.1', () => resolve(s));
    });
    t.after(() => new Promise<void>((resolve, reject) => servidor.close(e => e ? reject(e) : resolve())));
    const corpo = {
        petId: String(pet._id), enfermeiroId: String(enfermeiro._id),
        descricao: 'Verificar temperatura', prazo: '2026-12-01T12:00:00Z'
    };
    return { veterinario, enfermeiro, outro, pet, tarefas, notificacoes, corpo,
        async pedir(metodo: string, caminho = '', perfil = 'VETERINARIO', usuario: unknown = veterinario.usuarioId, dados?: Document) {
            const headers: Record<string, string> = { 'content-type': 'application/json', 'x-perfil-teste': perfil };
            if (usuario != null) headers['x-usuario-teste'] = String(usuario);
            const resposta = await fetch(`http://127.0.0.1:${(servidor.address() as AddressInfo).port}/tarefas-clinicas${caminho}`, {
                method: metodo, headers, ...(dados === undefined ? {} : { body: JSON.stringify(dados) })
            });
            const texto = await resposta.text();
            return { status: resposta.status, texto };
        }
    };
}

for (const legado of [false, true]) {
    test(`cria, lista e conclui tarefa com IDs ${legado ? 'antigos em texto' : 'ObjectId novos'}`, async t => {
        const a = await ambiente(t, legado);
        assert.equal((await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId, a.corpo)).status, 201);
        assert.equal(a.tarefas.length, 1);
        const tarefa = a.tarefas[0]!;
        assert.ok(igual(tarefa.enfermeiroId, a.enfermeiro._id));
        assert.ok(igual(tarefa.veterinarioId, a.veterinario._id));
        assert.ok(igual(tarefa.petId, a.pet._id));
        assert.equal(a.notificacoes.length, 1);
        const lista = await a.pedir('GET', `/pet/${a.pet._id}`, 'ENFERMEIRO', a.enfermeiro.usuarioId);
        assert.equal(lista.status, 200);
        assert.equal(JSON.parse(lista.texto).quantidade, 1);
        const caminho = `/${tarefa._id}/concluir`;
        assert.equal((await a.pedir('PATCH', caminho, 'ENFERMEIRO', a.enfermeiro.usuarioId, { observacoesConclusao: ' Feito ' })).status, 200);
        assert.equal(tarefa.status, 'concluida');
        assert.equal(tarefa.observacoesConclusao, 'Feito');
        assert.ok(tarefa.dataConclusao instanceof Date);
        assert.equal((await a.pedir('PATCH', caminho, 'ENFERMEIRO', a.enfermeiro.usuarioId, {})).status, 409);
    });
}

test('outro enfermeiro não conclui tarefa nem assume vínculo pelo corpo do pedido', async t => {
    const a = await ambiente(t);
    await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId, a.corpo);
    const tarefa = a.tarefas[0]!;
    assert.equal((await a.pedir('PATCH', `/${tarefa._id}/concluir`, 'ENFERMEIRO', a.outro.usuarioId,
        { enfermeiroId: String(a.enfermeiro._id) })).status, 403);
    assert.equal(tarefa.status, 'pendente');
});

test('mantém permissões: visitante, secretária e enfermeiro não criam tarefas', async t => {
    const a = await ambiente(t);
    assert.equal((await a.pedir('POST', '', 'VETERINARIO', null, a.corpo)).status, 401);
    for (const perfil of ['SECRETARIA', 'ENFERMEIRO', 'USUARIO']) {
        assert.equal((await a.pedir('POST', '', perfil, a.enfermeiro.usuarioId, a.corpo)).status, 403);
        assert.equal((await a.pedir('PATCH', `/${new ObjectId()}/concluir`, perfil === 'ENFERMEIRO' ? 'VETERINARIO' : perfil,
            a.veterinario.usuarioId, {})).status, 403);
    }
    assert.equal(a.tarefas.length, 0);
    assert.equal(a.notificacoes.length, 0);
});

test('não cria para enfermeiro inexistente ou inativo e rejeita veterinário inativo', async t => {
    const a = await ambiente(t);
    for (const id of ['ENF_INEXISTENTE', String(new ObjectId())]) {
        assert.equal((await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId,
            { ...a.corpo, enfermeiroId: id })).status, 404);
    }
    a.enfermeiro.ativo = false;
    assert.equal((await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId, a.corpo)).status, 404);
    a.enfermeiro.ativo = true; a.veterinario.ativo = false;
    assert.equal((await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId, a.corpo)).status, 403);
    assert.equal(a.tarefas.length, 0);
    assert.equal(a.notificacoes.length, 0);
});

test('campos e prazo inválidos não geram gravação', async t => {
    const a = await ambiente(t);
    for (const dados of [{ ...a.corpo, prazo: 'invalido' }, { ...a.corpo, enfermeiroId: '' }]) {
        assert.equal((await a.pedir('POST', '', 'VETERINARIO', a.veterinario.usuarioId, dados)).status, 400);
    }
    assert.equal((await a.pedir('PATCH', '/invalido/concluir', 'ENFERMEIRO', a.enfermeiro.usuarioId, {})).status, 400);
    assert.equal(a.tarefas.length, 0);
});
