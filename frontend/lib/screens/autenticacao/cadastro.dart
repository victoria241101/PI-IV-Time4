import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/botao_navegacao_compacto.dart';
import 'package:pet_care/widgets/cartao_base.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crie sua conta',
                style: TipografiaApp.heading1,
              ),

              const SizedBox(height: EspacamentosApp.sm),

              Text(
                'Preencha seus dados para começar a usar o PetCare.',
                style: TipografiaApp.body,
              ),

              const SizedBox(height: EspacamentosApp.lg),

              CartaoBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Campo(
                      label: 'Nome completo',
                      hint: 'Digite seu nome completo',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    _Campo(
                      label: 'CPF',
                      hint: 'Digite seu CPF',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    _Campo(
                      label: 'Telefone',
                      hint: 'Digite seu telefone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    _Campo(
                      label: 'E-mail',
                      hint: 'Digite seu e-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    Text(
                      'Senha',
                      style: TipografiaApp.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    TextField(
                      obscureText: !_mostrarSenha,
                      decoration: InputDecoration(
                        hintText: 'Crie uma senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EspacamentosApp.radiusMd,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    Text(
                      'Confirmar senha',
                      style: TipografiaApp.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    TextField(
                      obscureText: !_mostrarConfirmacao,
                      decoration: InputDecoration(
                        hintText: 'Digite a senha novamente',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrarConfirmacao = !_mostrarConfirmacao;
                            });
                          },
                          icon: Icon(
                            _mostrarConfirmacao
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EspacamentosApp.radiusMd,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    BotaoPrincipal(
                      label: 'Criar conta',
                      icon: Icons.person_add,
                      expanded: true,
                      onPressed: () {
                        // Futuramente: cadastro no backend.
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.lg),

              BotaoNavegacaoCompacto(
                icon: Icons.login,
                label: 'Já tenho uma conta',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TipografiaApp.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: EspacamentosApp.xs),

        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EspacamentosApp.radiusMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}