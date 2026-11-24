// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Estado compartilhado de consultas/prontuários, carga da agenda, notificações e limpeza por sessão.
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
// agenda e prontuarios compartilhados pelas equipes da clinica
import 'package:flutter/material.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';

class AgendaClinica extends ChangeNotifier {
  AgendaClinica._() {
    SessaoUsuario.instancia.addListener(() {
      if (_sessaoCarregada != SessaoUsuario.instancia.token) {
        ++_requisicao;
        consultas.clear();
        prontuarios.clear();
        _sessaoCarregada = SessaoUsuario.instancia.token;
        notifyListeners();
      }
    });
  }

  // Esta instância mantém agenda e prontuários compartilhados pelos perfis clínicos.
  static final AgendaClinica instancia = AgendaClinica._();

  ConsultasClinicaService servico = ConsultasClinicaService();
  String? _sessaoCarregada;
  int _requisicao = 0;

  /// A API decide quais consultas o usuário autenticado pode consultar.
  Future<void> carregarDia(DateTime dia) async {
    final token = SessaoUsuario.instancia.token;
    final requisicao = ++_requisicao;
    // Respostas antigas são ignoradas após mudar o dia ou a sessão.
    if (_sessaoCarregada != token) {
      consultas.clear();
      prontuarios.clear();
      _sessaoCarregada = token;
      notifyListeners();
    }
    final recebidas = await servico.listarDia(dia);
    if (requisicao != _requisicao || SessaoUsuario.instancia.token != token) {
      return;
    }
    // Converte o formato da API no modelo usado pela interface.
    final novas = recebidas.where((c) => c.statusTela != null).map((c) {
      final data = DateTime.parse(c.dataHora);
      return ConsultaRecepcao(
        id: c.id,
        petId: c.petId,
        tutorId: c.tutorId,
        veterinarioId: c.veterinarioId,
        data: DateUtils.dateOnly(data),
        horario: c.dataHora.substring(11, 16),
        duracaoMinutos: c.duracaoMinutos,
        pet: c.petNome ?? 'Pet sem nome',
        especie: c.especie ?? '',
        tutor: c.tutorNome ?? 'Tutor sem nome',
        profissional: c.veterinarioNome ?? 'Veterinário sem nome',
        motivo: c.tipo,
        sala: '',
        status: c.statusTela!,
      );
    }).toList();
    consultas.removeWhere((c) => DateUtils.isSameDay(c.data, dia));
    consultas.addAll(novas);
    notifyListeners();
  }

  final List<ConsultaRecepcao> consultas = [];
  final Map<String, ProntuarioCompartilhado> prontuarios = {};

  List<ConsultaRecepcao> get internacoesAtivas => consultas
      .where((consulta) => prontuarios[consulta.id]?.internacaoAtiva ?? false)
      .toList();

  // Cria sob demanda um prontuário associado ao ID da consulta.
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

  // Finalizar sincroniza prontuário e estado visual da consulta.
  void finalizarConsulta(
    ConsultaRecepcao consulta,
    ProntuarioCompartilhado prontuario,
  ) {
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
