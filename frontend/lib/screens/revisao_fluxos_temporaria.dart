// Tela temporária com três botões para revisar os fluxos; pode ser removida após a revisão.
import 'package:flutter/material.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

class RevisaoFluxosTemporaria extends StatelessWidget {
  const RevisaoFluxosTemporaria({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _abrir(context, const InicioRecepcao()),
              child: const Text('Secretária / Recepção'),
            ),
            TextButton(
              onPressed: () => _abrir(context, const InicioEnfermeiro()),
              child: const Text('Enfermeiro'),
            ),
            TextButton(
              onPressed: () => _abrir(context, const InicioVeterinario()),
              child: const Text('Veterinário'),
            ),
          ],
        ),
      ),
    ),
  );

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Revisão dos fluxos'),
          ),
          body: pagina,
        ),
      ),
    );
  }
}
