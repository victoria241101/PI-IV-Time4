import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

import 'package:pet_care/screens/sobre.dart';

import 'package:pet_care/widgets/barra_nav_tutor.dart';
import 'package:pet_care/widgets/cartao_campanha.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/publicos/barra_nav_publica.dart';

import 'detalhes_doacao.dart';

class Doacao extends StatefulWidget {
  const Doacao({
    super.key,
    this.publica = false,
  });

  final bool publica;

  @override
  State<Doacao> createState() => _DoacaoState();
}

class _DoacaoState extends State<Doacao> {
  int _currentNavIndex = 2;

  @override
  void initState() {
    super.initState();

    if (widget.publica) {
      _currentNavIndex = 1;
    }
  }

  // =====================================================
  // NAVEGAÇÃO DO TUTOR
  // =====================================================

  void _onNavTapTutor(int index) {
    if (index == _currentNavIndex) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentNavIndex = index;
    });
  }

  // =====================================================
  // NAVEGAÇÃO PÚBLICA
  // =====================================================

  void _onNavTapPublica(int index) {
    if (index == 1) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const Sobre(),
        ),
      );
    }
  }

  // =====================================================
  // ABRIR CAMPANHA
  // =====================================================

  void _abrirCampanha({
    required String nomeAnimal,
    required String titulo,
    required double valorArrecadado,
    required double meta,
    bool urgente = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalhesDoacao(
          nomeAnimal: nomeAnimal,
          titulo: titulo,
          valorArrecadado: valorArrecadado,
          meta: meta,
          urgente: urgente,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,

      // ===================================================
      // CONTEÚDO
      // ===================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: EspacamentosApp.lg,
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // CABEÇALHO
              // =================================================

              if (widget.publica)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspacamentosApp.pagePadding,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                      const SizedBox(
                        width: EspacamentosApp.xs,
                      ),
                      const Text(
                        'Campanhas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const CabecalhoApp(
                  greeting: 'Cuide. Ajude. Transforme.',
                  name: '',
                ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              // =================================================
              // TÍTULO
              // =================================================

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Campanhas',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
                    height: 1.15,
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  widget.publica
                      ? 'Conheça animais que precisam de cuidados '
                      'e veja como você pode ajudar.'
                      : 'Ajude animais que precisam de cuidados '
                      'veterinários.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // =================================================
              // CAMPANHAS ATIVAS
              // =================================================

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Campanhas ativas',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.md,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  children: [
                    // =================================================
                    // BOBBY
                    // =================================================

                    CartaoCampanha(
                      nomeAnimal: 'Bobby',
                      titulo: 'Cirurgia ortopédica de emergência',
                      valorArrecadado: 1250,
                      meta: 2000,
                      urgente: true,
                      onTap: () => _abrirCampanha(
                        nomeAnimal: 'Bobby',
                        titulo: 'Cirurgia ortopédica de emergência',
                        valorArrecadado: 1250,
                        meta: 2000,
                        urgente: true,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.lg,
                    ),

                    // =================================================
                    // LUNA
                    // =================================================

                    CartaoCampanha(
                      nomeAnimal: 'Luna',
                      titulo: 'Tratamento veterinário',
                      valorArrecadado: 400,
                      meta: 850,
                      onTap: () => _abrirCampanha(
                        nomeAnimal: 'Luna',
                        titulo: 'Tratamento veterinário',
                        valorArrecadado: 400,
                        meta: 850,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.lg,
                    ),

                    // =================================================
                    // INFORMAÇÃO
                    // =================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        EspacamentosApp.md,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black.withAlpha(10),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: CoresApp.primary,
                          ),
                          SizedBox(
                            width: EspacamentosApp.sm,
                          ),
                          Expanded(
                            child: Text(
                              'As campanhas são públicas. Para realizar '
                                  'uma doação, é necessário estar autenticado.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: CoresApp.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // =====================================================
      // BARRA DE NAVEGAÇÃO
      // =====================================================

      bottomNavigationBar: widget.publica
          ? BarraNavPublica(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapPublica,
      )
          : BarraNavTutor(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapTutor,
      ),
    );
  }
}