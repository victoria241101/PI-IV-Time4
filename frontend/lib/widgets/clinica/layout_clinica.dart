// Estrutura comum das abas, do cabeçalho e da navegação dos três fluxos.
import 'package:flutter/material.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/barra_navegacao_app.dart';

class LayoutClinica extends StatelessWidget {
  const LayoutClinica({
    super.key,
    required this.nomePadrao,
    required this.abaAtual,
    required this.onSelecionarAba,
    required this.paginas,
    required this.terceiraAba,
    required this.onNotificacao,
  });
  final String nomePadrao;
  final int abaAtual;
  final ValueChanged<int> onSelecionarAba;
  final List<Widget> paginas;
  final BottomNavigationBarItem terceiraAba;
  final VoidCallback onNotificacao;
  Future<void> _sair(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CoresApp.surface,
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    // A proteção de acesso pode remover esta tela ao encerrar a sessão.
    final navegador = Navigator.of(context);
    await SessaoUsuario.instancia.sair();
    if (!navegador.mounted) return;
    navegador.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final hora = TimeOfDay.now().hour;
    final saudacao = hora < 12
        ? 'Bom dia'
        : hora < 18
        ? 'Boa tarde'
        : 'Boa noite';
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: EspacamentosApp.md,
                bottom: EspacamentosApp.xs,
              ),
              child: AnimatedBuilder(
                animation: SessaoUsuario.instancia,
                builder: (context, _) {
                  final nome = SessaoUsuario.instancia.nomeUsuario;
                  return CabecalhoApp(
                    greeting: saudacao,
                    name: nome == null || nome.isEmpty ? nomePadrao : nome,
                    onNotificationTap: onNotificacao,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspacamentosApp.md,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _sair(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(index: abaAtual, children: paginas),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacaoApp(
        currentIndex: abaAtual,
        onTap: onSelecionarAba,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today_rounded),
            label: 'Hoje',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          terceiraAba,
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
