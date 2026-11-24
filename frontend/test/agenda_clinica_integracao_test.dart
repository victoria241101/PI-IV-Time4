// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: nomes/IDs da agenda, não duplicação ao recarregar e preservação ante erros.
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';
import 'package:pet_care/services/clinica/consulta_clinica_api.dart';

class _AgendaApi extends ConsultasClinicaService {
  bool falhar = false;
  @override
  Future<List<ConsultaClinicaApi>> listarDia(DateTime data) async {
    if (falhar) throw Exception('API indisponível');
    return [
      ConsultaClinicaApi.fromJson({
        'id': 'C1',
        'petId': 'P1',
        'tutorId': 'T1',
        'veterinarioId': 'V1',
        'petNome': 'Mel',
        'tutorNome': 'Ana',
        'veterinarioNome': 'Dra. Ana',
        'especie': 'gato',
        'dataHora': '2026-11-15T10:00:00',
        'duracaoMinutos': 30,
        'tipo': 'consulta_geral',
        'status': 'agendada',
        'enfermeiroUsuarioId': null,
      }),
    ];
  }
}

void main() {
  test(
    'Agenda carrega nomes e preserva IDs sem duplicar a mesma consulta',
    () async {
      final agenda = AgendaClinica.instancia;
      final anterior = agenda.servico;
      final consultas = List.of(agenda.consultas);
      final prontuarios = Map.of(agenda.prontuarios);
      addTearDown(() {
        agenda.servico = anterior;
        agenda.consultas
          ..clear()
          ..addAll(consultas);
        agenda.prontuarios
          ..clear()
          ..addAll(prontuarios);
      });
      agenda.consultas.clear();
      final api = _AgendaApi();
      agenda.servico = api;
      await agenda.carregarDia(DateTime(2026, 11, 15));
      await agenda.carregarDia(DateTime(2026, 11, 15));
      final consulta = agenda.consultas.single;
      expect(consulta.id, 'C1');
      expect(consulta.pet, 'Mel');
      expect(consulta.petId, 'P1');
      expect(consulta.tutorId, 'T1');
      expect(consulta.veterinarioId, 'V1');
      api.falhar = true;
      await expectLater(
        agenda.carregarDia(DateTime(2026, 11, 15)),
        throwsException,
      );
      expect(agenda.consultas.single, same(consulta));
    },
  );
}
