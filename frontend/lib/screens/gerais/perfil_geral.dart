import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/autenticacao/service/perfil_service.dart';
import 'package:pet_care/widgets/gerais/cabecalho_geral.dart';

class PerfilGeral extends StatefulWidget {
  const PerfilGeral({
    super.key,
  });

  @override
  State<PerfilGeral> createState() => _PerfilGeralState();
}

class _PerfilGeralState extends State<PerfilGeral> {
  // =====================================================
  // AÇÕES DO PERFIL
  // =====================================================

  void _mensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _editarPerfil() async {
    final formKey = GlobalKey<FormState>();

    final nomeController = TextEditingController(
      text: SessaoUsuario.instancia.nomeUsuario ?? '',
    );

    final emailController = TextEditingController(
      text: SessaoUsuario.instancia.emailUsuario ?? '',
    );

    try {
      final resultado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          bool salvando = false;

          return StatefulBuilder(
            builder: (contextDialogo, atualizarDialogo) {
              return AlertDialog(
                backgroundColor: CoresApp.surface,
                title: const Text('Editar perfil'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomeController,
                          enabled: !salvando,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.trim().length < 2) {
                              return 'Informe seu nome completo.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          enabled: !salvando,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            final email = valor?.trim() ?? '';
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Informe um e-mail válido.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: salvando
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;

                      atualizarDialogo(() => salvando = true);

                      try {
                        await SessaoUsuario.instancia.atualizarPerfil(
                          nome: nomeController.text,
                          email: emailController.text,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(true);
                      } catch (erro) {
                        if (!dialogContext.mounted) return;

                        atualizarDialogo(() => salvando = false);

                        ScaffoldMessenger.of(dialogContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Não foi possível solicitar a alteração: $erro',
                              ),
                            ),
                          );
                      }
                    },
                    child: salvando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Solicitar alteração'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (resultado == true && mounted) {
        _mensagem(
          'Solicitação enviada! Verifique seu e-mail para confirmar as alterações.',
        );
      }
    } finally {
      nomeController.dispose();
      emailController.dispose();
    }
  }

  Future<void> _alterarSenha() async {
    final formKey = GlobalKey<FormState>();

    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool salvando = false;
          bool mostrarSenhaAtual = false;
          bool mostrarNovaSenha = false;
          bool mostrarConfirmacao = false;

          return StatefulBuilder(
            builder: (contextDialogo, atualizarDialogo) {
              return AlertDialog(
                backgroundColor: CoresApp.surface,
                title: const Text('Alterar senha'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: senhaAtualController,
                          enabled: !salvando,
                          obscureText: !mostrarSenhaAtual,
                          decoration: InputDecoration(
                            labelText: 'Senha atual',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(
                                      () => mostrarSenhaAtual = !mostrarSenhaAtual,
                                );
                              },
                              icon: Icon(
                                mostrarSenhaAtual
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Informe sua senha atual.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: novaSenhaController,
                          enabled: !salvando,
                          obscureText: !mostrarNovaSenha,
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(
                                      () => mostrarNovaSenha = !mostrarNovaSenha,
                                );
                              },
                              icon: Icon(
                                mostrarNovaSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null || valor.isEmpty) {
                              return 'Informe a nova senha.';
                            }
                            if (valor.length < 8) {
                              return 'Use pelo menos 8 caracteres.';
                            }
                            if (valor == senhaAtualController.text) {
                              return 'Escolha uma senha diferente.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmarSenhaController,
                          enabled: !salvando,
                          obscureText: !mostrarConfirmacao,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nova senha',
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(
                                      () => mostrarConfirmacao = !mostrarConfirmacao,
                                );
                              },
                              icon: Icon(
                                mostrarConfirmacao
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor != novaSenhaController.text) {
                              return 'As senhas não coincidem.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Você receberá um e-mail para confirmar a alteração. '
                              'Sua senha atual continuará válida até a confirmação.',
                          style: TextStyle(
                            fontSize: 12,
                            color: CoresApp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: salvando
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: salvando
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;

                      atualizarDialogo(() => salvando = true);

                      try {
                        final servico = PerfilService.autenticado(
                          baseUrl: 'http://localhost:3000',
                          token: SessaoUsuario.instancia.token!,
                        );

                        await servico.alterarSenha(
                          senhaAtual: senhaAtualController.text,
                          novaSenha: novaSenhaController.text,
                          confirmarSenha: confirmarSenhaController.text,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();

                        _mensagem(
                          'Solicitação enviada! Verifique seu e-mail '
                              'para confirmar a nova senha.',
                        );
                      } catch (erro) {
                        if (!dialogContext.mounted) return;

                        atualizarDialogo(() => salvando = false);

                        ScaffoldMessenger.of(dialogContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Não foi possível solicitar a alteração: $erro',
                              ),
                            ),
                          );
                      }
                    },
                    child: salvando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Solicitar alteração'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      senhaAtualController.dispose();
      novaSenhaController.dispose();
      confirmarSenhaController.dispose();
    }
  }

  Future<void> _sair() async {
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: CoresApp.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  // =====================================================
  // TELA
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.md,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xl,
          ),
          child: AnimatedBuilder(
            animation: SessaoUsuario.instancia,
            builder: (context, child) {
              final nome =
              SessaoUsuario.instancia.nomeUsuario?.trim().isNotEmpty ==
                  true
                  ? SessaoUsuario.instancia.nomeUsuario!.trim()
                  : 'Usuário';

              final email =
              SessaoUsuario.instancia.emailUsuario?.trim().isNotEmpty ==
                  true
                  ? SessaoUsuario.instancia.emailUsuario!.trim()
                  : 'E-mail não informado';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CabecalhoGeral(),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  const Text(
                    'Meu perfil',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: CoresApp.darkBlue,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  const Text(
                    'Gerencie suas informações e configurações da conta.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: CoresApp.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  _CardPerfil(
                    nome: nome,
                    email: email,
                    onEditar: _editarPerfil,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  _SecaoPerfil(
                    titulo: 'Segurança',
                    icone: Icons.shield_outlined,
                    children: [
                      _ItemPerfil(
                        icone: Icons.lock_reset_rounded,
                        titulo: 'Alterar senha',
                        descricao:
                        'Atualize a senha usada para acessar sua conta.',
                        onTap: _alterarSenha,
                      ),

                      const SizedBox(
                        height: EspacamentosApp.sm,
                      ),

                      const _ItemPerfil(
                        icone: Icons.verified_user_outlined,
                        titulo: 'Conta autenticada',
                        descricao:
                        'Você está conectado à sua conta PetCare.',
                        mostrarSeta: false,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  _SecaoPerfil(
                    titulo: 'Conta',
                    icone: Icons.person_outline_rounded,
                    children: [
                      _ItemPerfil(
                        icone: Icons.logout_rounded,
                        titulo: 'Sair da conta',
                        descricao:
                        'Encerrar sua sessão neste dispositivo.',
                        onTap: _sair,
                        corIcone: CoresApp.primary,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

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
              );
            },
          ),
        ),
      ),
    );
  }
}

// =====================================================
// CARD PRINCIPAL DO PERFIL
// =====================================================

class _CardPerfil extends StatelessWidget {
  const _CardPerfil({
    required this.nome,
    required this.email,
    required this.onEditar,
  });

  final String nome;
  final String email;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return Container(
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

          const SizedBox(
            height: EspacamentosApp.md,
          ),

          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CoresApp.darkBlue,
            ),
          ),

          const SizedBox(
            height: EspacamentosApp.lg,
          ),

          _InformacaoPerfil(
            icone: Icons.email_outlined,
            titulo: 'E-mail',
            valor: email,
          ),

          const SizedBox(
            height: EspacamentosApp.sm,
          ),

          const _InformacaoPerfil(
            icone: Icons.phone_outlined,
            titulo: 'Telefone',
            valor: 'Não informado',
          ),

          const SizedBox(
            height: EspacamentosApp.sm,
          ),

          const _InformacaoPerfil(
            icone: Icons.badge_outlined,
            titulo: 'CPF',
            valor: 'Não informado',
          ),

          const SizedBox(
            height: EspacamentosApp.lg,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEditar,
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
    );
  }
}

// =====================================================
// INFORMAÇÕES INDIVIDUAIS
// =====================================================

class _InformacaoPerfil extends StatelessWidget {
  const _InformacaoPerfil({
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
      padding: const EdgeInsets.all(
        EspacamentosApp.md,
      ),
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

          const SizedBox(
            width: EspacamentosApp.md,
          ),

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

// =====================================================
// SEÇÕES DO PERFIL
// =====================================================

class _SecaoPerfil extends StatelessWidget {
  const _SecaoPerfil({
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
      padding: const EdgeInsets.all(
        EspacamentosApp.md,
      ),
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

              const SizedBox(
                width: EspacamentosApp.sm,
              ),

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

          const SizedBox(
            height: EspacamentosApp.md,
          ),

          ...children,
        ],
      ),
    );
  }
}

// =====================================================
// ITENS DAS SEÇÕES
// =====================================================

class _ItemPerfil extends StatelessWidget {
  const _ItemPerfil({
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
      padding: const EdgeInsets.all(
        EspacamentosApp.md,
      ),
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

          const SizedBox(
            width: EspacamentosApp.md,
          ),

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

    if (onTap == null) {
      return conteudo;
    }

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