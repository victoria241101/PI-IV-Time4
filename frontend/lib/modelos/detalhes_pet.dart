import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';

enum CategoriaHistoricoPet { vacina, medicamento, exame }

class RegistroHistoricoPet {
  const RegistroHistoricoPet({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.data,
    this.descricao,
    this.status,
  });

  final String id;
  final CategoriaHistoricoPet categoria;
  final String titulo;
  final String data;
  final String? descricao;
  final String? status;

  factory RegistroHistoricoPet.fromMap(Map<String, Object?> dados) {
    return RegistroHistoricoPet(
      id: dados['id']! as String,
      categoria: switch (dados['categoria']) {
        'vacina' => CategoriaHistoricoPet.vacina,
        'medicamento' => CategoriaHistoricoPet.medicamento,
        'exame' => CategoriaHistoricoPet.exame,
        _ => throw ArgumentError('Categoria de histórico inválida.'),
      },
      titulo: dados['titulo']! as String,
      data: dados['data']! as String,
      descricao: dados['descricao'] as String?,
      status: dados['status'] as String?,
    );
  }
}

class LembretePet {
  const LembretePet({
    required this.titulo,
    required this.prazo,
    required this.categoria,
  });

  final String titulo;
  final String prazo;
  final CategoriaHistoricoPet categoria;

  factory LembretePet.fromMap(Map<String, Object?> dados) {
    return LembretePet(
      titulo: dados['titulo']! as String,
      prazo: dados['prazo']! as String,
      categoria: switch (dados['categoria']) {
        'vacina' => CategoriaHistoricoPet.vacina,
        'medicamento' => CategoriaHistoricoPet.medicamento,
        'exame' => CategoriaHistoricoPet.exame,
        _ => throw ArgumentError('Categoria de lembrete inválida.'),
      },
    );
  }
}

class DetalhesPet {
  const DetalhesPet({
    required this.pet,
    required this.sexo,
    required this.dataNascimento,
    required this.microchip,
    required this.registros,
    required this.lembretes,
    this.proximaConsulta,
  });

  final ResumoPet pet;
  final String sexo;
  final String dataNascimento;
  final String microchip;
  final List<RegistroHistoricoPet> registros;
  final List<LembretePet> lembretes;
  final ResumoConsulta? proximaConsulta;

  factory DetalhesPet.fromMap(Map<String, Object?> dados) {
    final consulta = dados['proximaConsulta'] as Map<String, Object?>?;
    final registros = dados['registros']! as List<Object?>;
    final lembretes = dados['lembretes']! as List<Object?>;

    return DetalhesPet(
      pet: ResumoPet.fromMap(dados),
      sexo: dados['sexo']! as String,
      dataNascimento: dados['dataNascimento']! as String,
      microchip: dados['microchip']! as String,
      proximaConsulta: consulta == null
          ? null
          : ResumoConsulta.fromMap(consulta),
      registros: registros
          .cast<Map<String, Object?>>()
          .map(RegistroHistoricoPet.fromMap)
          .toList(growable: false),
      lembretes: lembretes
          .cast<Map<String, Object?>>()
          .map(LembretePet.fromMap)
          .toList(growable: false),
    );
  }
}
