import 'package:pet_care/modelos/prontuario_compartilhado.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/veterinario/consulta_veterinario.dart';
import 'package:pet_care/services/clinica/consultas_clinica_service.dart';

const idAtendimento = '507f1f77bcf86cd799439011';
const campos = {
  'Anamnese': 'anamnese',
  'Exame físico': 'exameFisico',
  'Diagnóstico': 'diagnostico',
  'Prognóstico': 'prognostico',
  'Tratamento': 'tratamento',
};

Future<String> salvar(ConsultasClinicaService api) => api.salvarAtendimento(
  'C1',
  anamnese: 'a',
  exameFisico: 'e',
  diagnostico: 'd',
  prognostico: 'p',
  tratamento: 't',
);

void main() {
  test(
    'Serviço retorna o ID real e recupera o mesmo ID pelo prontuário',
    () async {
      final api = ConsultasClinicaService(obterToken: () => 'token');
      await http.runWithClient(
        () async {
          expect(await salvar(api), idAtendimento);
          final dados = await api.lerProntuario('C1');
          expect(dados['atendimento']['_id'], idAtendimento);
        },
        () => MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer token');
          return http.Response(
            jsonEncode(
              r.method == 'POST'
                  ? {'atendimentoId': idAtendimento}
                  : {
                      'triagem': null,
                      'atendimento': {'_id': idAtendimento},
                    },
            ),
            r.method == 'POST' ? 201 : 200,
          );
        }),
      );
    },
  );

  test('Resposta sem ID válido é recusada sem repetir o salvamento', () async {
    final api = ConsultasClinicaService(obterToken: () => 'token');
    for (final id in [null, '', ' ', 123]) {
      var envios = 0;
      await http.runWithClient(
        () async {
          await expectLater(salvar(api), throwsFormatException);
          await expectLater(api.lerProntuario('C1'), throwsFormatException);
        },
        () => MockClient((r) async {
          if (r.method == 'POST') envios++;
          return http.Response(
            jsonEncode(
              r.method == 'POST'
                  ? {'atendimentoId': id}
                  : {
                      'triagem': null,
                      'atendimento': {'_id': id},
                    },
            ),
            200,
          );
        }),
      );
      expect(envios, 1);
    }
  });

  final agenda = AgendaClinica.instancia;
  late ConsultasClinicaService servicoAnterior;
  setUp(() {
    servicoAnterior = agenda.servico;
    agenda.prontuarios.clear();
  });
  tearDown(() {
    agenda.servico = servicoAnterior;
    agenda.prontuarios.clear();
  });

  Future<ConsultaRecepcao> abrir(
    WidgetTester tester,
    _ApiAtendimento api,
  ) async {
    agenda.servico = api;
    final consulta = ConsultaRecepcao(
      id: 'C1',
      petId: 'P1',
      data: DateTime(2026, 11, 22),
      horario: '10:00',
      duracaoMinutos: 30,
      pet: 'Mel',
      especie: 'Cachorro',
      tutor: 'Tutor',
      profissional: 'Veterinária',
      motivo: 'Consulta',
      sala: '1',
      status: StatusConsultaRecepcao.emConsulta,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConsultaVeterinario(consulta: consulta),
                ),
              ),
              child: const Text('Abrir atendimento'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir atendimento'));
    await tester.pumpAndSettle();
    return consulta;
  }

  Future<void> preencher(WidgetTester tester) async {
    for (final nome in campos.keys) {
      final campo = find.widgetWithText(TextField, nome);
      await tester.scrollUntilVisible(
        campo,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(campo, 'Informação clínica');
    }
  }

  testWidgets('Reabrir atendimento salvo recupera o ID e não repete POST', (
    tester,
  ) async {
    final api = _ApiAtendimento()
      ..registro = {
        '_id': idAtendimento,
        for (final campo in campos.values) campo: 'Salvo na API',
      };
    final consulta = await abrir(tester, api);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Anamnese'))
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Finalizar consulta'));
    await tester.pumpAndSettle();
    expect(api.salvamentos, 0);
    expect(api.finalizacoes, 1);
    expect(consulta.status, StatusConsultaRecepcao.finalizado);
    expect(agenda.prontuarioDa(consulta).atendimentoId, idAtendimento);
    expect(agenda.prontuarioDa(consulta).copiar().atendimentoId, idAtendimento);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Resposta perdida após gravar é recuperada antes de tentar novamente',
    (tester) async {
      final api = _ApiAtendimento()..perderResposta = true;
      final consulta = await abrir(tester, api);
      await preencher(tester);
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(api.salvamentos, 1);
      expect(api.finalizacoes, 0);
      expect(consulta.status, StatusConsultaRecepcao.emConsulta);
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(api.salvamentos, 1);
      expect(api.finalizacoes, 1);
      expect(agenda.prontuarioDa(consulta).atendimentoId, idAtendimento);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Falha ao finalizar preserva o atendimento e permite retomar após sair da tela',
    (tester) async {
      final api = _ApiAtendimento()..falharFinalizacao = true;
      final consulta = await abrir(tester, api);
      await preencher(tester);
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(api.salvamentos, 1);
      expect(consulta.status, StatusConsultaRecepcao.emConsulta);
      await tester.pageBack();
      await tester.pumpAndSettle();
      api.falharFinalizacao = false;
      await tester.tap(find.text('Abrir atendimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar consulta'));
      await tester.pumpAndSettle();
      expect(api.salvamentos, 1);
      expect(api.finalizacoes, 2);
      expect(agenda.prontuarioDa(consulta).atendimentoId, idAtendimento);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ApiAtendimento extends ConsultasClinicaService {
  Map<String, dynamic>? registro;
  int salvamentos = 0, finalizacoes = 0;
  bool perderResposta = false, falharFinalizacao = false;

  @override
  Future<List<MedicamentoPrescrito>> listarPrescricoes(
    String petId, {
    String? atendimentoId,
  }) async => [];

  @override
  Future<Map<String, dynamic>> lerProntuario(String id) async => {
    'triagem': null,
    'atendimento': registro,
  };

  @override
  Future<String> salvarAtendimento(
    String id, {
    required String anamnese,
    required String exameFisico,
    required String diagnostico,
    required String prognostico,
    required String tratamento,
    String observacoes = '',
    String? codigoICDVet,
  }) async {
    salvamentos++;
    registro = {
      '_id': idAtendimento,
      'anamnese': anamnese,
      'exameFisico': exameFisico,
      'diagnostico': diagnostico,
      'prognostico': prognostico,
      'tratamento': tratamento,
    };
    if (perderResposta) throw Exception('Resposta não recebida');
    return idAtendimento;
  }

  @override
  Future<void> finalizarAtendimento(String id) async {
    finalizacoes++;
    if (falharFinalizacao) throw Exception('Falha ao finalizar');
  }
}
