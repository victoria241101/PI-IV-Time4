import 'package:flutter/material.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

/// Protege apenas as entradas clínicas, sem alterar o login ou as rotas globais.
class AcessoClinico extends StatelessWidget {
  const AcessoClinico({super.key, required this.perfil, required this.builder});
  final String perfil;
  final WidgetBuilder builder;

  static bool permitido(String perfil) {
    final sessao = SessaoUsuario.instancia;
    return sessao.estaLogado && sessao.tipoUsuario == perfil;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: SessaoUsuario.instancia,
    builder: (context, _) {
      if (permitido(perfil)) return builder(context);
      final logado = SessaoUsuario.instancia.estaLogado;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                logado
                    ? 'Esta tela pertence a outro perfil.'
                    : 'Entre na sua conta para acessar a clínica.',
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  logado ? '/inicio-autenticado' : '/login',
                  (_) => false,
                ),
                child: Text(logado ? 'Ir para meu início' : 'Entrar'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
