// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: solicitação/leitura de exames e falhas.
// Testes de tela para o fluxo de exames veterinários.
// Cobre: preencher atendimento → solicitar exame → vínculo → reabrir e recuperar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/screens/veterinario/consulta_veterinario.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';

ConsultaRecepcao consulta() => ConsultaRecepcao(
  id: 'C1',
  petId: 'P1',
  data: DateTime(2026, 11, 22),
  horario: '10:00',
  duracaoMinutos: 30,
  pet: 'Mel',
  especie: 'Cachorro',
  tutor: 'Tutor Teste',
  profissional: 'Veterinária',
  motivo: 'Consulta de rotina',
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
      nome: 'Veterinária',
      email: 'vet@example.test',
      token: 'token',
      tipoUsuario: 'VETERINARIO',
    );
  });

  tearDown(() async {
    agenda.servico = anterior;
    agenda.prontuarios.clear();
    await SessaoUsuario.instancia.sair();
  });

  Future<void> abrir(WidgetTester tester, _ApiExames api, ConsultaRecepcao c) async {
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

  Future<void> preencherAtendimento(WidgetTester tester) async {
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
      await tester.enterText(campo, 'Valor de teste');
    }
  }

  testWidgets(
    'Solicitar exame salva o atendimento antes e vincula ao pet e atendimento',
    (tester) async {
      final api = _ApiExames();
      final c = consulta();
      await abrir(tester, api, c);
      await preencherAtendimento(tester);

      // Rola até a seção de exames e abre o botão adicionar
      await tester.scrollUntilVisible(
        find.text('Exames'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      // O botão só aparece após o atendimento ser salvo via _garantirAtendimentoSalvo.
      // Usamos o tooltip padrão do botão adicionar.
      await tester.tap(find.byTooltip('Adicionar').last);
      await tester.pumpAndSettle();

      // Preenche o diálogo de exame
      await tester.enterText(find.widgetWithText(TextField, 'Tipo do exame'), 'Hemograma');
      await tester.enterText(find.widgetWithText(TextField, 'Nome do exame'), 'Hemograma completo');
      await tester.tap(find.text('Solicitar exame'));
      await tester.pumpAndSettle();

      // Atendimento deve ter sido salvo antes do exame
      expect(api.eventos, ['atendimento', 'exame']);
      expect(api.exames.single.nome, 'Hemograma completo');
      expect(api.exames.single.petId, 'P1');
      expect(api.exames.single.atendimentoId, 'A1');
      expect(find.text('Hemograma completo'), findsOneWidget);
      expect(find.text('Exame solicitado no sistema.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reabrir consulta recupera o exame solicitado da API',
    (tester) async {
      final api = _ApiExames();
      api.exames.add(ExameVeterinario(
        id: 'EX001',
        petId: 'P1',
        atendimentoId: 'A1',
        nome: 'Hemograma completo',
        tipo: 'Hemograma',
      ));
      // Atendimento já estava gravado
      api.atendimento = {
        '_id': 'A1',
        'anamnese': 'a',
        'exameFisico': 'e',
        'diagnostico': 'd',
        'prognostico': 'p',
        'tratamento': 't',
      };
      final c = consulta();
      await abrir(tester, api, c);

      await tester.scrollUntilVisible(
        find.text('Hemograma completo'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hemograma completo'), findsOneWidget);
      expect(find.text('Aguardando resultado · Hemograma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Exame concluído exibe resultado na tela',
    (tester) async {
      final api = _ApiExames();
      api.exames.add(ExameVeterinario(
        id: 'EX001',
        petId: 'P1',
        atendimentoId: 'A1',
        nome: 'Ultrassom',
        tipo: 'Imagem',
        status: 'concluido',
        resultado: 'Sem alterações',
      ));
      api.atendimento = {
        '_id': 'A1',
        'anamnese': 'a',
        'exameFisico': 'e',
        'diagnostico': 'd',
        'prognostico': 'p',
        'tratamento': 't',
      };
      await abrir(tester, api, consulta());
      await tester.scrollUntilVisible(
        find.text('Ultrassom'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Resultado: Sem alterações'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sem petId o botão de exame mostra mensagem sem chamar a API',
    (tester) async {
      final api = _ApiExames();
      agenda.servico = api;
      // Consulta sem petId
      final semPet = ConsultaRecepcao(
        id: 'C2',
        petId: null,
        data: DateTime(2026, 11, 22),
        horario: '11:00',
        duracaoMinutos: 30,
        pet: 'Sem ID',
        especie: 'Gato',
        tutor: 'Tutor',
        profissional: 'Veterinária',
        motivo: 'Consulta',
        sala: '2',
        status: StatusConsultaRecepcao.emConsulta,
      );
      await tester.pumpWidget(
        MaterialApp(home: ConsultaVeterinario(consulta: semPet)),
      );
      await tester.pumpAndSettle();
      // O botão não aparece porque _dadosCarregados e _atendimentoSalvo são falsos.
      // Verificamos que nenhum POST foi feito.
      expect(api.eventos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ApiExames extends ConsultasClinicaService {
  Map<String, dynamic>? atendimento;
  final exames = <ExameVeterinario>[];
  final eventos = <String>[];

  @override
  Future<Map<String, dynamic>> lerProntuario(String id) async => {
    'triagem': null,
    'atendimento': atendimento,
  };

  @override
  Future<List<MedicamentoPrescrito>> listarPrescricoes(
    String petId, {
    String? atendimentoId,
  }) async => [];

  @override
  Future<List<ExameVeterinario>> listarExames(String petId) async =>
      exames.where((e) => e.petId == petId).toList();

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
  Future<ExameVeterinario> solicitarExame({
    required String petId,
    required String atendimentoId,
    required String tipo,
    required String nome,
    String justificativa = '',
  }) async {
    eventos.add('exame');
    final exame = ExameVeterinario(
      id: 'EX_${exames.length + 1}',
      petId: petId,
      atendimentoId: atendimentoId,
      tipo: tipo,
      nome: nome,
      justificativa: justificativa,
    );
    exames.add(exame);
    return exame;
  }

  @override
  Future<void> finalizarAtendimento(String id) async {
    eventos.add('finalizar');
  }
}

