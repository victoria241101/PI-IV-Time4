/*
 * Aluna: Victoria Beatriz Nobre Andrade
 * RA: 2516398
 */
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/cabecalho_petcare.dart';
import 'package:pet_care/screens/autenticacao/service/auth_service.dart';

class VerificacaoScreen extends StatefulWidget {
  const VerificacaoScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<VerificacaoScreen> createState() => _VerificacaoScreenState();
}

class _VerificacaoScreenState extends State<VerificacaoScreen> {
  bool _reenviando = false;

  Future<void> _reenviarLink() async {
    if (_reenviando) return;

    setState(() => _reenviando = true);

    try {
      await AuthService.instancia.solicitarRecuperacaoSenha(
        email: widget.email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Um novo link foi enviado, se o e-mail estiver cadastrado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            erro.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reenviando = false);
      }
    }
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
                  const SizedBox(height: EspacamentosApp.md),
                  const CabecalhoPetCare(
                    centralizado: true,
                    mostrarSaudacao: false,
                  ),
                  const SizedBox(height: EspacamentosApp.xl),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: CoresApp.darkBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.lg),
                  Center(
                    child: Text(
                      'Verifique seu e-mail',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.xs),
                  Center(
                    child: Text(
                      'Enviamos um link para redefinir sua senha para:',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.md),
                  Center(
                    child: Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodyMedium.copyWith(
                        color: CoresApp.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(EspacamentosApp.lg),
                    decoration: BoxDecoration(
                      color: CoresApp.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.black.withAlpha(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 34,
                          color: CoresApp.primary,
                        ),
                        const SizedBox(height: EspacamentosApp.md),
                        Text(
                          'Abra o e-mail e clique no link de recuperação. '
                              'Você terá 15 minutos para criar uma nova senha.',
                          textAlign: TextAlign.center,
                          style: TipografiaApp.bodySmall.copyWith(
                            color: CoresApp.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _reenviando ? null : _reenviarLink,
                            child: _reenviando
                                ? const CircularProgressIndicator()
                                : const Text('Reenviar link'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.lg),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (route) => false,
                        );
                      },
                      child: const Text('Voltar para o login'),
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
}
