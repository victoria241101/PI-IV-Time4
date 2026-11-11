import 'package:pet_care/modelos/consulta_recepcao.dart';

/// Contrato de GET /consultas. IDs são opacos: não converter para números
/// nem substituir por nomes exibidos na tela.
class ConsultaClinicaApi {
  const ConsultaClinicaApi({
    required this.id,
    this.petNome,
    this.tutorNome,
    this.veterinarioNome,
    this.especie,
    required this.petId,
    required this.tutorId,
    required this.veterinarioId,
    required this.dataHora,
    required this.duracaoMinutos,
    required this.tipo,
    required this.status,
    required this.enfermeiroUsuarioId,
    required this.podeIniciarTriagem,
    required this.podeContinuarTriagem,
  });

  final String id;
  final String? petNome, tutorNome, veterinarioNome, especie;
  final String? petId, tutorId, veterinarioId, enfermeiroUsuarioId;

  /// Hora civil da clínica; não aplicar conversão UTC/local.
  final String dataHora;
  final int duracaoMinutos;
  final String tipo, status;
  final bool podeIniciarTriagem, podeContinuarTriagem;

  // Canceladas e estados desconhecidos não viram consultas ativas na tela.
  StatusConsultaRecepcao? get statusTela => switch (status) {
    'agendada' => StatusConsultaRecepcao.agendada,
    'chegada_confirmada' => StatusConsultaRecepcao.aguardandoTriagem,
    'em_triagem' => StatusConsultaRecepcao.emTriagem,
    'aguardando_veterinario' => StatusConsultaRecepcao.aguardandoVeterinario,
    'em_consulta' => StatusConsultaRecepcao.emConsulta,
    'finalizada' => StatusConsultaRecepcao.finalizado,
    _ => null,
  };

  factory ConsultaClinicaApi.fromJson(Map<String, dynamic> json) {
    String texto(String chave) {
      final valor = json[chave];
      if (valor is! String || valor.isEmpty) {
        throw FormatException('Consulta com $chave inválido.');
      }
      return valor;
    }

    String? vinculo(String chave) {
      final valor = json[chave];
      if (valor == null) return null;
      return texto(chave);
    }

    final data = texto('dataHora');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$')
            .hasMatch(data) ||
        DateTime.tryParse(data) == null ||
        DateTime.parse(data).toIso8601String().substring(0, 19) !=
            data.substring(0, 19)) {
      throw const FormatException('Data/hora da consulta inválida.');
    }
    final duracao = json['duracaoMinutos'];
    if (duracao is! int || duracao <= 0) {
      throw const FormatException('Duração da consulta inválida.');
    }
    return ConsultaClinicaApi(
      id: texto('id'),
      petNome: json['petNome'] as String?,
      tutorNome: json['tutorNome'] as String?,
      veterinarioNome: json['veterinarioNome'] as String?,
      especie: json['especie'] as String?,
      petId: vinculo('petId'),
      tutorId: vinculo('tutorId'),
      veterinarioId: vinculo('veterinarioId'),
      dataHora: data,
      duracaoMinutos: duracao,
      tipo: texto('tipo'),
      status: texto('status'),
      enfermeiroUsuarioId: vinculo('enfermeiroUsuarioId'),
      podeIniciarTriagem: json['podeIniciarTriagem'] == true,
      podeContinuarTriagem: json['podeContinuarTriagem'] == true,
    );
  }
}
