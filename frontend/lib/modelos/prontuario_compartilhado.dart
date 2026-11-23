// dados clinicos compartilhados entre veterinario e enfermagem

class ProntuarioCompartilhado {
  ProntuarioCompartilhado({
    this.atendimentoId,
    this.observacoesTriagem = '',
    this.descricaoConsulta = '',
    this.retornoRecomendado = '',
    this.internacao = '',
    this.procedimentoIndicado = '',
    this.dataPrevistaInternacao,
    this.internacaoAtiva = false,
    this.internacaoIniciadaEm,
    this.internacaoFinalizadaEm,
    this.observacoes = '',
    List<MedicamentoPrescrito>? medicamentos,
    List<ExameVeterinario>? exames,
    List<ProcedimentoInternacao>? procedimentosInternacao,
    List<MedicacaoInternacao>? medicacoesInternacao,
    List<NotaInternacao>? notasInternacao,
  }) : medicamentos = medicamentos ?? [],
       exames = exames ?? [],
       procedimentosInternacao = procedimentosInternacao ?? [],
       medicacoesInternacao = medicacoesInternacao ?? [],
       notasInternacao = notasInternacao ?? [];

  String? atendimentoId;
  String observacoesTriagem;
  String descricaoConsulta;
  String retornoRecomendado;
  String internacao;
  String procedimentoIndicado;
  DateTime? dataPrevistaInternacao;
  bool internacaoAtiva;
  DateTime? internacaoIniciadaEm;
  DateTime? internacaoFinalizadaEm;
  String observacoes;
  final List<MedicamentoPrescrito> medicamentos;
  final List<ExameVeterinario> exames;
  final List<ProcedimentoInternacao> procedimentosInternacao;
  final List<MedicacaoInternacao> medicacoesInternacao;
  final List<NotaInternacao> notasInternacao;

  ProntuarioCompartilhado copiar() => ProntuarioCompartilhado(
    atendimentoId: atendimentoId,
    observacoesTriagem: observacoesTriagem,
    descricaoConsulta: descricaoConsulta,
    retornoRecomendado: retornoRecomendado,
    internacao: internacao,
    procedimentoIndicado: procedimentoIndicado,
    dataPrevistaInternacao: dataPrevistaInternacao,
    internacaoAtiva: internacaoAtiva,
    internacaoIniciadaEm: internacaoIniciadaEm,
    internacaoFinalizadaEm: internacaoFinalizadaEm,
    observacoes: observacoes,
    medicamentos: medicamentos.map((item) => item.copiar()).toList(),
    exames: List<ExameVeterinario>.of(exames),
    procedimentosInternacao: procedimentosInternacao
        .map((item) => item.copiar())
        .toList(),
    medicacoesInternacao: medicacoesInternacao
        .map((item) => item.copiar())
        .toList(),
    notasInternacao: notasInternacao.map((item) => item.copiar()).toList(),
  );
}

class MedicamentoPrescrito {
  MedicamentoPrescrito({
    required this.nome,
    required this.dosagem,
    required this.orientacao,
    this.id,
    this.petId,
    this.atendimentoId,
    this.frequencia = '',
    this.duracao = '',
    this.status = 'ativa',
  });

  final String nome, dosagem, orientacao, frequencia, duracao, status;
  final String? id, petId, atendimentoId;

  factory MedicamentoPrescrito.fromJson(Map<String, dynamic> dados) {
    String texto(String campo) {
      final valor = dados[campo];
      if (valor is! String || valor.trim().isEmpty) {
        throw FormatException('Prescrição sem $campo válido.');
      }
      return valor;
    }

    return MedicamentoPrescrito(
      id: texto('_id'),
      petId: texto('petId'),
      atendimentoId: texto('atendimentoId'),
      nome: texto('medicamento'),
      dosagem: texto('dose'),
      frequencia: texto('frequencia'),
      duracao: texto('duracao'),
      orientacao: dados['orientacoes'] as String? ?? '',
      status: dados['status'] as String? ?? 'ativa',
    );
  }

  MedicamentoPrescrito copiar() => MedicamentoPrescrito(
    id: id,
    petId: petId,
    atendimentoId: atendimentoId,
    nome: nome,
    dosagem: dosagem,
    orientacao: orientacao,
    frequencia: frequencia,
    duracao: duracao,
    status: status,
  );
}

class ProcedimentoInternacao {
  ProcedimentoInternacao({
    required this.nome,
    required this.agendadoPara,
    this.detalhes = '',
    this.concluidoEm,
    this.detalhesConclusao = '',
  });

  final String nome;
  final DateTime agendadoPara;
  final String detalhes;
  DateTime? concluidoEm;
  String detalhesConclusao;

  ProcedimentoInternacao copiar() => ProcedimentoInternacao(
    nome: nome,
    agendadoPara: agendadoPara,
    detalhes: detalhes,
    concluidoEm: concluidoEm,
    detalhesConclusao: detalhesConclusao,
  );
}

class MedicacaoInternacao {
  MedicacaoInternacao({
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    this.detalhes = '',
    List<AdministracaoMedicacao>? administracoes,
  }) : administracoes = administracoes ?? [];

  final String nome;
  final String dosagem;
  final String frequencia;
  final String detalhes;
  final List<AdministracaoMedicacao> administracoes;

  MedicacaoInternacao copiar() => MedicacaoInternacao(
    nome: nome,
    dosagem: dosagem,
    frequencia: frequencia,
    detalhes: detalhes,
    administracoes: administracoes.map((item) => item.copiar()).toList(),
  );
}

class AdministracaoMedicacao {
  AdministracaoMedicacao({
    required this.realizadaEm,
    required this.responsavel,
    this.observacao = '',
  });

  final DateTime realizadaEm;
  final String responsavel;
  final String observacao;

  AdministracaoMedicacao copiar() => AdministracaoMedicacao(
    realizadaEm: realizadaEm,
    responsavel: responsavel,
    observacao: observacao,
  );
}

class NotaInternacao {
  NotaInternacao({required this.texto, required this.autor});

  final String texto;
  final String autor;

  NotaInternacao copiar() => NotaInternacao(texto: texto, autor: autor);
}

/// Exame veterinário solicitado via API (/exames).
class ExameVeterinario {
  ExameVeterinario({
    required this.nome,
    required this.tipo,
    this.id,
    this.petId,
    this.atendimentoId,
    this.justificativa = '',
    this.status = 'solicitado',
    this.resultado,
  });

  final String? id;
  final String? petId;
  final String? atendimentoId;
  final String nome;
  final String tipo;
  final String justificativa;
  final String status;
  final String? resultado;

  bool get concluido => status == 'concluido';

  factory ExameVeterinario.fromJson(Map<String, dynamic> dados) {
    String? texto(String campo) {
      final valor = dados[campo];
      return valor is String && valor.trim().isNotEmpty ? valor : null;
    }

    return ExameVeterinario(
      id: texto('_id'),
      petId: texto('petId'),
      atendimentoId: texto('atendimentoId'),
      nome: texto('nome') ?? '',
      tipo: texto('tipo') ?? '',
      justificativa: texto('justificativa') ?? '',
      status: texto('status') ?? 'solicitado',
      resultado: texto('resultado'),
    );
  }

  ExameVeterinario copiar() => ExameVeterinario(
    id: id,
    petId: petId,
    atendimentoId: atendimentoId,
    nome: nome,
    tipo: tipo,
    justificativa: justificativa,
    status: status,
    resultado: resultado,
  );
}
