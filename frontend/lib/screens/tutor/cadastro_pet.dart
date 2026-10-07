import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

class CadastroPetScreen extends StatefulWidget {
  const CadastroPetScreen({super.key});

  @override
  State<CadastroPetScreen> createState() => _CadastroPetScreenState();
}

class _CadastroPetScreenState extends State<CadastroPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();

  String? _especie;
  String? _sexo;

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarPet() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await SessaoUsuario.instancia.tornarTutor();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: CoresApp.darkBlue,
        ),
        title: const Text(
          'Adicionar pet',
          style: TextStyle(
            color: CoresApp.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.md,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EspacamentosApp.lg),
                  decoration: BoxDecoration(
                    color: CoresApp.darkBlue,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: CoresApp.darkBlue.withAlpha(25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        color: CoresApp.accentOrange,
                        size: 34,
                      ),
                      SizedBox(width: EspacamentosApp.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vamos conhecer seu pet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Cadastre as informações básicas '
                                  'para começar a organizar os cuidados.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: EspacamentosApp.xl),

                const Text(
                  'Informações do pet',
                  style: TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.xs),

                const Text(
                  'Preencha os dados básicos do seu companheiro.',
                  style: TextStyle(
                    color: CoresApp.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.lg),

                _CampoLabel(
                  label: 'Nome do pet',
                ),
                const SizedBox(height: EspacamentosApp.sm),
                TextFormField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracaoCampo(
                    hintText: 'Digite o nome do pet',
                    icon: Icons.pets_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o nome do pet.';
                    }

                    if (value.trim().length < 2) {
                      return 'Digite um nome válido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: EspacamentosApp.md),

                _CampoLabel(
                  label: 'Espécie',
                ),
                const SizedBox(height: EspacamentosApp.sm),
                DropdownButtonFormField<String>(
                  initialValue: _especie,
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
                      _especie = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione a espécie.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: EspacamentosApp.md),

                _CampoLabel(
                  label: 'Raça',
                ),
                const SizedBox(height: EspacamentosApp.sm),
                TextFormField(
                  controller: _racaController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracaoCampo(
                    hintText: 'Digite a raça',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite a raça.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: EspacamentosApp.md),

                _CampoLabel(
                  label: 'Sexo',
                ),
                const SizedBox(height: EspacamentosApp.sm),
                Row(
                  children: [
                    Expanded(
                      child: _OpcaoSexo(
                        texto: 'Macho',
                        selecionado: _sexo == 'Macho',
                        icone: Icons.male_rounded,
                        onTap: () {
                          setState(() {
                            _sexo = 'Macho';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Expanded(
                      child: _OpcaoSexo(
                        texto: 'Fêmea',
                        selecionado: _sexo == 'Fêmea',
                        icone: Icons.female_rounded,
                        onTap: () {
                          setState(() {
                            _sexo = 'Fêmea';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (_sexo == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecione o sexo do pet.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: EspacamentosApp.xl),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _cadastrarPet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoresApp.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cadastrar pet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: EspacamentosApp.sm),

                const Center(
                  child: Text(
                    'Você poderá completar os dados do pet depois.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CoresApp.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: CoresApp.textSecondary,
      ),
      filled: true,
      fillColor: CoresApp.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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
}

class _CampoLabel extends StatelessWidget {
  const _CampoLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: CoresApp.darkBlue,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _OpcaoSexo extends StatelessWidget {
  const _OpcaoSexo({
    required this.texto,
    required this.selecionado,
    required this.icone,
    required this.onTap,
  });

  final String texto;
  final bool selecionado;
  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          decoration: BoxDecoration(
            color: selecionado
                ? CoresApp.primary.withAlpha(18)
                : CoresApp.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado
                  ? CoresApp.primary
                  : Colors.black.withAlpha(12),
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                color: selecionado
                    ? CoresApp.primary
                    : CoresApp.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(
                  color: selecionado
                      ? CoresApp.primary
                      : CoresApp.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}