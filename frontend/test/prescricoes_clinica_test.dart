// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: envio/leitura, recusas, troca de sessão e acesso de enfermagem somente leitura.
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
import 'package:pet_care/screens/veterinario/consulta_veterinario.dart';
import 'package:pet_care/screens/enfermeiro/prescricoes_enfermeiro.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';

const pedido = '507f1f77bcf86cd799439011';
Map<String, dynamic> prescricao([String atendimento = 'A1']) => {
  '_id': pedido,
  'petId': 'P1',
  'atendimentoId': atendimento,
  'medicamento': 'Medicamento teste',
  'dose': 'Dose teste',
  'frequencia': 'Frequência teste',
  'duracao': 'Duração teste',
  'orientacoes': 'Orientações teste',
  'status': 'ativa',
};
Future<String> salvar(ConsultasClinicaService api) => api.salvarPrescricao(
  petId: 'P1',
  atendimentoId: 'A1',
  solicitacaoId: pedido,
  medicamento: 'Medicamento teste',
  dose: 'Dose teste',
  frequencia: 'Frequência teste',
  duracao: 'Duração teste',
  orientacoes: 'Orientações teste',
);
ConsultaRecepcao consulta() => ConsultaRecepcao(
  id: 'C1',
  petId: 'P1',
  data: DateTime(2026, 11, 22),
  horario: '10:00',
  duracaoMinutos: 30,
  pet: 'Mel',
  especie: 'Cachorro',
  tutor: 'Tutor',
  profissional: 'Veterinário',
  motivo: 'Consulta',
  sala: '1',
  status: StatusConsultaRecepcao.emConsulta,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final agenda = AgendaClinica.instancia;
  late ConsultasClinicaService anterior;
  setUp(() async {
    anterior = agenda.servico;
    agenda.prontuarios.clear();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoUsuario.instancia.entrar(
      nome: 'Equipe',
      email: 'teste@example.test',
      token: 'token',
      tipoUsuario: 'VETERINARIO',
    );
  });
  tearDown(() async {
    agenda.servico = anterior;
    agenda.prontuarios.clear();
    await SessaoUsuario.instancia.sair();
  });
  test(
    'Contrato HTTP usa token, campos reais e filtra pelo atendimento',
    () async {
      final api = ConsultasClinicaService(obterToken: () => 'token');
      await http.runWithClient(
        () async {
          expect(await salvar(api), pedido);
          expect(
            (await api.listarPrescricoes('P1', atendimentoId: 'A1')).length,
            1,
          );
          expect((await api.listarPrescricoes('P1')).length, 2);
        },
        () => MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer token');
          if (r.method == 'POST') {
            expect(r.url.path, '/prescricoes');
            final esperado = prescricao()
              ..remove('_id')
              ..remove('status');
            esperado['solicitacaoId'] = pedido;
            expect(jsonDecode(r.body), esperado);
            return http.Response(jsonEncode({'prescricaoId': pedido}), 201);
          }
          expect(r.url.path, '/prescricoes/pet/P1');
          return http.Response(
            jsonEncode({
              'prescricoes': [prescricao(), prescricao('A2')],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    },
  );
  test('Recusas não são reenviadas automaticamente', () async {
    final api = ConsultasClinicaService(obterToken: () => 'token');
    for (final status in [401, 403, 409, 500]) {
      var chamadas = 0;
      await http.runWithClient(
        () async {
          await expectLater(salvar(api), throwsException);
        },
        () => MockClient((r) async {
          chamadas++;
          return http.Response('{"mensagem":"Recusado"}', status);
        }),
      );
      expect(chamadas, 1);
    }
  });
  test(
    'Prescrição de outro pet e resposta de gravação sem ID são recusadas',
    () async {
      final api = ConsultasClinicaService(obterToken: () => 'token');
      await http.runWithClient(
        () async {
          await expectLater(api.listarPrescricoes('P2'), throwsFormatException);
          await expectLater(salvar(api), throwsFormatException);
        },
        () => MockClient(
          (r) async => http.Response(
            jsonEncode(
              r.method == 'GET'
                  ? {
                      'prescricoes': [prescricao()],
                    }
                  : {'mensagem': 'ok'},
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
    },
  );
  test('Resposta de sessão anterior não atualiza a leitura', () async {
    var token = 'antigo';
    final api = ConsultasClinicaService(obterToken: () => token);
    await http.runWithClient(
      () async {
        await expectLater(api.listarPrescricoes('P1'), throwsStateError);
      },
      () => MockClient((r) async {
        token = 'novo';
        return http.Response('{"prescricoes":[]}', 200);
      }),
    );
  });
  Future<void> abrir(WidgetTester tester, _Api api, ConsultaRecepcao c) async {
    agenda.servico = api;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConsultaVeterinario(consulta: c),
                ),
              ),
              child: const Text('Abrir consulta'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir consulta'));
    await tester.pumpAndSettle();
  }

  Future<void> preparar(WidgetTester tester) async {
    for (final nome in [
      'Anamnese',
      'Exame físico',
      'Diagnóstico',
      'Prognóstico',
      'Tratamento',
    ]) {
      final campo = find.widgetWithText(TextField, nome);
      await tester.scrollUntilVisible(
        campo,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(campo, 'Informação clínica');
    }
    await tester.scrollUntilVisible(
      find.text('Medicações'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Adicionar').first);
    await tester.pumpAndSettle();
  }

  Future<void> preencher(WidgetTester tester) async {
    for (final nome in [
      'Medicamento',
      'Dose',
      'Frequência',
      'Duração',
      'Orientações',
    ]) {
      final campo = find.widgetWithText(TextField, nome);
      await tester.ensureVisible(campo);
      await tester.enterText(campo, '$nome teste');
    }
  }

  testWidgets(
    'Salva avaliação antes da prescrição, recupera ao reabrir e só finaliza por ação explícita',
    (tester) async {
      final api = _Api();
      final c = consulta();
      await abrir(tester, api, c);
      await preparar(tester);
      await tester.tap(find.text('Salvar prescrição'));
      await tester.pumpAndSettle();
      expect(find.text('Preencha os campos obrigatórios.'), findsOneWidget);
      expect(api.eventos, isEmpty);
      await preencher(tester);
      await tester.tap(find.text('Salvar prescrição'));
      await tester.pumpAndSettle();
      expect(api.eventos, ['atendimento', 'prescricao']);
      expect(c.status, StatusConsultaRecepcao.emConsulta);
      expect(find.text('Prescrição salva no sistema.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir consulta'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Medicamento teste'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Medicamento teste'), findsOneWidget);
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(api.eventos, ['atendimento', 'prescricao', 'finalizar']);
      expect(agenda.prontuarioDa(c).medicamentos.single.id, pedido);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Resposta perdida mantém formulário e reutiliza a mesma chave, sem falso sucesso',
    (tester) async {
      final api = _Api()..perderResposta = true;
      await abrir(tester, api, consulta());
      await preparar(tester);
      await preencher(tester);
      await tester.tap(find.text('Salvar prescrição'));
      await tester.pumpAndSettle();
      expect(find.text('Prescrição salva no sistema.'), findsNothing);
      expect(find.text('Adicionar medicação'), findsOneWidget);
      expect(api.chaves.length, 1);
      await tester.tap(find.text('Salvar prescrição'));
      await tester.pumpAndSettle();
      expect(api.chaves.length, 2);
      expect(api.chaves.first, api.chaves.last);
      expect(api.lista.length, 1);
      expect(find.text('Prescrição salva no sistema.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Enfermeiro consulta prescrições sem ação de cadastro', (
    tester,
  ) async {
    final api = _Api()..lista.add(MedicamentoPrescrito.fromJson(prescricao()));
    agenda.servico = api;
    await SessaoUsuario.instancia.entrar(
      nome: 'Enfermeira',
      email: 'enf@example.test',
      token: 'enf',
      tipoUsuario: 'ENFERMEIRO',
    );
    await tester.pumpWidget(
      MaterialApp(home: PrescricoesEnfermeiro(consultas: [consulta()])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Medicamento teste'), findsOneWidget);
    expect(find.text('Salvar prescrição'), findsNothing);
    expect(api.eventos, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Leitura de enfermagem bloqueia outro perfil antes de consultar a API',
    (tester) async {
      final api = _Api();
      agenda.servico = api;
      await tester.pumpWidget(
        MaterialApp(home: PrescricoesEnfermeiro(consultas: [consulta()])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Esta tela pertence a outro perfil.'), findsOneWidget);
      expect(api.leituras, 0);
    },
  );
}

class _Api extends ConsultasClinicaService {
  Map<String, dynamic>? atendimento;
  final lista = <MedicamentoPrescrito>[];
  final eventos = <String>[];
  final chaves = <String>[];
  int leituras = 0;
  bool perderResposta = false;
  @override
  Future<Map<String, dynamic>> lerProntuario(String id) async => {
    'triagem': null,
    'atendimento': atendimento,
  };
  @override
  Future<String> salvarAtendimento(
    String id, {
    required String anamnese,
    required String exameFisico,
    required String diagnostico,
    required String prognostico,
    required String tratamento,
    String observacoes = '',
    String? codigoICDVet,
  }) async {
    eventos.add('atendimento');
    atendimento = {
      '_id': 'A1',
      'anamnese': anamnese,
      'exameFisico': exameFisico,
      'diagnostico': diagnostico,
      'prognostico': prognostico,
      'tratamento': tratamento,
    };
    return 'A1';
  }

  @override
  Future<List<MedicamentoPrescrito>> listarPrescricoes(
    String petId, {
    String? atendimentoId,
  }) async {
    leituras++;
    return lista
        .where(
          (p) =>
              p.petId == petId &&
              (atendimentoId == null || p.atendimentoId == atendimentoId),
        )
        .toList();
  }

  @override
  Future<List<ExameVeterinario>> listarExames(String petId) async => [];

  @override
  Future<String> salvarPrescricao({
    required String petId,
    required String atendimentoId,
    required String solicitacaoId,
    required String medicamento,
    required String dose,
    required String frequencia,
    required String duracao,
    String orientacoes = '',
  }) async {
    eventos.add('prescricao');
    chaves.add(solicitacaoId);
    if (lista.isEmpty) {
      lista.add(
        MedicamentoPrescrito(
          id: pedido,
          petId: petId,
          atendimentoId: atendimentoId,
          nome: medicamento,
          dosagem: dose,
          frequencia: frequencia,
          duracao: duracao,
          orientacao: orientacoes,
        ),
      );
    }
    if (perderResposta && chaves.length == 1) {
      throw Exception('Resposta perdida');
    }
    return pedido;
  }

  @override
  Future<void> finalizarAtendimento(String id) async {
    eventos.add('finalizar');
  }
}
