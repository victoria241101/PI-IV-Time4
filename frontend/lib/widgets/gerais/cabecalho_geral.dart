import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class CabecalhoGeral extends StatelessWidget {
  const CabecalhoGeral({
    super.key,
    this.onPerfilTap,
  });

  final VoidCallback? onPerfilTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessaoUsuario.instancia,
      builder: (context, child) {
        final nome = SessaoUsuario.instancia.nomeUsuario;
        final primeiroNome = nome?.trim().split(' ').first;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.pagePadding,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.pets_rounded,
                size: 30,
                color: CoresApp.primary,
              ),
              const SizedBox(
                width: EspacamentosApp.sm,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PetCare',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: CoresApp.darkBlue,
                    ),
                  ),
                  if (primeiroNome != null &&
                      primeiroNome.isNotEmpty)
                    Text(
                      'Olá, $primeiroNome!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onPerfilTap,
                tooltip: 'Meu perfil',
                style: IconButton.styleFrom(
                  backgroundColor: CoresApp.surface,
                  foregroundColor: CoresApp.darkBlue,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(
                  Icons.person_outline_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}