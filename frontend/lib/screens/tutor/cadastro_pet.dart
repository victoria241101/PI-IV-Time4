import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

const Color _azulPet = Color(0xFF172A46);
const Color _turquesaPet = Color(0xFF27B8B0);
const Color _laranjaPet = Color(0xFFFFA45B);
const Color _fundoPet = Color(0xFFF5F7FA);
const Color _bordaPet = Color(0xFFE5EBF1);
const Color _textoSecundarioPet = Color(0xFF718096);
const Color _fundoLaranjaPet = Color(0xFFFFF2E5);

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

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrarPet() async {
    FocusScope.of(context).unfocus();

    if (_salvando) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await SessaoUsuario.instancia.tornarTutor();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível concluir o cadastro. Tente novamente.',
          ),
          backgroundColor: _azulPet,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  InputDecoration _decoracaoCampo({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _textoSecundarioPet,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: _turquesaPet,
        size: 21,
      ),
      filled: true,
      fillColor: _fundoPet,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _bordaPet),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _bordaPet),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _turquesaPet,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _campoLabel(String texto, {bool obrigatorio = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            texto,
            style: const TextStyle(
              color: _azulPet,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (obrigatorio) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: _laranjaPet,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _campoEspecie() {
    return DropdownButtonFormField<String>(
      initialValue: _especie,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _textoSecundarioPet,
      ),
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
      onChanged: _salvando
          ? null
          : (value) {
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
    );
  }

  Widget _campoSexo() {
    return DropdownButtonFormField<String>(
      initialValue: _sexo,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _textoSecundarioPet,
      ),
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
      onChanged: _salvando
          ? null
          : (value) {
        setState(() {
          _sexo = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione o sexo.';
        }

        return null;
      },
    );
  }

  Widget _cartaoFormulario({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _bordaPet),
        boxShadow: [
          BoxShadow(
            color: _azulPet.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoPet,
      appBar: AppBar(
        backgroundColor: _fundoPet,
        foregroundColor: _azulPet,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        title: const Text(
          'Adicionar pet',
          style: TextStyle(
            color: _azulPet,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              EspacamentosApp.pagePadding,
              EspacamentosApp.sm,
              EspacamentosApp.pagePadding,
              EspacamentosApp.xxl,
            ),
            children: [
              _cabecalho(),
              const SizedBox(height: 27),

              const Text(
                'Informações do pet',
                style: TextStyle(
                  color: _azulPet,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Preencha os dados básicos do seu companheiro.',
                style: TextStyle(
                  color: _textoSecundarioPet,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 21),

              _cartaoFormulario(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _campoLabel('Nome do pet'),
                    TextFormField(
                      controller: _nomeController,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _decoracaoCampo(
                        hintText: 'Ex.: Luna',
                        icon: Icons.pets_rounded,
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

                    const SizedBox(height: 22),

                    _campoLabel('Espécie'),
                    _campoEspecie(),

                    const SizedBox(height: 22),

                    _campoLabel('Raça'),
                    TextFormField(
                      controller: _racaController,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      decoration: _decoracaoCampo(
                        hintText: 'Ex.: Golden Retriever',
                        icon: Icons.loyalty_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite a raça.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    _campoLabel('Sexo'),
                    _campoSexo(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _fundoLaranjaPet,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _laranjaPet.withAlpha(65),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFAD6928),
                      size: 22,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Você pode completar a ficha depois',
                            style: TextStyle(
                              color: Color(0xFF87541F),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Informações como peso, nascimento e microchip podem ser adicionadas posteriormente.',
                            style: TextStyle(
                              color: Color(0xFF87541F),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _cadastrarPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _turquesaPet,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _turquesaPet.withAlpha(120),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets_rounded, size: 21),
                      SizedBox(width: 10),
                      Text(
                        'Cadastrar pet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 13),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: _textoSecundarioPet,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Seus dados são utilizados para organizar os cuidados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textoSecundarioPet,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _azulPet,
            Color(0xFF234367),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _azulPet.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 59,
            height: 59,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withAlpha(25),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: _laranjaPet,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vamos conhecer seu pet!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Cadastre as informações básicas para começar a organizar os cuidados.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}