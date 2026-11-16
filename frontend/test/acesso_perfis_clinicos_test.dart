import 'package:pet_care/widgets/clinica/acesso_clinico.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/main.dart';
import 'package:pet_care/screens/gerais/splash_screen.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';
import 'package:pet_care/services/api_http.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/screens/autenticacao/service/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sessao = SessaoUsuario.instancia;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await sessao.carregar();
  });
  tearDown(() async => sessao.sair());
  for (final tipo in ['SECRETARIA', 'ENFERMEIRO', 'VETERINARIO']) {
    test('$tipo autentica, restaura sessão e encerra acesso', () async {
      var chamadas = 0;
      await http.runWithClient(
        () async {
          await AuthService.instancia.login(
            email: 'equipe@example.test',
            senha: 'senha-teste',
          );
        },
        () => MockClient((req) async {
          chamadas++;
          expect(req.url.origin, Uri.parse(apiBaseUrl).origin);
          if (req.url.path == '/usuarios/login') {
            expect(req.method, 'POST');
            return http.Response(jsonEncode({'token': 'token-teste'}), 200);
          }
          expect(req.url.path, '/usuarios/perfil');
          expect(req.headers['Authorization'], 'Bearer token-teste');
          return http.Response(
            jsonEncode({
              'usuario': {
                'nome': 'Profissional Teste',
                'email': 'equipe@example.test',
                'tipo': tipo,
              },
              'ehTutor': false,
            }),
            200,
          );
        }),
      );
      expect(chamadas, 2);
      expect(sessao.estaLogado, isTrue);
      expect(sessao.tipoUsuario, tipo);
      expect(sessao.ehTutor, isFalse);
      final prefs = await SharedPreferences.getInstance();
      final persistido = Map<String, Object>.fromEntries(
        prefs.getKeys().map((k) => MapEntry(k, prefs.get(k)!)),
      );
      final seguro = Map<String, String>.from(
        await const FlutterSecureStorage().readAll(),
      );
      // Limpa a sessão em memória e restaura somente os valores persistidos.
      await sessao.sair();
      SharedPreferences.setMockInitialValues(persistido);
      FlutterSecureStorage.setMockInitialValues(seguro);
      await sessao.carregar();
      expect(sessao.token, 'token-teste');
      expect(sessao.tipoUsuario, tipo);
      expect(sessao.estaLogado, isTrue);
      expect(sessao.ehSecretaria, tipo == 'SECRETARIA');
      expect(sessao.ehEnfermeiro, tipo == 'ENFERMEIRO');
      expect(sessao.ehVeterinario, tipo == 'VETERINARIO');
      await sessao.sair();
      await sessao.carregar();
      expect(sessao.estaLogado, isFalse);
      expect(sessao.ehEquipeClinica, isFalse);
      expect(sessao.token, isNull);
    });
  }
  for (final status in [401, 403]) {
    test('Login recusado ($status) não cria sessão', () async {
      await http.runWithClient(
        () async {
          await expectLater(
            AuthService.instancia.login(
              email: 'equipe@example.test',
              senha: 'senha-teste',
            ),
            throwsException,
          );
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({'mensagem': 'Acesso recusado'}),
            status,
          ),
        ),
      );
      expect(sessao.estaLogado, isFalse);
      expect(sessao.token, isNull);
    });
  }
  test('Token rejeitado no perfil não cria sessão', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          AuthService.instancia.login(
            email: 'equipe@example.test',
            senha: 'senha-teste',
          ),
          throwsException,
        );
      },
      () => MockClient(
        (req) async => req.url.path.endsWith('/login')
            ? http.Response('{"token":"token-teste"}', 200)
            : http.Response('{"mensagem":"Token expirado"}', 401),
      ),
    );
    expect(sessao.estaLogado, isFalse);
  });
  Future<MaterialApp> app(WidgetTester tester) async {
    await tester.pumpWidget(const AplicativoVeterinaria());
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  testWidgets('Abertura mantém a restauração de sessão da develop', (
    tester,
  ) async {
    final aplicativo = await app(tester);
    final contexto = tester.element(find.byType(MaterialApp));
    expect((aplicativo.home as Builder).builder(contexto), isA<SplashScreen>());
  });

  for (final perfil in ['SECRETARIA', 'ENFERMEIRO', 'VETERINARIO']) {
    testWidgets('$perfil: bloqueia visitante, outros perfis e logout', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AcessoClinico(
            perfil: perfil,
            builder: (_) => const Text('Conteúdo clínico'),
          ),
        ),
      );
      expect(find.text('Conteúdo clínico'), findsNothing);
      for (final tipo in [
        'SECRETARIA',
        'ENFERMEIRO',
        'VETERINARIO',
        'USUARIO',
      ]) {
        await sessao.entrar(
          nome: 'Teste',
          email: 'teste@example.test',
          token: 'token-teste',
          tipoUsuario: tipo,
        );
        await tester.pump();
        expect(
          find.text('Conteúdo clínico'),
          tipo == perfil ? findsOneWidget : findsNothing,
        );
      }
      await sessao.sair();
      await tester.pump();
      expect(find.text('Conteúdo clínico'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    });
  }

  for (final perfil in {
    'SECRETARIA': InicioRecepcao,
    'ENFERMEIRO': InicioEnfermeiro,
    'VETERINARIO': InicioVeterinario,
  }.entries) {
    testWidgets('Login direciona ${perfil.key} para o fluxo correto', (
      tester,
    ) async {
      await sessao.entrar(
        nome: 'Teste',
        email: 'teste@example.test',
        token: 'teste',
        tipoUsuario: perfil.key,
      );
      final aplicativo = await app(tester);
      final contexto = tester.element(find.byType(MaterialApp));
      expect(
        aplicativo.routes!['/inicio-autenticado']!(contexto).runtimeType,
        perfil.value,
      );
    });
  }
  testWidgets('As três entradas clínicas bloqueiam visitantes', (tester) async {
    for (final tela in <Widget>[
      const InicioRecepcao(),
      const InicioEnfermeiro(),
      const InicioVeterinario(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: tela));
      await tester.pump();
      expect(
        find.text('Entre na sua conta para acessar a clínica.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
