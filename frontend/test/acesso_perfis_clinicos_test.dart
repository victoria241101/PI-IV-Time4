import 'package:flutter/material.dart';
import 'package:pet_care/main.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/gerais/inicio_geral.dart';
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
  final contexto = _ContextoTeste();
  MaterialApp app() => const AplicativoVeterinaria().build(contexto) as MaterialApp;
  Widget destino(String rota) {
    Widget tela = app().routes![rota]!(contexto);
    while (tela is AnimatedBuilder) {
      tela = tela.builder(contexto, null);
    }
    return tela;
  }
  const rotas = ['/recepcao', '/enfermeiro', '/veterinario', '/inicio-autenticado', '/revisao-fluxos'];
  test('Abertura usa splash existente para restaurar sessão', () {
    final inicio = app().home as Builder;
    expect(inicio.builder(contexto), isA<SplashScreen>());
  });
  test('Visitante não acessa nenhuma entrada clínica', () {
    for (final rota in rotas) {
      expect(destino(rota), isA<LoginScreen>());
    }
  });
  for (final perfil in {
    'SECRETARIA': InicioRecepcao,
    'ENFERMEIRO': InicioEnfermeiro,
    'VETERINARIO': InicioVeterinario,
  }.entries) {
    test('${perfil.key} acessa somente sua tela, inclusive por rota alheia', () async {
      await sessao.entrar(nome: 'Teste', email: 'teste@example.test',
        token: 'token-teste', tipoUsuario: perfil.key);
      for (final rota in rotas) {
        expect(destino(rota).runtimeType, perfil.value);
      }
      // Reavalia o mesmo guard após encerrar a sessão.
      final guard = app().routes!['/recepcao']!(contexto) as AnimatedBuilder;
      expect(guard.listenable, same(sessao));
      await sessao.sair();
      expect(guard.builder(contexto, null), isA<LoginScreen>());
    });
  }
  for (final tutor in [false, true]) {
    test('Destino original de usuário (tutor=$tutor) preservado', () async {
      await sessao.entrar(nome: 'Teste', email: 'teste@example.test',
        token: 'token-teste', tipoUsuario: 'USUARIO', ehTutor: tutor);
      for (final rota in rotas) {
        if (tutor) {
          expect(destino(rota).runtimeType.toString(), '_InicioTutorComDadosReais');
        } else {
          expect(destino(rota), isA<InicioGeral>());
        }
      }
    });
  }

}

class _ContextoTeste extends Fake implements BuildContext {}
