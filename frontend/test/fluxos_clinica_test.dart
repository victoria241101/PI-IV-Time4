// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: navegação dos três perfis, telas estreitas e ações clínicas.
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/clinica/consulta_clinica_api.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';
// Confere navegação, ações de cada perfil e notas compartilhadas após a padronização.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';
import 'package:pet_care/screens/veterinario/prontuario_internacao.dart';
import 'package:pet_care/widgets/clinica/cartao_atendimento.dart';

void main() {
  final agenda = AgendaClinica.instancia;
  late List<ConsultaRecepcao> anteriores;
  late Map<String, ProntuarioCompartilhado> prontuarios;
  late ConsultaRecepcao consulta;
  late ConsultasClinicaService servicoAnterior;
  setUpAll(() {
    // Fontes locais de teste evitam downloads; conservam os tamanhos do core.
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoUsuario.instancia.sair();

    servicoAnterior = agenda.servico;
    agenda.servico = _ApiClinicaTeste();
    anteriores = List.of(agenda.consultas);
    prontuarios = Map.of(agenda.prontuarios);
    agenda.consultas.clear();
    agenda.prontuarios.clear();
    consulta = ConsultaRecepcao(
      id: 'revisao',
      petId: 'P1',
      data: DateTime.now(),
      horario: '10:00',
      duracaoMinutos: 30,
      pet: 'Paciente teste',
      especie: 'Cão',
      tutor: 'Tutor teste',
      profissional: 'Dra. Camila',
      motivo: 'Consulta',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.agendada,
    );
    agenda.adicionarConsulta(consulta);
  });
  tearDown(() {
    agenda.servico = servicoAnterior;
    agenda.consultas
      ..clear()
      ..addAll(anteriores);
    agenda.prontuarios
      ..clear()
      ..addAll(prontuarios);
  });
  Future<void> abrir(
    WidgetTester tester,
    Widget pagina, {
    double largura = 390,
  }) async {
    final salvas = List<ConsultaRecepcao>.of(agenda.consultas);
    final notas = Map<String, ProntuarioCompartilhado>.of(agenda.prontuarios);
    await SessaoUsuario.instancia.entrar(
      nome: pagina is ProntuarioInternacao
          ? (pagina.responsavel ?? 'Profissional teste')
          : 'Profissional teste',
      email: 'teste@example.test',
      token: 'token-teste',
      tipoUsuario: pagina is InicioRecepcao
          ? 'SECRETARIA'
          : pagina is InicioEnfermeiro
          ? 'ENFERMEIRO'
          : 'VETERINARIO',
    );
    agenda.consultas
      ..clear()
      ..addAll(salvas);
    agenda.prontuarios
      ..clear()
      ..addAll(notas);
    tester.view.physicalSize = Size(largura, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: pagina));
    await tester.pumpAndSettle();
  }

  testWidgets('Três fluxos abrem todas as abas sem erro em tela estreita', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        consulta.status = StatusConsultaRecepcao.aguardandoTriagem;
        for (final pagina in <Widget>[
          const InicioRecepcao(),
          const InicioEnfermeiro(),
          const InicioVeterinario(profissional: 'Dra. Camila'),
        ]) {
          await abrir(tester, pagina, largura: 360);
          for (final aba in [1, 2, 3, 0]) {
            await tester.tap(find.byType(NavigationDestination).at(aba));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: "${pagina.runtimeType}, aba $aba",
            );
          }
          expect(
            find.text('Fale com a recepção e com os veterinários'),
            findsNothing,
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
      () => MockClient((request) async {
        expect(request.url.path, startsWith('/chat/'));
        return http.Response('{"conversas":[],"contatos":[]}', 200);
      }),
    );
  });
  testWidgets('Agenda simplificada mantém calendário e perfil nos três fluxos em tela estreita', (tester) async {
    consulta.status = StatusConsultaRecepcao.aguardandoTriagem;
    for (final pagina in <Widget>[const InicioRecepcao(), const InicioEnfermeiro(), const InicioVeterinario()]) {
      await abrir(tester, pagina, largura: 320);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Agendamentos'), findsNothing);
      expect(find.text('Escolha um dia para ver os horários e atendimentos'), findsNothing);
      expect(find.byTooltip('Perfil'), findsOneWidget);
      final proximoMes = find.byTooltip('Próximo mês');
      await tester.ensureVisible(proximoMes);
      await tester.tap(proximoMes);await tester.pumpAndSettle();
      await tester.tap(find.text('15'));await tester.pumpAndSettle();
      expect(find.textContaining(', 15 de '), findsOneWidget);
      expect(find.textContaining('Nenhum agendamento'), findsOneWidget);
      if (pagina is InicioEnfermeiro) {
        await tester.tap(find.byType(NavigationDestination).at(2));await tester.pumpAndSettle();
        expect(find.text('Consultar prescrições'), findsNothing);
        expect(find.text('Pacientes internados'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('Recepção apenas confirma chegada e mantém os demais status', (
    tester,
  ) async {
    await abrir(tester, const InicioRecepcao());
    expect(find.text('Finalizar consulta'), findsNothing);
    await tester.tap(find.text('Confirmar chegada'));
    await tester.pumpAndSettle();
    expect(consulta.status, StatusConsultaRecepcao.aguardandoTriagem);
    expect(find.text('Confirmar chegada'), findsNothing);
    expect(find.text('Iniciar triagem'), findsNothing);
    for (final status in StatusConsultaRecepcao.values.where(
      (s) => s != StatusConsultaRecepcao.agendada,
    )) {
      agenda.atualizarStatus(consulta, status);
      await tester.pumpAndSettle();
      expect(find.text('Confirmar chegada'), findsNothing);
      expect(find.byType(CartaoAtendimento), findsOneWidget);
    }
  });
  testWidgets('Enfermeiro conclui triagem, sai de Hoje e atualiza o contador', (
    tester,
  ) async {
    consulta.status = StatusConsultaRecepcao.aguardandoTriagem;
    await abrir(tester, const InicioEnfermeiro());
    await tester.tap(find.text('Iniciar triagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar triagem'));
    await tester.pumpAndSettle();
    expect(consulta.status, StatusConsultaRecepcao.emTriagem);
    await tester.enterText(find.widgetWithText(TextField, 'Peso (kg)'), '10');
    await tester.enterText(
      find.widgetWithText(TextField, 'Temperatura (°C)'),
      '38.5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Sintomas'),
      'Coceira',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Observações clínicas'),
      'Observações preservadas',
    );
    await tester.tap(find.text('Concluir triagem'));
    await tester.pumpAndSettle();
    expect(consulta.status, StatusConsultaRecepcao.aguardandoVeterinario);
    expect(find.byType(CartaoAtendimento), findsNothing);
    expect(find.text('1  Triagem finalizada'), findsOneWidget);
    expect(
      agenda.prontuarioDa(consulta).observacoesTriagem,
      'Observações preservadas',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Veterinário acompanha a triagem e só finaliza após iniciar consulta',
    (tester) async {
      consulta.status = StatusConsultaRecepcao.emTriagem;
      await abrir(tester, const InicioVeterinario(profissional: 'Dra. Camila'));
      await tester.tap(find.text('Ver atendimento'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar consulta'), findsNothing);
      expect(find.text('Finalizar consulta'), findsNothing);
      await tester.pageBack();
      agenda.atualizarStatus(
        consulta,
        StatusConsultaRecepcao.aguardandoVeterinario,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar consulta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar consulta'));
      await tester.pumpAndSettle();
      expect(consulta.status, StatusConsultaRecepcao.emConsulta);
      for (final nome in [
        'Anamnese',
        'Exame físico',
        'Diagnóstico',
        'Prognóstico',
        'Tratamento',
      ]) {
        await tester.scrollUntilVisible(
          find.widgetWithText(TextField, nome),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.widgetWithText(TextField, nome),
          'Informação clínica de teste',
        );
      }
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(consulta.status, StatusConsultaRecepcao.finalizado);
      expect(find.byType(CartaoAtendimento), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Falha na API não confirma chegada localmente', (tester) async {
    agenda.servico = _ApiClinicaFalha();
    await abrir(tester, const InicioRecepcao());
    await tester.tap(find.text('Confirmar chegada'));
    await tester.pumpAndSettle();
    expect(consulta.status, StatusConsultaRecepcao.agendada);
    expect(find.text('Serviço indisponível'), findsOneWidget);
  });

  testWidgets('Nota identifica o autor e preserva data e hora digitadas', (
    tester,
  ) async {
    final api = agenda.servico as _ApiClinicaTeste;
    api.internacoes.add({
      '_id': 'I1', 'petId': 'P1', 'status': 'ativa', 'motivo': 'Observação',
      'leito': 'L1', 'dataEntrada': '2026-11-22T10:00:00Z', 'versao': 0,
    });
    await abrir(
      tester,
      ProntuarioInternacao(consulta: consulta, responsavel: 'Enfermeira Ana'),
    );
    final adicionar = find.text('Adicionar nota');
    await tester.ensureVisible(adicionar);
    await tester.tap(adicionar);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    const nota = '02/11, 11h: paciente se alimentou bem.';
    await tester.enterText(find.byType(TextField), nota);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    final salvo = ProntuarioCompartilhado()..lerInternacao(api.internacoes.single);
    final registro = salvo.notasInternacao.single;
    expect(registro.autor, 'Enfermeira Ana');
    expect(registro.texto, nota);
    await tester.pumpWidget(const SizedBox());
    await abrir(
      tester,
      ProntuarioInternacao(consulta: consulta, responsavel: 'Dra. Camila'),
    );
    await tester.ensureVisible(find.text(nota));
    expect(find.text('Registrado por Enfermeira Ana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ApiClinicaTeste extends ConsultasClinicaService {
  final internacoes = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> listarInternacoes({String? petId}) async => internacoes;
  @override
  Future<void> salvarProntuarioInternacao(ProntuarioCompartilhado p) async {
    internacoes.single['prontuario'] = p.dadosInternacao();
    internacoes.single['versao'] = p.versaoInternacao + 1;
  }

  // Estes testes exercitam ações sobre a agenda já carregada.
  // A leitura da API é testada em agenda_clinica_integracao_test.dart.
  @override
  Future<List<ConsultaClinicaApi>> listarDia(DateTime dia) =>
      Completer<List<ConsultaClinicaApi>>().future;

  @override
  Future<List<MedicamentoPrescrito>> listarPrescricoes(
    String petId, {
    String? atendimentoId,
  }) async => [];

  @override
  Future<List<ExameVeterinario>> listarExames(String petId) async => [];

  @override
  Future<Map<String, dynamic>> lerProntuario(String id) async => {
    'triagem': null,
    'atendimento': null,
  };
  @override
  Future<void> confirmarChegada(String id) async {}
  @override
  Future<void> iniciarTriagem(String id) async {}
  @override
  Future<void> finalizarTriagem(String id) async {}
  @override
  Future<void> iniciarAtendimento(String id) async {}
  @override
  Future<void> finalizarAtendimento(String id) async {}
  @override
  Future<void> salvarTriagem(
    String id, {
    required double peso,
    required double temperatura,
    required String sintomas,
    String observacoes = '',
  }) async {}
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
  }) async => 'ATENDIMENTO1';
}

class _ApiClinicaFalha extends _ApiClinicaTeste {
  @override
  Future<void> confirmarChegada(String id) async {
    throw Exception('Serviço indisponível');
  }
}
