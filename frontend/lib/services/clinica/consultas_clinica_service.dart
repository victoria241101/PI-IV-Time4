// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Chamadas de agenda, chegada, triagem, atendimento, prescrições, exames e internações.

import 'package:pet_care/core/constantes/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/services/api_http.dart';
import 'package:pet_care/services/agendamentos_service.dart';

import 'consulta_clinica_api.dart';

import 'package:pet_care/modelos/prontuario_compartilhado.dart';

/// Adaptador exclusivo dos fluxos clínicos. A autorização continua na API.
class ConsultasClinicaService {
  ConsultasClinicaService({String? baseUrl, String? Function()? obterToken})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _obterToken = obterToken ?? (() => SessaoUsuario.instancia.token);
  final String baseUrl;
  final String? Function() _obterToken;

  // Todas as chamadas exigem sessão; o backend continua validando o perfil.
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

  // Centraliza GET, POST e PATCH de internação e detecta troca de sessão.
  Future<Map<String, dynamic>> _internacaoHttp(String caminho, {Map<String, dynamic>? corpo, bool criar = false}) async {
    final token = _token;
    final uri = _uri(caminho);
    final headers = cabecalhosJson(token);
    final resposta = await (corpo == null
        ? http.get(uri, headers: headers)
        : criar ? http.post(uri, headers: headers, body: jsonEncode(corpo))
        : http.patch(uri, headers: headers, body: jsonEncode(corpo)))
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');

    final dados = processarRespostaJson(resposta);
    if (dados is! Map) throw const FormatException('Resposta de internação inválida.');
    return Map<String, dynamic>.from(dados);
  }

  Future<List<Map<String, dynamic>>> listarInternacoes({String? petId}) async {
    final dados = await _internacaoHttp(petId == null ? '/internacoes' : '/internacoes/pet/${Uri.encodeComponent(petId)}');
    if (dados['internacoes'] is! List) throw const FormatException('Lista de internações inválida.');
    return (dados['internacoes'] as List).map((e) {
      if (e is! Map || e['_id'] is! String || e['petId'] is! String ||
          (petId != null && e['petId'] != petId)) {
        throw const FormatException('Internação sem vínculo válido.');
      }
      return Map<String, dynamic>.from(e);
    }).toList();
  }

  Future<String> criarInternacao({required String petId, required String motivo, required String leito, String observacoes = ''}) async {
    if ([petId, motivo, leito].any((v) => v.trim().isEmpty)) throw const FormatException('Informe o pet, o motivo e o leito.');
    final dados = await _internacaoHttp('/internacoes', criar: true, corpo: {
      'petId': petId, 'motivo': motivo.trim(), 'leito': leito.trim(), 'observacoes': observacoes.trim(),
    });
    final id = dados['internacaoId'];
    if (id is! String || id.isEmpty) throw const FormatException('Internação sem identificador.');
    return id;
  }

  Future<void> salvarProntuarioInternacao(ProntuarioCompartilhado prontuario) async {
    final id = prontuario.internacaoId;
    if (id == null) throw StateError('Internação não identificada.');
    await _internacaoHttp('/internacoes/${Uri.encodeComponent(id)}/prontuario', corpo: {
      'versao': prontuario.versaoInternacao, 'prontuario': prontuario.dadosInternacao(),
    });
  }

  Future<void> darAltaInternacao(String id) async {
    await _internacaoHttp('/internacoes/${Uri.encodeComponent(id)}/alta', corpo: {});
  }

