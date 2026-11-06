
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class DoacoesService {
  final String baseUrl;
  final String token;

  DoacoesService({
    required this.baseUrl,
    required this.token,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  factory DoacoesService.autenticado({
    required String baseUrl,
  }) {
    final token = SessaoUsuario.instancia.token;

    if (token == null || token.isEmpty) {
      throw StateError(
        'Você precisa estar logado para realizar doações.',
      );
    }

    return DoacoesService(
      baseUrl: baseUrl,
      token: token,
    );
  }

  dynamic _processarResposta(http.Response resposta) {
    dynamic conteudo;

    try {
      conteudo = jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (resposta.statusCode >= 200 &&
        resposta.statusCode < 300) {
      return conteudo;
    }

    final mensagem = conteudo is Map
        ? conteudo['mensagem']
        : null;

    throw Exception(
      mensagem is String
          ? mensagem
          : 'Erro ao comunicar com o servidor.',
    );
  }

  Future<Map<String, dynamic>> criarDoacao({
    required String campanhaId,
    required double valor,
    required String metodoPagamento,
  }) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl/doacoes'),
      headers: _headers,
      body: jsonEncode({
        'campanhaId': campanhaId,
        'valor': valor,
        'metodoPagamento': metodoPagamento,
      }),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<Map<String, dynamic>> confirmarDoacao({
    required String doacaoId,
  }) async {
    final resposta = await http.patch(
      Uri.parse('$baseUrl/doacoes/$doacaoId/confirmar'),
      headers: _headers,
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<List<dynamic>> listarDoacoes({
    required String campanhaId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/doacoes',
    ).replace(queryParameters: {
      'campanhaId': campanhaId,
    });

    final resposta = await http.get(
      uri,
      headers: _headers,
    );

    final conteudo = _processarResposta(resposta);

    return conteudo['doacoes'] as List<dynamic>;
  }
}
