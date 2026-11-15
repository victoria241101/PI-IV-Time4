import 'package:flutter/foundation.dart';

/// Modelo de dados imutável para as notificações da API do PetCare.
@immutable
class Notificacao {
  final String id;
  final String tipo;
  final String titulo;
  final String mensagem;
  final String? petId;
  final String? consultaId;
  final bool lida;
  final DateTime? lidaEm;
  final DateTime criadoEm;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.petId,
    this.consultaId,
    this.lida = false,
    this.lidaEm,
    required this.criadoEm,
  });

  /// Constrói uma instância a partir do JSON serializado pelo backend.
  /// O backend retorna "id" (string hex) e "lida" (booleano).
  factory Notificacao.fromJson(Map<String, dynamic> json) {
    final idBruto = json['id'];
    final id = idBruto != null ? idBruto.toString() : '';

    final lidaEmBruto = json['lidaEm'];
    DateTime? lidaEm;
    if (lidaEmBruto != null && lidaEmBruto.toString().isNotEmpty) {
      lidaEm = DateTime.tryParse(lidaEmBruto.toString())?.toLocal();
    }

    final criadoEmBruto = json['criadoEm'];
    DateTime criadoEm;
    if (criadoEmBruto != null && criadoEmBruto.toString().isNotEmpty) {
      criadoEm = DateTime.parse(criadoEmBruto.toString()).toLocal();
    } else {
      criadoEm = DateTime.now();
    }

    return Notificacao(
      id: id,
      tipo: json['tipo']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensagem: json['mensagem']?.toString() ?? '',
      petId: json['petId']?.toString(),
      consultaId: json['consultaId']?.toString(),
      lida: json['lida'] == true,
      lidaEm: lidaEm,
      criadoEm: criadoEm,
    );
  }

  /// Retorna uma nova instância com o status de leitura atualizado.
  Notificacao copiarComLida(bool lida) {
    return Notificacao(
      id: id,
      tipo: tipo,
      titulo: titulo,
      mensagem: mensagem,
      petId: petId,
      consultaId: consultaId,
      lida: lida,
      lidaEm: lida ? (lidaEm ?? DateTime.now()) : null,
      criadoEm: criadoEm,
    );
  }

  /// Converte a notificação para Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'titulo': titulo,
      'mensagem': mensagem,
      'petId': petId,
      'consultaId': consultaId,
      'lida': lida,
      'lidaEm': lidaEm?.toIso8601String(),
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notificacao &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Notificacao(id: $id, tipo: $tipo, titulo: $titulo, lida: $lida)';
}

