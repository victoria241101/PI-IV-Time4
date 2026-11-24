// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: internações, prontuário compartilhado, autoria de notas/doses, versão, permissões e alta.
import assert from 'node:assert/strict';
import test, { type TestContext } from 'node:test';
import express from 'express';
import type { AddressInfo } from 'node:net';
import type { Server } from 'node:http';
import { ObjectId, type Db, type Document } from 'mongodb';
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/sem_conexao';
process.env.JWT_SECRET = 'a'.repeat(64);
const { criarRotasInternacoes } = await import('../src/routes/internacoes.routes.ts');
const igual = (a: any, b: any): boolean => a instanceof ObjectId && b instanceof ObjectId ? a.equals(b) : a === b;
function corresponde(d: Document, f: Document): boolean {
    return Object.entries(f).every(([k,v]) => k === '$or' ? v.some((e: Document) => corresponde(d,e)) :
        v?.$in ? v.$in.some((x: unknown) => igual(d[k],x)) : v && '$ne' in Object(v) ? !igual(d[k],v.$ne) :
        v && '$exists' in Object(v) ? (d[k] !== undefined) === v.$exists : igual(d[k],v));
}
async function ambiente(t: TestContext) {
    const vet = { _id: 'VET1', usuarioId: new ObjectId(), ativo: true, nome: 'Veterinário' };
    const enf = { _id: new ObjectId(), usuarioId: new ObjectId(), ativo: true, nome: 'Enfermeira' };
    const outro = { _id: new ObjectId(), usuarioId: new ObjectId(), ativo: true, nome: 'Outro veterinário' };
    const internacoes: Document[]=[];
    const tabelas: Record<string,Document[]> = { veterinarios:[vet,outro], enfermeiros:[enf], pets:[{_id:'P1',tutorId:'T1',nome:'Pet do teste',ativo:true}], tutores:[{_id:'T1',nome:'Tutor'}], internacoes };
    const banco = { collection(nome: string) { const docs=tabelas[nome]!; return {
        async findOne(f: Document) {return docs.find(d=>corresponde(d,f))??null;},
        find(f: Document) {return {sort(){return {async toArray(){return docs.filter(d=>corresponde(d,f));}};}};},
        async insertOne(d: Document){const id=new ObjectId();docs.push({...d,_id:id});return {insertedId:id};},
        async updateOne(f: Document,u: Document){const d=docs.find(d=>corresponde(d,f));if(!d)return {modifiedCount:0};Object.assign(d,u.$set);for(const [k,v] of Object.entries(u.$inc??{}))d[k]=(d[k]??0)+Number(v);return {modifiedCount:1};}
    };}};
    const app=express();app.use(express.json());app.use('/internacoes',criarRotasInternacoes({
        obterBanco:()=>banco as unknown as Db,
        async autenticar(req,res,next){if(!req.headers['x-user'])return res.sendStatus(401);res.locals.usuarioId=req.headers['x-user'];res.locals.usuarioTipo=req.headers['x-role'];next();},
        notificarAlta:async()=>{},
    }));
    const server=await new Promise<Server>(resolve=>{const s=app.listen(0,'127.0.0.1',()=>resolve(s));});
    t.after(()=>new Promise<void>((resolve,reject)=>server.close(e=>e?reject(e):resolve())));
    async function pedir(path='', method='GET', body?:unknown, role='VETERINARIO', user:unknown=vet.usuarioId) {
        const headers:Record<string,string>={'content-type':'application/json','x-role':role};if(user)headers['x-user']=String(user);
        const r=await fetch(`http://127.0.0.1:${(server.address() as AddressInfo).port}/internacoes${path}`,{method,headers,...(body?{body:JSON.stringify(body)}:{})});
        const raw=await r.text();let dados:any;try{dados=JSON.parse(raw);}catch{dados=raw;}return {status:r.status,dados};
    }
    const criar=()=>pedir('','POST',{petId:'P1',motivo:'Observação clínica',leito:'L1'});
    const vazio=()=>({observacoesTriagem:'',descricaoConsulta:'',procedimentosInternacao:[],medicacoesInternacao:[],notasInternacao:[]}) as any;
    return {vet,enf,outro,internacoes,pedir,criar,vazio};
}
test('Cria e lista pela enfermagem sem agenda; evita segunda internação ativa',async t=>{
    const a=await ambiente(t);assert.equal((await a.criar()).status,201);
    assert.equal(a.internacoes[0]!.petId,'P1');assert.equal(a.internacoes[0]!.veterinarioId,'VET1');
    const lista=await a.pedir('','GET',undefined,'ENFERMEIRO',a.enf.usuarioId);
    assert.equal(lista.status,200);assert.equal(lista.dados.internacoes[0].petNome,'Pet do teste');
    assert.equal((await a.criar()).status,409);
});
test('Notas têm autor autenticado e versão antiga não sobrescreve atualização',async t=>{
    const a=await ambiente(t);const id=(await a.criar()).dados.internacaoId;const p=a.vazio();
    p.notasInternacao.push({texto:'Evolução',autor:'falso'});
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:p},'ENFERMEIRO',a.enf.usuarioId)).status,200);
    assert.equal((await a.pedir('/pet/P1')).dados.internacoes[0].prontuario.notasInternacao[0].autor,'Enfermeira');
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:a.vazio()})).status,409);
});
test('Veterinário e enfermagem registram administrações no mesmo prontuário sem duplicar reenvio',async t=>{
    const a=await ambiente(t);const id=(await a.criar()).dados.internacaoId;const p=a.vazio();
    p.medicacoesInternacao.push({nome:'m',dosagem:'d',frequencia:'f',detalhes:'',administracoes:[]});
    const negada=await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:p},'ENFERMEIRO',a.enf.usuarioId);
    assert.equal(negada.status,403);assert.equal(typeof negada.dados.mensagem,'string');
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:p})).status,200);
    p.medicacoesInternacao[0].administracoes.push({realizadaEm:'2026-11-23T10:00:00Z',responsavel:'falso',observacao:''});
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:1,prontuario:p})).status,200);
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:1,prontuario:p})).status,409);
    const lido=(await a.pedir('/pet/P1','GET',undefined,'ENFERMEIRO',a.enf.usuarioId)).dados.internacoes[0];
    assert.equal(lido.prontuario.medicacoesInternacao[0].administracoes.length,1);
    assert.equal(lido.prontuario.medicacoesInternacao[0].administracoes[0].responsavel,'Veterinário');
    lido.prontuario.medicacoesInternacao[0].administracoes.push({realizadaEm:'2026-11-23T12:00:00Z',responsavel:'falso',observacao:''});
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:lido.versao,prontuario:lido.prontuario},'ENFERMEIRO',a.enf.usuarioId)).status,200);
    const atualizado=(await a.pedir('/pet/P1')).dados.internacoes[0];
    assert.deepEqual(atualizado.prontuario.medicacoesInternacao[0].administracoes.map((d:any)=>d.responsavel),['Veterinário','Enfermeira']);
    atualizado.prontuario.medicacoesInternacao[0].administracoes[0].observacao='Alteração indevida';
    const alteracao=await a.pedir(`/${id}/prontuario`,'PATCH',{versao:atualizado.versao,prontuario:atualizado.prontuario});
    assert.equal(alteracao.status,403);assert.equal(typeof alteracao.dados.mensagem,'string');
    assert.equal(a.internacoes[0]!.prontuario.medicacoesInternacao[0].administracoes[0].observacao,'');
});
test('Alta é restrita ao responsável; remove da lista e bloqueia edição mantendo histórico',async t=>{
    const a=await ambiente(t);const id=(await a.criar()).dados.internacaoId;
    assert.equal((await a.pedir(`/${id}/alta`,'PATCH',{},'ENFERMEIRO',a.enf.usuarioId)).status,403);
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:a.vazio()},'VETERINARIO',a.outro.usuarioId)).status,403);
    assert.equal((await a.pedir(`/${id}/alta`,'PATCH',{})).status,200);
    assert.deepEqual((await a.pedir()).dados.internacoes,[]);
    assert.equal((await a.pedir('/pet/P1')).dados.internacoes[0].status,'alta');
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:a.vazio()})).status,409);
});
test('Visitante, tutor e profissional inativo não consultam internações',async t=>{
    const a=await ambiente(t);assert.equal((await a.pedir('','GET',undefined,'VETERINARIO',null)).status,401);
    assert.equal((await a.pedir('','GET',undefined,'USUARIO')).status,403);
    a.enf.ativo=false;assert.equal((await a.pedir('/pet/P1','GET',undefined,'ENFERMEIRO',a.enf.usuarioId)).status,403);
});
test('Salvamentos simultâneos preservam uma versão e rejeitam o segundo; corpo inválido não grava',async t=>{
    const a=await ambiente(t);const id=(await a.criar()).dados.internacaoId;
    assert.equal((await a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:{}})).status,400);
    const p=a.vazio();p.notasInternacao.push({texto:'Nota concorrente',autor:'falso'});
    const resultados=await Promise.all([a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:p}),a.pedir(`/${id}/prontuario`,'PATCH',{versao:0,prontuario:p},'ENFERMEIRO',a.enf.usuarioId)]);
    assert.deepEqual(resultados.map(r=>r.status).sort(),[200,409]);assert.equal(a.internacoes[0]!.versao,1);
});
