import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/modelos/notificacao_modelo.dart';

/// Exceção padronizada para erros de comunicação com a API do PetCare.
class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  const ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => 'ApiException($statusCode): $mensagem';
}

/// Estrutura de retorno para a listagem paginada de notificações.
class ResultadoNotificacoes {
  final List<Notificacao> notificacoes;
  final int naoLidas;

  const ResultadoNotificacoes({
    required this.notificacoes,
    required this.naoLidas,
  });
}

/// Serviço responsável pelo acesso aos endpoints do módulo de Notificações.
class NotificacoesService {
  final String? _baseUrl;
  final http.Client? _clienteHttp;

  NotificacoesService({
    String? baseUrl,
    http.Client? clienteHttp,
  })  : _baseUrl = baseUrl,
        _clienteHttp = clienteHttp;

  String get _urlBase => _baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _obterHeaders() {
    final token = SessaoUsuario.instancia.token;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Usuário não autenticado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _get(Uri uri, Map<String, String> headers) {
    if (_clienteHttp != null) {
      return _clienteHttp.get(uri, headers: headers);
    }
    return http.get(uri, headers: headers);
  }

  Future<http.Response> _patch(Uri uri, Map<String, String> headers) {
    if (_clienteHttp != null) {
      return _clienteHttp.patch(uri, headers: headers);
    }
    return http.patch(uri, headers: headers);
  }

  Future<http.Response> _delete(Uri uri, Map<String, String> headers) {
    if (_clienteHttp != null) {
      return _clienteHttp.delete(uri, headers: headers);
    }
    return http.delete(uri, headers: headers);
  }

  dynamic _processarResposta(http.Response resposta) {
    dynamic corpoDecodificado;
    try {
      corpoDecodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      corpoDecodificado = null;
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpoDecodificado;
    }

    String? mensagemErro;
    if (corpoDecodificado is Map && corpoDecodificado['mensagem'] is String) {
      mensagemErro = corpoDecodificado['mensagem'] as String;
    }

    mensagemErro ??= 'Erro na requisição (código ${resposta.statusCode}).';
    throw ApiException(resposta.statusCode, mensagemErro);
  }

  Future<T> _executarRequisicao<T>(Future<http.Response> Function() chamada) async {
    try {
      final resposta = await chamada().timeout(const Duration(seconds: 10));
      return _processarResposta(resposta) as T;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        0,
        'O servidor demorou muito para responder. Verifique sua conexão.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        0,
        'Falha de conexão com o servidor: ${e.message}',
      );
    } catch (e) {
      throw ApiException(
        0,
        'Não foi possível completar a requisição: $e',
      );
    }
  }

  /// Retorna o número de notificações não lidas do usuário autenticado.
  /// Rota: GET /notificacoes/contagem -> {"naoLidas": n}
  Future<int> contagem() async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/notificacoes/contagem');

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _get(uri, headers),
    );

    final naoLidas = dados['naoLidas'];
    if (naoLidas is num) {
      return naoLidas.toInt();
    }
    return 0;
  }

  /// Lista notificações do usuário autenticado, com paginação e filtros opcionais.
  /// Rota: GET /notificacoes -> {"notificacoes": [...], "naoLidas": n}
  Future<ResultadoNotificacoes> listar({
    int limite = 20,
    String? antes,
    String? depois,
    bool somenteNaoLidas = false,
  }) async {
    final headers = _obterHeaders();

    final queryParams = <String, String>{
      'limite': limite.toString(),
      if (antes != null && antes.isNotEmpty) 'antes': antes,
      if (depois != null && depois.isNotEmpty) 'depois': depois,
      if (somenteNaoLidas) 'somenteNaoLidas': 'true',
    };

    final uri = Uri.parse('$_urlBase/notificacoes').replace(
      queryParameters: queryParams,
    );

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _get(uri, headers),
    );

    final listaJson = dados['notificacoes'] as List<dynamic>? ?? [];
    final notificacoes = listaJson
        .map((item) => Notificacao.fromJson(item as Map<String, dynamic>))
        .toList();

    final naoLidas = dados['naoLidas'] is num
        ? (dados['naoLidas'] as num).toInt()
        : 0;

    return ResultadoNotificacoes(
      notificacoes: notificacoes,
      naoLidas: naoLidas,
    );
  }

  /// Marca uma notificação individual como lida.
  /// Rota: PATCH /notificacoes/:id/lida -> {"mensagem": "...", "notificacao": {...}}
  Future<Notificacao> marcarLida(String id) async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/notificacoes/$id/lida');

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _patch(uri, headers),
    );

    final notificacaoJson = dados['notificacao'] as Map<String, dynamic>?;
    if (notificacaoJson == null) {
      throw const ApiException(
        500,
        'Resposta do servidor não continha a notificação atualizada.',
      );
    }

    return Notificacao.fromJson(notificacaoJson);
  }

  /// Marca todas as notificações não lidas do usuário autenticado como lidas.
  /// Rota: PATCH /notificacoes/lidas -> {"mensagem": "...", "atualizadas": n}
  Future<int> marcarTodasLidas() async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/notificacoes/lidas');

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _patch(uri, headers),
    );

    final atualizadas = dados['atualizadas'];
    if (atualizadas is num) {
      return atualizadas.toInt();
    }
    return 0;
  }

  /// Exclui permanentemente uma notificação.
  /// Rota: DELETE /notificacoes/:id -> {"mensagem": "..."}
  Future<void> excluir(String id) async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/notificacoes/$id');

    await _executarRequisicao<Map<String, dynamic>>(
      () => _delete(uri, headers),
    );
  }
}

