import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/botao_navegacao_compacto.dart';
import 'package:pet_care/widgets/cartao_base.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: EspacamentosApp.xl),

              // Logo
              Icon(
                Icons.pets,
                size: 72,
                color: CoresApp.primary,
              ),

              const SizedBox(height: EspacamentosApp.md),

              Text(
                'PetCare',
                textAlign: TextAlign.center,
                style: TipografiaApp.heading1.copyWith(
                  color: CoresApp.primary,
                ),
              ),

              const SizedBox(height: EspacamentosApp.sm),

              Text(
                'Cuide de quem cuida de você.',
                textAlign: TextAlign.center,
                style: TipografiaApp.body,
              ),

              const SizedBox(height: EspacamentosApp.xl),

              CartaoBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Entrar',
                      style: TipografiaApp.heading2,
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    Text(
                      'E-mail',
                      style: TipografiaApp.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Digite seu e-mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EspacamentosApp.radiusMd,
                          ),
                        ),
                      ),
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
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EspacamentosApp.radiusMd,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.sm),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Futuramente: recuperação de senha.
                        },
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    BotaoPrincipal(
                      label: 'Entrar',
                      icon: Icons.login,
                      expanded: true,
                      onPressed: () {
                        // Futuramente: autenticação com o backend.
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.lg),

              Text(
                'Ainda não possui uma conta?',
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall,
              ),

              const SizedBox(height: EspacamentosApp.sm),

              BotaoNavegacaoCompacto(
                icon: Icons.person_add_outlined,
                label: 'Criar uma conta',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CadastroScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}