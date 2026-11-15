import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/api_exception.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/modelos/chat/contato_chat_modelo.dart';
import 'package:pet_care/modelos/chat/conversa_resumo_modelo.dart';
import 'package:pet_care/modelos/chat/mensagem_chat_modelo.dart';

export 'package:pet_care/core/api_exception.dart';

/// Retorno estruturado ao abrir ou reaproveitar uma conversa.
class ConversaAberta {
  final String id;
  final String tipo;
  final ContatoChat outro;
  final bool criada;

  const ConversaAberta({
    required this.id,
    required this.tipo,
    required this.outro,
    required this.criada,
  });
}

/// Retorno estruturado ao enviar uma mensagem no chat.
class MensagemEnviada {
  final String id;
  final DateTime criadoEm;

  const MensagemEnviada({
    required this.id,
    required this.criadoEm,
  });
}

/// Serviço responsável pelo acesso aos endpoints do módulo de Chat.
class ChatService {
  final String? _baseUrl;
  final http.Client? _clienteHttp;

  ChatService({
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

  Future<http.Response> _post(
    Uri uri,
    Map<String, String> headers, {
    Object? body,
  }) {
    if (_clienteHttp != null) {
      return _clienteHttp.post(uri, headers: headers, body: body);
    }
    return http.post(uri, headers: headers, body: body);
  }

  Future<http.Response> _patch(
    Uri uri,
    Map<String, String> headers, {
    Object? body,
  }) {
    if (_clienteHttp != null) {
      return _clienteHttp.patch(uri, headers: headers, body: body);
    }
    return http.patch(uri, headers: headers, body: body);
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

  Future<({dynamic corpo, int statusCode})> _executarRequisicaoComStatus(
    Future<http.Response> Function() chamada,
  ) async {
    try {
      final resposta = await chamada().timeout(const Duration(seconds: 10));
      final corpo = _processarResposta(resposta);
      return (corpo: corpo, statusCode: resposta.statusCode);
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

  /// Lista contatos permitidos para o usuário autenticado.
  /// Rota: GET /chat/contatos?busca=
  Future<List<ContatoChat>> listarContatos({String? busca}) async {
    final headers = _obterHeaders();

    final queryParams = <String, String>{
      if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
    };

    final uri = Uri.parse('$_urlBase/chat/contatos').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _get(uri, headers),
    );

    final listaJson = dados['contatos'] as List<dynamic>? ?? [];
    return listaJson
        .map((item) => ContatoChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Abre ou reaproveita uma conversa com a secretaria ou outro usuário.
  /// Rota: POST /chat/conversas
  /// Exige exatamente um entre `secretaria` (true) ou `usuarioId` informado.
  Future<ConversaAberta> abrirConversa({
    bool secretaria = false,
    String? usuarioId,
  }) async {
    final bool temSecretaria = secretaria;
    final bool temUsuario = usuarioId != null && usuarioId.trim().isNotEmpty;

    if ((temSecretaria && temUsuario) || (!temSecretaria && !temUsuario)) {
      throw ArgumentError(
        'Informe exatamente um dos alvos: secretaria=true ou um usuarioId válido.',
      );
    }

    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/chat/conversas');
    final corpo = temSecretaria
        ? {'com': 'secretaria'}
        : {'usuarioId': usuarioId!.trim()};

    final resultado = await _executarRequisicaoComStatus(
      () => _post(uri, headers, body: jsonEncode(corpo)),
    );

    final dados = resultado.corpo as Map<String, dynamic>;
    final conversaJson = dados['conversa'] as Map<String, dynamic>? ?? {};

    final id = conversaJson['_id']?.toString() ?? '';
    final tipo = conversaJson['tipo']?.toString() ?? '';
    final outroJson = conversaJson['outro'] as Map<String, dynamic>? ?? {};
    final outro = ContatoChat.fromJson(outroJson);

    return ConversaAberta(
      id: id,
      tipo: tipo,
      outro: outro,
      criada: resultado.statusCode == 201,
    );
  }

  /// Lista as conversas do usuário autenticado.
  /// Rota: GET /chat/conversas
  Future<List<ConversaResumo>> listarConversas() async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/chat/conversas');

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _get(uri, headers),
    );

    final listaJson = dados['conversas'] as List<dynamic>? ?? [];
    return listaJson
        .map((item) => ConversaResumo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lista mensagens de uma conversa com paginação por cursor.
  /// Rota: GET /chat/conversas/:id/mensagens
  Future<List<MensagemChat>> listarMensagens(
    String conversaId, {
    int limite = 50,
    String? antes,
    String? depois,
  }) async {
    final headers = _obterHeaders();

    final queryParams = <String, String>{
      'limite': limite.toString(),
      if (antes != null && antes.trim().isNotEmpty) 'antes': antes.trim(),
      if (depois != null && depois.trim().isNotEmpty) 'depois': depois.trim(),
    };

    final uri = Uri.parse('$_urlBase/chat/conversas/$conversaId/mensagens')
        .replace(queryParameters: queryParams);

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _get(uri, headers),
    );

    final listaJson = dados['mensagens'] as List<dynamic>? ?? [];
    return listaJson
        .map((item) => MensagemChat.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Envia uma mensagem em uma conversa existente.
  /// Rota: POST /chat/conversas/:id/mensagens
  Future<MensagemEnviada> enviarMensagem(
    String conversaId,
    String texto,
  ) async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/chat/conversas/$conversaId/mensagens');

    final dados = await _executarRequisicao<Map<String, dynamic>>(
      () => _post(uri, headers, body: jsonEncode({'texto': texto})),
    );

    final id = dados['mensagemId']?.toString() ?? '';
    final rawCriadoEm = dados['criadoEm']?.toString();
    final criadoEm = (rawCriadoEm != null && rawCriadoEm.isNotEmpty)
        ? DateTime.parse(rawCriadoEm).toLocal()
        : DateTime.now();

    return MensagemEnviada(
      id: id,
      criadoEm: criadoEm,
    );
  }

  /// Marca uma conversa como lida pelo usuário autenticado.
  /// Rota: PATCH /chat/conversas/:id/lida
  Future<void> marcarLida(String conversaId) async {
    final headers = _obterHeaders();
    final uri = Uri.parse('$_urlBase/chat/conversas/$conversaId/lida');

    await _executarRequisicao<Map<String, dynamic>>(
      () => _patch(uri, headers),
    );
  }
}

