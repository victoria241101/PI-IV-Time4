// painel resumido dos agendamentos do dia
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/indicador_status.dart';

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
          Text('Acompanhamento de hoje', style: TipografiaApp.heading2),
          const SizedBox(height: EspacamentosApp.xs),
          Text(_dataDeHoje(), style: TipografiaApp.bodySmall),
          const SizedBox(height: EspacamentosApp.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: CoresApp.primary,
                size: 16,
              ),
              const SizedBox(width: EspacamentosApp.xs),
              Text(
                '${consultas.length} consulta${consultas.length == 1 ? '' : 's'}',
                style: TipografiaApp.captionBold,
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.sm),
          if (grupos.isEmpty)
            _vazio()
          else
            for (var i = 0; i < grupos.length; i++)
              _grupoHorario(
                grupos.entries.elementAt(i).key,
                grupos.entries.elementAt(i).value,
                mostrarConector: i < grupos.length - 1,
              ),
        ],
      ),
    );
  }

  Widget _grupoHorario(
    String horario,
    List<ConsultaRecepcao> consultas, {
    required bool mostrarConector,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: EspacamentosApp.sm),
                child: Text(
                  horario,
                  style: TipografiaApp.captionBold.copyWith(fontSize: 13),
                ),
              ),
            ),
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  const SizedBox(height: EspacamentosApp.sm + 2),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: consultas.first.status.cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (mostrarConector)
                    Expanded(
                      child: Center(
                        child: Container(width: 2, color: CoresApp.divider),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: EspacamentosApp.xs),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < consultas.length; i++) ...[
                    _cartaoConsulta(consultas[i]),
                    if (i != consultas.length - 1)
                      const SizedBox(height: EspacamentosApp.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoConsulta(ConsultaRecepcao consulta) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IndicadorStatus(
              label: consulta.status.rotulo,
              color: consulta.status.cor,
            ),
          ),
          const SizedBox(height: EspacamentosApp.sm),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: consulta.emergencia
                      ? const Color(0xFFFFE9E7)
                      : const Color(0xFFFFF1D9),
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusSm),
                ),
                child: Icon(
                  consulta.emergencia
                      ? Icons.warning_amber_rounded
                      : Icons.pets_rounded,
                  color: consulta.emergencia
                      ? CoresApp.danger
                      : CoresApp.darkBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${consulta.pet} · ${consulta.especie}',
                      style: TipografiaApp.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${consulta.profissional} · ${consulta.sala}',
                      style: TipografiaApp.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (consulta.status == StatusConsultaRecepcao.agendada) ...[
            const SizedBox(height: EspacamentosApp.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onConfirmarChegada(consulta),
                icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                label: const Text('Confirmar chegada'),
                style: TextButton.styleFrom(
                  foregroundColor: CoresApp.primaryDark,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vazio() {
    return CartaoBase(
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

  String _dataDeHoje() {
    const dias = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final hoje = DateTime.now();
    return '${dias[hoje.weekday - 1]}, ${hoje.day} de ${meses[hoje.month - 1]}';
  }
}
