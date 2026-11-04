import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class AgendamentosService {
  final String baseUrl;
  final String token;

  AgendamentosService({
    required this.baseUrl,
    required this.token,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  factory AgendamentosService.autenticado({
    required String baseUrl,
  }) {
    final token = SessaoUsuario.instancia.token;

    if (token == null || token.isEmpty) {
      throw StateError(
        'Você precisa estar logado para realizar agendamentos.',
      );
    }

    return AgendamentosService(
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

  Future<List<String>> consultarDisponibilidade({
    required String veterinarioId,
    required DateTime data,
    int duracaoMinutos = 30,
  }) async {
    final dataFormatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '$baseUrl/agendamentos/disponibilidade',
    ).replace(queryParameters: {
      'veterinarioId': veterinarioId,
      'data': dataFormatada,
      'duracaoMinutos': duracaoMinutos.toString(),
    });

    final resposta = await http.get(uri, headers: _headers);
    final conteudo = _processarResposta(resposta);

    return (conteudo['horarios'] as List)
      .map((horario) {
        final valor = horario.toString();
        return valor.substring(11, 16);
      })
      .toList();
  }

  Future<Map<String, dynamic>> criarAgendamento({
    required String petId,
    required String veterinarioId,
    required DateTime data,
    required String horario,
    required String tipo,
    int duracaoMinutos = 30,
    String observacoes = '',
  }) async {
    final dataHora =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}'
        'T$horario:00';

    final resposta = await http.post(
      Uri.parse('$baseUrl/agendamentos'),
      headers: _headers,
      body: jsonEncode({
        'petId': petId,
        'veterinarioId': veterinarioId,
        'dataHora': dataHora,
        'duracaoMinutos': duracaoMinutos,
        'tipo': tipo,
        'observacoes': observacoes,
      }),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<List<dynamic>> listarAgendamentos() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/agendamentos'),
      headers: _headers,
    );

    final conteudo = _processarResposta(resposta);
    return conteudo['agendamentos'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> remarcarAgendamento({
    required String consultaId,
    required String dataHora,
    required int duracaoMinutos,
  }) async {
    final resposta = await http.patch(
      Uri.parse(
        '$baseUrl/agendamentos/$consultaId/remarcar',
      ),
      headers: _headers,
      body: jsonEncode({
        'dataHora': dataHora,
        'duracaoMinutos': duracaoMinutos,
      }),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<Map<String, dynamic>> cancelarAgendamento({
    required String consultaId,
  }) async {
    final resposta = await http.patch(
      Uri.parse(
        '$baseUrl/agendamentos/$consultaId/cancelar',
      ),
      headers: _headers,
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  

}
