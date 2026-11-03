// Inicialização e rotas compartilhadas do aplicativo.
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/screens/autenticacao/cadastro.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/doacao/doacao.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/gerais/splash_screen.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/publico/sobre.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/revisao_fluxos_temporaria.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

void main() {
  // Após a revisão, remova o parâmetro home e o import da tela temporária.
  runApp(const AplicativoVeterinaria(home: RevisaoFluxosTemporaria()));
}

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({
    super.key,
    this.home = const SplashScreen(),
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
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/inicio-publico': (context) => const InicioPublico(),
        '/campanhas': (context) => const Doacao(publica: true),
        '/sobre': (context) => const Sobre(),
        '/recepcao': (context) => const InicioRecepcao(),
        '/veterinario': (context) => const InicioVeterinario(),
        '/enfermeiro': (context) => const InicioEnfermeiro(),
      },
    );
  }
}
