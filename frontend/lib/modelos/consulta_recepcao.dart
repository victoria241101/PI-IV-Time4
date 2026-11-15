// modelo de consulta da recepção e seus status de atendimento
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

/// Etapas únicas do fluxo da consulta, conforme o fluxo da recepção.
enum StatusConsultaRecepcao {
  agendada,
  aguardandoTriagem,
  emTriagem,
  aguardandoVeterinario,
  emConsulta,
  finalizado,
}

extension StatusConsultaRecepcaoUi on StatusConsultaRecepcao {
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
    this.fotoPetUrl,
  });

  final String id;
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
  final String? fotoPetUrl;

  String? get fotoPet => fotoPetUrl;

  String get duracao => '$duracaoMinutos min';
}
