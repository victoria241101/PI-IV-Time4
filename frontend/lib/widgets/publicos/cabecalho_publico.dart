import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/widgets/cabecalho_petcare.dart';

class CabecalhoPublico extends StatelessWidget {
  const CabecalhoPublico({
    super.key,
    this.onBackTap,
  });

  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessaoUsuario.instancia,
      builder: (context, child) {
        final sessao = SessaoUsuario.instancia;

        final cabecalho = CabecalhoPetCare(
          nome: sessao.estaLogado ? sessao.nomeUsuario : null,
          onLoginTap: sessao.estaLogado
              ? null
              : () {
            Navigator.pushNamed(context, '/login');
          },
        );

        if (onBackTap == null) {
          return cabecalho;
        }

        return Row(
          children: [
            IconButton(
              onPressed: onBackTap,
              tooltip: 'Voltar',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CoresApp.darkBlue,
              ),
            ),
            Expanded(
              child: cabecalho,
            ),
          ],
        );
      },
    );
  }
}
