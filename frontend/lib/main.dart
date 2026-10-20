// inicializacao e rotas principais do aplicativo
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/screens/autenticacao/cadastro.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

void main() {
  runApp(const AplicativoVeterinaria(home: InicioVeterinario()));
}

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ComportamentoRolagemApp(),
      theme: TemaApp.light,
      home: home,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/inicio-publico': (context) => const InicioPublico(),
        '/recepcao': (context) => const InicioRecepcao(),
        '/veterinario': (context) => const InicioVeterinario(),
      },
    );
  }
}
