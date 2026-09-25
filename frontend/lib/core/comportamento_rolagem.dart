import 'package:flutter/material.dart';

/// Comportamento de rolagem global do app
class ComportamentoRolagemApp extends MaterialScrollBehavior {
  const ComportamentoRolagemApp();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Sem indicador de overscroll (glow/stretch).
    return child;
  }
}
