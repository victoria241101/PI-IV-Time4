
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class AuthService {
  AuthService._();

  static final AuthService instancia = AuthService._();

  // Endereço do backend durante os testes no Chrome.
  static const String _baseUrl = 'http://localhost:3000';

  final SessaoUsuario _sessao = SessaoUsuario.instancia;

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    try {
      // 1. Realiza o login.
      final respostaLogin = await http
          .post(
        Uri.parse('$_baseUrl/usuarios/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'senha': senha,
        }),
      )
          .timeout(const Duration(seconds: 15));

      final dadosLogin = _decodificarResposta(respostaLogin);

      if (respostaLogin.statusCode != 200) {
        throw Exception(
          dadosLogin['mensagem'] ?? 'Não foi possível realizar o login.',
        );
      }

      final token = dadosLogin['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('O servidor não retornou o token de autenticação.');
      }

      // 2. Consulta o perfil utilizando o JWT recebido.
      final respostaPerfil = await http
          .get(
        Uri.parse('$_baseUrl/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 15));

      final dadosPerfil = _decodificarResposta(respostaPerfil);

      if (respostaPerfil.statusCode != 200) {
        throw Exception(
          dadosPerfil['mensagem'] ?? 'Não foi possível carregar o perfil.',
        );
      }

      // 3. Extrai os dados do usuário.
      final usuario = dadosPerfil['usuario'];

      if (usuario == null || usuario is! Map<String, dynamic>) {
        throw Exception('O servidor retornou um perfil inválido.');
      }

      final nome = usuario['nome']?.toString();
      final emailUsuario = usuario['email']?.toString();

      if (nome == null || emailUsuario == null) {
        throw Exception('Os dados do perfil estão incompletos.');
      }

      final ehTutor = dadosPerfil['ehTutor'] == true;

      // 4. Salva o token e os dados na sessão.
      await _sessao.entrar(
        nome: nome,
        email: emailUsuario,
        token: token.toString(),
        ehTutor: ehTutor,
      );
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique se o backend está ativo.',
      );
    } on FormatException {
      throw Exception('O servidor retornou uma resposta inválida.');
    }
  }

  Map<String, dynamic> _decodificarResposta(http.Response resposta) {
    final dados = jsonDecode(resposta.body);

    if (dados is! Map<String, dynamic>) {
      throw const FormatException('Resposta inválida do servidor.');
    }

    return dados;
  }
}
