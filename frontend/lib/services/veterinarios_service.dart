
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class VeterinariosService {
  final String baseUrl;

  VeterinariosService({
    required this.baseUrl,
  });

  Future<List<Map<String, dynamic>>> listarVeterinarios() async {
    // Token de teste utilizado apenas durante o desenvolvimento.
    final token = SessaoUsuario.instancia.token ??
        const String.fromEnvironment('TOKEN_TESTE');

    if (token.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }

    final resposta = await http.get(
      Uri.parse('$baseUrl/veterinarios'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Não foi possível carregar os veterinários.',
      );
    }

    final dados = jsonDecode(
      utf8.decode(resposta.bodyBytes),
    ) as Map<String, dynamic>;

    final lista = dados['veterinarios'] as List<dynamic>;

    return lista
        .map((vet) => Map<String, dynamic>.from(vet as Map))
        .toList();
  }
}
