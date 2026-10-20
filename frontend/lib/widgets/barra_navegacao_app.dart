// barra inferior compartilhada entre os fluxos internos
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

class BarraNavegacaoApp extends StatelessWidget {
  const BarraNavegacaoApp({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: CoresApp.primary,
      unselectedItemColor: CoresApp.textSecondary,
      items: items,
    );
  }
}
