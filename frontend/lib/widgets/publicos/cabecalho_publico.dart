import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class CabecalhoPublico extends StatelessWidget {
  const CabecalhoPublico({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessaoUsuario.instancia,
      builder: (context, child) {
        final estaLogado = SessaoUsuario.instancia.estaLogado;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.pagePadding,
          ),
          child: Row(
            children: [
              // Logo / identidade
              const Icon(
                Icons.pets_rounded,
                size: 30,
                color: CoresApp.primary,
              ),

              const SizedBox(
                width: EspacamentosApp.sm,
              ),

              const Text(
                'PetCare',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const Spacer(),

              // Só aparece para visitantes.
              if (!estaLogado)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/login',
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: CoresApp.darkBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.sm,
                      vertical: EspacamentosApp.xs,
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}