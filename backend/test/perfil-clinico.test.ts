// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: telefone/CPF do profissional correto e resposta de perfil do tutor.
import test from 'node:test';
import assert from 'node:assert/strict';
import type { Request, Response, NextFunction } from 'express';
import type { Db, Document } from 'mongodb';
import { ObjectId } from 'mongodb';

// Toda operação de banco deste teste usa apenas objetos em memória.
process.env.MONGODB_URI = 'mongodb://127.0.0.1:1/teste';
const { obterCliente, conectarBanco } = await import('../src/database.ts');
const { default: router } = await import('../src/routes/usuarios.routes.ts');

test('perfil clínico lê o vínculo do próprio usuário e preserva resposta do tutor', async (t) => {
    const id = new ObjectId();
    let tipo = 'ENFERMEIRO';
    let profissional: Document | null = { telefone: '11912345678', cpf: '12345678900' };
    const consultas: string[] = [];
    const banco = {
        collection(nome: string) {
            return {
                async createIndex() { return ''; },
                async findOne(filtro: Document, opcoes?: Document) {
                    consultas.push(nome);
                    if (nome === 'usuarios') return { _id: id, nome: 'Profissional', email: 'perfil@example.test', tipo };
                    if (nome === 'tutores') return tipo === 'USUARIO' ? { usuarioId: id } : null;
                    assert.deepEqual(filtro.usuarioId.$in, [id, id.toString()]);
                    assert.equal(filtro.ativo, true);
                    assert.deepEqual(opcoes?.projection, { telefone: 1, cpf: 1 });
                    return profissional;
                }
            };
        }
    };
    const cliente = obterCliente();
    t.mock.method(cliente, 'connect', async () => cliente);
    t.mock.method(cliente, 'db', () => banco as unknown as Db);
    t.mock.method(console, 'log', () => {});
    await conectarBanco();
    const rota = router.stack.find((layer) => layer.route?.path === '/perfil' && layer.route.methods.get)!.route;
    const handler = rota.stack[rota.stack.length - 1].handle;
    let corpo: Document = {};
    const res = {
        locals: { usuarioId: id.toString() },
        status(codigo: number) { assert.equal(codigo, 200); return this; },
        json(dados: Document) { corpo = dados; return this; }
    };
    for (const [papel, colecao] of [['SECRETARIA', 'secretaria'], ['ENFERMEIRO', 'enfermeiros'], ['VETERINARIO', 'veterinarios']]) {
        tipo = papel!;
        consultas.length = 0;
        await handler({} as Request, res as unknown as Response, (() => {}) as NextFunction);
        assert.equal(corpo.usuario.telefone, profissional!.telefone);
        assert.equal(corpo.usuario.cpf, profissional!.cpf);
        assert.ok(consultas.includes(colecao!));
    }
    profissional = null;
    await handler({} as Request, res as unknown as Response, (() => {}) as NextFunction);
    assert.equal(corpo.usuario.telefone, null);
    assert.equal(corpo.usuario.cpf, null);
    tipo = 'USUARIO';
    consultas.length = 0;
    await handler({} as Request, res as unknown as Response, (() => {}) as NextFunction);
    assert.equal(corpo.ehTutor, true);
    assert.equal('telefone' in corpo.usuario, false);
    assert.deepEqual(consultas, ['usuarios', 'tutores']);
});
