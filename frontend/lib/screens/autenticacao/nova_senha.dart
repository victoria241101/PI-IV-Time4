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
  final _formKey = GlobalKey<FormState>();

  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

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

  double get _forcaSenha {
    if (_senhaController.text.isEmpty) return 0;

    int criterios = 0;

    if (_temOitoCaracteres) criterios++;
    if (_temMaiuscula) criterios++;
    if (_temNumero) criterios++;
    if (_temEspecial) criterios++;

    return criterios / 4;
  }

  String get _textoForcaSenha {
    if (_senhaController.text.isEmpty) {
      return 'Digite uma senha';
    }

    if (_forcaSenha < 0.5) return 'Senha fraca';
    if (_forcaSenha < 1) return 'Senha média';

    return 'Senha forte';
  }

  Color _corForcaSenha() {
    if (_forcaSenha < 0.5) return Colors.redAccent;
    if (_forcaSenha < 1) return Colors.orange;

    return CoresApp.primary;
  }

  void _resetarSenha() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Senha alterada com sucesso!',
        ),
        behavior: SnackBarBehavior.floating,
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

  InputDecoration _decoracaoCampo({
    required String hintText,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TipografiaApp.bodySmall.copyWith(
        color: CoresApp.textSecondary.withAlpha(170),
      ),
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        color: CoresApp.primary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: CoresApp.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.black.withAlpha(12),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.black.withAlpha(12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: CoresApp.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _criterio(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            atendido
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: atendido
                ? CoresApp.primary
                : CoresApp.textSecondary.withAlpha(100),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TipografiaApp.bodySmall.copyWith(
                fontSize: 12,
                color: atendido
                    ? CoresApp.textPrimary
                    : CoresApp.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
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
              constraints: const BoxConstraints(maxWidth: 470),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CoresApp.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withAlpha(10),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: CoresApp.darkBlue,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: CoresApp.darkBlue.withAlpha(35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    Center(
                      child: Text(
                        'Crie uma nova senha',
                        textAlign: TextAlign.center,
                        style: TipografiaApp.heading1.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    Center(
                      child: Text(
                        'Escolha uma senha forte para proteger sua conta.',
                        textAlign: TextAlign.center,
                        style: TipografiaApp.bodySmall.copyWith(
                          color: CoresApp.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    Container(
                      padding: const EdgeInsets.all(EspacamentosApp.lg),
                      decoration: BoxDecoration(
                        color: CoresApp.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.black.withAlpha(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova senha',
                            style: TipografiaApp.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: EspacamentosApp.sm),

                          TextFormField(
                            controller: _senhaController,
                            obscureText: _ocultarSenha,
                            onChanged: (_) => setState(() {}),
                            decoration: _decoracaoCampo(
                              hintText: 'Digite sua nova senha',
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
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite uma senha.';
                              }

                              if (!_temOitoCaracteres) {
                                return 'A senha deve ter no mínimo 8 caracteres.';
                              }

                              if (!_temMaiuscula) {
                                return 'Adicione uma letra maiúscula.';
                              }

                              if (!_temNumero) {
                                return 'Adicione um número.';
                              }

                              if (!_temEspecial) {
                                return 'Adicione um caractere especial.';
                              }

                              return null;
                            },
                          ),

                          if (_senhaController.text.isNotEmpty) ...[
                            const SizedBox(height: EspacamentosApp.sm),
                            _buildForcaSenha(),
                          ],

                          const SizedBox(height: EspacamentosApp.lg),

                          Text(
                            'Confirmar nova senha',
                            style: TipografiaApp.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: EspacamentosApp.sm),

                          TextFormField(
                            controller:
                            _confirmarSenhaController,
                            obscureText: _ocultarConfirmacao,
                            onChanged: (_) => setState(() {}),
                            decoration: _decoracaoCampo(
                              hintText: 'Digite a senha novamente',
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
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirme sua senha.';
                              }

                              if (value != _senhaController.text) {
                                return 'As senhas não coincidem.';
                              }

                              return null;
                            },
                          ),

                          if (_confirmarSenhaController
                              .text
                              .isNotEmpty) ...[
                            const SizedBox(height: EspacamentosApp.xs),
                            Row(
                              children: [
                                Icon(
                                  _senhasIguais
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  size: 17,
                                  color: _senhasIguais
                                      ? CoresApp.primary
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _senhasIguais
                                      ? 'As senhas coincidem'
                                      : 'As senhas não coincidem',
                                  style:
                                  TipografiaApp.bodySmall.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: EspacamentosApp.xl),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _senhaValida
                                  ? _resetarSenha
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CoresApp.darkBlue,
                                disabledBackgroundColor:
                                CoresApp.textSecondary
                                    .withAlpha(35),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Redefinir senha e entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.lg),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CoresApp.primary.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 20,
                                  color: CoresApp.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Por segurança, a alteração da senha será registrada na sua conta.',
                                    style:
                                    TipografiaApp.bodySmall.copyWith(
                                      color: CoresApp.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildForcaSenha() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(10),
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
                _textoForcaSenha,
                style: TipografiaApp.bodySmall.copyWith(
                  color: _corForcaSenha(),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  color: CoresApp.textSecondary.withAlpha(25),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: _forcaSenha,
                  child: Container(
                    height: 7,
                    color: _corForcaSenha(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _criterio('8+ caracteres', _temOitoCaracteres),
          _criterio('Maiúscula', _temMaiuscula),
          _criterio('Número', _temNumero),
          _criterio('Especial', _temEspecial),
        ],
      ),
    );
  }
}