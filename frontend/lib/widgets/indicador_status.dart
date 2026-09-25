import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Indicador de status reutilizável (ex.: Confirmada, Pendente, Cancelada).
class IndicadorStatus extends StatelessWidget {
  const IndicadorStatus({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  Color get _resolvedColor {
    if (color != null) return color!;
    switch (label.toLowerCase()) {
      case 'confirmada':
      case 'consulta confirmada':
        return CoresApp.statusConfirmed;
      case 'pendente':
      case 'aguardando confirmação':
        return CoresApp.statusPending;
      case 'cancelada':
        return CoresApp.statusCancelled;
      default:
        return CoresApp.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.sm + 4,
        vertical: EspacamentosApp.xs,
      ),
      decoration: BoxDecoration(
        color: resolved.withAlpha(30),
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: resolved, shape: BoxShape.circle),
          ),
          const SizedBox(width: EspacamentosApp.xs + 2),
          Flexible(
            child: Text(
              label,
              style: TipografiaApp.captionBold.copyWith(color: resolved),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
