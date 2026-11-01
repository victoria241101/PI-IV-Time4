import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

class BarraNavPublica extends StatelessWidget {
  const BarraNavPublica({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: CoresApp.primary,
      unselectedItemColor: CoresApp.textSecondary,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism_outlined),
          activeIcon: Icon(Icons.volunteer_activism_rounded),
          label: 'Campanhas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline_rounded),
          activeIcon: Icon(Icons.info_rounded),
          label: 'Sobre',
        ),
      ],
    );
  }
}