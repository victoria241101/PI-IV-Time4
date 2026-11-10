import 'package:flutter/foundation.dart';

/// Modelo imutável de contato do chat (secretaria ou usuário do sistema).
@immutable
class ContatoChat {
  final String tipo;
  final String nome;
  final String? usuarioId;
  final String? papel;

  const ContatoChat({
    required this.tipo,
    required this.nome,
    this.usuarioId,
    this.papel,
  });

  /// Identifica se o contato representa a caixa compartilhada da secretaria.
  bool get ehSecretaria => tipo == 'secretaria';

  factory ContatoChat.fromJson(Map<String, dynamic> json) {
    return ContatoChat(
      tipo: json['tipo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString(),
      papel: json['papel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'nome': nome,
      if (usuarioId != null) 'usuarioId': usuarioId,
      if (papel != null) 'papel': papel,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContatoChat &&
          runtimeType == other.runtimeType &&
          tipo == other.tipo &&
          nome == other.nome &&
          usuarioId == other.usuarioId &&
          papel == other.papel;

  @override
  int get hashCode =>
      tipo.hashCode ^ nome.hashCode ^ usuarioId.hashCode ^ papel.hashCode;

  @override
  String toString() =>
      'ContatoChat(tipo: $tipo, nome: $nome, usuarioId: $usuarioId, papel: $papel)';
}

