import 'package:pet_care/widgets/clinica/layout_clinica.dart';
import 'package:pet_care/screens/gerais/perfil_geral.dart';
import 'package:pet_care/widgets/cabecalho_petcare.dart';
import 'package:pet_care/widgets/clinica/acesso_clinico.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/main.dart';
import 'package:pet_care/screens/gerais/splash_screen.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';
import 'package:pet_care/core/constantes/api_config.dart';

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
          expect(req.url.origin, Uri.parse(ApiConfig.baseUrl).origin);
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
  for (final tipo in ['SECRETARIA', 'ENFERMEIRO', 'VETERINARIO']) {
    testWidgets('$tipo pode cancelar ou confirmar saída e voltar ao login', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await sessao.entrar(
        nome: 'Alycia $tipo',
        email: 'equipe@example.test',
        token: 'token-teste',
        tipoUsuario: tipo,
      );
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Tela de login')),
          },
          home: AcessoClinico(
            perfil: tipo,
            builder: (_) => LayoutClinica(
              nomePadrao: 'Equipe',
              abaAtual: 0,
              onSelecionarAba: (_) {},
              paginas: const [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
              terceiraAba: const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Cadastro',
              ),
              onNotificacao: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Alycia $tipo!'), findsOneWidget);
      expect(find.text('Sair da conta'), findsNothing);
      await sessao.entrar(nome: 'Bruna $tipo', email: 'nova@example.test', token: 'token-teste', tipoUsuario: tipo);
      await tester.pumpAndSettle();
      expect(find.textContaining('Alycia'), findsNothing);
      expect(find.textContaining('Bruna $tipo!'), findsOneWidget);
      await tester.tap(find.byTooltip('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(PerfilGeral), findsOneWidget);
      expect(find.text('Bruna $tipo'), findsOneWidget);
      expect(find.text('nova@example.test'), findsOneWidget);
      expect(find.text('Meu perfil'), findsNothing);
      expect(find.text('Informações da sua conta.'), findsNothing);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Alterar senha'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Sair da conta'), 150, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(sessao.estaLogado, isTrue);
      expect(sessao.token, 'token-teste');

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(find.text('Tela de login'), findsOneWidget);
      expect(find.byType(LayoutClinica), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Tela de login'))).canPop(),
        isFalse,
      );
      await sessao.carregar();
      expect(sessao.estaLogado, isFalse);
      expect(sessao.token, isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Cabeçalho sem nome não inventa usuário e mantém padrão dos demais perfis', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CabecalhoPetCare(nome: ' ', saudacao: 'Bom dia', abreviarNome: false))));
    expect(find.text('Bom dia!'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CabecalhoPetCare(nome: 'Ana Silva'))));
    expect(find.text('Olá, Ana!'), findsOneWidget);
  });
  testWidgets('Perfil geral original mantém suas ações', (tester) async {
    await sessao.entrar(nome: 'Ana Silva', email: 'ana@example.test', token: 'token-teste');
    await tester.pumpWidget(const MaterialApp(home: PerfilGeral()));
    await tester.pumpAndSettle();
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Alterar senha'), findsOneWidget);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Gerencie suas informações e configurações da conta.'), findsOneWidget);
    expect(find.text('Informações da sua conta.'), findsNothing);
  });
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
