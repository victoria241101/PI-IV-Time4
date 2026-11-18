import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/screens/recepcao/cadastro/formulario_administrativo.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sessao = SessaoUsuario.instancia;
  Future<void> entrar(String token) => sessao.entrar(
    nome: 'Secretária',
    email: 'teste@example.test',
    token: token,
    tipoUsuario: 'SECRETARIA',
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await entrar('token-antigo');
  });
  tearDown(() => sessao.sair());

  for (final status in [401, 403, 500]) {
    test(
      'Cadastro distingue sessão expirada de outros erros: $status',
      () async {
        await http.runWithClient(
          () async {
            await expectLater(
              CadastrosRecepcaoService().cadastrarFuncionario(
                {},
                'solicitacao',
              ),
              throwsA(
                status == 401
                    ? isA<SessaoCadastroExpirada>()
                    : isNot(isA<SessaoCadastroExpirada>()),
              ),
            );
            // Sair exige uma ação explícita do usuário.
            expect(sessao.token, 'token-antigo');
          },
          () => MockClient(
            (_) async => http.Response('{"mensagem":"Erro"}', status),
          ),
        );
      },
    );
  }

  test(
    'Resposta de sessão antiga não encerra nem invalida a sessão nova',
    () async {
      final resposta = Completer<http.Response>();
      final recebeu = Completer<void>();
      await http.runWithClient(
        () async {
          final pedido = CadastrosRecepcaoService().cadastrarFuncionario(
            {},
            'solicitacao',
          );
          final verificacao = expectLater(pedido, throwsA(isA<StateError>()));
          await recebeu.future;
          await entrar('token-novo');
          resposta.complete(http.Response('{"mensagem":"Expirou"}', 401));
          await verificacao;
          expect(sessao.token, 'token-novo');
        },
        () => MockClient((_) {
          recebeu.complete();
          return resposta.future;
        }),
      );
    },
  );

  testWidgets(
    'Sessão expirada mantém formulário e oferece retorno seguro ao login',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Tela de login')),
          },
          home: FormularioAdministrativo(
            tipo: TipoCadastroRecepcao.funcionario,
            cadastrosService: _CadastroExpirado(),
          ),
        ),
      );
      for (final entrada in {
        'Nome completo': 'Enfermeira Teste',
        'E-mail para acesso': 'enf@example.test',
        'Celular': '11999999999',
        'Registro': 'ENF-001',
      }.entries) {
        await tester.enterText(
          find.widgetWithText(TextFormField, entrada.key),
          entrada.value,
        );
      }
      await tester.ensureVisible(find.text('Salvar cadastro'));
      await tester.tap(find.text('Salvar cadastro'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sua sessão expirou. Entre novamente para cadastrar.'),
        findsOneWidget,
      );
      expect(find.text('Enfermeira Teste'), findsOneWidget);
      expect(find.text('Tela de login'), findsNothing);
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(sessao.token, 'token-antigo');
      expect(find.text('Enfermeira Teste'), findsOneWidget);

      await tester.tap(find.text('Salvar cadastro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ir para o login'));
      await tester.pumpAndSettle();
      expect(find.text('Tela de login'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.text('Tela de login'))).canPop(),
        isFalse,
      );
      await sessao.carregar();
      expect(sessao.estaLogado, isFalse);
      expect(sessao.token, isNull);
    },
  );
}

class _CadastroExpirado extends CadastrosRecepcaoService {
  @override
  Future<Map<String, dynamic>> cadastrarFuncionario(
    Map<String, String> dados,
    String solicitacaoId,
  ) async {
    throw SessaoCadastroExpirada(SessaoUsuario.instancia.token);
  }
}
