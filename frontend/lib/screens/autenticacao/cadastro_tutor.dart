import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _cadastrar() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: conectar ao backend/cadastro.
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
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================
                  // VOLTAR
                  // ==========================

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    color: CoresApp.textPrimary,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // ==========================
                  // MARCA
                  // ==========================

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: CoresApp.cardHighlight,
                            shape: BoxShape.circle,
                            boxShadow: EspacamentosApp.cardShadow,
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            size: 38,
                            color: CoresApp.cardHighlightText,
                          ),
                        ),

                        const SizedBox(
                          height: EspacamentosApp.sm,
                        ),

                        Text(
                          'PetCare',
                          style: TipografiaApp.heading2.copyWith(
                            fontWeight: FontWeight.w800,
                            color: CoresApp.cardHighlight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // ==========================
                  // TÍTULO
                  // ==========================

                  Text(
                    'Crie sua conta',
                    style: TipografiaApp.heading1,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  Text(
                    'Cadastre-se para acompanhar a saúde e os cuidados dos seus pets.',
                    style: TipografiaApp.bodySmall,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // ==========================
                  // NOME
                  // ==========================

                  Text(
                    'Nome completo',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextFormField(
                    controller: _nomeController,
                    textCapitalization:
                    TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu nome',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Digite seu nome.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // ==========================
                  // E-MAIL
                  // ==========================

                  Text(
                    'E-mail',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                    TextInputType.emailAddress,
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

                  Text(
                    'Senha',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Crie uma senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _ocultarSenha
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                        onPressed: () {
                          setState(() {
                            _ocultarSenha =
                            !_ocultarSenha;
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
                        return 'Digite uma senha.';
                      }

                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // ==========================
                  // CONFIRMAR SENHA
                  // ==========================

                  Text(
                    'Confirmar senha',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextFormField(
                    controller:
                    _confirmarSenhaController,
                    obscureText: _ocultarConfirmacao,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _cadastrar(),
                    decoration: InputDecoration(
                      hintText: 'Digite a senha novamente',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _ocultarConfirmacao
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
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

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // ==========================
                  // CADASTRAR
                  // ==========================

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cadastrar,
                      child: const Text('Criar minha conta'),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // ==========================
                  // LOGIN
                  // ==========================

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'Já possui uma conta? ',
                          style: TipografiaApp.bodySmall,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Entrar',
                            style: TipografiaApp.buttonSmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
    );
  }
}