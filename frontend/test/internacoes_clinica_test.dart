// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: internações, prontuário compartilhado, doses, atualização, alta e conflitos.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/screens/veterinario/clientes_veterinario.dart';
import 'package:pet_care/screens/veterinario/prontuario_internacao.dart';
import 'package:pet_care/screens/veterinario/consulta_veterinario.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';

ConsultaRecepcao consulta() => ConsultaRecepcao(id:'C1',petId:'P1',data:DateTime(2026,11,22),horario:'10:00',duracaoMinutos:30,pet:'Mel',especie:'cachorro',tutor:'Tutor',profissional:'Veterinária',motivo:'Consulta',sala:'1',status:StatusConsultaRecepcao.emConsulta);
Map<String,dynamic> registro() => {'_id':'I1','petId':'P1','veterinarioId':'V1','petNome':'Mel','tutorNome':'Tutor','especie':'cachorro','veterinarioNome':'Veterinária','status':'ativa','dataEntrada':'2026-11-20T10:00:00.000Z','dataAlta':null,'motivo':'Observação','leito':'L1','observacoes':'Cuidados registrados','versao':0};
Future<void> entrar(String perfil) => SessaoUsuario.instancia.entrar(nome:perfil,email:'teste@example.test',token:perfil,tipoUsuario:perfil);
void main() {
 TestWidgetsFlutterBinding.ensureInitialized();
 late ConsultasClinicaService anterior;
 setUp(() async {SharedPreferences.setMockInitialValues({});FlutterSecureStorage.setMockInitialValues({});anterior=AgendaClinica.instancia.servico;await entrar('VETERINARIO');});
 tearDown(() async {AgendaClinica.instancia.servico=anterior;await SessaoUsuario.instancia.sair();});
 test('Serviço usa rotas existentes, token e versão e recusa resposta de outro pet',() async {
   final pedidos=<http.Request>[];
   await http.runWithClient(() async {
     final s=ConsultasClinicaService(baseUrl:'http://api.test',obterToken:()=> 'token');
     expect(await s.criarInternacao(petId:'P1',motivo:'Observação',leito:'L1'),'I1');
     final dados=await s.listarInternacoes(petId:'P1');
     final p=ProntuarioCompartilhado()..lerInternacao(dados.single);
     await s.salvarProntuarioInternacao(p);await s.darAltaInternacao('I1');
     await expectLater(s.listarInternacoes(petId:'P2'),throwsFormatException);
   },()=>MockClient((r)async{pedidos.add(r);expect(r.headers['Authorization'],'Bearer token');return http.Response(jsonEncode(r.method=='GET'?{'internacoes':[registro()]}:r.method=='POST'?{'internacaoId':'I1'}:{'mensagem':'ok'}),200,headers:{'content-type':'application/json; charset=utf-8'});}));
   expect(pedidos[0].url.path,'/internacoes');expect(jsonDecode(pedidos[2].body)['versao'],0);expect(pedidos[3].url.path,'/internacoes/I1/alta');
 });
 test('Erro de permissão no prontuário preserva mensagem da API sem repetir gravação',() async {
   var envios=0;
   await http.runWithClient(() async {
     final s=ConsultasClinicaService(baseUrl:'http://api.test',obterToken:()=> 'token');
     final p=ProntuarioCompartilhado()..lerInternacao(registro());
     await expectLater(s.salvarProntuarioInternacao(p),throwsA(isA<Exception>().having((e)=>e.toString(),'mensagem',contains('Você não tem permissão'))));
   },()=>MockClient((r)async {
     envios++;expect(r.method,'PATCH');expect(r.url.path,'/internacoes/I1/prontuario');
     return http.Response(jsonEncode({'mensagem':'Você não tem permissão para alterar este prontuário.'}),403,headers:{'content-type':'application/json; charset=utf-8'});
   }));
   expect(envios,1);
 });
 testWidgets('Enfermeira vê internado sem consultas na agenda e abre o mesmo prontuário', (tester) async {
   await tester.binding.setSurfaceSize(const Size(320,720));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final api=_Api();AgendaClinica.instancia.servico=api;await entrar('ENFERMEIRO');
   await tester.pumpWidget(const MaterialApp(home:Scaffold(body:ClientesVeterinario(consultas:[],profissional:'Enfermeira',somenteInternados:true))));await tester.pumpAndSettle();
   expect(find.text('Mel'),findsOneWidget);expect(find.text('Pacientes internados'),findsOneWidget);
   expect(find.text('Internado'),findsNothing);expect(find.text('Tutor: Tutor'),findsOneWidget);expect(tester.takeException(),isNull);
   await tester.tap(find.byTooltip('Abrir prontuário da internação'));await tester.pumpAndSettle();
   expect(find.byType(ProntuarioInternacao),findsOneWidget);expect(find.text('Finalizar internação'),findsNothing);
   expect(find.text('Internação ativa'),findsNothing);
   await tester.tap(find.text('Adicionar nota'));await tester.pumpAndSettle();await tester.enterText(find.byType(TextField),'Evolução da enfermagem');await tester.tap(find.text('Salvar'));await tester.pumpAndSettle();
   expect(api.r['prontuario']['notasInternacao'][0]['texto'],'Evolução da enfermagem');
   await tester.pumpWidget(const SizedBox());await entrar('VETERINARIO');
   await tester.pumpWidget(MaterialApp(home:ProntuarioInternacao(consulta:consulta(),internacaoId:'I1')));await tester.pumpAndSettle();
   expect(find.text('Evolução da enfermagem'),findsOneWidget);expect(find.text('Finalizar internação'),findsOneWidget);
   await tester.pumpWidget(const SizedBox());
 });
 testWidgets('Veterinário e enfermeira registram doses e recuperam o mesmo histórico', (tester) async {
   await tester.binding.setSurfaceSize(const Size(900,1400));
   addTearDown(()=>tester.binding.setSurfaceSize(null));
   final api=_Api();AgendaClinica.instancia.servico=api;
   api.r['prontuario']=ProntuarioCompartilhado(medicacoesInternacao:[MedicacaoInternacao(nome:'Medicação registrada',dosagem:'Dose registrada',frequencia:'Horário registrado')]).dadosInternacao();
   for(final perfil in ['VETERINARIO','ENFERMEIRO']) {
     await entrar(perfil);
     await tester.pumpWidget(MaterialApp(home:ProntuarioInternacao(consulta:consulta(),internacaoId:'I1')));await tester.pumpAndSettle();
     await tester.tap(find.text('Cuidados'));await tester.pumpAndSettle();
     final botao=find.widgetWithText(OutlinedButton,'Registrar administração');
     await tester.scrollUntilVisible(botao,150,scrollable:find.byType(Scrollable).last);
     await tester.tap(botao);await tester.pumpAndSettle();
     await tester.enterText(find.widgetWithText(TextField,'Observação (opcional)'),'Dose de $perfil');
     await tester.tap(find.text('Salvar'));await tester.pumpAndSettle();
     await tester.tap(find.text('OK'));await tester.pumpAndSettle();
     await tester.tap(find.text('OK'));await tester.pumpAndSettle();
     final doses=api.r['prontuario']['medicacoesInternacao'][0]['administracoes'] as List;
     expect(doses.length,perfil=='VETERINARIO'?1:2);
     expect(doses.last['observacao'],'Dose de $perfil');
     await tester.pumpWidget(const SizedBox());
   }
   await entrar('VETERINARIO');
   await tester.pumpWidget(MaterialApp(home:ProntuarioInternacao(consulta:consulta(),internacaoId:'I1')));await tester.pumpAndSettle();
   await tester.tap(find.text('Cuidados'));await tester.pumpAndSettle();
   expect(find.textContaining('Dose de VETERINARIO'),findsOneWidget);
   expect(find.textContaining('Dose de ENFERMEIRO'),findsOneWidget);
   await tester.pumpWidget(const SizedBox());
 });
 testWidgets('Prontuário aberto recebe atualização do banco e alta por outra sessão', (tester) async {
   final api=_Api();AgendaClinica.instancia.servico=api;await entrar('ENFERMEIRO');
   await tester.pumpWidget(MaterialApp(home:ProntuarioInternacao(consulta:consulta(),internacaoId:'I1')));await tester.pumpAndSettle();
   api.r['prontuario']=ProntuarioCompartilhado(notasInternacao:[NotaInternacao(texto:'Nova evolução',autor:'Veterinária')]).dadosInternacao();
   api.r['status']='alta';api.r['dataAlta']='2026-11-22T12:00:00Z';
   await tester.pump(const Duration(seconds:11));await tester.pumpAndSettle();
   expect(find.text('Nova evolução'),findsOneWidget);expect(find.text('Adicionar nota'),findsNothing);
   await tester.pumpWidget(const SizedBox());
 });
 testWidgets('Conflito não publica nota local como se estivesse salva', (tester) async {
   final api=_Api()..falhar=true;AgendaClinica.instancia.servico=api;
   await tester.pumpWidget(MaterialApp(home:ProntuarioInternacao(consulta:consulta(),internacaoId:'I1')));await tester.pumpAndSettle();
   await tester.tap(find.text('Adicionar nota'));await tester.pumpAndSettle();await tester.enterText(find.byType(TextField),'Não confirmada');await tester.tap(find.text('Salvar'));await tester.pumpAndSettle();
   expect(find.text('Não confirmada'),findsNothing);expect(api.r['prontuario'],isNull);
   await tester.pumpWidget(const SizedBox());
 });
 testWidgets('Veterinário registra internação antes de finalizar e recebe o vínculo real', (tester) async {
   final api=_Api()..existe=false;AgendaClinica.instancia.servico=api;
   await tester.pumpWidget(MaterialApp(home:ConsultaVeterinario(consulta:consulta())));await tester.pumpAndSettle();
   for(final nome in ['Anamnese','Exame físico','Diagnóstico','Prognóstico','Tratamento']) {
     final campo=find.widgetWithText(TextField,nome);await tester.scrollUntilVisible(campo,150,scrollable:find.byType(Scrollable).first);await tester.enterText(campo,'Registro clínico');
   }
   await tester.scrollUntilVisible(find.text('Indicação de internação'),150,scrollable:find.byType(Scrollable).first);
   await tester.tap(find.byType(DropdownButtonFormField<String>));await tester.pumpAndSettle();await tester.tap(find.text('Imediata · emergência').last);await tester.pumpAndSettle();
   await tester.tap(find.text('Finalizar consulta'));await tester.pumpAndSettle();
   await tester.enterText(find.widgetWithText(TextField,'Leito'),'L1');await tester.tap(find.text('Salvar'));await tester.pumpAndSettle();
   expect(api.eventos,['atendimento','internacao','prontuario','finalizar']);expect(api.r['status'],'ativa');
   await tester.pumpWidget(const SizedBox());
 });
}
class _Api extends ConsultasClinicaService {
 final r=registro();bool falhar=false,existe=true;final eventos=<String>[];Map<String,dynamic>? atendimento;
 @override Future<List<Map<String,dynamic>>> listarInternacoes({String? petId}) async=>existe && (petId!=null||r['status']=='ativa')?[Map<String,dynamic>.from(jsonDecode(jsonEncode(r)))]:[];
 @override Future<void> salvarProntuarioInternacao(ProntuarioCompartilhado p)async {if(falhar)throw StateError('Versão desatualizada');eventos.add('prontuario');r['prontuario']=p.dadosInternacao();r['versao']=p.versaoInternacao+1;}
 @override Future<void> darAltaInternacao(String id)async{r['status']='alta';}
 @override Future<Map<String,dynamic>> lerProntuario(String id)async=>{'triagem':null,'atendimento':atendimento};
 @override Future<List<MedicamentoPrescrito>> listarPrescricoes(String petId,{String? atendimentoId})async=>[];
 @override Future<List<ExameVeterinario>> listarExames(String petId)async=>[];
 @override Future<String> salvarAtendimento(String id,{required String anamnese,required String exameFisico,required String diagnostico,required String prognostico,required String tratamento,String observacoes='',String? codigoICDVet})async{eventos.add('atendimento');atendimento={'_id':'A1','anamnese':anamnese,'exameFisico':exameFisico,'diagnostico':diagnostico,'prognostico':prognostico,'tratamento':tratamento};return 'A1';}
 @override Future<String> criarInternacao({required String petId,required String motivo,required String leito,String observacoes=''})async{eventos.add('internacao');existe=true;return 'I1';}
 @override Future<void> finalizarAtendimento(String id)async{eventos.add('finalizar');}
}
