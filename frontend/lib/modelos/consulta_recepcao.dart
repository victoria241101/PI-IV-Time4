// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Modelo de consulta da recepção.
// modelo de consulta da recepção e seus status de atendimento
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

/// Etapas únicas do fluxo da consulta, conforme o fluxo da recepção.
// A enum fixa as etapas válidas do fluxo clínico da recepção.
enum StatusConsultaRecepcao {
  agendada,
  aguardandoTriagem,
  emTriagem,
  aguardandoVeterinario,
  emConsulta,
  finalizado,
}

extension StatusConsultaRecepcaoUi on StatusConsultaRecepcao {
  // A mesma etapa recebe texto e cor em todas as telas da clínica.
  String get rotulo => switch (this) {
    StatusConsultaRecepcao.agendada => 'Agendada',
    StatusConsultaRecepcao.aguardandoTriagem => 'Aguardando triagem',
    StatusConsultaRecepcao.emTriagem => 'Em triagem',
    StatusConsultaRecepcao.aguardandoVeterinario => 'Aguardando veterinário',
    StatusConsultaRecepcao.emConsulta => 'Em consulta',
    StatusConsultaRecepcao.finalizado => 'Finalizado',
  };

  Color get cor => switch (this) {
    StatusConsultaRecepcao.agendada => CoresApp.darkBlue,
    StatusConsultaRecepcao.aguardandoTriagem => CoresApp.accentOrange,
    StatusConsultaRecepcao.emTriagem => CoresApp.primary,
    StatusConsultaRecepcao.aguardandoVeterinario => CoresApp.accentOrangeDark,
    StatusConsultaRecepcao.emConsulta => CoresApp.primaryDark,
    StatusConsultaRecepcao.finalizado => CoresApp.textSecondary,
  };
}

/// Resumo de agendamento compartilhado entre o acompanhamento diário e o calendário.
class ConsultaRecepcao {
  ConsultaRecepcao({
    required this.id,
    this.petId,
    this.tutorId,
    this.veterinarioId,
    required this.data,
    required this.horario,
    required this.duracaoMinutos,
    required this.pet,
    required this.especie,
    required this.tutor,
    required this.profissional,
    required this.motivo,
    required this.sala,
    required this.status,
    this.emergencia = false,
    this.internacaoAgendada = false,
    this.prontuarioOrigemId,
    this.dataPrevistaInternacao,
    this.fotoPetUrl,
  });

  final String id;
  // IDs opcionais preservam vínculos externos sem virar números ou nomes.
  final String? petId, tutorId, veterinarioId;
  DateTime data;
  String horario;
  final int duracaoMinutos;
  final String pet;
  final String especie;
  final String tutor;
  String profissional;
  final String motivo;
  String sala;
  StatusConsultaRecepcao status;
  final bool emergencia;
  final bool internacaoAgendada;
  final String? prontuarioOrigemId;
  final DateTime? dataPrevistaInternacao;
  final String? fotoPetUrl;

  String? get fotoPet => fotoPetUrl;

  // O getter prepara a duração já no formato exibido pela interface.
  String get duracao => '$duracaoMinutos min';
}
