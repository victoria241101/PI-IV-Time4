// agenda e prontuarios compartilhados pelas equipes da clinica
import 'package:flutter/material.dart';

import 'package:pet_care/mocks/cenarios_clinica_temporarios.dart';

import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';

class AgendaClinica extends ChangeNotifier {
  AgendaClinica._() {
    // TEMPORÁRIO: remover esta chamada e o import ao conectar os dados reais.
    carregarCenariosClinicaTemporarios(consultas, prontuarios);
  }

  static final AgendaClinica instancia = AgendaClinica._();

  final List<ConsultaRecepcao> consultas = [];
  final Map<String, ProntuarioCompartilhado> prontuarios = {};

  List<ConsultaRecepcao> get internacoesAtivas => consultas
      .where((consulta) => prontuarios[consulta.id]?.internacaoAtiva ?? false)
      .toList();

  ProntuarioCompartilhado prontuarioDa(ConsultaRecepcao consulta) =>
      prontuarios.putIfAbsent(consulta.id, ProntuarioCompartilhado.new);

  List<ConsultaRecepcao> consultasDoPet(String pet, String tutor) =>
      consultas
          .where(
            (consulta) =>
                consulta.pet.toLowerCase() == pet.toLowerCase() &&
                consulta.tutor.toLowerCase() == tutor.toLowerCase(),
          )
          .toList()
        ..sort((a, b) {
          final porData = b.data.compareTo(a.data);
          return porData != 0 ? porData : b.horario.compareTo(a.horario);
        });

  void atualizarStatus(
    ConsultaRecepcao consulta,
    StatusConsultaRecepcao status,
  ) {
    consulta.status = status;
    notifyListeners();
  }

  void finalizarConsulta(
    ConsultaRecepcao consulta,
    ProntuarioCompartilhado prontuario,
  ) {
    if (prontuario.internacao.isNotEmpty) {
      prontuario
        ..internacaoAtiva = true
        ..internacaoIniciadaEm ??= DateTime.now()
        ..internacaoFinalizadaEm = null;
    }
    prontuarios[consulta.id] = prontuario;
    consulta.status = StatusConsultaRecepcao.finalizado;
    notifyListeners();
  }

  void adicionarConsulta(ConsultaRecepcao consulta) {
    consultas.add(consulta);
    prontuarioDa(consulta);
    notifyListeners();
  }

  void removerConsulta(ConsultaRecepcao consulta) {
    consultas.removeWhere((item) => item.id == consulta.id);
    prontuarios.remove(consulta.id);
    notifyListeners();
  }

  void notificarAlteracao() => notifyListeners();

  void adicionarProcedimentoInternacao(
    ConsultaRecepcao consulta,
    ProcedimentoInternacao procedimento,
  ) {
    prontuarioDa(consulta).procedimentosInternacao.add(procedimento);
    notifyListeners();
  }

  void concluirProcedimentoInternacao(
    ConsultaRecepcao consulta,
    ProcedimentoInternacao procedimento, {
    required DateTime concluidoEm,
    required String detalhes,
  }) {
    procedimento
      ..concluidoEm = concluidoEm
      ..detalhesConclusao = detalhes;
    notifyListeners();
  }

  void adicionarMedicacaoInternacao(
    ConsultaRecepcao consulta,
    MedicacaoInternacao medicacao,
  ) {
    prontuarioDa(consulta).medicacoesInternacao.add(medicacao);
    notifyListeners();
  }

  void registrarAdministracaoMedicacao(
    ConsultaRecepcao consulta,
    MedicacaoInternacao medicacao,
    AdministracaoMedicacao administracao,
  ) {
    medicacao.administracoes.add(administracao);
    notifyListeners();
  }

  void adicionarNotaInternacao(ConsultaRecepcao consulta, NotaInternacao nota) {
    prontuarioDa(consulta).notasInternacao.insert(0, nota);
    notifyListeners();
  }

  void finalizarInternacao(ConsultaRecepcao consulta) {
    final prontuario = prontuarioDa(consulta);
    prontuario
      ..internacaoAtiva = false
      ..internacaoFinalizadaEm = DateTime.now();
    notifyListeners();
  }
}
