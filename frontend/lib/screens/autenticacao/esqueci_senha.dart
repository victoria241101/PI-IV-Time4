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
  final _identificadorController = TextEditingController();

  bool _usarEmail = true;

  @override
  void dispose() {
    _identificadorController.dispose();
    super.dispose();
  }

  void _enviarCodigo() {
    if (_identificadorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _usarEmail
                ? 'Digite seu e-mail.'
                : 'Digite seu número de telefone.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerificacaoScreen(),
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
                        color: CoresApp.cardHighlight,
                        shape: BoxShape.circle,
                        boxShadow: EspacamentosApp.cardShadow,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 36,
                        color: CoresApp.cardHighlightText,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // TÍTULO
                  Center(
                    child: Text(
                      'Esqueceu sua senha?',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.heading1,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  // DESCRIÇÃO
                  Center(
                    child: Text(
                      'Digite seu e-mail ou número de telefone para receber um código de verificação.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // SELETOR EMAIL / SMS
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CoresApp.cardHighlight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetodoButton(
                            texto: 'E-mail',
                            icone: Icons.email_outlined,
                            selecionado: _usarEmail,
                            onTap: () {
                              setState(() {
                                _usarEmail = true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildMetodoButton(
                            texto: 'SMS',
                            icone: Icons.phone_outlined,
                            selecionado: !_usarEmail,
                            onTap: () {
                              setState(() {
                                _usarEmail = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  Text(
                    _usarEmail
                        ? 'E-mail ou ID da conta'
                        : 'Número de telefone',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.sm,
                  ),

                  TextField(
                    controller: _identificadorController,
                    keyboardType: _usarEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: _usarEmail
                          ? 'Digite seu e-mail'
                          : 'Digite seu telefone',
                      prefixIcon: Icon(
                        _usarEmail
                            ? Icons.email_outlined
                            : Icons.phone_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // AVISO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CoresApp.cardHighlight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: CoresApp.cardHighlight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Você receberá um código de verificação para continuar a recuperação da sua conta.',
                            style: TipografiaApp.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.lg,
                  ),

                  // BOTÃO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviarCodigo,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                      ),
                      label: const Text(
                        'Enviar código de verificação',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // LOGIN
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'Lembrou sua senha? ',
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

                  Center(
                    child: Text(
                      'Precisa de ajuda? Entre em contato com o suporte.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall.copyWith(
                        fontSize: 11,
                      ),
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

  Widget _buildMetodoButton({
    required String texto,
    required IconData icone,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? CoresApp.cardHighlight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 18,
              color: selecionado
                  ? CoresApp.cardHighlightText
                  : CoresApp.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TipografiaApp.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: selecionado
                    ? CoresApp.cardHighlightText
                    : CoresApp.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}