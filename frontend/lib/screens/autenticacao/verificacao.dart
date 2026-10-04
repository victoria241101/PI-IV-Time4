import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

import 'nova_senha.dart';

class VerificacaoScreen extends StatefulWidget {
  const VerificacaoScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<VerificacaoScreen> createState() =>
      _VerificacaoScreenState();
}

class _VerificacaoScreenState extends State<VerificacaoScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  String get _codigo =>
      _controllers.map((controller) => controller.text).join();

  bool get _codigoCompleto => _codigo.length == 6;

  String _mascararEmail(String email) {
    final partes = email.split('@');

    if (partes.length != 2) {
      return email;
    }

    final usuario = partes[0];
    final dominio = partes[1];

    if (usuario.length <= 2) {
      return '${usuario[0]}••••@$dominio';
    }

    return '${usuario[0]}${'•' * (usuario.length - 2)}${usuario[usuario.length - 1]}@$dominio';
  }

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

  void _preencherCodigoColado(String value) {
    final numeros = value.replaceAll(RegExp(r'\D'), '');

    if (numeros.isEmpty) return;

    final limite = numeros.length > 6 ? 6 : numeros.length;

    for (int i = 0; i < 6; i++) {
      _controllers[i].text =
      i < limite ? numeros[i] : '';
    }

    final proximo = limite >= 6 ? 5 : limite;

    _focusNodes[proximo].requestFocus();

    setState(() {});
  }

  void _verificarCodigo() {
    if (!_codigoCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite o código completo de 6 dígitos.',
          ),
          behavior: SnackBarBehavior.floating,
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

  void _alterarCampo(int index, String value) {
    if (value.length > 1) {
      _preencherCodigoColado(value);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
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
                        Icons.mark_email_read_outlined,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: EspacamentosApp.lg),

                  Center(
                    child: Text(
                      'Digite o código',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: EspacamentosApp.xs),

                  Center(
                    child: Text(
                      'Enviamos um código de 6 dígitos para o seu e-mail.',
                      textAlign: TextAlign.center,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: EspacamentosApp.md),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mascararEmail(widget.email),
                        style: TipografiaApp.bodySmall.copyWith(
                          color: CoresApp.darkBlue,
                          fontWeight: FontWeight.w700,
                        ),
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
                          'Código de segurança',
                          style: TipografiaApp.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: EspacamentosApp.md),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                                (index) => _buildCodigoField(index),
                          ),
                        ),

                        const SizedBox(height: EspacamentosApp.md),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Não recebeu o código? ',
                                style: TipografiaApp.bodySmall.copyWith(
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Novo código enviado.',
                                      ),
                                      behavior:
                                      SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Reenviar código',
                                  style:
                                  TipografiaApp.buttonSmall.copyWith(
                                    color: CoresApp.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: EspacamentosApp.xl),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                            _codigoCompleto
                                ? _verificarCodigo
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CoresApp.darkBlue,
                              disabledBackgroundColor:
                              CoresApp.textSecondary.withAlpha(35),
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
                                  'Verificar e continuar',
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

                  const SizedBox(height: EspacamentosApp.lg),

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
                      label: const Text('Voltar para o login'),
                      style: TextButton.styleFrom(
                        foregroundColor: CoresApp.primary,
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
    final preenchido =
        _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: preenchido
            ? CoresApp.primary.withAlpha(10)
            : CoresApp.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: preenchido
              ? CoresApp.primary
              : Colors.black.withAlpha(18),
          width: preenchido ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: TipografiaApp.heading2.copyWith(
          fontWeight: FontWeight.w800,
          color: CoresApp.darkBlue,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
        onChanged: (value) {
          _alterarCampo(index, value);
        },
      ),
    );
  }
}