// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Cadastros de tutor/pet/funcionário e busca por CPF.
import 'package:pet_care/core/constantes/api_config.dart';

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/api_http.dart';

class SessaoCadastroExpirada implements Exception {
  const SessaoCadastroExpirada(this.token);
  final String? token;

  @override
  String toString() => 'Sua sessão expirou. Entre novamente para cadastrar.';
}

class CadastrosRecepcaoService {
  CadastrosRecepcaoService({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;
  final String baseUrl;

  static String novaSolicitacao() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Map<String, String> get _headers {
    final token = SessaoUsuario.instancia.token;
    if (token == null || token.isEmpty) {
      throw StateError('Entre na sua conta para cadastrar.');
    }
    return cabecalhosJson(token);
  }

  Future<Map<String, dynamic>> cadastrar(
    Map<String, String> dados,
    String solicitacaoId,
  ) async {
    final resposta = await http
        .post(
          Uri.parse('$baseUrl/recepcao/tutores-pets'),
          headers: _headers,
          body: jsonEncode({
            'nome': dados['nome'],
            'cpf': dados['cpf'],
            'email': dados['email'],
            'telefone': dados['telefone'],
            'solicitacaoId': solicitacaoId,
            'pet': {
              'nome': dados['pet'],
              'especie': dados['especie']?.toLowerCase(),
              'raca': dados['raca'],
              'sexo': dados['sexo']?.toLowerCase().replaceAll('ê', 'e'),
              'possuiMicrochip': dados['possuiMicrochip'] == 'true',
              'microchip': dados['possuiMicrochip'] == 'true'
                  ? dados['microchip']?.trim()
                  : '',
              if (dados['dataNascimento']?.isNotEmpty == true)
                'dataNascimento': dados['dataNascimento']!.substring(0, 10),
            },
          }),
        )
        .timeout(const Duration(seconds: 30));
    final resultado = processarRespostaJson(resposta);
    if (resultado is! Map ||
        resultado['tutorId'] is! String ||
        resultado['petId'] is! String) {
      throw const FormatException('Resposta de cadastro inválida.');
    }
    return Map<String, dynamic>.from(resultado);
  }

  Future<Map<String, dynamic>> cadastrarFuncionario(
    Map<String, String> dados,
    String solicitacaoId,
  ) async {
    final token = SessaoUsuario.instancia.token;
    final resposta = await http
        .post(
          Uri.parse('$baseUrl/recepcao/funcionarios'),
          headers: _headers,
          body: jsonEncode({
            ...dados,
            'tipo': {
              'Secretária': 'SECRETARIA',
              'Enfermeiro': 'ENFERMEIRO',
              'Veterinário': 'VETERINARIO',
            }[dados['cargo']],
            'solicitacaoId': solicitacaoId,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (SessaoUsuario.instancia.token != token) {
      throw StateError('A sessão mudou. Entre novamente.');
    }
    if (resposta.statusCode == 401) {
      throw SessaoCadastroExpirada(token);
    }
    final resultado = processarRespostaJson(resposta);
    if (resultado is! Map || resultado['funcionarioId'] is! String) {
      throw const FormatException('Resposta de cadastro inválida.');
    }
    return Map<String, dynamic>.from(resultado);
  }

  Future<Map<String, dynamic>?> buscarTutor(String cpf) async {
    final resposta = await http
        .get(
          Uri.parse('$baseUrl/recepcao/tutores')
              .replace(queryParameters: {'cpf': cpf}),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 20));
    if (resposta.statusCode == 404) return null;
    return Map<String, dynamic>.from(processarRespostaJson(resposta) as Map);
  }
}
