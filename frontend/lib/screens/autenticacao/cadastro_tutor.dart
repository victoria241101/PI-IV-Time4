import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  // ==========================
  // CRITÉRIOS DA SENHA
  // ==========================

  bool get _temOitoCaracteres =>
      _senhaController.text.length >= 8;

  bool get _temMaiuscula =>
      RegExp(r'[A-Z]').hasMatch(_senhaController.text);

  bool get _temNumero =>
      RegExp(r'[0-9]').hasMatch(_senhaController.text);

  bool get _temEspecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/]')
          .hasMatch(_senhaController.text);

  bool get _senhaForte =>
      _temOitoCaracteres &&
          _temMaiuscula &&
          _temNumero &&
          _temEspecial;

  double get _forcaSenha {
    if (_senhaController.text.isEmpty) {
      return 0;
    }

    int criteriosAtendidos = 0;

    if (_temOitoCaracteres) criteriosAtendidos++;
    if (_temMaiuscula) criteriosAtendidos++;
    if (_temNumero) criteriosAtendidos++;
    if (_temEspecial) criteriosAtendidos++;

    return criteriosAtendidos / 4;
  }

  String get _textoForcaSenha {
    if (_senhaController.text.isEmpty) {
      return 'Digite uma senha';
    }

    if (_forcaSenha < 0.5) {
      return 'Senha fraca';
    }

    if (_forcaSenha < 1) {
      return 'Senha média';
    }

    return 'Senha forte';
  }

  Color _corForcaSenha() {
    if (_forcaSenha < 0.5) {
      return Colors.red;
    }

    if (_forcaSenha < 1) {
      return Colors.orange;
    }

    return CoresApp.cardHighlight;
  }

  // ==========================
  // VALIDADOR DE E-MAIL
  // ==========================

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Digite seu e-mail.';
    }

    final email = value.trim();

    final regexEmail = RegExp(
      r'^[\w.!#$%&’*+/=?^`{|}~-]+@'
      r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
    );

    if (!regexEmail.hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }

    return null;
  }

  // ==========================
  // VALIDADOR DE CPF
  // ==========================

  String? _validarCpf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Digite seu CPF.';
    }

    final cpf = value.replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) {
      return 'Digite um CPF válido.';
    }

    // Rejeita CPFs como:
    // 000.000.000-00
    // 111.111.111-11
    // 222.222.222-22
    // etc.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'Digite um CPF válido.';
    }

    // ==========================
    // PRIMEIRO DÍGITO VERIFICADOR
    // ==========================

    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }

    int resto = soma % 11;

    int primeiroDigito =
    resto < 2 ? 0 : 11 - resto;

    if (primeiroDigito != int.parse(cpf[9])) {
      return 'Digite um CPF válido.';
    }

    // ==========================
    // SEGUNDO DÍGITO VERIFICADOR
    // ==========================

    soma = 0;

    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }

    resto = soma % 11;

    int segundoDigito =
    resto < 2 ? 0 : 11 - resto;

    if (segundoDigito != int.parse(cpf[10])) {
      return 'Digite um CPF válido.';
    }

    return null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
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
                      textInputAction:
                      TextInputAction.next,
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
                      textInputAction:
                      TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Digite seu e-mail',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                      validator: _validarEmail,
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    // ==========================
                    // CPF
                    // ==========================

                    Text(
                      'CPF',
                      style: TipografiaApp.bodyMedium,
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    TextFormField(
                      controller: _cpfController,
                      keyboardType:
                      TextInputType.number,
                      textInputAction:
                      TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CpfInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                        ),
                      ),
                      validator: _validarCpf,
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
                      textInputAction:
                      TextInputAction.next,
                      onChanged: (_) {
                        setState(() {});
                      },
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
                        if (value == null ||
                            value.isEmpty) {
                          return 'Digite uma senha.';
                        }

                        if (!_senhaForte) {
                          return 'A senha não atende aos critérios de segurança.';
                        }

                        return null;
                      },
                    ),

                    // ==========================
                    // FORÇA DA SENHA
                    // ==========================

                    if (_senhaController.text.isNotEmpty) ...[
                      const SizedBox(
                        height: EspacamentosApp.sm,
                      ),
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CoresApp.cardHighlight
                              .withValues(alpha: 0.05),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                            color: CoresApp.cardHighlight
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Text(
                                  'Segurança da senha',
                                  style: TipografiaApp
                                      .bodySmall
                                      .copyWith(
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    CoresApp.textPrimary,
                                  ),
                                ),
                                AnimatedDefaultTextStyle(
                                  duration:
                                  const Duration(
                                    milliseconds: 250,
                                  ),
                                  style: TipografiaApp
                                      .bodySmall
                                      .copyWith(
                                    fontWeight:
                                    FontWeight.w700,
                                    color:
                                    _corForcaSenha(),
                                  ),
                                  child: Text(
                                    _textoForcaSenha,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 7,
                                    width: double.infinity,
                                    color: CoresApp
                                        .textSecondary
                                        .withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                  AnimatedFractionallySizedBox(
                                    duration:
                                    const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve:
                                    Curves.easeOutCubic,
                                    alignment:
                                    Alignment.centerLeft,
                                    widthFactor: _forcaSenha,
                                    child: Container(
                                      height: 7,
                                      decoration:
                                      BoxDecoration(
                                        borderRadius:
                                        BorderRadius
                                            .circular(20),
                                        color:
                                        _corForcaSenha(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildCriterioPremium(
                                  '8+ caracteres',
                                  _temOitoCaracteres,
                                ),
                                _buildCriterioPremium(
                                  'Maiúscula',
                                  _temMaiuscula,
                                ),
                                _buildCriterioPremium(
                                  'Número',
                                  _temNumero,
                                ),
                                _buildCriterioPremium(
                                  'Especial',
                                  _temEspecial,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

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
                      obscureText:
                      _ocultarConfirmacao,
                      textInputAction:
                      TextInputAction.done,
                      onChanged: (_) {
                        setState(() {});
                      },
                      onFieldSubmitted: (_) =>
                          _cadastrar(),
                      decoration: InputDecoration(
                        hintText:
                        'Digite a senha novamente',
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
                        if (value == null ||
                            value.isEmpty) {
                          return 'Confirme sua senha.';
                        }

                        if (value !=
                            _senhaController.text) {
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
                        child: const Text(
                          'Criar minha conta',
                        ),
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
                        alignment:
                        WrapAlignment.center,
                        children: [
                          Text(
                            'Já possui uma conta? ',
                            style:
                            TipografiaApp.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Entrar',
                              style:
                              TipografiaApp.buttonSmall,
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
      ),
    );
  }

  // ==========================
  // CRITÉRIO DA SENHA
  // ==========================

  Widget _buildCriterioPremium(
      String texto,
      bool atendido,
      ) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: atendido
            ? CoresApp.cardHighlight.withValues(
          alpha: 0.10,
        )
            : CoresApp.textSecondary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 200,
            ),
            child: Icon(
              atendido
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              key: ValueKey(atendido),
              size: 14,
              color: atendido
                  ? CoresApp.cardHighlight
                  : CoresApp.textSecondary,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            texto,
            style: TipografiaApp.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: atendido
                  ? CoresApp.textPrimary
                  : CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// FORMATADOR DE CPF
// ==================================================

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final numeros =
    newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numeros.length > 11) {
      return oldValue;
    }

    String cpfFormatado = '';

    for (int i = 0; i < numeros.length; i++) {
      if (i == 3 || i == 6) {
        cpfFormatado += '.';
      }

      if (i == 9) {
        cpfFormatado += '-';
      }

      cpfFormatado += numeros[i];
    }

    return TextEditingValue(
      text: cpfFormatado,
      selection: TextSelection.collapsed(
        offset: cpfFormatado.length,
      ),
    );
  }
}