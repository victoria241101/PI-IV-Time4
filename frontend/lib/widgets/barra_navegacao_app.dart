// Navegação azul compartilhada pelos fluxos de recepção, enfermagem e veterinário.
import 'package:flutter/material.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

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
  Widget build(BuildContext context) => NavigationBarTheme(
    data: const NavigationBarThemeData(
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: CoresApp.textOnDarkBlue),
      ),
    ),
    child: NavigationBar(
      backgroundColor: CoresApp.darkBlue,
      indicatorColor: CoresApp.primary,
      labelTextStyle: WidgetStateProperty.all(
        TipografiaApp.captionBold.copyWith(color: CoresApp.textOnDarkBlue),
      ),
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items
          .map(
            (item) =>
                NavigationDestination(icon: item.icon, label: item.label ?? ''),
          )
          .toList(),
    ),
  );
}
