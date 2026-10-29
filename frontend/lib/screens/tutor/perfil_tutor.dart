
import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/barra_nav_tutor.dart';

class PerfilTutor extends StatelessWidget {
  const PerfilTutor({super.key});

  void _voltarParaAba(BuildContext context, int index) {
    if (index == 4) return;

    Navigator.of(context).pop(index);
  }

  void _mostrarAviso(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CoresApp.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Sair da conta',
            style: TextStyle(
              color: CoresApp.darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta?',
            style: TextStyle(
              color: CoresApp.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                'Sair',
                style: TextStyle(
                  color: CoresApp.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await SessaoUsuario.instancia.sair();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: SessaoUsuario.instancia,
          builder: (context, child) {
            final nome = SessaoUsuario
                .instancia.nomeUsuario
                ?.trim()
                .isNotEmpty == true
                ? SessaoUsuario.instancia.nomeUsuario!.trim()
                : 'Usuário';

            final email = SessaoUsuario
                .instancia.emailUsuario
                ?.trim()
                .isNotEmpty == true
                ? SessaoUsuario.instancia.emailUsuario!.trim()
                : 'E-mail não informado';

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                EspacamentosApp.pagePadding,
                EspacamentosApp.lg,
                EspacamentosApp.pagePadding,
                EspacamentosApp.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: CoresApp.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: CoresApp.primary,
                          size: 27,
                        ),
                      ),
                      const SizedBox(
                        width: EspacamentosApp.md,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PetCare',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: CoresApp.textSecondary,
                              ),
                            ),
                            Text(
                              'Meu perfil',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: CoresApp.darkBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: EspacamentosApp.sm),
                  const Text(
                    'Gerencie suas informações e configurações da conta.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.lg),

                  // Dados do tutor
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      EspacamentosApp.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.black.withAlpha(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CoresApp.darkBlue.withAlpha(18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CoresApp.primary.withAlpha(20),
                            border: Border.all(
                              color: CoresApp.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: CoresApp.primary,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.md),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: CoresApp.darkBlue,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.lg),
                        _InformacaoPerfilTutor(
                          icone: Icons.email_outlined,
                          titulo: 'E-mail',
                          valor: email,
                        ),
                        const SizedBox(height: EspacamentosApp.sm),
                        const _InformacaoPerfilTutor(
                          icone: Icons.phone_outlined,
                          titulo: 'Telefone',
                          valor: 'Não informado',
                        ),
                        const SizedBox(height: EspacamentosApp.sm),
                        const _InformacaoPerfilTutor(
                          icone: Icons.badge_outlined,
                          titulo: 'CPF',
                          valor: 'Não informado',
                        ),
                        const SizedBox(height: EspacamentosApp.lg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarAviso(
                              context,
                              'A edição do perfil será implementada em seguida.',
                            ),
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'Editar perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CoresApp.darkBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: EspacamentosApp.lg),

                  _SecaoPerfilTutor(
                    titulo: 'Segurança',
                    icone: Icons.shield_outlined,
                    children: [
                      _ItemPerfilTutor(
                        icone: Icons.lock_reset_rounded,
                        titulo: 'Alterar senha',
                        descricao:
                        'Atualize a senha usada para acessar sua conta.',
                        onTap: () => _mostrarAviso(
                          context,
                          'A alteração de senha será implementada em seguida.',
                        ),
                      ),
                      const SizedBox(height: EspacamentosApp.sm),
                      const _ItemPerfilTutor(
                        icone: Icons.verified_user_outlined,
                        titulo: 'Conta autenticada',
                        descricao:
                        'Você está conectado à sua conta PetCare.',
                        mostrarSeta: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: EspacamentosApp.lg),

                  _SecaoPerfilTutor(
                    titulo: 'Conta',
                    icone: Icons.person_outline_rounded,
                    children: [
                      _ItemPerfilTutor(
                        icone: Icons.logout_rounded,
                        titulo: 'Sair da conta',
                        descricao:
                        'Encerrar sua sessão neste dispositivo.',
                        corIcone: CoresApp.primary,
                        onTap: () => _sair(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: EspacamentosApp.xl),

                  const Center(
                    child: Text(
                      'PetCare • Cuidar também é uma forma de amar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BarraNavTutor(
        currentIndex: 4,
        onTap: (index) => _voltarParaAba(context, index),
      ),
    );
  }
}

class _InformacaoPerfilTutor extends StatelessWidget {
  const _InformacaoPerfilTutor({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  final IconData icone;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: CoresApp.primary,
            size: 20,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoPerfilTutor extends StatelessWidget {
  const _SecaoPerfilTutor({
    required this.titulo,
    required this.icone,
    required this.children,
  });

  final String titulo;
  final IconData icone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: CoresApp.primary,
                size: 20,
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          ...children,
        ],
      ),
    );
  }
}

class _ItemPerfilTutor extends StatelessWidget {
  const _ItemPerfilTutor({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.onTap,
    this.mostrarSeta = true,
    this.corIcone,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback? onTap;
  final bool mostrarSeta;
  final Color? corIcone;

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: corIcone ?? CoresApp.primary,
            size: 21,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (mostrarSeta)
            const Icon(
              Icons.chevron_right_rounded,
              color: CoresApp.textSecondary,
              size: 21,
            ),
        ],
      ),
    );

    if (onTap == null) return conteudo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: conteudo,
      ),
    );
  }
}
