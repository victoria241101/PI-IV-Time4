import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/widgets/botao_principal.dart';

/// Cartão destacado da próxima consulta.
class CartaoProximaConsulta extends StatelessWidget {
  const CartaoProximaConsulta({
    super.key,
    required this.appointment,
    required this.onDetailsTap,
    this.onConfirmTap,
    this.isConfirming = false,
  });

  final ResumoConsulta appointment;
  final VoidCallback onDetailsTap;
  final VoidCallback? onConfirmTap;
  final bool isConfirming;

  @override
  Widget build(BuildContext context) {
    final secondaryText = CoresApp.cardHighlightText.withAlpha(200);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.lg,
        vertical: EspacamentosApp.lg,
      ),
      decoration: BoxDecoration(
        color: CoresApp.cardHighlight,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusXl),
        boxShadow: EspacamentosApp.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services_outlined,
                color: CoresApp.cardHighlightText.withAlpha(180),
                size: 18,
                semanticLabel: 'Consulta',
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Flexible(
                child: Text(
                  'Próxima consulta',
                  style: TipografiaApp.captionBold.copyWith(
                    color: CoresApp.cardHighlightText.withAlpha(180),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          Text(
            appointment.type,
            style: TipografiaApp.heading3.copyWith(
              color: CoresApp.cardHighlightText,
            ),
          ),
          const SizedBox(height: EspacamentosApp.xs + 2),
          _StatusConsulta(isConfirmed: appointment.isConfirmed),
          const SizedBox(height: EspacamentosApp.md),
          Wrap(
            spacing: EspacamentosApp.md,
            runSpacing: EspacamentosApp.sm,
            children: [
              _InformacaoConsulta(
                icon: Icons.calendar_today_outlined,
                value: appointment.date,
                color: secondaryText,
              ),
              _InformacaoConsulta(
                icon: Icons.access_time_outlined,
                value: appointment.time,
                color: secondaryText,
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.sm),
          _InformacaoConsulta(
            icon: Icons.person_outline_rounded,
            value: '${appointment.vetName} • ${appointment.petName}',
            color: secondaryText,
          ),
          const SizedBox(height: EspacamentosApp.md),
          Divider(color: CoresApp.cardHighlightText.withAlpha(35), height: 1),
          const SizedBox(height: EspacamentosApp.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final useVerticalLayout = constraints.maxWidth < 420;
              final actions = <Widget>[
                if (!appointment.isConfirmed)
                  BotaoPrincipal(
                    label: isConfirming
                        ? 'Confirmando...'
                        : 'Confirmar consulta',
                    icon: isConfirming
                        ? Icons.hourglass_top_rounded
                        : Icons.check_rounded,
                    onPressed: isConfirming ? null : onConfirmTap,
                    expanded: useVerticalLayout,
                    backgroundColor: CoresApp.cardHighlightText,
                    textColor: CoresApp.cardHighlight,
                  ),
                _BotaoDetalhes(
                  onPressed: onDetailsTap,
                  expanded: useVerticalLayout,
                ),
              ];

              if (useVerticalLayout) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      actions[index],
                      if (index != actions.length - 1)
                        const SizedBox(height: EspacamentosApp.sm),
                    ],
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    actions[index],
                    if (index != actions.length - 1)
                      const SizedBox(width: EspacamentosApp.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InformacaoConsulta extends StatelessWidget {
  const _InformacaoConsulta({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: EspacamentosApp.xs + 2),
        Flexible(
          child: Text(
            value,
            style: TipografiaApp.caption.copyWith(color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusConsulta extends StatelessWidget {
  const _StatusConsulta({required this.isConfirmed});

  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final color = isConfirmed
        ? CoresApp.statusConfirmed
        : CoresApp.statusPending;

    return Row(
      children: [
        Icon(
          isConfirmed ? Icons.check_circle_outline : Icons.schedule_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: EspacamentosApp.xs + 2),
        Expanded(
          child: Text(
            isConfirmed ? 'Consulta confirmada' : 'Aguardando confirmação',
            style: TipografiaApp.captionBold.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _BotaoDetalhes extends StatelessWidget {
  const _BotaoDetalhes({required this.onPressed, required this.expanded});

  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      label: 'Ver detalhes da consulta',
      button: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CoresApp.cardHighlightText,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.md,
            vertical: EspacamentosApp.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
          ),
          side: BorderSide(color: CoresApp.cardHighlightText.withAlpha(100)),
        ),
        child: Text(
          'Ver detalhes',
          style: TipografiaApp.buttonSmall.copyWith(
            color: CoresApp.cardHighlightText,
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
