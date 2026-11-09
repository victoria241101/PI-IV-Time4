import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

void main() {
  testWidgets(
    'A fila do enfermeiro contém apenas triagens pendentes e em andamento',
    (tester) async {
      late InicioVeterinario fluxo;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            fluxo =
                const InicioEnfermeiro().build(context) as InicioVeterinario;
            return const SizedBox();
          },
        ),
      );
      final consulta = ConsultaRecepcao(
        id: 'triagem-teste',
        data: DateTime.now(),
        horario: '10:00',
        duracaoMinutos: 30,
        pet: 'Mel',
        especie: 'Cão',
        tutor: 'Ana',
        profissional: 'Dra. Camila',
        motivo: 'Consulta',
        sala: '01',
        status: StatusConsultaRecepcao.aguardandoTriagem,
      );
      final visiveis = <StatusConsultaRecepcao>[];
      for (final status in StatusConsultaRecepcao.values) {
        consulta.status = status;
        if (fluxo.filtroConsultas!(consulta)) visiveis.add(status);
      }
      expect(visiveis, [
        StatusConsultaRecepcao.aguardandoTriagem,
        StatusConsultaRecepcao.emTriagem,
      ]);
      expect(fluxo.profissional, 'Enfermeiro');
      consulta.status = StatusConsultaRecepcao.emTriagem;
      expect(fluxo.filtroConsultas!(consulta), isTrue);
      consulta.status = StatusConsultaRecepcao.aguardandoVeterinario;
      expect(fluxo.filtroConsultas!(consulta), isFalse);
      expect(fluxo.rotuloAcaoConsulta!(consulta), isNull);
    },
  );
}
