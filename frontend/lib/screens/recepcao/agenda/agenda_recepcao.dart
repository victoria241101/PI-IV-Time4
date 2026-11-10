// painel resumido dos agendamentos do dia
import 'package:flutter/material.dart';
import 'package:pet_care/core/formatadores/data_app.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/widgets/clinica/cartao_atendimento.dart';

/// Painel enxuto para acompanhar os agendamentos de hoje.
class AgendaRecepcao extends StatelessWidget {
  const AgendaRecepcao({
    super.key,
    required this.consultas,
    required this.onConfirmarChegada,
  });

  final List<ConsultaRecepcao> consultas;
  final ValueChanged<ConsultaRecepcao> onConfirmarChegada;

  @override
  Widget build(BuildContext context) {
    final ordenadas = consultas.toList()
      ..sort((a, b) => a.horario.compareTo(b.horario));
    final grupos = <String, List<ConsultaRecepcao>>{};
    for (final consulta in ordenadas) {
      grupos.putIfAbsent(consulta.horario, () => []).add(consulta);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResumoClinica(
            titulo: 'Acompanhamento de hoje',
            distribuirIndicadores: true,
            indicadores: [
              (
                consultas
                    .where((c) => c.status == StatusConsultaRecepcao.agendada)
                    .length,
                'Aguardando chegada',
              ),
              (
                consultas
                    .where(
                      (c) =>
                          c.status != StatusConsultaRecepcao.agendada &&
                          c.status != StatusConsultaRecepcao.finalizado,
                    )
                    .length,
                'Em atendimento',
              ),
              (
                consultas
                    .where((c) => c.status == StatusConsultaRecepcao.finalizado)
                    .length,
                'Finalizadas',
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          const SizedBox(height: EspacamentosApp.xs),
          Text(
            formatarDataExtensa(DateTime.now()),
            style: TipografiaApp.bodySmall,
          ),
          const SizedBox(height: EspacamentosApp.md),
          Row(
            children: [
              Expanded(
                child: Text('Atendimentos', style: TipografiaApp.heading3),
              ),
              Text(
                '${consultas.length} consulta${consultas.length == 1 ? '' : 's'}',
                style: TipografiaApp.caption,
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.sm),
          if (ordenadas.isEmpty)
            _vazio()
          else
            for (final grupo in grupos.entries) ...[
              CartaoClinica(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 20,
                          color: CoresApp.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          grupo.key,
                          style: TipografiaApp.bodyMedium.copyWith(
                            color: CoresApp.primaryDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${grupo.value.length} atendimento${grupo.value.length == 1 ? '' : 's'}',
                          style: TipografiaApp.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: EspacamentosApp.md),
                    for (var i = 0; i < grupo.value.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: EspacamentosApp.md,
                          ),
                          child: Divider(height: 1),
                        ),
                      _atendimento(grupo.value[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: EspacamentosApp.md),
            ],
        ],
      ),
    );
  }

  Widget _atendimento(ConsultaRecepcao consulta) => CartaoAtendimento(
    consulta: consulta,
    mostrarSala: true,
    mostrarHorario: false,
    agrupado: true,
    emergenciaCompacta: true,
    acao: consulta.status == StatusConsultaRecepcao.agendada
        ? 'Confirmar chegada'
        : null,
    iconeAcao: Icons.how_to_reg_outlined,
    onAcao: consulta.status == StatusConsultaRecepcao.agendada
        ? () => onConfirmarChegada(consulta)
        : null,
  );

  Widget _vazio() {
    return CartaoClinica(
      padding: const EdgeInsets.all(EspacamentosApp.xl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 36,
              color: CoresApp.iconDefault,
            ),
            const SizedBox(height: EspacamentosApp.sm),
            Text('Nenhuma consulta hoje', style: TipografiaApp.bodyMedium),
            const SizedBox(height: EspacamentosApp.xs),
            Text(
              'Os atendimentos do dia aparecerão aqui',
              textAlign: TextAlign.center,
              style: TipografiaApp.caption,
            ),
          ],
        ),
      ),
    );
  }
}
