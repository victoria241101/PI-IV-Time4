enum StatusInternacaoPet {
  aguardandoAdmissao,
  internado,
  altaConcedida,
  encerrada,
}

class AtualizacaoInternacaoPet {
  const AtualizacaoInternacaoPet({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataHora,
    this.responsavel,
  });

  final String id;
  final String titulo;
  final String descricao;
  final DateTime dataHora;
  final String? responsavel;

  factory AtualizacaoInternacaoPet.fromMap(
      Map<String, Object?> dados,
      ) {
    return AtualizacaoInternacaoPet(
      id: dados['id']! as String,
      titulo: dados['titulo']! as String,
      descricao: dados['descricao']! as String,
      dataHora: DateTime.parse(dados['dataHora']! as String),
      responsavel: dados['responsavel'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'dataHora': dataHora.toIso8601String(),
      'responsavel': responsavel,
    };
  }
}

class InternacaoPet {
  const InternacaoPet({
    required this.id,
    required this.petId,
    required this.motivo,
    required this.dataEntrada,
    required this.status,
    required this.resumoAtual,
    required this.atualizacoes,
    this.dataPrevisaoAlta,
    this.dataAlta,
    this.veterinarioResponsavel,
    this.ultimaAtualizacao,
  });

  final String id;
  final String petId;
  final String motivo;
  final DateTime dataEntrada;
  final StatusInternacaoPet status;
  final String resumoAtual;
  final List<AtualizacaoInternacaoPet> atualizacoes;
  final DateTime? dataPrevisaoAlta;
  final DateTime? dataAlta;
  final String? veterinarioResponsavel;
  final DateTime? ultimaAtualizacao;

  bool get estaAtiva =>
      status == StatusInternacaoPet.aguardandoAdmissao ||
          status == StatusInternacaoPet.internado;

  factory InternacaoPet.fromMap(Map<String, Object?> dados) {
    final atualizacoes = dados['atualizacoes'] as List<Object?>? ?? [];

    return InternacaoPet(
      id: dados['id']! as String,
      petId: dados['petId']! as String,
      motivo: dados['motivo']! as String,
      dataEntrada: DateTime.parse(
        dados['dataEntrada']! as String,
      ),
      status: _statusFromString(dados['status']! as String),
      resumoAtual: dados['resumoAtual']! as String,
      atualizacoes: atualizacoes
          .map(
            (item) => AtualizacaoInternacaoPet.fromMap(
          Map<String, Object?>.from(item as Map),
        ),
      )
          .toList(growable: false),
      dataPrevisaoAlta: dados['dataPrevisaoAlta'] == null
          ? null
          : DateTime.parse(dados['dataPrevisaoAlta']! as String),
      dataAlta: dados['dataAlta'] == null
          ? null
          : DateTime.parse(dados['dataAlta']! as String),
      veterinarioResponsavel:
      dados['veterinarioResponsavel'] as String?,
      ultimaAtualizacao: dados['ultimaAtualizacao'] == null
          ? null
          : DateTime.parse(dados['ultimaAtualizacao']! as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'petId': petId,
      'motivo': motivo,
      'dataEntrada': dataEntrada.toIso8601String(),
      'status': status.name,
      'resumoAtual': resumoAtual,
      'atualizacoes': atualizacoes.map((item) => item.toMap()).toList(),
      'dataPrevisaoAlta': dataPrevisaoAlta?.toIso8601String(),
      'dataAlta': dataAlta?.toIso8601String(),
      'veterinarioResponsavel': veterinarioResponsavel,
      'ultimaAtualizacao': ultimaAtualizacao?.toIso8601String(),
    };
  }

  static StatusInternacaoPet _statusFromString(String valor) {
    return StatusInternacaoPet.values.firstWhere(
          (status) => status.name == valor,
      orElse: () => throw ArgumentError(
        'Status de internação inválido: $valor',
      ),
    );
  }
}