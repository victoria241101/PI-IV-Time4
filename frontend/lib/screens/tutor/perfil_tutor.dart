import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class PerfilTutor extends StatefulWidget {
  const PerfilTutor({super.key});

  @override
  State<PerfilTutor> createState() => _PerfilTutorState();
}

class _PerfilTutorState extends State<PerfilTutor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;

  bool _salvandoPerfil = false;

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(
      text: SessaoUsuario.instancia.nomeUsuario ?? '',
    );

    _emailController = TextEditingController(
      text: SessaoUsuario.instancia.emailUsuario ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String mensagem) {
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

  // ============================================================
  // EDITAR PERFIL
  // ============================================================

  Future<void> _editarPerfil() async {
    _nomeController.text =
        SessaoUsuario.instancia.nomeUsuario ?? '';

    _emailController.text =
        SessaoUsuario.instancia.emailUsuario ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool salvando = false;

        return StatefulBuilder(
          builder: (contextDialogo, atualizarDialogo) {
            return AlertDialog(
              backgroundColor: CoresApp.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Editar perfil',
                style: TextStyle(
                  color: CoresApp.darkBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        textCapitalization:
                        TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null ||
                              valor.trim().isEmpty) {
                            return 'Informe seu nome.';
                          }

                          if (valor.trim().length < 2) {
                            return 'Digite um nome válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          final email = valor?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Informe seu e-mail.';
                          }

                          final formatoValido = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email);

                          if (!formatoValido) {
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
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: salvando
                      ? null
                      : () {
                    if (!_formKey.currentState!
                        .validate()) {
                      return;
                    }

                    atualizarDialogo(() {
                      salvando = true;
                    });

                    // A sessão atual expõe os dados para leitura,
                    // mas não temos aqui um método confirmado
                    // para persistir as alterações no backend.
                    atualizarDialogo(() {
                      salvando = false;
                    });

                    Navigator.of(dialogContext).pop();

                    _mostrarMensagem(
                      'O formulário foi validado. '
                          'A gravação permanente depende da '
                          'integração de atualização do usuário.',
                    );
                  },
                  child: salvando
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  Future<void> _alterarSenha() async {
    final formKeySenha = GlobalKey<FormState>();

    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    bool mostrarSenhaAtual = false;
    bool mostrarNovaSenha = false;
    bool mostrarConfirmacao = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (contextDialogo, atualizarDialogo) {
              return AlertDialog(
                backgroundColor: CoresApp.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text(
                  'Alterar senha',
                  style: TextStyle(
                    color: CoresApp.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: Form(
                  key: formKeySenha,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: senhaAtualController,
                          obscureText: !mostrarSenhaAtual,
                          decoration: InputDecoration(
                            labelText: 'Senha atual',
                            prefixIcon:
                            const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(() {
                                  mostrarSenhaAtual =
                                  !mostrarSenhaAtual;
                                });
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
                          obscureText: !mostrarNovaSenha,
                          decoration: InputDecoration(
                            labelText: 'Nova senha',
                            prefixIcon:
                            const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(() {
                                  mostrarNovaSenha =
                                  !mostrarNovaSenha;
                                });
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
                          obscureText: !mostrarConfirmacao,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nova senha',
                            prefixIcon:
                            const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              onPressed: () {
                                atualizarDialogo(() {
                                  mostrarConfirmacao =
                                  !mostrarConfirmacao;
                                });
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKeySenha.currentState!.validate()) {
                        return;
                      }

                      Navigator.of(dialogContext).pop();

                      _mostrarMensagem(
                        'Os dados foram validados. '
                            'A alteração efetiva da senha precisa '
                            'ser conectada ao serviço de autenticação.',
                      );
                    },
                    child: const Text('Alterar senha'),
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

  // ============================================================
  // SAIR DA CONTA
  // ============================================================

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
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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

    if (confirmar != true || !mounted) return;

    await SessaoUsuario.instancia.sair();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                ?.trim() ??
                '';

            final email = SessaoUsuario
                .instancia.emailUsuario
                ?.trim() ??
                '';

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
                    'Gerencie suas informações e configurações '
                        'da conta.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),
                  _CardPerfilTutor(
                    nome: nome.isEmpty ? 'Tutor' : nome,
                    email: email.isEmpty
                        ? 'E-mail não informado'
                        : email,
                    onEditar: _editarPerfil,
                  ),
                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),
                  _SecaoPerfilTutor(
                    titulo: 'Minha conta',
                    icone: Icons.person_outline_rounded,
                    children: [
                      _ItemPerfilTutor(
                        icone: Icons.edit_outlined,
                        titulo: 'Editar perfil',
                        descricao:
                        'Atualize suas informações pessoais.',
                        onTap: _editarPerfil,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),
                  _SecaoPerfilTutor(
                    titulo: 'Segurança',
                    icone: Icons.shield_outlined,
                    children: [
                      _ItemPerfilTutor(
                        icone: Icons.lock_reset_rounded,
                        titulo: 'Alterar senha',
                        descricao:
                        'Defina uma nova senha para sua conta.',
                        onTap: _alterarSenha,
                      ),
                      const SizedBox(
                        height: EspacamentosApp.sm,
                      ),
                      const _ItemPerfilTutor(
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
                  _SecaoPerfilTutor(
                    titulo: 'Conta',
                    icone: Icons.settings_outlined,
                    children: [
                      _ItemPerfilTutor(
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
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// CARTÃO DO PERFIL
// ============================================================

class _CardPerfilTutor extends StatelessWidget {
  const _CardPerfilTutor({
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
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CoresApp.darkBlue.withAlpha(10),
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
            height: EspacamentosApp.sm,
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(
            height: EspacamentosApp.lg,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar informações'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CoresApp.primary,
                side: const BorderSide(
                  color: CoresApp.primary,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: EspacamentosApp.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEÇÕES DO PERFIL
// ============================================================

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icone,
              color: CoresApp.primary,
              size: 22,
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
    );
  }
}

// ============================================================
// ITENS CLICÁVEIS
// ============================================================

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
      padding: const EdgeInsets.all(
        EspacamentosApp.md,
      ),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: corIcone ?? CoresApp.primary,
            size: 22,
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
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
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