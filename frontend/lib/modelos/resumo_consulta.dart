/// resumo de uma consulta para exibição em cartões e modais
class ResumoConsulta {
  const ResumoConsulta({
    required this.id,
    required this.type,
    required this.date,
    required this.time,
    required this.vetName,
    required this.petName,
    this.status = 'Confirmada',
    this.petPhotoUrl,
    this.vetPhotoUrl,
    this.instructions,
    this.clinicAddress,
  });

  final String id;
  final String type;
  final String date;
  final String time;
  final String vetName;
  final String petName;
  final String status;
  final String? petPhotoUrl;
  final String? vetPhotoUrl;
  final String? instructions;
  final String? clinicAddress;

  bool get isConfirmed => status.toLowerCase() == 'confirmada';

  ResumoConsulta copyWith({String? status}) {
    return ResumoConsulta(
      id: id,
      type: type,
      date: date,
      time: time,
      vetName: vetName,
      petName: petName,
      status: status ?? this.status,
      petPhotoUrl: petPhotoUrl,
      vetPhotoUrl: vetPhotoUrl,
      instructions: instructions,
      clinicAddress: clinicAddress,
    );
  }

  factory ResumoConsulta.fromMap(Map<String, Object?> dados) {
    return ResumoConsulta(
      id: dados['id']! as String,
      type: dados['tipo']! as String,
      date: dados['data']! as String,
      time: dados['horario']! as String,
      vetName: dados['nomeVeterinario']! as String,
      petName: dados['nomePet']! as String,
      status: dados['status'] as String? ?? 'Confirmada',
      petPhotoUrl: dados['urlFotoPet'] as String?,
      vetPhotoUrl: dados['urlFotoVeterinario'] as String?,
      instructions: dados['orientacoes'] as String?,
      clinicAddress: dados['enderecoClinica'] as String?,
    );
  }
}
