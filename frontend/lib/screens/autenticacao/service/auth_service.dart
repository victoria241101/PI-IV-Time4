
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/constantes/api_config.dart';

class AuthService {
  AuthService._();

  static final AuthService instancia = AuthService._();

  final SessaoUsuario _sessao = SessaoUsuario.instancia;

  // =====================================================
  // LOGIN
  // =====================================================

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    try {
      final respostaLogin = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/login'),
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
          dadosLogin['mensagem'] ??
              'Não foi possível realizar o login.',
        );
      }

      final token = dadosLogin['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('O servidor não retornou o token.');
      }

      final respostaPerfil = await http
          .get(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/perfil'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 15));

      final dadosPerfil = _decodificarResposta(respostaPerfil);

      if (respostaPerfil.statusCode != 200) {
        throw Exception(
          dadosPerfil['mensagem'] ??
              'Não foi possível carregar o perfil.',
        );
      }

      final usuario = dadosPerfil['usuario'];

      if (usuario is! Map<String, dynamic>) {
        throw Exception(
          'O perfil retornado pelo servidor é inválido.',
        );
      }

      final nome = usuario['nome']?.toString();
      final emailUsuario = usuario['email']?.toString();
      final tipoUsuario = usuario['tipo']?.toString().toUpperCase();

      if (nome == null ||
          emailUsuario == null ||
          tipoUsuario == null) {
        throw Exception('Os dados do perfil estão incompletos.');
      }

      const tiposPermitidos = {
        'USUARIO',
        'VETERINARIO',
        'ENFERMEIRO',
        'SECRETARIA',
      };

      if (!tiposPermitidos.contains(tipoUsuario)) {
        throw Exception(
          'Tipo de usuário não reconhecido: $tipoUsuario',
        );
      }

      await _sessao.entrar(
        nome: nome,
        email: emailUsuario,
        token: token.toString(),
        tipoUsuario: tipoUsuario,
        ehTutor: tipoUsuario == 'USUARIO' &&
            dadosPerfil['ehTutor'] == true,
      );
    } on http.ClientException catch (e) {
      debugPrint('ERRO DE CONEXÃO: ${e.message}');
      throw Exception(
        'Falha na comunicação com o servidor: ${e.message}',
      );
    } on FormatException catch (e) {
      debugPrint('ERRO DE FORMATO: $e');
      throw Exception(
        'O servidor retornou uma resposta inválida.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou demais para responder.',
      );
    }
  }

  // =====================================================
  // CADASTRO DE USUÁRIO E PRIMEIRO PET
  // =====================================================

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
    required String confirmarSenha,
    required bool possuiPet,
    Map<String, dynamic>? pet,
  }) async {
    try {
      // Validação da ficha do primeiro pet.
      // Essa validação só se aplica quando o usuário
      // informa que já possui um pet.

      if (possuiPet) {
        if (pet == null) {
          throw Exception(
            'Preencha todos os dados obrigatórios do pet.',
          );
        }

        const camposObrigatorios = [
          'nome',
          'especie',
          'raca',
          'sexo',
          'dataNascimento',
        ];

        for (final campo in camposObrigatorios) {
          final valor = pet[campo];

          if (valor == null || valor.toString().trim().isEmpty) {
            throw Exception(
              'Preencha todos os dados obrigatórios do pet.',
            );
          }
        }

        // Validação do peso.
        final peso = pet['peso'];

        if (peso is! num || !peso.isFinite || peso <= 0) {
          throw Exception(
            'Informe um peso válido para o pet.',
          );
        }

        // A pessoa precisa responder Sim ou Não.
        // Não existe campo de número de microchip.
        if (pet['possuiMicrochip'] is! bool) {
          throw Exception(
            'Informe se o pet possui microchip.',
          );
        }

        // Validação da data de nascimento.
        final dataNascimento = pet['dataNascimento'];

        if (dataNascimento is! String ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$')
                .hasMatch(dataNascimento)) {
          throw Exception(
            'Informe uma data de nascimento válida.',
          );
        }

        final dataConvertida = DateTime.tryParse(dataNascimento);

        if (dataConvertida == null ||
            dataConvertida.year.toString().padLeft(4, '0') !=
                dataNascimento.substring(0, 4) ||
            dataConvertida.month.toString().padLeft(2, '0') !=
                dataNascimento.substring(5, 7) ||
            dataConvertida.day.toString().padLeft(2, '0') !=
                dataNascimento.substring(8, 10)) {
          throw Exception(
            'Informe uma data de nascimento válida.',
          );
        }

        final hoje = DateTime.now();
        final dataHoje = DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        );

        if (dataConvertida.isAfter(dataHoje)) {
          throw Exception(
            'A data de nascimento não pode ser futura.',
          );
        }
      }

      final resposta = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/cadastro'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nome': nome.trim(),
          'email': email.trim().toLowerCase(),
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
          'senha': senha,
          'confirmarSenha': confirmarSenha,
          'possuiPet': possuiPet,
          if (possuiPet)
            'pet': {
              'nome': pet!['nome'].toString().trim(),
              'especie': pet['especie'].toString().trim(),
              'raca': pet['raca'].toString().trim(),
              'sexo': pet['sexo'].toString().trim(),
              'dataNascimento': pet['dataNascimento'],
              'peso': (pet['peso'] as num).toDouble(),
              'possuiMicrochip': pet['possuiMicrochip'],
            },
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 201) {
        throw Exception(
          dados['mensagem'] ??
              'Não foi possível concluir o cadastro.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('ERRO DE CONEXÃO NO CADASTRO: ${e.message}');
      throw Exception(
        'Falha na comunicação com o servidor.',
      );
    } on FormatException {
      throw Exception(
        'O servidor retornou uma resposta inválida.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou demais para responder.',
      );
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
    required double peso,
    required bool possuiMicrochip,
  }) async {
    try {
      final token = _sessao.token;

      if (token == null || token.isEmpty) {
        throw Exception(
          'Sua sessão expirou. Faça login novamente.',
        );
      }

      // Validar campos obrigatórios.
      if (nome.trim().isEmpty ||
          especie.trim().isEmpty ||
          raca.trim().isEmpty ||
          sexo.trim().isEmpty ||
          dataNascimento.trim().isEmpty) {
        throw Exception(
          'Preencha todos os campos do pet.',
        );
      }

      // Validar peso.
      if (!peso.isFinite || peso <= 0) {
        throw Exception(
          'Informe um peso válido para o pet.',
        );
      }

      // Validar formato da data.
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$')
          .hasMatch(dataNascimento)) {
        throw Exception(
          'Informe uma data de nascimento válida.',
        );
      }

      final data = DateTime.tryParse(dataNascimento);

      if (data == null ||
          data.year.toString().padLeft(4, '0') !=
              dataNascimento.substring(0, 4) ||
          data.month.toString().padLeft(2, '0') !=
              dataNascimento.substring(5, 7) ||
          data.day.toString().padLeft(2, '0') !=
              dataNascimento.substring(8, 10)) {
        throw Exception(
          'Informe uma data de nascimento válida.',
        );
      }

      final hoje = DateTime.now();
      final dataHoje = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      );

      if (data.isAfter(dataHoje)) {
        throw Exception(
          'A data de nascimento não pode ser futura.',
        );
      }

      final resposta = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/pets'),
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
          'peso': peso,
          'possuiMicrochip': possuiMicrochip,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 201) {
        throw Exception(
          dados['mensagem'] ??
              'Não foi possível cadastrar o pet.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint(
        'ERRO DE CONEXÃO AO CADASTRAR PET: ${e.message}',
      );
      throw Exception(
        'Falha na comunicação com o servidor.',
      );
    } on FormatException {
      throw Exception(
        'O servidor retornou uma resposta inválida.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou demais para responder.',
      );
    }
  }

  // =====================================================
  // RECUPERAÇÃO DE SENHA
  // =====================================================

  Future<void> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    try {
      final resposta = await http
          .post(
        Uri.parse(
          '${ApiConfig.baseUrl}/usuarios/esqueci-senha',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 200) {
        throw Exception(
          dados['mensagem'] ??
              'Não foi possível solicitar a recuperação de senha.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint(
        'ERRO AO SOLICITAR RECUPERAÇÃO: $e',
      );
      throw Exception(
        'Falha na comunicação com o servidor.',
      );
    } on FormatException {
      throw Exception(
        'O servidor retornou uma resposta inválida.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou demais para responder.',
      );
    }
  }

  // =====================================================
  // REDEFINIR SENHA
  // =====================================================

  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    try {
      final resposta = await http
          .post(
        Uri.parse(
          '${ApiConfig.baseUrl}/usuarios/redefinir-senha',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'novaSenha': novaSenha,
          'confirmarSenha': confirmarSenha,
        }),
      )
          .timeout(const Duration(seconds: 20));

      final dados = _decodificarResposta(resposta);

      if (resposta.statusCode != 200) {
        throw Exception(
          dados['mensagem'] ??
              'Não foi possível redefinir sua senha.',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('ERRO AO REDEFINIR SENHA: ${e.message}');
      throw Exception(
        'Falha na comunicação com o servidor.',
      );
    } on FormatException {
      throw Exception(
        'O servidor retornou uma resposta inválida.',
      );
    } on TimeoutException {
      throw Exception(
        'O servidor demorou demais para responder.',
      );
    }
  }

  // =====================================================
  // DECODIFICAÇÃO DE RESPOSTAS
  // =====================================================

  Map<String, dynamic> _decodificarResposta(
      http.Response resposta,
      ) {
    final dados = jsonDecode(resposta.body);

    if (dados is! Map<String, dynamic>) {
      throw const FormatException(
        'Resposta inválida do servidor.',
      );
    }

    return dados;
  }
}
