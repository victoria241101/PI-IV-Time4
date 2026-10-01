import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

import 'nova_senha.dart';

class VerificacaoScreen extends StatefulWidget {
  const VerificacaoScreen({super.key});

  @override
  State<VerificacaoScreen> createState() => _VerificacaoScreenState();
}

class _VerificacaoScreenState extends State<VerificacaoScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _verificarCodigo() {
    final codigo = _controllers
        .map((controller) => controller.text)
        .join();

    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite o código de 6 dígitos.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaSenhaScreen(),
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
                        color: CoresApp.cardHighlight.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
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
                      'Digite o código',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.heading1,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  Center(
                    child: Text(
                      'Enviamos um código de 6 dígitos para o seu e-mail cadastrado.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall,
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // E-MAIL MOCKADO
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.cardHighlight.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'v••••••@petcare.org',
                        style: TipografiaApp.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  Text(
                    'Código de segurança',
                    style: TipografiaApp.bodyMedium,
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // CÓDIGO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                          (index) => _buildCodigoField(index),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  // REENVIAR
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'Não recebeu o código? ',
                          style: TipografiaApp.bodySmall,
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Novo código enviado.',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Reenviar código',
                            style: TipografiaApp.buttonSmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xs,
                  ),

                  Center(
                    child: Text(
                      'Você poderá solicitar um novo código em alguns segundos.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.xl,
                  ),

                  // BOTÃO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _verificarCodigo,
                      icon: const Icon(
                        Icons.verified_outlined,
                      ),
                      label: const Text(
                        'Verificar e continuar',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: EspacamentosApp.md,
                  ),

                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                              (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Voltar para o login',
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

  Widget _buildCodigoField(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TipografiaApp.heading2.copyWith(
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }

          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}