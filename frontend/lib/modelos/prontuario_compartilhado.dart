// dados clinicos compartilhados entre veterinario e enfermagem

class ProntuarioCompartilhado {
  ProntuarioCompartilhado({
    this.observacoesTriagem = '',
    this.descricaoConsulta = '',
    this.retornoRecomendado = '',
    this.internacao = '',
    this.internacaoAtiva = false,
    this.internacaoIniciadaEm,
    this.internacaoFinalizadaEm,
    this.observacoes = '',
    List<MedicamentoPrescrito>? medicamentos,
    List<String>? exames,
    List<ProcedimentoInternacao>? procedimentosInternacao,
    List<MedicacaoInternacao>? medicacoesInternacao,
    List<NotaInternacao>? notasInternacao,
  }) : medicamentos = medicamentos ?? [],
       exames = exames ?? [],
       procedimentosInternacao = procedimentosInternacao ?? [],
       medicacoesInternacao = medicacoesInternacao ?? [],
       notasInternacao = notasInternacao ?? [];

  String observacoesTriagem;
  String descricaoConsulta;
  String retornoRecomendado;
  String internacao;
  bool internacaoAtiva;
  DateTime? internacaoIniciadaEm;
  DateTime? internacaoFinalizadaEm;
  String observacoes;
  final List<MedicamentoPrescrito> medicamentos;
  final List<String> exames;
  final List<ProcedimentoInternacao> procedimentosInternacao;
  final List<MedicacaoInternacao> medicacoesInternacao;
  final List<NotaInternacao> notasInternacao;

  ProntuarioCompartilhado copiar() => ProntuarioCompartilhado(
    observacoesTriagem: observacoesTriagem,
    descricaoConsulta: descricaoConsulta,
    retornoRecomendado: retornoRecomendado,
    internacao: internacao,
    internacaoAtiva: internacaoAtiva,
    internacaoIniciadaEm: internacaoIniciadaEm,
    internacaoFinalizadaEm: internacaoFinalizadaEm,
    observacoes: observacoes,
    medicamentos: medicamentos
        .map(
          (item) => MedicamentoPrescrito(
            nome: item.nome,
            dosagem: item.dosagem,
            orientacao: item.orientacao,
          ),
        )
        .toList(),
    exames: List<String>.of(exames),
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
  });

  final String nome;
  final String dosagem;
  final String orientacao;
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
  NotaInternacao({
    required this.texto,
    required this.autor,
    required this.registradaEm,
  });

  final String texto;
  final String autor;
  final DateTime registradaEm;

  NotaInternacao copiar() => NotaInternacao(
    texto: texto,
    autor: autor,
    registradaEm: registradaEm,
  );
}
