import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

import 'verificacao.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Digite seu e-mail.';
    }

    final regexEmail = RegExp(
      r'^[A-Za-z0-9.!#$%&’*+/=?^_`{|}~-]+@'
      r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
      r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
    );

    if (!regexEmail.hasMatch(email) ||
        email.contains('..') ||
        email.startsWith('.') ||
        email.endsWith('.')) {
      return 'Digite um e-mail válido.';
    }

    return null;
  }

  void _enviarCodigo() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificacaoScreen(
          email: _emailController.text.trim(),
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo() {
    return InputDecoration(
      hintText: 'Digite seu e-mail',
      hintStyle: TipografiaApp.bodySmall.copyWith(
        color: CoresApp.textSecondary.withAlpha(170),
      ),
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: CoresApp.primary,
      ),
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
                        'Esqueceu sua senha?',
                        textAlign: TextAlign.center,
                        style: TipografiaApp.heading1.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    Center(
                      child: Text(
                        'Informe seu e-mail e enviaremos um código para recuperar sua conta.',
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
                            'E-mail da conta',
                            style: TipografiaApp.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: EspacamentosApp.sm),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _enviarCodigo(),
                            decoration: _decoracaoCampo(),
                            validator: _validarEmail,
                          ),

                          const SizedBox(height: EspacamentosApp.md),

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
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: CoresApp.primary.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 18,
                                    color: CoresApp.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Enviaremos um código de verificação para este endereço.',
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

                          const SizedBox(height: EspacamentosApp.lg),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _enviarCodigo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CoresApp.darkBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Enviar código',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                        ),
                        label: const Text('Voltar para o login'),
                        style: TextButton.styleFrom(
                          foregroundColor: CoresApp.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    Center(
                      child: Text(
                        'Precisa de ajuda? Entre em contato com o suporte.',
                        textAlign: TextAlign.center,
                        style: TipografiaApp.bodySmall.copyWith(
                          fontSize: 11,
                          color: CoresApp.textSecondary.withAlpha(180),
                        ),
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
}