import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';

/// Cartão-base reutilizável com cantos arredondados, fundo branco e sombra discreta.
class CartaoBase extends StatelessWidget {
  const CartaoBase({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(EspacamentosApp.radiusLg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(EspacamentosApp.md),
        decoration: BoxDecoration(
          color: color ?? CoresApp.surface,
          borderRadius: radius,
          boxShadow: EspacamentosApp.cardShadow,
        ),
        child: child,
      ),
    );
  }
}
