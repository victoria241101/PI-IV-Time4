import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/screens/gerais/perfil_geral.dart';
import 'package:pet_care/widgets/clinica/acesso_clinico.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/widgets/cartao_proxima_consulta.dart';

void main() {
  final sessao = SessaoUsuario.instancia;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await sessao.carregar();
  });
  tearDown(() => sessao.sair());

  for (final tipo in ['SECRETARIA', 'ENFERMEIRO', 'VETERINARIO']) {
    testWidgets('$tipo lê telefone e CPF pela API existente', (tester) async {
      await sessao.entrar(
        nome: 'Profissional',
        email: 'perfil@example.test',
        token: 'token-teste',
        tipoUsuario: tipo,
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: PerfilGeral(modoCompacto: true)),
          );
          await tester.pumpAndSettle();
          expect(find.text('11912345678'), findsOneWidget);
          expect(find.text('12345678900'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((req) async {
          expect(req.url.toString(), '${ApiConfig.baseUrl}/usuarios/perfil');
          expect(req.headers['Authorization'], 'Bearer token-teste');
          return http.Response(
            jsonEncode({
              'usuario': {'telefone': '11912345678', 'cpf': '12345678900'},
            }),
            200,
          );
        }),
      );
    });

    testWidgets('$tipo edita, cancela, salva e retorna sem erro', (
      tester,
    ) async {
      await sessao.entrar(
        nome: 'Profissional',
        email: 'perfil@example.test',
        token: 'token-teste',
        tipoUsuario: tipo,
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => AcessoClinico(
                            perfil: tipo,
                            builder: (_) =>
                                const PerfilGeral(modoCompacto: true),
                          ),
                        ),
                      ),
                      child: const Text('Abrir perfil'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Abrir perfil'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Editar perfil'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          await tester.ensureVisible(find.text('Alterar senha'));
          await tester.tap(find.text('Alterar senha'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(TextFormField, 'Senha atual'), findsOneWidget);
          expect(find.widgetWithText(TextFormField, 'Nova senha'), findsOneWidget);
          expect(find.widgetWithText(TextFormField, 'Confirmar nova senha'), findsOneWidget);
          await tester.tap(find.text('Cancelar'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.text('Sair da conta'), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Abrir perfil'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((req) async {
          if (req.method == 'GET' && req.url.path == '/usuarios/perfil') {
            return http.Response(
              jsonEncode({
                'usuario': {
                  'nome': 'Profissional',
                  'email': 'perfil@example.test',
                },
              }),
              200,
            );
          }
          return http.Response('{"mensagem":"Rota inesperada"}', 404);
        }),
      );
    });
  }

  testWidgets('Cartão da próxima consulta mantém detalhes sem ação de confirmação', (
    tester,
  ) async {
    var abriuDetalhes = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartaoProximaConsulta(
            appointment: const ResumoConsulta(
              id: 'C1',
              type: 'Consulta geral',
              date: '24/12/2026',
              time: '09:00',
              vetName: 'Dra. Bia',
              petName: 'Mel',
              status: 'Aguardando confirmação',
            ),
            onDetailsTap: () => abriuDetalhes = true,
          ),
        ),
      ),
    );
    expect(find.text('24/12/2026'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Dra. Bia • Mel'), findsOneWidget);
    expect(find.text('Ver detalhes'), findsOneWidget);
    expect(find.text('Confirmar consulta'), findsNothing);
    expect(find.text('Aguardando confirmação'), findsNothing);
    await tester.tap(find.text('Ver detalhes'));
    expect(abriuDetalhes, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falha permite tentar novamente e dados ausentes não são inventados',
    (tester) async {
      await sessao.entrar(
        nome: 'Profissional',
        email: 'perfil@example.test',
        token: 'token-teste',
        tipoUsuario: 'ENFERMEIRO',
      );
      var chamadas = 0;
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: PerfilGeral(modoCompacto: true)),
          );
          await tester.pumpAndSettle();
          expect(find.text('Não disponível'), findsNWidgets(2));
          final tentar = find.text(
            'Não foi possível carregar os dados. Tentar novamente',
          );
          await tester.ensureVisible(tentar);
          await tester.tap(tentar);
          await tester.pumpAndSettle();
          expect(find.text('Não informado'), findsNWidgets(2));
          expect(chamadas, 2);
        },
        () => MockClient((_) async {
          chamadas++;
          return chamadas == 1
              ? http.Response('{"mensagem":"Indisponível"}', 503)
              : http.Response('{"usuario":{}}', 200);
        }),
      );
    },
  );

  testWidgets('perfil padrão preserva comportamento sem nova consulta', (
    tester,
  ) async {
    await sessao.entrar(
      nome: 'Tutor',
      email: 'tutor@example.test',
      token: 'token-tutor',
      ehTutor: true,
    );
    var chamadas = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: PerfilGeral()));
        await tester.pumpAndSettle();
        expect(chamadas, 0);
        expect(find.text('Não informado'), findsNWidgets(2));
      },
      () => MockClient((_) async {
        chamadas++;
        return http.Response('{}', 500);
      }),
    );
  });
}
