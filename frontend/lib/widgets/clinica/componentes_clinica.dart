// Cards, botões, títulos e resumos usados nos três fluxos da clínica.
import 'package:flutter/material.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/botao_principal.dart';

class CartaoClinica extends CartaoBase {
  const CartaoClinica({
    super.key,
    required super.child,
    super.padding,
    super.color = CoresApp.surfaceSoft,
    super.onTap,
    super.borderRadius,
  });
}

class BotaoClinica extends BotaoPrincipal {
  const BotaoClinica({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.expanded,
    super.backgroundColor = CoresApp.primaryDark,
    super.textColor,
  });
}

AppBar cabecalhoClinica(String titulo, {List<Widget>? actions}) => AppBar(
  backgroundColor: CoresApp.darkBlue,
  foregroundColor: CoresApp.textOnDarkBlue,
  elevation: 0,
  title: Text(
    titulo,
    style: TipografiaApp.heading3.copyWith(color: CoresApp.textOnDarkBlue),
  ),
  actions: actions,
);

IconButton botaoAdicionarClinica(VoidCallback onPressed) => IconButton.filled(
  tooltip: 'Adicionar',
  onPressed: onPressed,
  style: IconButton.styleFrom(
    backgroundColor: CoresApp.primaryDark,
    foregroundColor: CoresApp.textOnPrimary,
  ),
  icon: const Icon(Icons.add_rounded),
);

class SecaoClinica extends StatelessWidget {
  const SecaoClinica({
    super.key,
    required this.titulo,
    required this.icone,
    required this.child,
    this.acao,
  });
  final String titulo;
  final IconData icone;
  final Widget child;
  final Widget? acao;
  @override
  Widget build(BuildContext context) => CartaoClinica(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, color: CoresApp.primary, size: 20),
            const SizedBox(width: EspacamentosApp.sm),
            Expanded(child: Text(titulo, style: TipografiaApp.bodyMedium)),
            ?acao,
          ],
        ),
        const SizedBox(height: EspacamentosApp.sm),
        child,
      ],
    ),
  );
}

class ResumoClinica extends StatelessWidget {
  const ResumoClinica({
    super.key,
    required this.titulo,
    required this.indicadores,
    this.distribuirIndicadores = false,
  });
  final bool distribuirIndicadores;
  final String titulo;
  final List<(int, String)> indicadores;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CartaoClinica(
      color: CoresApp.darkBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TipografiaApp.heading2.copyWith(
              color: CoresApp.textOnDarkBlue,
            ),
          ),
          const SizedBox(height: EspacamentosApp.sm),
          if (distribuirIndicadores)
            _indicadoresDistribuidos(context)
          else
            Wrap(
              spacing: EspacamentosApp.sm,
              runSpacing: EspacamentosApp.sm,
              children: indicadores
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.all(EspacamentosApp.sm),
                      decoration: BoxDecoration(
                        color: CoresApp.darkBlueLight,
                        borderRadius: BorderRadius.circular(
                          EspacamentosApp.radiusSm,
                        ),
                      ),
                      child: Text(
                        '${item.$1}  ${item.$2}',
                        style: TipografiaApp.captionBold.copyWith(
                          color: CoresApp.textOnDarkBlue,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    ),
  );
  Widget _indicadoresDistribuidos(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal =
          constraints.maxWidth >= 280 &&
          MediaQuery.textScalerOf(context).scale(14) <= 19;
      Widget indicador((int, String) item) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: CoresApp.darkBlueLight,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusSm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${item.$1}',
              style: TipografiaApp.heading2.copyWith(
                color: CoresApp.textOnDarkBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.$2,
              textAlign: TextAlign.center,
              style: TipografiaApp.captionBold.copyWith(
                color: CoresApp.textOnDarkBlue,
              ),
            ),
          ],
        ),
      );
      if (!horizontal) {
        return Column(
          children: [
            for (var i = 0; i < indicadores.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              indicador(indicadores[i]),
            ],
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < indicadores.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: indicador(indicadores[i])),
            ],
          ],
        ),
      );
    },
  );
}

class RodapeClinica extends StatelessWidget {
  const RodapeClinica({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
      ),
      child: child,
    ),
  );
}
