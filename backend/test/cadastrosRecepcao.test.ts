// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: criação/vínculos de usuário, tutor, pet e funcionário, permissões, validações e duplicação.
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
  const banco={collection(nome: string){acessos++;docs[nome] ??= [];return {
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
  async function enviar(body: unknown){const r=await fetch(url+'/tutores-pets',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});return {status:r.status,body:await r.json().catch(()=>null)};}
  return {docs,senhas,enviar,url,get acessos(){return acessos;}};
}
test('Cria conta, tutor e pet vinculados; senha aleatória não é retornada',async t=>{
  const h=await preparar(t);const r=await h.enviar(corpo());assert.equal(r.status,201);
  assert.equal(r.body.contaCriada,true);assert.equal(h.senhas[0]!.length,64);
  assert.equal(h.docs.usuarios![0]!.senhaHash,'hash-de-teste');
  assert.equal(h.docs.usuarios![0]!.tipo,'USUARIO');
  assert.equal(String(h.docs.tutores![0]!.usuarioId),String(h.docs.usuarios![0]!._id));
  assert.equal(String(h.docs.pets![0]!.tutorId),String(h.docs.tutores![0]!._id));
  assert.equal(h.docs.pets![0]!.possuiMicrochip,false);
  assert.equal(h.docs.pets![0]!.microchip,'');
  assert.equal(JSON.stringify(r.body).includes('hash'),false);
  assert.equal(JSON.stringify(r.body).includes(h.senhas[0]!),false);
});
test('Reenvio não duplica conta, tutor ou pet e preserva a senha',async t=>{
  const h=await preparar(t);const base=corpo();const body={...base,pet:{...base.pet,possuiMicrochip:true,microchip:'000123456789'}};
  await h.enviar(body);const r=await h.enviar(body);
  assert.equal(r.status,201);assert.equal(r.body.contaCriada,false);
  assert.deepEqual(Object.values(h.docs).map(x=>x.length),[1,1,1]);assert.equal(h.senhas.length,1);
  assert.equal(h.docs.pets![0]!.microchip,'000123456789');
  assert.equal(h.docs.pets![0]!.possuiMicrochip,true);
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
  const h=await preparar(t);const base=corpo();await h.enviar({...base,pet:{...base.pet,possuiMicrochip:true,microchip:'000123456789'}});h.docs.pets!.push({_id:'P2',tutorId:'outro',nome:'Outro pet'});
  const r=await fetch(h.url+'/tutores?cpf=52998224725');const dados=await r.json();
  assert.equal(r.status,200);assert.equal(dados.tutor.nome,'Ana Teste');assert.equal(dados.pets.length,1);
  assert.equal(dados.pets[0].microchip,'000123456789');assert.equal(dados.pets[0].possuiMicrochip,true);
  assert.equal(JSON.stringify(dados).includes('senhaHash'),false);
});
test('Dados inválidos não chegam ao banco',async t=>{
  const h=await preparar(t);for(const parte of [{cpf:'11111111111'},{email:'invalido'},{pet:{nome:'Mel'}},{solicitacaoId:'x'}]) {
    assert.equal((await h.enviar({...corpo(),...parte})).status,400);
  }
  const base=corpo();
  for(const pet of [{...base.pet,possuiMicrochip:true},{...base.pet,possuiMicrochip:true,microchip:'   '},
    {...base.pet,possuiMicrochip:'true',microchip:'123'},{...base.pet,microchip:123}]) {
    assert.equal((await h.enviar({...base,pet})).status,400);
  }
  assert.equal(h.acessos,0);
});

const funcionario = (tipo='ENFERMEIRO') => ({
  nome:'Funcionário Teste',email:'funcionario@example.test',telefone:'11999999999',
  tipo,cpf:'52998224725',registro:'ENF-123',crmv:'CRMV-SP-123',especialidade:'Clínica geral',
  solicitacaoId:new ObjectId().toString()
});
async function enviarFuncionario(h: Awaited<ReturnType<typeof preparar>>, body: unknown) {
  const r=await fetch(h.url+'/funcionarios',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  return {status:r.status,body:await r.json().catch(()=>null)};
}
test('Funcionários: cada perfil cria conta e vínculo e reenvio preserva senha',async t=>{
  for(const [tipo,colecao] of [['SECRETARIA','secretaria'],['ENFERMEIRO','enfermeiros'],['VETERINARIO','veterinarios']] as const){
    const h=await preparar(t),body=funcionario(tipo);
    const r=await enviarFuncionario(h,body);assert.equal(r.status,201);
    const u=h.docs.usuarios![0]!,p=h.docs[colecao]![0]!;
    assert.equal(u.tipo,tipo);assert.equal(String(p.usuarioId),String(u._id));
    assert.equal(u.senhaHash,'hash-de-teste');
    assert.equal(JSON.stringify(r.body).includes(h.senhas[0]!),false);
    assert.equal((await enviarFuncionario(h,body)).status,201);
    assert.equal(h.docs.usuarios!.length,1);assert.equal(h.senhas.length,1);
    assert.equal((await enviarFuncionario(h,{...body,nome:'Outro'})).status,409);
  }
});
test('Funcionários: recusa contas existentes sem promover perfil ou trocar senha',async t=>{
  const h=await preparar(t);const u={_id:new ObjectId(),email:'funcionario@example.test',tipo:'USUARIO',senhaHash:'original'};
  h.docs.usuarios!.push(u);
  assert.equal((await enviarFuncionario(h,funcionario())).status,409);
  assert.deepEqual(h.docs.usuarios![0],u);assert.equal(h.senhas.length,0);
});
test('Funcionários: erros e permissões não deixam gravação parcial',async t=>{
  for(const opcoes of [{papel:'ENFERMEIRO'},{papel:'VETERINARIO'},{papel:'USUARIO'},{autenticado:false}]){
    const h=await preparar(t,opcoes);assert.equal((await enviarFuncionario(h,funcionario())).status,opcoes.autenticado===false?401:403);
    assert.equal(h.acessos,0);
  }
  const h=await preparar(t,{falharHash:true});
  assert.equal((await enviarFuncionario(h,funcionario())).status,503);
  assert.equal(h.docs.usuarios!.length,0);
  assert.equal((await enviarFuncionario(h,{...funcionario(),tipo:'ADMIN'})).status,400);
  assert.equal((await enviarFuncionario(h,{...funcionario(),registro:''})).status,400);
});
