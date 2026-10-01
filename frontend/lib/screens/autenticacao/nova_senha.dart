import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class NovaSenhaScreen extends StatefulWidget {
  const NovaSenhaScreen({super.key});

  @override
  State<NovaSenhaScreen> createState() => _NovaSenhaScreenState();
}

class _NovaSenhaScreenState extends State<NovaSenhaScreen> {
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  bool get _temOitoCaracteres =>
      _senhaController.text.length >= 8;

  bool get _temMaiuscula =>
      RegExp(r'[A-Z]').hasMatch(_senhaController.text);

  bool get _temNumero =>
      RegExp(r'[0-9]').hasMatch(_senhaController.text);

  bool get _temEspecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/]')
          .hasMatch(_senhaController.text);

  bool get _senhasIguais =>
      _senhaController.text.isNotEmpty &&
          _senhaController.text ==
              _confirmarSenhaController.text;

  bool get _senhaValida =>
      _temOitoCaracteres &&
          _temMaiuscula &&
          _temNumero &&
          _temEspecial &&
          _senhasIguais;

  void _resetarSenha() {
    if (!_senhaValida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A senha ainda não atende a todos os critérios.',
          ),
        ),
      );
      return;
    }

    // Mock: futuramente conectar ao backend.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Senha alterada com sucesso!',
        ),
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 700),
          () {
        if (!mounted) return;

        Navigator.popUntil(
          context,
              (route) => route.isFirst,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.pagePadding,
            vertical: EspacamentosApp.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VOLTAR
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    color: CoresApp.textPrimary,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  // ÍCONE
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: CoresApp.cardHighlight.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 34,
                        color: CoresApp.cardHighlight,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // TÍTULO
                  Center(
                    child: Text(
                      'Crie uma nova senha',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.heading1,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  Center(
                    child: Text(
                      'Sua nova senha deve ser diferente da anterior e atender aos critérios de segurança.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // NOVA SENHA
                  Text(
                    'Nova senha',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Digite sua nova senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _ocultarSenha = !_ocultarSenha;
                          });
                        },
                        icon: Icon(
                          _ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // INDICADOR
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CoresApp.cardHighlight.withValues(
                        alpha: 0.07,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Segurança da senha',
                              style: TipografiaApp.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _senhaValida
                                  ? 'Senha forte'
                                  : 'Verificando',
                              style: TipografiaApp.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        _buildCriterio(
                          'Pelo menos 8 caracteres',
                          _temOitoCaracteres,
                        ),

                        _buildCriterio(
                          'Pelo menos uma letra maiúscula',
                          _temMaiuscula,
                        ),

                        _buildCriterio(
                          'Pelo menos um número',
                          _temNumero,
                        ),

                        _buildCriterio(
                          'Pelo menos um caractere especial',
                          _temEspecial,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  // CONFIRMAR SENHA
                  Text(
                    'Confirmar nova senha',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextField(
                    controller: _confirmarSenhaController,
                    obscureText: _ocultarConfirmacao,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Digite a senha novamente',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _ocultarConfirmacao =
                            !_ocultarConfirmacao;
                          });
                        },
                        icon: Icon(
                          _ocultarConfirmacao
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  if (_confirmarSenhaController.text.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          _senhasIguais
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 16,
                          color: _senhasIguais
                              ? CoresApp.cardHighlight
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _senhasIguais
                              ? 'As senhas coincidem'
                              : 'As senhas não coincidem',
                          style: TipografiaApp.bodySmall.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // BOTÃO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _senhaValida
                          ? _resetarSenha
                          : null,
                      icon: const Icon(
                        Icons.lock_reset_rounded,
                      ),
                      label: const Text(
                        'Redefinir senha e entrar',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // SEGURANÇA
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CoresApp.cardHighlight.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: CoresApp.cardHighlight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Por segurança, a alteração da senha será registrada na sua conta.',
                            style: TipografiaApp.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriterio(
      String texto,
      bool atendido,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Icon(
            atendido
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 17,
            color: atendido
                ? CoresApp.cardHighlight
                : CoresApp.textPrimary.withValues(
              alpha: 0.45,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TipografiaApp.bodySmall.copyWith(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}