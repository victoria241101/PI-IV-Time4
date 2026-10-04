import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';

import 'package:pet_care/screens/tutor/inicio_tutor.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

import 'esqueci_senha.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.destinoAposLogin,
  });

  final Widget Function()? destinoAposLogin;

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

  String? _validarSenha(String? value) {
    final senha = value ?? '';

    if (senha.isEmpty) {
      return 'Digite sua senha.';
    }

    if (senha.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }

    return null;
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    await SessaoUsuario.instancia.entrar(
      nome: 'Victoria',
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    final destino = widget.destinoAposLogin;

    if (destino != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destino(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InicioTutor(
          saudacao: 'Olá,',
          nomeTutor: 'Victoria',
          pets: const [
            ResumoPet(
              id: 'pet-001',
              name: 'Mel',
              species: 'Cachorro',
              breed: 'Golden Retriever',
              age: '3 anos',
              weight: 25.5,
            ),
            ResumoPet(
              id: 'pet-002',
              name: 'Luna',
              species: 'Gato',
              breed: 'Siamês',
              age: '2 anos',
              weight: 4.2,
            ),
          ],
          proximaConsulta: const ResumoConsulta(
            id: 'consulta-001',
            type: 'Consulta veterinária',
            date: '15/10/2026',
            time: '14:00',
            vetName: 'Dra. Ana Oliveira',
            petName: 'Mel',
            status: 'Confirmada',
            instructions: 'Chegar com 10 minutos de antecedência.',
            clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
          ),
          banners: const [],
          onConfirmarConsulta: (consultaId) async {
            return const ResumoConsulta(
              id: 'consulta-001',
              type: 'Consulta veterinária',
              date: '15/10/2026',
              time: '14:00',
              vetName: 'Dra. Ana Oliveira',
              petName: 'Mel',
              status: 'Confirmada',
              instructions: 'Chegar com 10 minutos de antecedência.',
              clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
            );
          },
          carregarDetalhesPet: (petId) async {
            throw UnimplementedError(
              'Detalhes do pet ainda não estão conectados ao backend.',
            );
          },
          onAgendarNovaConsulta: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Agendamento ainda não está conectado ao backend.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onNotificacoes: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notificações ainda não estão disponíveis.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TipografiaApp.bodySmall.copyWith(
        color: CoresApp.textSecondary.withAlpha(170),
      ),
      prefixIcon: Icon(
        icon,
        color: CoresApp.primary,
        size: 21,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.pagePadding,
            vertical: EspacamentosApp.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BOTÃO VOLTAR
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: CoresApp.darkBlue,
                          elevation: 2,
                          shadowColor: Colors.black.withAlpha(20),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    // LOGO
                    Center(
                      child: Column(
                        children: [
                          Container(
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
                              Icons.pets_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: EspacamentosApp.md,
                          ),
                          Text(
                            'PetCare',
                            style: TipografiaApp.heading1.copyWith(
                              color: CoresApp.darkBlue,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xxl,
                    ),

                    Text(
                      'Bem-vindo de volta!',
                      style: TipografiaApp.heading1.copyWith(
                        color: CoresApp.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xs,
                    ),

                    Text(
                      'Entre na sua conta para continuar cuidando dos seus pets.',
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xl,
                    ),

                    // CARD DO FORMULÁRIO
                    Container(
                      padding: const EdgeInsets.all(
                        EspacamentosApp.lg,
                      ),
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
                            'E-mail',
                            style: TipografiaApp.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _decoracaoCampo(
                              hintText: 'Digite seu e-mail',
                              icon: Icons.email_outlined,
                            ),
                            validator: _validarEmail,
                          ),

                          const SizedBox(
                            height: EspacamentosApp.md,
                          ),

                          Text(
                            'Senha',
                            style: TipografiaApp.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
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
                            decoration: _decoracaoCampo(
                              hintText: 'Digite sua senha',
                              icon: Icons.lock_outline_rounded,
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
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                            ),
                            validator: _validarSenha,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const EsqueciSenhaScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: CoresApp.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Esqueci minha senha',
                                style: TipografiaApp.buttonSmall.copyWith(
                                  color: CoresApp.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _entrar,
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
                                    'Entrar',
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

                          const SizedBox(
                            height: EspacamentosApp.lg,
                          ),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: EspacamentosApp.md,
                              vertical: EspacamentosApp.sm,
                            ),
                            decoration: BoxDecoration(
                              color: CoresApp.primary.withAlpha(10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: CoresApp.primary.withAlpha(22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_outlined,
                                    size: 18,
                                    color: CoresApp.primary,
                                  ),
                                ),
                                const SizedBox(
                                  width: EspacamentosApp.sm,
                                ),
                                Expanded(
                                  child: Text(
                                    'Seus dados são tratados com segurança e privacidade.',
                                    style: TipografiaApp.bodySmall.copyWith(
                                      color: CoresApp.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.xl,
                    ),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Ainda não possui uma conta? ',
                            style: TipografiaApp.bodySmall.copyWith(
                              color: CoresApp.textSecondary,
                            ),
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
                              style: TipografiaApp.buttonSmall.copyWith(
                                color: CoresApp.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.lg,
                    ),

                    Center(
                      child: Text(
                        'Cuidar também é uma forma de amar.',
                        textAlign: TextAlign.center,
                        style: TipografiaApp.bodySmall.copyWith(
                          color: CoresApp.textSecondary.withAlpha(180),
                          fontStyle: FontStyle.italic,
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