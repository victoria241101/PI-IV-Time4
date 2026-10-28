
import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/widgets/cabecalho_petcare.dart';

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

        return CabecalhoPetCare(
          nome: nome,
        );
      },
    );
  }
}
