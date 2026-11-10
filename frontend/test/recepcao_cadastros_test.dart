import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/central_cadastros_recepcao.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';

void main() {
  final agenda = AgendaClinica.instancia;
  final cadastros = CadastrosRecepcaoLocal.instancia;
  late List<ConsultaRecepcao> consultas;
  late Map<String, ProntuarioCompartilhado> prontuarios;
  late List<RegistroRecepcaoLocal> registros;
  setUpAll(() {
    TipografiaApp.heading1 = const TextStyle(fontSize: 24);
    TipografiaApp.heading2 = const TextStyle(fontSize: 20);
    TipografiaApp.heading3 = const TextStyle(fontSize: 18);
    TipografiaApp.body = const TextStyle(fontSize: 16);
    TipografiaApp.bodyMedium = const TextStyle(fontSize: 14);
    TipografiaApp.bodySmall = const TextStyle(fontSize: 14);
    TipografiaApp.caption = const TextStyle(fontSize: 12);
    TipografiaApp.captionBold = const TextStyle(fontSize: 12);
    TipografiaApp.button = const TextStyle(fontSize: 16);
    TipografiaApp.buttonSmall = const TextStyle(fontSize: 14);
  });
  setUp(() {
    consultas = List.of(agenda.consultas);
    prontuarios = Map.of(agenda.prontuarios);
    registros = List.of(cadastros.registros);
    agenda.consultas.clear();
    agenda.prontuarios.clear();
    cadastros.registros.clear();
  });
  tearDown(() {
    agenda.consultas
      ..clear()
      ..addAll(consultas);
    agenda.prontuarios
      ..clear()
      ..addAll(prontuarios);
    cadastros.registros
      ..clear()
      ..addAll(registros);
  });
  Future<void> abrir(WidgetTester t, Widget tela) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: tela)));
    await t.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester t, String texto) async {
    final alvo = find.text(texto);
    await t.ensureVisible(alvo);
    await t.tap(alvo);
    await t.pumpAndSettle();
  }

  Future<void> preencher(WidgetTester t, String label, String valor) async {
    final campo = find.widgetWithText(TextFormField, label);
    await t.ensureVisible(campo);
    await t.enterText(campo, valor);
    await t.pumpAndSettle();
  }

  ConsultaRecepcao consulta(
    String id, {
    String pet = 'Mel',
    DateTime? data,
    bool emergencia = false,
  }) => ConsultaRecepcao(
    id: id,
    emergencia: emergencia,
    data: data ?? DateTime.now(),
    horario: '10:00',
    duracaoMinutos: 30,
    pet: pet,
    especie: 'Cachorro',
    tutor: 'Marina Costa',
    profissional: 'Dra. Beatriz',
    motivo: 'Consulta',
    sala: 'Sala 02',
    status: StatusConsultaRecepcao.finalizado,
  );
  Future<void> selecionarMel(WidgetTester t) async {
    await tocar(t, 'Sim, já tem cadastro');
    await preencher(t, 'CPF do responsável', '12345678901');
    await tocar(t, 'Buscar responsável');
    await tocar(t, 'Mel');
    await tocar(t, 'Continuar com pet selecionado');
  }

  testWidgets('Hoje agrupa mesmo horário e mantém cada paciente e emergência', (
    t,
  ) async {
    agenda.consultas.addAll([
      consulta('a'),
      consulta('b', pet: 'Luna', emergencia: true),
    ]);
    await abrir(t, const InicioRecepcao());
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Mel'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.byTooltip('Emergência'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Tutor exige pet e salva sem gerar consulta', (t) async {
    var consultasCriadas = 0;
    RegistroRecepcaoLocal? salvo;
    await abrir(
      t,
      CadastroRecepcao(
        somenteCadastro: true,
        onRegistrarConsulta: (_) {
          consultasCriadas++;
          return true;
        },
        onCadastroConcluido: (r) => salvo = r,
      ),
    );
    await preencher(t, 'Nome completo', 'Ana Teste');
    await preencher(t, 'CPF', '12345678901');
    await preencher(t, 'Celular', '11999999999');
    await tocar(t, 'Continuar para perfil do pet');
    expect(salvo, isNull);
    await tocar(t, 'Cadastrar tutor e pet');
    expect(find.text('Informe o nome do pet'), findsOneWidget);
    expect(salvo, isNull);
    await preencher(t, 'Nome do pet', 'Pipoca');
    await tocar(t, 'Cadastrar tutor e pet');
    expect(salvo?.nome, 'Ana Teste');
    expect(salvo?.dados['pet'], 'Pipoca');
    expect(consultasCriadas, 0);
    expect(find.text('Tutor e pet cadastrados'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Funcionário veterinário exige CRMV e retorna cadastro local', (
    t,
  ) async {
    await abrir(t, const CentralCadastrosRecepcao());
    await tocar(t, 'Funcionário');
    await tocar(t, 'Enfermeiro');
    await tocar(t, 'Veterinário');
    await preencher(t, 'Nome completo', 'Beatriz Teste');
    await preencher(t, 'E-mail para acesso', 'beatriz@example.com');
    await preencher(t, 'Celular', '11999999999');
    await tocar(t, 'Salvar cadastro');
    expect(find.text('Preencha este campo'), findsOneWidget);
    expect(cadastros.registros, isEmpty);
    await preencher(t, 'CRMV', 'CRMV-SP-12345');
    await tocar(t, 'Salvar cadastro');
    expect(cadastros.registros.single.dados['cargo'], 'Veterinário');
    expect(cadastros.registros.single.dados['crmv'], 'CRMV-SP-12345');
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Internação exige indicação e preserva previsão diferente da reserva',
    (t) async {
      final agendada = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 2)),
      );
      final prevista = agendada.add(const Duration(days: 3));
      final origem = consulta(
        'origem',
        data: DateTime.now().subtract(const Duration(days: 2)),
      );
      agenda.consultas.add(origem);
      agenda.prontuarios[origem.id] = ProntuarioCompartilhado(
        internacao: 'Programada',
        procedimentoIndicado: 'Procedimento de teste',
        dataPrevistaInternacao: prevista,
      );
      ConsultaRecepcao? criada;
      // Pré-cadastra tutor de demonstração para a busca por CPF avançar.
      cadastros.registros.add(
        RegistroRecepcaoLocal(
          tipo: TipoCadastroRecepcao.tutorPet,
          nome: 'Marina Costa',
          dados: const {
            'cpf': '12345678901',
            'telefone': '(11) 98842-1092',
            'email': 'marina.costa@email.com',
            'endereco': 'Av. Paulista, 1200 · Bela Vista',
            'pet': 'Mel',
            'especie': 'Cachorro',
            'raca': '',
            'dataNascimento': '',
            'sexo': 'Fêmea',
            'castrado': 'Sim',
            'condicoes': '',
            'microchip': 'Não',
          },
        ),
      );
      await abrir(
        t,
        CadastroRecepcao(
          dataInicial: agendada,
          onRegistrarConsulta: (c) {
            criada = c;
            agenda.consultas.add(c);
            return true;
          },
        ),
      );
      await selecionarMel(t);
      await tocar(t, 'Agendar internação');
      await tocar(t, 'Confirmar agendamento');
      expect(criada, isNull);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      final seletor = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Prontuário com indicação',
      );
      await t.ensureVisible(seletor);
      await t.tap(seletor);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Procedimento de teste').last);
      await t.pumpAndSettle();
      await tocar(t, 'Confirmar agendamento');
      expect(criada?.data, agendada);
      expect(criada?.dataPrevistaInternacao, prevista);
      expect(criada?.prontuarioOrigemId, origem.id);
      expect(criada?.internacaoAgendada, isTrue);
      expect(agenda.prontuarios[origem.id]!.internacaoAtiva, isFalse);
      await tocar(t, 'Novo cadastro');
      await selecionarMel(t);
      await tocar(t, 'Agendar internação');
      expect(find.textContaining('Este pet não tem indicação'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'CPF inválido (sequência repetida) é rejeitado no cadastro de Secretária',
    (t) async {
      await abrir(t, const CentralCadastrosRecepcao());
      await tocar(t, 'Funcionário');
      await tocar(t, 'Enfermeiro');
      await tocar(t, 'Secretária');
      await preencher(t, 'Nome completo', 'Teste Secretária');
      await preencher(t, 'E-mail para acesso', 'sec@example.com');
      await preencher(t, 'Celular', '11999999999');
      await preencher(t, 'CPF', '11111111111');
      await tocar(t, 'Salvar cadastro');
      expect(find.text('CPF inválido'), findsOneWidget);
      expect(cadastros.registros, isEmpty);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('CPF válido é aceito no cadastro de Secretária', (t) async {
    await abrir(t, const CentralCadastrosRecepcao());
    await tocar(t, 'Funcionário');
    await tocar(t, 'Enfermeiro');
    await tocar(t, 'Secretária');
    await preencher(t, 'Nome completo', 'Teste Secretária');
    await preencher(t, 'E-mail para acesso', 'sec2@example.com');
    await preencher(t, 'Celular', '11999999999');
    await preencher(t, 'CPF', '52998224725');
    await tocar(t, 'Salvar cadastro');
    expect(cadastros.registros, isNotEmpty);
    expect(cadastros.registros.single.dados['cpf'], '52998224725');
    expect(cadastros.registros.single.dados['cargo'], 'Secretária');
    expect(t.takeException(), isNull);
  });

  testWidgets('Trocar cargo não vaza campos da função anterior', (t) async {
    await abrir(t, const CentralCadastrosRecepcao());
    await tocar(t, 'Funcionário');
    await tocar(t, 'Enfermeiro');
    await tocar(t, 'Veterinário');
    await preencher(t, 'Nome completo', 'Dr. Teste');
    await preencher(t, 'E-mail para acesso', 'vet@example.com');
    await preencher(t, 'Celular', '11999999999');
    await preencher(t, 'CRMV', 'CRMV-SP-99999');
    await tocar(t, 'Veterinário');
    await tocar(t, 'Enfermeiro');
    await preencher(t, 'Registro', 'ENF-VET-001');
    await tocar(t, 'Salvar cadastro');
    expect(cadastros.registros.single.dados['cargo'], 'Enfermeiro');
    expect(cadastros.registros.single.dados.containsKey('crmv'), isFalse);
    expect(cadastros.registros.single.dados['registro'], 'ENF-VET-001');
    expect(t.takeException(), isNull);
  });

  testWidgets('Tutor e pet usam os campos presentes no banco', (t) async {
    RegistroRecepcaoLocal? salvo;
    await abrir(
      t,
      CadastroRecepcao(
        somenteCadastro: true,
        onRegistrarConsulta: (_) => true,
        onCadastroConcluido: (r) => salvo = r,
      ),
    );
    await preencher(t, 'Nome completo', 'Tutor Castrado');
    await preencher(t, 'CPF', '52998224725');
    await preencher(t, 'Celular', '11888888888');
    await tocar(t, 'Continuar para perfil do pet');
    await preencher(t, 'Nome do pet', 'Bolinha');
    expect(find.text('Possui microchip?'), findsNothing);
    expect(find.text('Castrado(a)'), findsNothing);
    expect(find.text('Observações clínicas'), findsNothing);
    await tocar(t, 'Cadastrar tutor e pet');
    expect(
      salvo?.dados.keys,
      unorderedEquals([
        'cpf',
        'telefone',
        'email',
        'pet',
        'especie',
        'raca',
        'dataNascimento',
        'sexo',
      ]),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('CPF não cadastrado exibe mensagem e não avança', (t) async {
    await abrir(t, CadastroRecepcao(onRegistrarConsulta: (_) => true));
    await tocar(t, 'Sim, já tem cadastro');
    await preencher(t, 'CPF do responsável', '52998224725');
    await tocar(t, 'Buscar responsável');
    expect(
      find.text(
        'CPF não encontrado nesta sessão. Cadastre o tutor como novo responsável.',
      ),
      findsOneWidget,
    );
    expect(find.text('Buscar responsável'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
