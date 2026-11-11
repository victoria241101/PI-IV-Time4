import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/services/clinica/consulta_clinica_api.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';

Map<String, dynamic> consulta([String id = 'C001']) => {
  'id': id,
  'petId': 'P001',
  'tutorId': 'T001',
  'veterinarioId': 'VET001',
  'dataHora': '2026-11-11T14:30:00',
  'duracaoMinutos': 30,
  'tipo': 'consulta_geral',
  'status': 'chegada_confirmada',
  'enfermeiroUsuarioId': null,
  'podeIniciarTriagem': true,
  'podeContinuarTriagem': false,
};
void main() {
  final api = ConsultasClinicaService(
    baseUrl: 'https://clinica.example.test/',
    obterToken: () => 'token',
  );
  test('Preserva IDs legados e hexadecimais sem usar nomes', () {
    for (final id in ['C001', '6ad699396b4693cb4ce48c33']) {
      final dado = ConsultaClinicaApi.fromJson(consulta(id));
      expect(dado.id, id);
      expect(dado.petId, 'P001');
      expect(dado.veterinarioId, 'VET001');
      expect(dado.tutorId, 'T001');
      expect(dado.dataHora, '2026-11-11T14:30:00');
      expect(dado.podeContinuarTriagem, isFalse);
      expect(dado.statusTela, StatusConsultaRecepcao.aguardandoTriagem);
    }
  });
  test('Mapeia os seis estados e preserva canceladas/desconhecidas', () {
    final estados = [
      'agendada',
      'chegada_confirmada',
      'em_triagem',
      'aguardando_veterinario',
      'em_consulta',
      'finalizada',
    ];
    for (var i = 0; i < estados.length; i++) {
      expect(
        ConsultaClinicaApi.fromJson({...consulta(), 'status': estados[i]})
            .statusTela,
        StatusConsultaRecepcao.values[i],
      );
    }
    for (final status in ['cancelada', 'estado_novo']) {
      final dado = ConsultaClinicaApi.fromJson({
        ...consulta(),
        'status': status,
      });
      expect(dado.status, status);
      expect(dado.statusTela, isNull);
    }
  });
  test('Recusa ID, duração e datas inválidas', () {
    for (final invalido in [
      {'id': ''},
      {'duracaoMinutos': 0},
      {'dataHora': '2026-02-31T14:30:00'},
      {'dataHora': '2026-11-11T14:30:00Z'},
    ]) {
      expect(
        () => ConsultaClinicaApi.fromJson({...consulta(), ...invalido}),
        throwsFormatException,
      );
    }
  });
  test('Busca todas as páginas do dia, usando token e data civil', () async {
    var chamadas = 0;
    await http.runWithClient(
      () async {
        final lista = await api.listarDia(DateTime(2026, 11, 11));
        expect(lista.map((c) => c.id), ['C001', 'C002']);
      },
      () => MockClient((r) async {
        chamadas++;
        expect(r.url.path, '/consultas');
        expect(r.url.queryParameters, {
          'data': '2026-11-11',
          'pagina': '$chamadas',
        });
        expect(r.headers['Authorization'], 'Bearer token');
        return http.Response(
          jsonEncode({
            'consultas': [consulta('C00$chamadas')],
            'pagina': chamadas,
            'temMais': chamadas == 1,
          }),
          200,
        );
      }),
    );
    expect(chamadas, 2);
  });
  test('Operações clínicas usam os endpoints e métodos existentes', () async {
    final recebidas = <String>[];
    await http.runWithClient(
      () async {
        await api.confirmarChegada('C001');
        await api.iniciarTriagem('C001');
        await api.salvarTriagem(
          'C001',
          peso: 8.5,
          temperatura: 38.5,
          sintomas: 'Teste',
        );
        await api.finalizarTriagem('C001');
        await api.iniciarAtendimento('C001');
        await api.salvarAtendimento(
          'C001',
          anamnese: 'a',
          exameFisico: 'e',
          diagnostico: 'd',
          prognostico: 'p',
          tratamento: 't',
        );
        await api.finalizarAtendimento('C001');
      },
      () => MockClient((r) async {
        recebidas.add('${r.method} ${r.url.path}');
        expect(r.headers['Authorization'], 'Bearer token');
        if (r.method == 'POST') {
          final body = jsonDecode(r.body) as Map;
          expect(body.containsKey('petId'), isFalse);
          expect(body.containsKey('veterinarioId'), isFalse);
          expect(body.containsKey('enfermeiroUsuarioId'), isFalse);
          if (r.url.path.endsWith('/triagem')) {
            expect(body['peso'], 8.5);
          } else {
            expect(
              body.keys,
              containsAll([
                'anamnese',
                'exameFisico',
                'diagnostico',
                'prognostico',
                'tratamento',
              ]),
            );
          }
        }
        return http.Response('{"mensagem":"ok"}', 200);
      }),
    );
    expect(recebidas, [
      'PATCH /consultas/C001/confirmar-chegada',
      'PATCH /consultas/C001/iniciar-triagem',
      'POST /consultas/C001/triagem',
      'PATCH /consultas/C001/finalizar-triagem',
      'PATCH /consultas/C001/iniciar-atendimento',
      'POST /consultas/C001/atendimento',
      'PATCH /consultas/C001/finalizar-atendimento',
    ]);
  });
  for (final codigo in [401, 403, 409, 500]) {
    test('Preserva recusa $codigo e não repete envio', () async {
      var chamadas = 0;
      await http.runWithClient(
        () async {
          await expectLater(
            api.confirmarChegada('C001'),
            throwsA(predicate((e) => e.toString().contains('Recusado'))),
          );
        },
        () => MockClient((_) async {
          chamadas++;
          return http.Response('{"mensagem":"Recusado"}', codigo);
        }),
      );
      expect(chamadas, 1);
    });
  }
  test(
    'Sem token não faz requisição; logout durante leitura descarta resultado',
    () async {
      String? token;
      final servico = ConsultasClinicaService(obterToken: () => token);
      var chamadas = 0;
      await http.runWithClient(
        () async {
          await expectLater(
            servico.listarDia(DateTime(2026, 11, 11)),
            throwsStateError,
          );
          expect(chamadas, 0);
          token = 'token';
          await expectLater(
            servico.listarDia(DateTime(2026, 11, 11)),
            throwsStateError,
          );
        },
        () => MockClient((_) async {
          chamadas++;
          token = null;
          return http.Response(
            '{"consultas":[],"pagina":1,"temMais":false}',
            200,
          );
        }),
      );
    },
  );
  test('Falha de transporte não se transforma em agenda vazia', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          api.listarDia(DateTime(2026, 11, 11)),
          throwsA(isA<http.ClientException>()),
        );
      },
      () => MockClient((_) async {
        throw http.ClientException('Sem conexão');
      }),
    );
  });
  test('Reutiliza serviço existente de agendamento com URL e token', () {
    expect(api.agendamentos.baseUrl, 'https://clinica.example.test');
    expect(api.agendamentos.token, 'token');
  });
}
