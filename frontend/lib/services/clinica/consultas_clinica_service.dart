import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/api_http.dart';
import 'package:pet_care/services/agendamentos_service.dart';

import 'consulta_clinica_api.dart';

/// Adaptador exclusivo dos fluxos clínicos. A autorização continua na API.
class ConsultasClinicaService {
  ConsultasClinicaService({
    this.baseUrl = apiBaseUrl,
    String? Function()? obterToken,
  }) : _obterToken = obterToken ?? (() => SessaoUsuario.instancia.token);
  final String baseUrl;
  final String? Function() _obterToken;

  String get _token {
    final token = _obterToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Entre na sua conta para acessar a clínica.');
    }
    return token;
  }

  /// Reutiliza disponibilidade, criação, remarcação e cancelamento existentes.
  AgendamentosService get agendamentos =>
      AgendamentosService(baseUrl: _uri('').toString(), token: _token);

  Uri _uri(String caminho) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$caminho');

  Future<List<ConsultaClinicaApi>> listarDia(DateTime data) async {
    final dia =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    final token = _token;
    final consultas = <ConsultaClinicaApi>[];
    for (var pagina = 1; pagina <= 9999; pagina++) {
      if (_token != token) {
        throw StateError('A sessão mudou. Atualize a agenda.');
      }
      final resposta = await http
          .get(
            _uri('/consultas')
                .replace(queryParameters: {'data': dia, 'pagina': '$pagina'}),
            headers: cabecalhosJson(token),
          )
          .timeout(const Duration(seconds: 20));
      if (_token != token) {
        throw StateError('A sessão mudou. Atualize a agenda.');
      }
      final dados = processarRespostaJson(resposta);
      if (dados is! Map ||
          dados['consultas'] is! List ||
          dados['pagina'] != pagina ||
          dados['temMais'] is! bool) {
        throw const FormatException('Resposta de agenda inválida.');
      }
      for (final item in dados['consultas'] as List) {
        if (item is! Map) throw const FormatException('Consulta inválida.');
        consultas.add(
          ConsultaClinicaApi.fromJson(Map<String, dynamic>.from(item)),
        );
      }
      if (dados['temMais'] == false) return consultas;
    }
    throw StateError('Limite de páginas da agenda excedido.');
  }

  Future<Map<String, dynamic>> _enviar(
    String id,
    String acao, {
    Map<String, dynamic>? dados,
  }) async {
    if (id.trim().isEmpty) throw ArgumentError('Informe o ID da consulta.');
    final uri = _uri('/consultas/${Uri.encodeComponent(id)}/$acao');
    final headers = cabecalhosJson(_token);
    // Nenhum reenvio automático de operações que alteram dados.
    final resposta =
        await (dados == null
                ? http.patch(uri, headers: headers)
                : http.post(uri, headers: headers, body: jsonEncode(dados)))
            .timeout(const Duration(seconds: 20));
    final conteudo = processarRespostaJson(resposta);
    if (conteudo is! Map) {
      throw const FormatException('Resposta clínica inválida.');
    }
    return Map<String, dynamic>.from(conteudo);
  }

  Future<void> confirmarChegada(String id) async {
    await _enviar(id, 'confirmar-chegada');
  }

  Future<void> iniciarTriagem(String id) async {
    await _enviar(id, 'iniciar-triagem');
  }

  Future<void> finalizarTriagem(String id) async {
    await _enviar(id, 'finalizar-triagem');
  }

  Future<void> iniciarAtendimento(String id) async {
    await _enviar(id, 'iniciar-atendimento');
  }

  Future<void> finalizarAtendimento(String id) async {
    await _enviar(id, 'finalizar-atendimento');
  }

  Future<void> salvarTriagem(
    String id, {
    required double peso,
    required double temperatura,
    required String sintomas,
    String observacoes = '',
  }) async {
    await _enviar(
      id,
      'triagem',
      dados: {
        'peso': peso,
        'temperatura': temperatura,
        'sintomas': sintomas,
        'observacoes': observacoes,
      },
    );
  }

  Future<void> salvarAtendimento(
    String id, {
    required String anamnese,
    required String exameFisico,
    required String diagnostico,
    required String prognostico,
    required String tratamento,
    String observacoes = '',
    String? codigoICDVet,
  }) async {
    await _enviar(
      id,
      'atendimento',
      dados: {
        'anamnese': anamnese,
        'exameFisico': exameFisico,
        'diagnostico': diagnostico,
        'prognostico': prognostico,
        'tratamento': tratamento,
        'observacoes': observacoes,
        'codigoICDVet': ?codigoICDVet,
      },
    );
  }
}
