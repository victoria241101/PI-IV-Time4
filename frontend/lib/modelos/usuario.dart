enum TipoUsuario {
  tutor,
  funcionario,
}

enum CargoFuncionario {
  veterinario,
  secretaria,
  enfermeiro,
}

enum StatusUsuario {
  ativo,
  pendente,
  recusado,
}

class Usuario {
  final String id;
  final String nome;
  final String email;
  final TipoUsuario tipo;
  final CargoFuncionario? cargo;
  final StatusUsuario status;
  final String? clinicaId;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    this.cargo,
    required this.status,
    this.clinicaId,
  });

  // Converte o usuário para um Map.
  // Vai ser útil quando começarmos a enviar os dados para o backend/MongoDB.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo.name,
      'cargo': cargo?.name,
      'status': status.name,
      'clinicaId': clinicaId,
    };
  }

  // Cria um usuário a partir de um Map.
  // Vai ser útil quando o backend devolver os dados do usuário.
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      tipo: TipoUsuario.values.byName(map['tipo'] as String),
      cargo: map['cargo'] != null
          ? CargoFuncionario.values.byName(map['cargo'] as String)
          : null,
      status: StatusUsuario.values.byName(map['status'] as String),
      clinicaId: map['clinicaId'] as String?,
    );
  }

  // Cria uma cópia do usuário alterando apenas os campos necessários.
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    TipoUsuario? tipo,
    CargoFuncionario? cargo,
    StatusUsuario? status,
    String? clinicaId,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      cargo: cargo ?? this.cargo,
      status: status ?? this.status,
      clinicaId: clinicaId ?? this.clinicaId,
    );
  }
}