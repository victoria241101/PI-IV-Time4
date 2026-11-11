import test, { type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import { ObjectId, type Db, type Document } from 'mongodb';
import { completarNomesAgenda } from '../src/consultas/nomesAgenda.ts';

test('Agenda resolve vínculos antigos e novos sem retornar dados privados', async () => {
  const uid = new ObjectId();
  const vet = new ObjectId();
  const dados: Record<string, Document[]> = {
    pets: [{_id:'P1', nome:'Mel', especie:'cachorro'}],
    tutores: [{_id:'T1', nome:'Nome antigo', usuarioId:uid}],
    usuarios: [{_id:uid, nome:'Nome atualizado'}],
    veterinarios:[{_id:vet, nome:'Veterinária'}]
  };
  const chamadas: { nome: string; filtro: Document; opcoes: Document }[] = [];
  const banco = { collection(nome: string) { return { find(filtro: Document, opcoes: Document) {
    chamadas.push({nome, filtro, opcoes});
    return { toArray:async()=>dados[nome] };
  } }; } };
  const [consulta] = await completarNomesAgenda(banco as unknown as Db, [{_id:'C1',petId:'P1',tutorId:'T1',veterinarioId:String(vet)}]);
  assert.ok(consulta);
  assert.equal(consulta.petNome,'Mel');
  assert.equal(consulta.tutorNome,'Nome atualizado');
  assert.equal(consulta.veterinarioNome,'Veterinária');
  assert.equal(consulta.veterinarioId,String(vet));
  assert.equal(chamadas.length,4);
  assert.deepEqual(chamadas.find(c=>c.nome==='usuarios')!.opcoes.projection,{nome:1});
  assert.ok(chamadas.find(c=>c.nome==='veterinarios')!.filtro._id.$in.some((id: unknown)=>id instanceof ObjectId));
});
test('Vínculo ausente não inventa nome nem perde consulta',async()=>{
  const banco={collection(){return {find(){return {toArray:async()=>[]};}};}};
  const [c]=await completarNomesAgenda(banco as unknown as Db,[{_id:'C1',petId:'P1'}]);
  assert.ok(c);
  assert.equal(c._id,'C1');assert.equal(c.petNome,null);assert.equal(c.tutorNome,null);
});
test('Agenda vazia não faz buscas adicionais',async()=>{
  const banco={collection(){throw new Error('Não deveria consultar');}};
  assert.deepEqual(await completarNomesAgenda(banco as unknown as Db,[]),[]);
});
