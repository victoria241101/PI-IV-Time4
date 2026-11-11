import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import test, { type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import { ObjectId, type Db, type Document, type MongoClient } from 'mongodb';
import { criarRotasCadastrosRecepcao } from '../src/recepcao/cadastros.routes.ts';

const corpo = () => ({nome:'Ana Teste',cpf:'52998224725',email:'ana@example.test',telefone:'11999999999',
  solicitacaoId:new ObjectId().toString(),pet:{nome:'Mel',especie:'cachorro',raca:'SRD',sexo:'femea'}});
const igual = (a: unknown,b: unknown) => a instanceof ObjectId && b instanceof ObjectId ? a.equals(b) : a===b;
function corresponde(d: Document,f: Document) { return Object.entries(f).every(([k,v]) => k==='$or'
  ? v.some((x: Document)=>corresponde(d,x))
  : v && typeof v==='object' && !(v instanceof ObjectId) ? ('$in' in v ? v.$in.some((x: unknown)=>igual(d[k],x)) : '$ne' in v ? !igual(d[k],v.$ne) : false)
  : igual(d[k],v)); }
async function preparar(t: TestContext, {papel='SECRETARIA', autenticado=true, falharHash=false}={}) {
  const docs: Record<string, Document[]>={usuarios:[],tutores:[],pets:[]};const senhas: string[]=[];let acessos=0;
  const banco={collection(nome: string){acessos++;return {
    find(f: Document){const rows=docs[nome]!.filter(d=>corresponde(d,f));return {limit(n: number){rows.splice(n);return this;},async toArray(){return rows;}};},
    async findOne(f: Document){return docs[nome]!.find(d=>corresponde(d,f))??null;},
    async insertOne(d: Document){docs[nome]!.push(d);return {insertedId:d._id};},
    async updateOne(f: Document,u: Document){const i=docs[nome]!.findIndex(d=>corresponde(d,f));if(i>=0)docs[nome]![i]={...docs[nome]![i],...u.$set};return {modifiedCount:i>=0?1:0};}
  };}};
  const cliente={startSession(){return {async withTransaction(fn: () => Promise<void>){const antes=Object.fromEntries(Object.entries(docs).map(([k,v])=>[k,[...v]]));try{await fn();}catch(e){Object.assign(docs,antes);throw e;}},async endSession(){}};}};
  const app=express();app.use(express.json());
  app.use('/recepcao',criarRotasCadastrosRecepcao({obterBanco:()=>banco as unknown as Db,obterCliente:()=>cliente as unknown as MongoClient,
    autenticar(req,res,next){if(!autenticado)return res.sendStatus(401);res.locals.usuarioTipo=papel;res.locals.usuarioId='secretaria';next();},
    async gerarHash(senha){senhas.push(senha);if(falharHash)throw new Error('Java indisponível');return 'hash-de-teste';}}));
  const servidor=await new Promise<Server>(resolve=>{const s=app.listen(0,'127.0.0.1',()=>resolve(s));});
  t.after(()=>new Promise<void>((resolve, reject) => servidor.close(erro => erro ? reject(erro) : resolve())));
  const url=`http://127.0.0.1:${(servidor.address() as AddressInfo).port}/recepcao`;
  async function enviar(body: unknown){const r=await fetch(url+'/tutores-pets',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});return {status:r.status,body:await r.json()};}
  return {docs,senhas,enviar,url,get acessos(){return acessos;}};
}
test('Cria conta, tutor e pet vinculados; senha aleatória não é retornada',async t=>{
  const h=await preparar(t);const r=await h.enviar(corpo());assert.equal(r.status,201);
  assert.equal(r.body.contaCriada,true);assert.equal(h.senhas[0]!.length,64);
  assert.equal(h.docs.usuarios![0]!.senhaHash,'hash-de-teste');
  assert.equal(h.docs.usuarios![0]!.tipo,'USUARIO');
  assert.equal(String(h.docs.tutores![0]!.usuarioId),String(h.docs.usuarios![0]!._id));
  assert.equal(String(h.docs.pets![0]!.tutorId),String(h.docs.tutores![0]!._id));
  assert.equal(JSON.stringify(r.body).includes('hash'),false);
  assert.equal(JSON.stringify(r.body).includes(h.senhas[0]!),false);
});
test('Reenvio não duplica conta, tutor ou pet e preserva a senha',async t=>{
  const h=await preparar(t);const body=corpo();await h.enviar(body);const r=await h.enviar(body);
  assert.equal(r.status,201);assert.equal(r.body.contaCriada,false);
  assert.deepEqual(Object.values(h.docs).map(x=>x.length),[1,1,1]);assert.equal(h.senhas.length,1);
});
test('Conta existente é reutilizada e CPF/e-mail incompatíveis são recusados',async t=>{
  const h=await preparar(t);const id=new ObjectId();h.docs.usuarios!.push({_id:id,nome:'Ana',cpf:'52998224725',email:'ana@example.test',tipo:'USUARIO',ativo:true,senhaHash:'senha-anterior'});
  const r=await h.enviar(corpo());assert.equal(r.status,201);assert.equal(h.senhas.length,0);
  assert.equal(h.docs.usuarios![0]!.senhaHash,'senha-anterior');
  assert.equal((await h.enviar({...corpo(),email:'outra@example.test'})).status,409);
});
test('Falha na geração da senha não deixa cadastro parcial',async t=>{
  const h=await preparar(t,{falharHash:true});assert.equal((await h.enviar(corpo())).status,503);
  assert.deepEqual(Object.values(h.docs).map(x=>x.length),[0,0,0]);
});
test('Somente secretária autenticada pode criar e consultar',async t=>{
  for(const opcoes of [{papel:'USUARIO'},{papel:'ENFERMEIRO'},{papel:'VETERINARIO'},{autenticado:false}]) {
    const h=await preparar(t,opcoes);const esperado=opcoes.autenticado===false?401:403;
    const r=await fetch(h.url+'/tutores-pets',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(corpo())});
    assert.equal(r.status,esperado);assert.equal((await fetch(h.url+'/tutores?cpf=52998224725')).status,esperado);assert.equal(h.acessos,0);
  }
});
test('Busca pelo CPF devolve somente o tutor e os pets vinculados',async t=>{
  const h=await preparar(t);await h.enviar(corpo());h.docs.pets!.push({_id:'P2',tutorId:'outro',nome:'Outro pet'});
  const r=await fetch(h.url+'/tutores?cpf=52998224725');const dados=await r.json();
  assert.equal(r.status,200);assert.equal(dados.tutor.nome,'Ana Teste');assert.equal(dados.pets.length,1);
  assert.equal(JSON.stringify(dados).includes('senhaHash'),false);
});
test('Dados inválidos não chegam ao banco',async t=>{
  const h=await preparar(t);for(const parte of [{cpf:'11111111111'},{email:'invalido'},{pet:{nome:'Mel'}},{solicitacaoId:'x'}]) {
    assert.equal((await h.enviar({...corpo(),...parte})).status,400);
  }assert.equal(h.acessos,0);
});
