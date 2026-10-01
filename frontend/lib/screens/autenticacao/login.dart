import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: conectar ao backend/autenticação.
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: EspacamentosApp.pagePadding,
              vertical: EspacamentosApp.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==========================
                    // MARCA
                    // ==========================

                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: CoresApp.cardHighlight,
                        shape: BoxShape.circle,
                        boxShadow: EspacamentosApp.cardShadow,
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 42,
                        color: CoresApp.cardHighlightText,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    Text(
                      'PetCare',
                      style: TipografiaApp.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                        color: CoresApp.cardHighlight,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xxl,
                    ),

                    // ==========================
                    // TÍTULO
                    // ==========================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bem-vindo de volta!',
                        style: TipografiaApp.heading1,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xs,
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Entre na sua conta para continuar cuidando dos seus pets.',
                        style: TipografiaApp.bodySmall,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xl,
                    ),

                    // ==========================
                    // E-MAIL
                    // ==========================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'E-mail',
                        style: TipografiaApp.bodyMedium,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Digite seu e-mail',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Digite seu e-mail.';
                        }

                        if (!value.contains('@')) {
                          return 'Digite um e-mail válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    // ==========================
                    // SENHA
                    // ==========================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Senha',
                        style: TipografiaApp.bodyMedium,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    TextFormField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _ocultarSenha
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite sua senha.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    // ==========================
                    // ESQUECI SENHA
                    // ==========================

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: recuperação de senha.
                        },
                        child: Text(
                          'Esqueci minha senha',
                          style: TipografiaApp.buttonSmall,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    // ==========================
                    // ENTRAR
                    // ==========================

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _entrar,
                        child: const Text('Entrar'),
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xl,
                    ),

                    // ==========================
                    // CADASTRO
                    // ==========================

                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'Ainda não possui uma conta? ',
                          style: TipografiaApp.bodySmall,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/cadastro',
                            );
                          },
                          child: Text(
                            'Cadastre-se',
                            style: TipografiaApp.buttonSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }}