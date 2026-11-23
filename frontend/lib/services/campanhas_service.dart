
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class CampanhasService {
  final String baseUrl;
  final String? token;

  CampanhasService({
    required this.baseUrl,
    this.token,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  factory CampanhasService.criar({
    required String baseUrl,
  }) {
    return CampanhasService(
      baseUrl: baseUrl,
      token: SessaoUsuario.instancia.token,
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

  Future<List<dynamic>> listarCampanhas({
    String? status,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/campanhas',
    ).replace(
      queryParameters: status == null
          ? null
          : {'status': status},
    );

    final resposta = await http.get(
      uri,
      headers: _headers,
    );

    final conteudo = _processarResposta(resposta);

    return conteudo['campanhas'] as List<dynamic>;
  }

  Future<String> criarCampanha({
    required String titulo,
    required String descricao,
    required double metaValor,
    String? imagemCapa,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    if (token == null || token!.isEmpty) {
      throw StateError('Entre como secretária para cadastrar uma campanha.');
    }

    final resposta = await http.post(
      Uri.parse('$baseUrl/campanhas'),
      headers: _headers,
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'metaValor': metaValor,
        'imagemCapa': imagemCapa,
        'dataInicio': dataInicio.toIso8601String(),
        'dataFim': dataFim.toIso8601String(),
      }),
    );
    final conteudo = _processarResposta(resposta);
    final campanhaId = conteudo is Map ? conteudo['campanhaId'] : null;
    if (campanhaId is! String || campanhaId.isEmpty) {
      throw const FormatException('Resposta de cadastro da campanha inválida.');
    }
    return campanhaId;
  }

  Future<Map<String, dynamic>> buscarCampanha({
    required String campanhaId,
  }) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/campanhas/$campanhaId'),
      headers: _headers,
    );

    final conteudo = _processarResposta(resposta);

    return Map<String, dynamic>.from(
      conteudo['campanha'] as Map,
    );
  }
}
