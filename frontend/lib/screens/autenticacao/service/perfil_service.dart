import 'dart:convert';
import 'package:http/http.dart' as http;
class PerfilService {
  final String baseUrl;
  final String token;

  PerfilService({
    required this.baseUrl,
    required this.token,
  });

  factory PerfilService.autenticado({
    required String baseUrl,
    required String token,
  }) {
    if (token.isEmpty) {
      throw StateError('Você precisa estar logado.');
    }

    return PerfilService(
      baseUrl: baseUrl,
      token: token,
    );
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

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

    final mensagem =
    conteudo is Map ? conteudo['mensagem'] : null;

    throw Exception(
      mensagem is String
          ? mensagem
          : 'Erro ao comunicar com o servidor.',
    );
  }

  Future<Map<String, dynamic>> atualizarPerfil({
    required String nome,
    required String email,
  }) async {
    final resposta = await http.patch(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome.trim(),
        'email': email.trim(),
      }),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<Map<String, dynamic>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    final resposta = await http.patch(
      Uri.parse('$baseUrl/usuarios/alterar-senha'),
      headers: _headers,
      body: jsonEncode({
        'senhaAtual': senhaAtual,
        'novaSenha': novaSenha,
        'confirmarSenha': confirmarSenha,
      }),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }


  Future<Map<String, dynamic>> confirmarAlteracaoPerfil({
    required String token,
  }) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl/usuarios/confirmar-alteracao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<Map<String, dynamic>> confirmarAlteracaoSenha({
    required String token,
  }) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl/usuarios/confirmar-alteracao-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }

  Future<Map<String, dynamic>> buscarPerfil() async {
    final resposta = await http.get(
      Uri.parse('$baseUrl/usuarios/perfil'),
      headers: _headers,
    );

    return Map<String, dynamic>.from(
      _processarResposta(resposta) as Map,
    );
  }
}