
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class CampanhasService {
  final String baseUrl;
  final String token;

  CampanhasService({
    required this.baseUrl,
    required this.token,
  });

  factory CampanhasService.autenticado({
    required String baseUrl,
  }) {
    final token = SessaoUsuario.instancia.token;

    if (token == null || token.isEmpty) {
      throw StateError(
        'Você precisa estar logado para consultar as campanhas.',
      );
    }

    return CampanhasService(
      baseUrl: baseUrl,
      token: token,
    );
  }

  Future<List<dynamic>> listarCampanhas() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/campanhas'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode != 200) {
      throw Exception(
        dados is Map
            ? dados['mensagem'] ?? 'Erro ao buscar campanhas.'
            : 'Erro ao buscar campanhas.',
      );
    }

    return dados['campanhas'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> buscarCampanha(String id) async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/campanhas/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode != 200) {
      throw Exception(
        dados is Map
            ? dados['mensagem'] ?? 'Erro ao buscar campanha.'
            : 'Erro ao buscar campanha.',
      );
    }

    return Map<String, dynamic>.from(dados['campanha'] as Map);
  }
}
