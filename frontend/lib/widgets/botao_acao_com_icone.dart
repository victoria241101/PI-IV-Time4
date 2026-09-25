import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Botão de ação com ícone, reutilizável para ações como "Agendar nova consulta".
class BotaoAcaoComIcone extends StatelessWidget {
  const BotaoAcaoComIcone({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: Material(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EspacamentosApp.lg,
              vertical: EspacamentosApp.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
              boxShadow: EspacamentosApp.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(EspacamentosApp.sm + 2),
                  decoration: BoxDecoration(
                    color: CoresApp.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(
                      EspacamentosApp.radiusMd,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: CoresApp.primary,
                    size: 24,
                    semanticLabel: semanticLabel,
                  ),
                ),
                const SizedBox(width: EspacamentosApp.md),
                Expanded(child: Text(label, style: TipografiaApp.bodyMedium)),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: CoresApp.iconDefault,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
