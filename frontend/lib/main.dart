import 'package:flutter/material.dart';
import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/screens/gerais/splash_screen.dart';

void main() {
  runApp(
    const AplicativoVeterinaria(
      home: SplashScreen(),
    ),
  );
}

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({
    super.key,
    required this.home,
  });

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ComportamentoRolagemApp(),
      theme: TemaApp.light,
      home: home,
    );
  }
}