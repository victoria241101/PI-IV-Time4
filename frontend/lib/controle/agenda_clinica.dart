// agenda e prontuarios compartilhados pelas equipes da clinica
import 'package:flutter/material.dart';

import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';

class AgendaClinica extends ChangeNotifier {
  AgendaClinica._() {
    final hoje = DateUtils.dateOnly(DateTime.now());
    consultas.addAll(_criarConsultasExemplo(hoje));
    consultas.add(
      ConsultaRecepcao(
        id: 'pipoca-internada',
        data: hoje.subtract(const Duration(days: 1)),
        horario: '18:30',
        duracaoMinutos: 45,
        pet: 'Pipoca',
        especie: 'SRD',
        tutor: 'Mariana Alves',
        profissional: 'Dra. Camila',
        motivo: 'Atendimento de emergência · exemplo',
        sala: 'Internação',
        status: StatusConsultaRecepcao.finalizado,
        emergencia: true,
      ),
    );
    prontuarios['max-1000'] = ProntuarioCompartilhado(
      observacoesTriagem: 'Paciente alerta, com sensibilidade ao apoiar a pata traseira direita',
    );
    prontuarios['nina-1130'] = ProntuarioCompartilhado(
      observacoesTriagem: 'Aguardando conclusão da triagem de sinais vitais',
    );
    prontuarios['thor-1300'] = ProntuarioCompartilhado(
      observacoesTriagem:
          'Temperatura 39,4 °C · mucosas pálidas · dor abdominal à palpação',
      internacao: 'Imediata (emergência)',
    );
    prontuarios['pipoca-internada'] = ProntuarioCompartilhado(
      observacoesTriagem: 'Exemplo de triagem para visualização do prontuário',
      descricaoConsulta: 'Exemplo de avaliação clínica e estabilização inicial',
      medicamentos: [
        MedicamentoPrescrito(
          nome: 'Medicação de demonstração',
          dosagem: 'Conforme prescrição',
          orientacao: 'Registro de exemplo para a equipe',
        ),
      ],
      exames: ['Hemograma · exemplo'],
      internacao: 'Imediata (emergência)',
      internacaoAtiva: true,
      internacaoIniciadaEm: DateTime(
        hoje.year,
        hoje.month,
        hoje.day - 1,
        18,
        30,
      ),
      observacoes: 'Acompanhamento compartilhado com a equipe de enfermagem',
      procedimentosInternacao: [
        ProcedimentoInternacao(
          nome: 'Reavaliação clínica',
          agendadoPara: DateTime.now().add(const Duration(hours: 2)),
          detalhes: 'Procedimento de demonstração',
        ),
      ],
      medicacoesInternacao: [
        MedicacaoInternacao(
          nome: 'Medicação de demonstração',
          dosagem: 'Conforme prescrição',
          frequencia: 'Conforme plano veterinário',
          detalhes: 'Exemplo para testar os registros de administração',
          administracoes: [
            AdministracaoMedicacao(
              realizadaEm: DateTime.now().subtract(const Duration(hours: 1)),
              responsavel: 'Equipe de enfermagem',
              observacao: 'Registro de demonstração',
            ),
          ],
        ),
      ],
      notasInternacao: [
        NotaInternacao(
          texto: 'Exemplo de atualização compartilhada da equipe',
          autor: 'Dra. Camila',
          registradaEm: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
    );
  }

  static final AgendaClinica instancia = AgendaClinica._();

  final List<ConsultaRecepcao> consultas = [];
  final Map<String, ProntuarioCompartilhado> prontuarios = {};

  List<ConsultaRecepcao> get internacoesAtivas => consultas
      .where((consulta) => prontuarios[consulta.id]?.internacaoAtiva ?? false)
      .toList();

  List<ConsultaRecepcao> _criarConsultasExemplo(DateTime hoje) => [
    ConsultaRecepcao(
      id: 'bella-0900',
      data: hoje,
      horario: '09:00',
      duracaoMinutos: 45,
      pet: 'Bella',
      especie: 'Gata siamesa',
      tutor: 'Ana Souza',
      profissional: 'Dra. Beatriz',
      motivo: 'Reforço anual',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.finalizado,
    ),
    ConsultaRecepcao(
      id: 'max-1000',
      data: hoje,
      horario: '10:00',
      duracaoMinutos: 45,
      pet: 'Max',
      especie: 'Golden Retriever',
      tutor: 'Carlos Lima',
      profissional: 'Dra. Camila',
      motivo: 'Avaliação ortopédica',
      sala: 'Sala 02',
      status: StatusConsultaRecepcao.emConsulta,
    ),
    ConsultaRecepcao(
      id: 'lola-1000',
      data: hoje,
      horario: '10:00',
      duracaoMinutos: 30,
      pet: 'Lola',
      especie: 'Shih-tzu',
      tutor: 'Marina Costa',
      profissional: 'Dr. Silva',
      motivo: 'Consulta de rotina',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.agendada,
    ),
    ConsultaRecepcao(
      id: 'oliver-1100',
      data: hoje,
      horario: '11:00',
      duracaoMinutos: 30,
      pet: 'Oliver',
      especie: 'Bulldog francês',
      tutor: 'Fernanda Reis',
      profissional: 'Dr. Silva',
      motivo: 'Retorno pós-operatório',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.aguardandoTriagem,
    ),
    ConsultaRecepcao(
      id: 'nina-1130',
      data: hoje,
      horario: '11:30',
      duracaoMinutos: 30,
      pet: 'Nina',
      especie: 'SRD',
      tutor: 'João Mendes',
      profissional: 'Dra. Beatriz',
      motivo: 'Avaliação clínica',
      sala: 'Sala 02',
      status: StatusConsultaRecepcao.emTriagem,
    ),
    ConsultaRecepcao(
      id: 'thor-1300',
      data: hoje,
      horario: '13:00',
      duracaoMinutos: 45,
      pet: 'Thor',
      especie: 'Labrador',
      tutor: 'Paula Nunes',
      profissional: 'Dra. Camila',
      motivo: 'Aguardando avaliação clínica',
      sala: 'Sala 02',
      status: StatusConsultaRecepcao.aguardandoVeterinario,
    ),
    ConsultaRecepcao(
      id: 'mel-0900-tomorrow',
      data: hoje.add(const Duration(days: 1)),
      horario: '09:00',
      duracaoMinutos: 30,
      pet: 'Mel',
      especie: 'Poodle',
      tutor: 'Rafael Dias',
      profissional: 'Dra. Beatriz',
      motivo: 'Vacinação',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.agendada,
    ),
    ConsultaRecepcao(
      id: 'bento-1030-tomorrow',
      data: hoje.add(const Duration(days: 1)),
      horario: '10:30',
      duracaoMinutos: 45,
      pet: 'Bento',
      especie: 'Beagle',
      tutor: 'Luiza Prado',
      profissional: 'Dr. Silva',
      motivo: 'Consulta de rotina',
      sala: 'Sala 02',
      status: StatusConsultaRecepcao.agendada,
    ),
    ConsultaRecepcao(
      id: 'amora-1400',
      data: hoje.add(const Duration(days: 3)),
      horario: '14:00',
      duracaoMinutos: 30,
      pet: 'Amora',
      especie: 'Gata',
      tutor: 'Bianca Alves',
      profissional: 'Dra. Camila',
      motivo: 'Retorno',
      sala: 'Sala 01',
      status: StatusConsultaRecepcao.agendada,
    ),
  ];

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
