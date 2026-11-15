import 'package:flutter/foundation.dart';
import 'package:pet_care/modelos/chat/contato_chat_modelo.dart';

/// Dados resumidos da última mensagem enviada em uma conversa.
@immutable
class UltimaMensagemChat {
  final String texto;
  final String remetenteId;
  final String remetenteTipo;
  final DateTime criadoEm;

  const UltimaMensagemChat({
    required this.texto,
    required this.remetenteId,
    required this.remetenteTipo,
    required this.criadoEm,
  });

  factory UltimaMensagemChat.fromJson(Map<String, dynamic> json) {
    final rawCriadoEm = json['criadoEm']?.toString();
    DateTime data;
    if (rawCriadoEm != null && rawCriadoEm.isNotEmpty) {
      data = DateTime.parse(rawCriadoEm).toLocal();
    } else {
      data = DateTime.now();
    }

    return UltimaMensagemChat(
      texto: json['texto']?.toString() ?? '',
      remetenteId: json['remetenteId']?.toString() ?? '',
      remetenteTipo: json['remetenteTipo']?.toString() ?? '',
      criadoEm: data,
    );
  }

  Map<String, dynamic> toJson() => {
    'texto': texto,
    'remetenteId': remetenteId,
    'remetenteTipo': remetenteTipo,
    'criadoEm': criadoEm.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UltimaMensagemChat &&
          runtimeType == other.runtimeType &&
          texto == other.texto &&
          remetenteId == other.remetenteId &&
          remetenteTipo == other.remetenteTipo &&
          criadoEm == other.criadoEm;

  @override
  int get hashCode =>
      texto.hashCode ^
      remetenteId.hashCode ^
      remetenteTipo.hashCode ^
      criadoEm.hashCode;

  @override
  String toString() =>
      'UltimaMensagemChat(texto: $texto, remetenteId: $remetenteId, remetenteTipo: $remetenteTipo, criadoEm: $criadoEm)';
}

/// Modelo imutável para a lista resumida de conversas.
@immutable
class ConversaResumo {
  final String id;
  final String tipo;
  final ContatoChat outro;
  final UltimaMensagemChat? ultimaMensagem;
  final DateTime? ultimaMensagemEm;
  final int naoLidas;

  const ConversaResumo({
    required this.id,
    required this.tipo,
    required this.outro,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
    this.naoLidas = 0,
  });

  factory ConversaResumo.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    if (rawId.trim().isEmpty) {
      throw const FormatException('ID da conversa não pode ser vazio.');
    }

    final rawTipo = json['tipo']?.toString() ?? '';
    final outroJson = json['outro'];
    final outro = outroJson is Map<String, dynamic>
        ? ContatoChat.fromJson(outroJson)
        : const ContatoChat(tipo: '', nome: '');

    UltimaMensagemChat? ultimaMensagem;
    final ultMsgJson = json['ultimaMensagem'];
    if (ultMsgJson is Map<String, dynamic>) {
      ultimaMensagem = UltimaMensagemChat.fromJson(ultMsgJson);
    }

    DateTime? ultimaMensagemEm;
    final rawUltimaEm = json['ultimaMensagemEm']?.toString();
    if (rawUltimaEm != null && rawUltimaEm.isNotEmpty) {
      try {
        ultimaMensagemEm = DateTime.parse(rawUltimaEm).toLocal();
      } catch (_) {
        ultimaMensagemEm = null;
      }
    }

    final rawNaoLidas = json['naoLidas'];
    final naoLidas = rawNaoLidas is num ? rawNaoLidas.toInt() : 0;

    return ConversaResumo(
      id: rawId,
      tipo: rawTipo,
      outro: outro,
      ultimaMensagem: ultimaMensagem,
      ultimaMensagemEm: ultimaMensagemEm,
      naoLidas: naoLidas,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'tipo': tipo,
    'outro': outro.toJson(),
    if (ultimaMensagem != null) 'ultimaMensagem': ultimaMensagem!.toJson(),
    if (ultimaMensagemEm != null)
      'ultimaMensagemEm': ultimaMensagemEm!.toIso8601String(),
    'naoLidas': naoLidas,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversaResumo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tipo == other.tipo &&
          outro == other.outro &&
          ultimaMensagem == other.ultimaMensagem &&
          ultimaMensagemEm == other.ultimaMensagemEm &&
          naoLidas == other.naoLidas;

  @override
  int get hashCode =>
      id.hashCode ^
      tipo.hashCode ^
      outro.hashCode ^
      ultimaMensagem.hashCode ^
      ultimaMensagemEm.hashCode ^
      naoLidas.hashCode;

  @override
  String toString() =>
      'ConversaResumo(id: $id, tipo: $tipo, outro: $outro, ultimaMensagem: $ultimaMensagem, ultimaMensagemEm: $ultimaMensagemEm, naoLidas: $naoLidas)';
}