  Future<List<ConsultaClinicaApi>> listarDia(DateTime data) async {
    final dia =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    final token = _token;
    final consultas = <ConsultaClinicaApi>[];
    // Percorre todas as páginas até a API informar que terminou.
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
        throw StateError('A sessão mudou. Atualize a tela.');
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

  // Operações de mudança não são reenviadas automaticamente pelo cliente.
  Future<Map<String, dynamic>> _enviar(
    String id,
    String acao, {
    Map<String, dynamic>? dados,
  }) async {
    if (id.trim().isEmpty) throw ArgumentError('Informe o ID da consulta.');
    final uri = _uri('/consultas/${Uri.encodeComponent(id)}/$acao');
    final token = _token;
    final headers = cabecalhosJson(token);
    // Nenhum reenvio automático de operações que alteram dados.
    final resposta =
        await (dados == null
                ? http.patch(uri, headers: headers)
                : http.post(uri, headers: headers, body: jsonEncode(dados)))
            .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final conteudo = processarRespostaJson(resposta);
    if (conteudo is! Map) {
      throw const FormatException('Resposta clínica inválida.');
    }
    return Map<String, dynamic>.from(conteudo);
  }

  Future<Map<String, dynamic>> lerProntuario(String id) async {
    final token = _token;
    final resposta = await http
        .get(
          _uri('/consultas/${Uri.encodeComponent(id)}/dados-clinicos'),
          headers: cabecalhosJson(token),
        )
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final dados = processarRespostaJson(resposta);
    if (dados is! Map ||
        !dados.containsKey('triagem') ||
        !dados.containsKey('atendimento')) {
      throw const FormatException('Resposta de prontuário inválida.');
    }
    final atendimento = dados['atendimento'];
    if (atendimento != null &&
        (atendimento is! Map ||
            atendimento['_id'] is! String ||
            (atendimento['_id'] as String).trim().isEmpty)) {
      throw const FormatException('Atendimento sem identificador válido.');
    }
    return Map<String, dynamic>.from(dados);
  }

  Future<List<MedicamentoPrescrito>> listarPrescricoes(
    String petId, {
    String? atendimentoId,
  }) async {
    // Valida os vínculos antes de aceitar a resposta de uma prescrição.
    if (petId.trim().isEmpty) throw ArgumentError('Pet não identificado.');
    final token = _token;
    final resposta = await http
        .get(
          _uri('/prescricoes/pet/${Uri.encodeComponent(petId)}'),
          headers: cabecalhosJson(token),
        )
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final dados = processarRespostaJson(resposta);
    if (dados is! Map || dados['prescricoes'] is! List) {
      throw const FormatException('Resposta de prescrições inválida.');
    }
    return (dados['prescricoes'] as List)
        .map((item) {
          if (item is! Map) throw const FormatException('Prescrição inválida.');
          final prescricao = MedicamentoPrescrito.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (prescricao.petId != petId) {
            throw const FormatException('Prescrição de outro pet.');
          }
          return prescricao;
        })
        .where((p) => atendimentoId == null || p.atendimentoId == atendimentoId)
        .toList();
  }

  Future<String> salvarPrescricao({
    required String petId,
    required String atendimentoId,
    required String solicitacaoId,
    required String medicamento,
    required String dose,
    required String frequencia,
    required String duracao,
    String orientacoes = '',
  }) async {
    if ([
      petId,
      atendimentoId,
      medicamento,
      dose,
      frequencia,
      duracao,
    ].any((v) => v.trim().isEmpty)) {
      throw const FormatException(
        'Preencha medicamento, dose, frequência e duração.',
      );
    }
    final token = _token;
    final resposta = await http
        .post(
          _uri('/prescricoes'),
          headers: cabecalhosJson(token),
          body: jsonEncode({
            'petId': petId,
            'atendimentoId': atendimentoId,
            'solicitacaoId': solicitacaoId,
            'medicamento': medicamento.trim(),
            'dose': dose.trim(),
            'frequencia': frequencia.trim(),
            'duracao': duracao.trim(),
            'orientacoes': orientacoes.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final dados = processarRespostaJson(resposta);
    final id = dados is Map ? dados['prescricaoId'] : null;
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Prescrição sem identificador válido.');
    }
    return id;
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

  /// Solicita um exame via POST /exames.
  /// Requer atendimentoId já gravado — a API valida a vinculação pet+vet.
  Future<ExameVeterinario> solicitarExame({
    required String petId,
    required String atendimentoId,
    required String tipo,
    required String nome,
    String justificativa = '',
  }) async {
    if ([petId, atendimentoId, tipo, nome].any((v) => v.trim().isEmpty)) {
      throw const FormatException(
        'Preencha tipo e nome do exame.',
      );
    }
    final token = _token;
    final resposta = await http
        .post(
          _uri('/exames'),
          headers: cabecalhosJson(token),
          body: jsonEncode({
            'petId': petId,
            'atendimentoId': atendimentoId,
            'tipo': tipo.trim(),
            'nome': nome,
            if (justificativa.trim().isNotEmpty)
              'justificativa': justificativa.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final dados = processarRespostaJson(resposta);
    if (dados is! Map) {
      throw const FormatException('Resposta de exame inválida.');
    }
    final id = dados['exameId'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Exame sem identificador válido.');
    }
    return ExameVeterinario(
      id: id,
      petId: petId,
      atendimentoId: atendimentoId,
      tipo: tipo.trim(),
      nome: nome.trim(),
      justificativa: justificativa.trim(),
    );
  }

  /// Lista exames do pet via GET /exames/pet/:petId.
  /// Acessível por VETERINARIO e ENFERMEIRO.
  // Veterinário e enfermagem podem consultar exames do mesmo pet.
  Future<List<ExameVeterinario>> listarExames(String petId) async {
    if (petId.trim().isEmpty) throw ArgumentError('Pet não identificado.');
    final token = _token;
    final resposta = await http
        .get(
          _uri('/exames/pet/${Uri.encodeComponent(petId)}'),
          headers: cabecalhosJson(token),
        )
        .timeout(const Duration(seconds: 20));
    if (_token != token) throw StateError('A sessão mudou. Atualize a tela.');
    final dados = processarRespostaJson(resposta);
    if (dados is! Map || dados['exames'] is! List) {
      throw const FormatException('Resposta de exames inválida.');
    }
    return (dados['exames'] as List).map((item) {
      if (item is! Map) throw const FormatException('Exame inválido.');
      final exame = ExameVeterinario.fromJson(Map<String, dynamic>.from(item));
      if (exame.petId != null && exame.petId != petId) {
        throw const FormatException('Exame de outro pet na resposta.');
      }
      return exame;
    }).toList();
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

  Future<String> salvarAtendimento(
    String id, {
    required String anamnese,
    required String exameFisico,
    required String diagnostico,
    required String prognostico,
    required String tratamento,
    String observacoes = '',
    String? codigoICDVet,
  }) async {
    final resposta = await _enviar(
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
    final atendimentoId = resposta['atendimentoId'];
    if (atendimentoId is! String || atendimentoId.trim().isEmpty) {
      throw const FormatException('Atendimento sem identificador válido.');
    }
    return atendimentoId;
  }
}
