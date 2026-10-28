
import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/widgets/cabecalho_petcare.dart';

class CabecalhoPublico extends StatelessWidget {
  const CabecalhoPublico({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessaoUsuario.instancia,
      builder: (context, child) {
        final sessao = SessaoUsuario.instancia;

        return CabecalhoPetCare(
          nome: sessao.estaLogado ? sessao.nomeUsuario : null,
          onLoginTap: sessao.estaLogado
              ? null
              : () {
            Navigator.pushNamed(context, '/login');
          },
        );
      },
    );
  }
}
