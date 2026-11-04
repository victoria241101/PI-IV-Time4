
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class PetsService {
  final String baseUrl;

  PetsService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> listarPets() async {
    // Usa a sessão normal ou o token temporário de teste.
    final token = SessaoUsuario.instancia.token ??
        const String.fromEnvironment('TOKEN_TESTE');

    if (token.isEmpty) {
      throw StateError(
        'Você precisa estar logado para consultar seus pets.',
      );
    }

    final resposta = await http.get(
      Uri.parse('$baseUrl/pets'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar os pets. '
        'Código: ${resposta.statusCode}',
      );
    }

    final dados = jsonDecode(
      utf8.decode(resposta.bodyBytes),
    ) as Map<String, dynamic>;

    final pets = dados['pets'] as List<dynamic>;

    return pets
        .map((pet) => Map<String, dynamic>.from(pet as Map))
        .toList();
  }
}
