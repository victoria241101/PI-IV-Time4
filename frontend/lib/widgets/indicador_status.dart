// Etiqueta global de status; preserva as cores, os textos e o tamanho compacto.
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

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
    final luminancia = resolved.computeLuminance();
    final contrasteClaro = 1.05 / (luminancia + 0.05);
    final contrasteEscuro =
        (luminancia + 0.05) / (CoresApp.textPrimary.computeLuminance() + 0.05);
    return Container(
      // Mantém a largura e a altura anteriores, sem o marcador ao lado do texto.
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md + 3,
        vertical: EspacamentosApp.xs,
      ),
      decoration: BoxDecoration(
        color: resolved,
        borderRadius: BorderRadius.circular(EspacamentosApp.xs),
      ),
      child: Text(
        label,
        style: TipografiaApp.captionBold.copyWith(
          color: contrasteClaro > contrasteEscuro
              ? CoresApp.textOnPrimary
              : CoresApp.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
