// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Validação de sessão e perfil autorizado.
import 'package:flutter/material.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

/// Protege apenas as entradas clínicas, sem alterar o login ou as rotas globais.
class AcessoClinico extends StatelessWidget {
  const AcessoClinico({super.key, required this.perfil, required this.builder});
  final String perfil;
  final WidgetBuilder builder;

    // Exige login e correspondência exata do perfil solicitado pela rota.
  static bool permitido(String perfil) {
    final sessao = SessaoUsuario.instancia;
    return sessao.estaLogado && sessao.tipoUsuario == perfil;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: SessaoUsuario.instancia,
    // Escuta a sessão para liberar ou retirar a tela quando ela muda.
    builder: (context, _) {
      // Usuários autorizados recebem o conteúdo sem alterar o layout global.
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
