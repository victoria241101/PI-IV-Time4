import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Botão primário reutilizável do aplicativo.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textColor ?? CoresApp.textOnPrimary),
              const SizedBox(width: EspacamentosApp.sm),
              Text(
                label,
                style: TipografiaApp.button.copyWith(
                  color: textColor ?? CoresApp.textOnPrimary,
                ),
              ),
            ],
          )
        : Text(
            label,
            style: TipografiaApp.button.copyWith(
              color: textColor ?? CoresApp.textOnPrimary,
            ),
          );

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? CoresApp.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.xl,
          vertical: 14,
        ),
        elevation: 0,
      ),
      child: child,
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
