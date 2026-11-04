
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';

class AuthService {
  AuthService._();

  static final AuthService instancia = AuthService._();

  static const String _baseUrl = 'http://localhost:3000';

  final SessaoUsuario _sessao = SessaoUsuario.instancia;

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    try {
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
        throw Exception('O servidor não retornou o token.');
      }

      final respostaPerfil = await http
          .get(
        Uri.parse('$_baseUrl/usuarios/perfil'),
        headers: {
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

      final usuario = dadosPerfil['usuario'];

      if (usuario is! Map<String, dynamic>) {
        throw Exception('O perfil retornado pelo servidor é inválido.');
      }

      final nome = usuario['nome']?.toString();
      final emailUsuario = usuario['email']?.toString();

      if (nome == null || emailUsuario == null) {
        throw Exception('Os dados do perfil estão incompletos.');
      }

      await _sessao.entrar(
        nome: nome,
        email: emailUsuario,
        token: token.toString(),
        ehTutor: dadosPerfil['ehTutor'] == true,
      );
    } on http.ClientException catch (e) {
      debugPrint('ERRO DE CONEXÃO: ${e.message}');
      throw Exception(
        'Falha na comunicação com o servidor: ${e.message}',
      );
    } on FormatException catch (e) {
      debugPrint('ERRO DE FORMATO: $e');
      throw Exception('O servidor retornou uma resposta inválida.');
    } on TimeoutException {
      throw Exception('O servidor demorou demais para responder.');
    }
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
    required String confirmarSenha,
    required bool possuiPet,
    Map<String, String>? pet,
  }) async {
    try {
      final resposta = await http
          .post(
        Uri.parse('$_baseUrl/usuarios/cadastro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome.trim(),
          'email': email.trim().toLowerCase(),
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          'senha': senha,
          'confirmarSenha': confirmarSenha,
          'possuiPet': possuiPet,
          if (possuiPet) 'pet': pet,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 201) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível concluir o cadastro.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('ERRO DE CONEXÃO NO CADASTRO: ${e.message}');
      throw Exception('Falha na comunicação com o servidor.');
    } on FormatException catch (e) {
      debugPrint('ERRO DE FORMATO NO CADASTRO: $e');
      throw Exception('O servidor retornou uma resposta inválida.');
    } on TimeoutException {
      throw Exception('O servidor demorou demais para responder.');
    }
  }

  // =====================================================
  // CADASTRAR PET
  // =====================================================

  Future<void> cadastrarPet({
    required String nome,
    required String especie,
    required String raca,
    required String sexo,
    required String dataNascimento,
  }) async {
    try {
      final token = _sessao.token;

      if (token == null || token.isEmpty) {
        throw Exception('Sua sessão expirou. Faça login novamente.');
      }

      final resposta = await http
          .post(
        Uri.parse('$_baseUrl/pets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nome': nome.trim(),
          'especie': especie.trim(),
          'raca': raca.trim(),
          'sexo': sexo.trim(),
          'dataNascimento': dataNascimento,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 201) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível cadastrar o pet.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('ERRO DE CONEXÃO AO CADASTRAR PET: ${e.message}');
      throw Exception('Falha na comunicação com o servidor.');
    } on FormatException catch (e) {
      debugPrint('ERRO DE FORMATO AO CADASTRAR PET: $e');
      throw Exception('O servidor retornou uma resposta inválida.');
    } on TimeoutException {
      throw Exception('O servidor demorou demais para responder.');
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
