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

  final _nomePetController = TextEditingController();
  final _racaPetController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  bool? _temPet;

  String? _especiePet;
  String? _sexoPet;

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
    if (_senhaController.text.isEmpty) return 0;

    int criterios = 0;

    if (_temOitoCaracteres) criterios++;
    if (_temMaiuscula) criterios++;
    if (_temNumero) criterios++;
    if (_temEspecial) criterios++;

    return criterios / 4;
  }

  String get _textoForcaSenha {
    if (_senhaController.text.isEmpty) {
      return 'Digite uma senha';
    }

    if (_forcaSenha < 0.5) return 'Senha fraca';
    if (_forcaSenha < 1) return 'Senha média';

    return 'Senha forte';
  }

  Color _corForcaSenha() {
    if (_forcaSenha < 0.5) return Colors.redAccent;
    if (_forcaSenha < 1) return Colors.orange;

    return CoresApp.primary;
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

  String? _validarCpf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Digite seu CPF.';
    }

    final cpf = value.replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) {
      return 'Digite um CPF válido.';
    }

    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'Digite um CPF válido.';
    }

    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }

    int resto = soma % 11;
    int primeiroDigito = resto < 2 ? 0 : 11 - resto;

    if (primeiroDigito != int.parse(cpf[9])) {
      return 'Digite um CPF válido.';
    }

    soma = 0;

    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }

    resto = soma % 11;
    int segundoDigito = resto < 2 ? 0 : 11 - resto;

    if (segundoDigito != int.parse(cpf[10])) {
      return 'Digite um CPF válido.';
    }

    return null;
  }

  void _cadastrar() {
    if (_temPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe se você já tem um pet.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_temPet == true) {
      if (_nomePetController.text.trim().isEmpty ||
          _especiePet == null ||
          _racaPetController.text.trim().isEmpty ||
          _sexoPet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preencha os dados básicos do seu pet.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cadastro ainda não está conectado ao backend.',
        ),
        behavior: SnackBarBehavior.floating,
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

  Widget _label(String texto) {
    return Text(
      texto,
      style: TipografiaApp.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: CoresApp.textPrimary,
      ),
    );
  }

  Widget _buildForcaSenha() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CoresApp.primary.withAlpha(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Segurança da senha',
                style: TipografiaApp.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _textoForcaSenha,
                style: TipografiaApp.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _corForcaSenha(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  color: CoresApp.textSecondary.withAlpha(25),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: _forcaSenha,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: _corForcaSenha(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _criterio(
                '8+ caracteres',
                _temOitoCaracteres,
              ),
              _criterio(
                'Maiúscula',
                _temMaiuscula,
              ),
              _criterio(
                'Número',
                _temNumero,
              ),
              _criterio(
                'Especial',
                _temEspecial,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criterio(String texto, bool atendido) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: atendido
            ? CoresApp.primary.withAlpha(20)
            : CoresApp.textSecondary.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            atendido
                ? Icons.check_rounded
                : Icons.circle_outlined,
            size: 14,
            color: atendido
                ? CoresApp.primary
                : CoresApp.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TipografiaApp.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscolhaPet() {
    return Container(
      width: double.infinity,
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
            'Você já tem um pet?',
            style: TipografiaApp.heading3.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Isso nos ajuda a preparar sua conta da melhor forma.',
            style: TipografiaApp.bodySmall.copyWith(
              color: CoresApp.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          _opcaoPet(
            titulo: 'Sim, já tenho um pet',
            subtitulo: 'Quero cadastrar meu pet agora.',
            icone: Icons.pets_rounded,
            valor: true,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          _opcaoPet(
            titulo: 'Não, ainda não tenho',
            subtitulo: 'Vou cadastrar um pet depois.',
            icone: Icons.person_outline_rounded,
            valor: false,
          ),
        ],
      ),
    );
  }

  Widget _opcaoPet({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required bool valor,
  }) {
    final selecionado = _temPet == valor;

    return InkWell(
      onTap: () {
        setState(() {
          _temPet = valor;

          if (!valor) {
            _nomePetController.clear();
            _racaPetController.clear();
            _especiePet = null;
            _sexoPet = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? CoresApp.primary.withAlpha(12)
              : CoresApp.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado
                ? CoresApp.primary
                : Colors.black.withAlpha(10),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selecionado
                    ? CoresApp.primary.withAlpha(20)
                    : CoresApp.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                color: CoresApp.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TipografiaApp.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: TipografiaApp.bodySmall.copyWith(
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selecionado
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selecionado
                  ? CoresApp.primary
                  : CoresApp.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardUsuario() {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: CoresApp.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Seus dados',
                style: TipografiaApp.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.lg),
          _label('Nome completo'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _decoracaoCampo(
              hintText: 'Digite seu nome',
              icon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Digite seu nome.';
              }

              if (value.trim().length < 3) {
                return 'Digite seu nome completo.';
              }

              return null;
            },
          ),
          const SizedBox(height: EspacamentosApp.md),
          _label('E-mail'),
          const SizedBox(height: EspacamentosApp.sm),
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
          const SizedBox(height: EspacamentosApp.md),
          _label('CPF'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CpfInputFormatter(),
            ],
            decoration: _decoracaoCampo(
              hintText: '000.000.000-00',
              icon: Icons.badge_outlined,
            ),
            validator: _validarCpf,
          ),
          const SizedBox(height: EspacamentosApp.md),
          _label('Senha'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _senhaController,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: _decoracaoCampo(
              hintText: 'Crie uma senha',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite uma senha.';
              }

              if (!_senhaForte) {
                return 'A senha não atende aos critérios.';
              }

              return null;
            },
          ),
          if (_senhaController.text.isNotEmpty) ...[
            const SizedBox(height: EspacamentosApp.sm),
            _buildForcaSenha(),
          ],
          const SizedBox(height: EspacamentosApp.md),
          _label('Confirmar senha'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: _ocultarConfirmacao,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _cadastrar(),
            decoration: _decoracaoCampo(
              hintText: 'Digite a senha novamente',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
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
                  color: CoresApp.textSecondary,
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
        ],
      ),
    );
  }

  Widget _buildCardPet() {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: CoresApp.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dados do pet',
                style: TipografiaApp.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoresApp.primary.withAlpha(9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Para um cadastro rápido, cadastre um pet apenas. '
                  'Caso tenha mais de um, você poderá cadastrar os '
                  'outros em breve na seção "Meus Pets".',
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: EspacamentosApp.lg),
          _label('Nome do pet'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _nomePetController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _decoracaoCampo(
              hintText: 'Digite o nome do pet',
              icon: Icons.pets_rounded,
            ),
            validator: (value) {
              if (_temPet != true) return null;

              if (value == null ||
                  value.trim().isEmpty) {
                return 'Digite o nome do pet.';
              }

              return null;
            },
          ),
          const SizedBox(height: EspacamentosApp.md),
          _label('Espécie'),
          const SizedBox(height: EspacamentosApp.sm),
          DropdownButtonFormField<String>(
            value: _especiePet,
            decoration: _decoracaoCampo(
              hintText: 'Selecione a espécie',
              icon: Icons.category_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Cachorro',
                child: Text('Cachorro'),
              ),
              DropdownMenuItem(
                value: 'Gato',
                child: Text('Gato'),
              ),
              DropdownMenuItem(
                value: 'Ave',
                child: Text('Ave'),
              ),
              DropdownMenuItem(
                value: 'Outro',
                child: Text('Outro'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _especiePet = value;
              });
            },
            validator: (value) {
              if (_temPet != true) return null;

              if (value == null || value.isEmpty) {
                return 'Selecione a espécie.';
              }

              return null;
            },
          ),
          const SizedBox(height: EspacamentosApp.md),
          _label('Raça'),
          const SizedBox(height: EspacamentosApp.sm),
          TextFormField(
            controller: _racaPetController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _decoracaoCampo(
              hintText: 'Digite a raça',
              icon: Icons.pets_outlined,
            ),
            validator: (value) {
              if (_temPet != true) return null;

              if (value == null ||
                  value.trim().isEmpty) {
                return 'Digite a raça.';
              }

              return null;
            },
          ),
          const SizedBox(height: EspacamentosApp.md),
          _label('Sexo'),
          const SizedBox(height: EspacamentosApp.sm),
          DropdownButtonFormField<String>(
            value: _sexoPet,
            decoration: _decoracaoCampo(
              hintText: 'Selecione o sexo',
              icon: Icons.wc_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Macho',
                child: Text('Macho'),
              ),
              DropdownMenuItem(
                value: 'Fêmea',
                child: Text('Fêmea'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _sexoPet = value;
              });
            },
            validator: (value) {
              if (_temPet != true) return null;

              if (value == null || value.isEmpty) {
                return 'Selecione o sexo.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomePetController.dispose();
    _racaPetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.pagePadding,
            vertical: EspacamentosApp.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 470,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CoresApp.surface,
                          borderRadius:
                          BorderRadius.circular(14),
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
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: CoresApp.darkBlue,
                              borderRadius:
                              BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: CoresApp.darkBlue
                                      .withAlpha(35),
                                  blurRadius: 24,
                                  offset:
                                  const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              size: 37,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),
                          Text(
                            'PetCare',
                            style:
                            TipografiaApp.heading2.copyWith(
                              color: CoresApp.darkBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xl),
                    Text(
                      'Crie sua conta',
                      style: TipografiaApp.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xs),
                    Text(
                      'Cadastre-se para cuidar da saúde dos '
                          'seus pets com o PetCare.',
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xl),
                    _buildEscolhaPet(),
                    if (_temPet != null) ...[
                      const SizedBox(height: EspacamentosApp.lg),
                      _buildCardUsuario(),
                    ],
                    if (_temPet == true) ...[
                      const SizedBox(height: EspacamentosApp.lg),
                      _buildCardPet(),
                    ],
                    if (_temPet != null) ...[
                      const SizedBox(height: EspacamentosApp.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _cadastrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            CoresApp.darkBlue,
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
                                'Criar minha conta',
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
                      const SizedBox(height: EspacamentosApp.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: EspacamentosApp.md,
                          vertical: EspacamentosApp.sm,
                        ),
                        decoration: BoxDecoration(
                          color: CoresApp.primary.withAlpha(10),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: CoresApp.primary,
                            ),
                            const SizedBox(
                              width: EspacamentosApp.sm,
                            ),
                            Expanded(
                              child: Text(
                                'Seus dados são tratados com segurança '
                                    'e privacidade.',
                                style:
                                TipografiaApp.bodySmall.copyWith(
                                  color:
                                  CoresApp.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: EspacamentosApp.xl),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Já possui uma conta? ',
                            style:
                            TipografiaApp.bodySmall.copyWith(
                              color: CoresApp.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Entrar',
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
                    const SizedBox(height: EspacamentosApp.lg),
                    Center(
                      child: Text(
                        'Cuidar também é uma forma de amar.',
                        style: TipografiaApp.bodySmall.copyWith(
                          color: CoresApp.textSecondary
                              .withAlpha(180),
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