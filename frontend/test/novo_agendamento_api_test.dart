// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: agendamento com tutor/pet existentes ou novos e data selecionada.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/screens/recepcao/agenda/novo_agendamento_api.dart';
import 'package:pet_care/screens/recepcao/cadastro/central_cadastros_recepcao.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';

const _cpf = '52998224725';
const _tutorId = '111111111111111111111111';
const _petExistenteId = '222222222222222222222222';
const _petNovoId = '333333333333333333333333';
const _veterinarioId = '444444444444444444444444';
final _dia = DateTime(2026, 12, 24);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoUsuario.instancia.entrar(
      nome: 'Secretária',
      email: 'secretaria@example.test',
      token: 'token-teste',
      tipoUsuario: 'SECRETARIA',
    );
  });

  tearDown(() async => SessaoUsuario.instancia.sair());

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => NovoAgendamentoApi(
                      dia: _dia,
                      cadastrosService: CadastrosRecepcaoService(
                        baseUrl: 'https://api.example.test',
                      ),
                    ),
                  ),
                ),
                child: const Text('Abrir agenda'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir agenda'));
    await tester.pumpAndSettle();
  }

  Future<void> concluirAgendamento(WidgetTester tester) async {
    final veterinario = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(veterinario);
    await tester.tap(veterinario);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dra. Bia').last);
    await tester.pumpAndSettle();

    final horario = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(horario);
    await tester.tap(horario);
    await tester.pumpAndSettle();
    await tester.tap(find.text('09:00').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmar agendamento'));
    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();
  }

  Future<void> habilitarMicrochip(WidgetTester tester) async {
    expect(find.text('Número do microchip'), findsNothing);
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Número do microchip'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número do microchip'),
      '001234567890123',
    );
  }

  Future<void> executarFluxo(
    WidgetTester tester, {
    required String opcao,
    required bool cadastrarTutor,
    bool cadastrarPet = false,
  }) async {
    var cadastroChamado = false;
    var agendamentoChamado = false;
    var dataHoraAgendada = '';
    final client = MockClient((request) async {
      if (request.url.path == '/recepcao/tutores' && request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'tutor': {
              'id': _tutorId,
              'cpf': _cpf,
              'nome': 'Ana Teste',
              'email': 'ana@example.test',
              'telefone': '11999999999',
            },
            'pets': [
              {'id': _petExistenteId, 'nome': 'Mel', 'especie': 'cachorro'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/recepcao/tutores-pets' &&
          request.method == 'POST') {
        cadastroChamado = true;
        final body = jsonDecode(request.body) as Map;
        expect(body['cpf'], _cpf);
        expect(body['pet']['nome'], 'Rex');
        expect(body['pet']['possuiMicrochip'], isTrue);
        expect(body['pet']['microchip'], '001234567890123');
        expect(body['solicitacaoId'], isA<String>());
        return http.Response(
          jsonEncode({
            'tutorId': _tutorId,
            'petId': _petNovoId,
            'contaCriada': cadastrarTutor,
            'nome': 'Ana Teste',
          }),
          201,
        );
      }
      if (request.url.path == '/veterinarios') {
        return http.Response(
          jsonEncode({
            'veterinarios': [
              {'_id': _veterinarioId, 'nome': 'Dra. Bia'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/agendamentos/disponibilidade') {
        expect(request.url.queryParameters['data'], '2026-12-24');
        return http.Response('{"horarios":["2026-12-24T09:00:00.000Z"]}', 200);
      }
      if (request.url.path == '/agendamentos' && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map;
        agendamentoChamado = true;
        dataHoraAgendada = body['dataHora'] as String;
        expect(
          body['petId'],
          cadastrarTutor || cadastrarPet ? _petNovoId : _petExistenteId,
        );
        return http.Response('{"id":"555555555555555555555555"}', 201);
      }
      fail('Requisição inesperada: ${request.method} ${request.url}');
    });

    await http.runWithClient(() async {
      await abrir(tester);
      expect(find.text('Data selecionada · 24/12/2026'), findsOneWidget);
      await tester.tap(find.text(opcao));
      await tester.pumpAndSettle();

      if (opcao == 'Tutor existente') {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'CPF do tutor'),
          _cpf,
        );
        await tester.tap(find.text('Buscar tutor e pets'));
        await tester.pumpAndSettle();
        if (cadastrarPet) {
          await tester.tap(find.text('Cadastrar outro pet'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'CPF do responsável'),
            _cpf,
          );
          await tester.tap(find.text('Buscar responsável'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Nome do pet'),
            'Rex',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Raça'),
            'SRD',
          );
          await habilitarMicrochip(tester);
          await tester.tap(find.text('Cadastrar pet para este tutor'));
          await tester.pumpAndSettle();
          expect(find.text('Pet cadastrado'), findsOneWidget);
          await tester.tap(find.text('Concluir'));
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Mel').last);
          await tester.pumpAndSettle();
        }
      } else {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo'),
          'Ana Teste',
        );
        await tester.enterText(find.widgetWithText(TextFormField, 'CPF'), _cpf);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Celular'),
          '11999999999',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail'),
          'ana@example.test',
        );
        await tester.tap(find.text('Continuar para perfil do pet'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome do pet'),
          'Rex',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Raça'),
          'SRD',
        );
        await habilitarMicrochip(tester);
        final botaoCadastro = find.text('Cadastrar tutor e pet');
        await tester.ensureVisible(botaoCadastro.first);
        await tester.tap(botaoCadastro.first);
        await tester.pumpAndSettle();
        expect(find.text('Tutor e pet cadastrados'), findsOneWidget);
        await tester.tap(find.text('Concluir'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Veterinário'), findsOneWidget);
      await concluirAgendamento(tester);
      expect(cadastroChamado, cadastrarTutor || cadastrarPet);
      expect(agendamentoChamado, isTrue);
      expect(dataHoraAgendada, '2026-12-24T09:00:00');
      expect(tester.takeException(), isNull);
    }, () => client);
  }

  testWidgets('Agenda oferece somente as duas opções de tutor', (tester) async {
    await abrir(tester);
    expect(find.text('Tutor existente'), findsOneWidget);
    expect(find.text('Novo tutor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Central da secretária abre cadastro de pet para tutor existente',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CentralCadastrosRecepcao(
              cadastrosService: CadastrosRecepcaoService(
                baseUrl: 'https://api.example.test',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tutor e pet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tutor existente'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextFormField, 'CPF do responsável'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Agenda tutor e pet existentes sem perder a data', (
    tester,
  ) async {
    await executarFluxo(
      tester,
      opcao: 'Tutor existente',
      cadastrarTutor: false,
    );
  });

  testWidgets('Cadastra tutor e pet novos antes de agendar', (tester) async {
    await executarFluxo(tester, opcao: 'Novo tutor', cadastrarTutor: true);
  });

  testWidgets('Cadastra pet para tutor existente antes de agendar', (
    tester,
  ) async {
    await executarFluxo(
      tester,
      opcao: 'Tutor existente',
      cadastrarTutor: false,
      cadastrarPet: true,
    );
  });
}
