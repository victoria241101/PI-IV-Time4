import 'package:flutter/foundation.dart';

/// Modelo imutável de mensagem do chat (utilizado na listagem da Parte 5).
@immutable
class MensagemChat {
  final String id;
  final String conversaId;
  final String texto;
  final DateTime criadoEm;
  final String remetenteUsuarioId;
  final String remetenteNome;
  final String remetentePapel;
  final bool minha;

  const MensagemChat({
    required this.id,
    required this.conversaId,
    required this.texto,
    required this.criadoEm,
    required this.remetenteUsuarioId,
    required this.remetenteNome,
    required this.remetentePapel,
    required this.minha,
  });

  factory MensagemChat.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final conversaId = json['conversaId']?.toString() ?? '';
    final texto = json['texto']?.toString() ?? '';

    final rawCriadoEm = json['criadoEm']?.toString();
    final criadoEm = (rawCriadoEm != null && rawCriadoEm.isNotEmpty)
        ? DateTime.parse(rawCriadoEm).toLocal()
        : DateTime.now();

    String remetenteUsuarioId = '';
    String remetenteNome = '';
    String remetentePapel = '';

    final remetente = json['remetente'];
    if (remetente is Map<String, dynamic>) {
      remetenteUsuarioId = remetente['usuarioId']?.toString() ?? '';
      remetenteNome = remetente['nome']?.toString() ?? '';
      remetentePapel = remetente['papel']?.toString() ?? '';
    } else {
      remetenteUsuarioId = json['remetenteUsuarioId']?.toString() ??
          json['remetenteId']?.toString() ??
          '';
      remetenteNome = json['remetenteNome']?.toString() ?? '';
      remetentePapel = json['remetentePapel']?.toString() ??
          json['remetenteTipo']?.toString() ??
          '';
    }

    final minha = json['minha'] == true;

    return MensagemChat(
      id: rawId,
      conversaId: conversaId,
      texto: texto,
      criadoEm: criadoEm,
      remetenteUsuarioId: remetenteUsuarioId,
      remetenteNome: remetenteNome,
      remetentePapel: remetentePapel,
      minha: minha,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'conversaId': conversaId,
    'texto': texto,
    'criadoEm': criadoEm.toIso8601String(),
    'remetente': {
      'usuarioId': remetenteUsuarioId,
      'nome': remetenteNome,
      'papel': remetentePapel,
    },
    'minha': minha,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MensagemChat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversaId == other.conversaId &&
          texto == other.texto &&
          criadoEm == other.criadoEm &&
          remetenteUsuarioId == other.remetenteUsuarioId &&
          remetenteNome == other.remetenteNome &&
          remetentePapel == other.remetentePapel &&
          minha == other.minha;

  @override
  int get hashCode =>
      id.hashCode ^
      conversaId.hashCode ^
      texto.hashCode ^
      criadoEm.hashCode ^
      remetenteUsuarioId.hashCode ^
      remetenteNome.hashCode ^
      remetentePapel.hashCode ^
      minha.hashCode;

  @override
  String toString() =>
      'MensagemChat(id: $id, conversaId: $conversaId, texto: $texto, criadoEm: $criadoEm, remetente: $remetenteNome, minha: $minha)';
}

