import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pet_care/services/api_http.dart';

void main() {
  test('UTF-8 e resposta de sucesso', () {
    expect(
      processarRespostaJson(
        http.Response.bytes(utf8.encode('{"nome":"João"}'), 200),
      ),
      {'nome': 'João'},
    );
  });
  for (final codigo in [400, 401, 403, 500]) {
    test('Preserva mensagem HTTP $codigo', () {
      expect(
        () => processarRespostaJson(
          http.Response('{"mensagem":"Falha controlada"}', codigo),
        ),
        throwsA(predicate((e) => e.toString().contains('Falha controlada'))),
      );
    });
  }
  test('JSON inválido e erro sem mensagem', () {
    expect(
      () => processarRespostaJson(http.Response('<html>', 502)),
      throwsA(predicate((e) => e.toString().contains('Resposta inválida'))),
    );
    expect(
      () => processarRespostaJson(http.Response('{}', 500)),
      throwsA(predicate((e) => e.toString().contains('Erro ao comunicar'))),
    );
  });
  test('Cabeçalhos incluem token quando fornecido', () {
    expect(cabecalhosJson('token-teste'), {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer token-teste',
    });
  });
  test('Cabeçalhos sem token não incluem autenticação', () {
    for (final token in [null, '']) {
      expect(cabecalhosJson(token), {'Content-Type': 'application/json'});
    }
  });
  test('Endereço respeita a configuração de compilação', () {
    expect(
      apiBaseUrl,
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
    );
  });
}
