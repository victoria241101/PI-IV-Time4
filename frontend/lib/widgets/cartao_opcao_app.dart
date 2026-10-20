import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

/// Cartão selecionável compartilhado por fluxos e formulários.
class CartaoOpcaoApp extends StatelessWidget {
  const CartaoOpcaoApp({
    super.key,
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
    this.selecionado = false,
    this.compacto = false,
  });

  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;
  final bool selecionado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? CoresApp.primary : CoresApp.darkBlue;
    return Semantics(
      button: true,
      selected: selecionado,
      label: '$titulo. $descricao',
      child: Material(
        color: selecionado ? CoresApp.primary.withAlpha(14) : CoresApp.surface,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
          child: Container(
            padding: EdgeInsets.all(
              compacto ? EspacamentosApp.md : EspacamentosApp.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
              border: Border.all(
                color: selecionado ? CoresApp.primary : CoresApp.divider,
                width: selecionado ? 1.5 : 1,
              ),
              boxShadow: EspacamentosApp.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: compacto ? 40 : 48,
                  height: compacto ? 40 : 48,
                  decoration: BoxDecoration(
                    color: cor.withAlpha(20),
                    borderRadius: BorderRadius.circular(
                      EspacamentosApp.radiusMd,
                    ),
                  ),
                  child: Icon(icon, color: cor, size: 22),
                ),
                const SizedBox(width: EspacamentosApp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TipografiaApp.bodyMedium),
                      const SizedBox(height: EspacamentosApp.xs),
                      Text(descricao, style: TipografiaApp.caption),
                    ],
                  ),
                ),
                const SizedBox(width: EspacamentosApp.sm),
                Icon(
                  selecionado
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: selecionado ? 21 : 16,
                  color: cor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
