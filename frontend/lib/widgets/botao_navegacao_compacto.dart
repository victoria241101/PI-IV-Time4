import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Botão global compacto para atalhos que abrem outra tela.
class BotaoNavegacaoCompacto extends StatelessWidget {
  const BotaoNavegacaoCompacto({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: CoresApp.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
          side: BorderSide(color: CoresApp.primary.withAlpha(50)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspacamentosApp.md,
                vertical: EspacamentosApp.sm,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: CoresApp.primaryDark),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: TipografiaApp.buttonSmall.copyWith(
                        color: CoresApp.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
