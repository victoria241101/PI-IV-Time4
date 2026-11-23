import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';

/// Cartão destacado da próxima consulta.
class CartaoProximaConsulta extends StatelessWidget {
  const CartaoProximaConsulta({
    super.key,
    required this.appointment,
    required this.onDetailsTap,
  });

  final ResumoConsulta appointment;
  final VoidCallback onDetailsTap;

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
              if (useVerticalLayout) {
                return _BotaoDetalhes(
                  onPressed: onDetailsTap,
                  expanded: true,
                );
              }

              return Align(
                alignment: Alignment.centerRight,
                child: _BotaoDetalhes(
                  onPressed: onDetailsTap,
                  expanded: false,
                ),
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
