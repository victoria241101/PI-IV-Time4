
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class DetalhesAgendamentoTutor extends StatefulWidget {
  const DetalhesAgendamentoTutor({
    super.key,
    required this.dataSelecionada, required List<String> nomesPets,
  });

  final DateTime dataSelecionada;

  @override
  State<DetalhesAgendamentoTutor> createState() =>
      _DetalhesAgendamentoTutorState();
}

class _DetalhesAgendamentoTutorState
    extends State<DetalhesAgendamentoTutor> {
  String get _dataFormatada {
    final data = widget.dataSelecionada;
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        title: Text(
          'Detalhes do agendamento',
          style: TipografiaApp.heading3,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            EspacamentosApp.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _indicadorEtapa(),
              const SizedBox(height: EspacamentosApp.xl),
              _resumoData(),
              const SizedBox(height: EspacamentosApp.xl),
              Text(
                'Vamos organizar a consulta',
                style: TipografiaApp.heading3,
              ),
              const SizedBox(height: EspacamentosApp.sm),
              Text(
                'Escolha os detalhes do atendimento do seu pet.',
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicadorEtapa() {
    return Row(
      children: [
        _etapa('1', 'Data', concluida: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: CoresApp.primary,
          ),
        ),
        _etapa('2', 'Detalhes', atual: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: CoresApp.textSecondary.withAlpha(45),
          ),
        ),
        _etapa('3', 'Revisão'),
      ],
    );
  }

  Widget _etapa(
      String numero,
      String texto, {
        bool concluida = false,
        bool atual = false,
      }) {
    final destacada = concluida || atual;

    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor:
          destacada ? CoresApp.primary : CoresApp.surface,
          child: concluida
              ? const Icon(
            Icons.check,
            color: Colors.white,
            size: 17,
          )
              : Text(
            numero,
            style: TipografiaApp.bodySmall.copyWith(
              color: destacada
                  ? Colors.white
                  : CoresApp.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          texto,
          style: TipografiaApp.bodySmall.copyWith(
            color: destacada
                ? CoresApp.primary
                : CoresApp.textSecondary,
            fontWeight:
            atual ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _resumoData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(
          EspacamentosApp.radiusLg,
        ),
        border: Border.all(
          color: CoresApp.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: CoresApp.primary,
            size: 30,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data selecionada',
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  _dataFormatada,
                  style: TipografiaApp.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: CoresApp.primary,
          ),
        ],
      ),
    );
  }
}
