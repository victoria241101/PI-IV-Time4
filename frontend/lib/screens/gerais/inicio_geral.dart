import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

import 'package:pet_care/screens/doacao/doacao.dart';
import 'package:pet_care/screens/publico/sobre_publico.dart';

import 'package:pet_care/widgets/gerais/barra_nav_geral.dart';
import 'package:pet_care/widgets/gerais/cabecalho_geral.dart';

class InicioGeral extends StatefulWidget {
  const InicioGeral({super.key});

  @override
  State<InicioGeral> createState() => _InicioGeralState();
}

class _InicioGeralState extends State<InicioGeral> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const Doacao(publica: false),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SobrePublico(),
        ),
      );
      return;
    }

    if (index == 3) {
      _abrirPerfil();
    }
  }

  void _abrirPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil do usuário será implementado em seguida.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _adicionarPet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cadastro do pet será implementado em seguida.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _abrirCampanhas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Doacao(publica: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: EspacamentosApp.md,
            bottom: EspacamentosApp.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabecalhoGeral(
                onPerfilTap: _abrirPerfil,
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              // =====================================================
              // HERO
              // =====================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    EspacamentosApp.lg,
                  ),
                  decoration: BoxDecoration(
                    color: CoresApp.darkBlue,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: CoresApp.darkBlue.withAlpha(25),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -25,
                        top: -25,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: CoresApp.primary.withAlpha(35),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -55,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: CoresApp.accentOrange.withAlpha(22),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: CoresApp.accentOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(
                            height: EspacamentosApp.md,
                          ),
                          const Text(
                            'Cuide. Ajude.\nTransforme.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),
                          const Text(
                            'Um lugar para cuidar dos seus pets '
                                'e fazer a diferença na vida de outros animais.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(
                            height: EspacamentosApp.lg,
                          ),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _abrirCampanhas,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                CoresApp.accentOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Quero ajudar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // =====================================================
              // MEUS PETS
              // =====================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meus pets',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Cadastre seus companheiros e tenha '
                          'os cuidados organizados em um só lugar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),
                    _CardAdicionarPet(
                      onTap: _adicionarPet,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // =====================================================
              // COMO PODEMOS AJUDAR?
              // =====================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Como podemos ajudar?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    const SizedBox(
                      height: EspacamentosApp.xs,
                    ),
                    const Text(
                      'Tudo começa com uma pequena ação.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _AcaoGeral(
                            icon: Icons.volunteer_activism_rounded,
                            titulo: 'Apoiar',
                            descricao:
                            'Contribua com uma campanha.',
                            onTap: _abrirCampanhas,
                          ),
                        ),
                        const SizedBox(
                          width: EspacamentosApp.sm,
                        ),
                        Expanded(
                          child: _AcaoGeral(
                            icon: Icons.pets_rounded,
                            titulo: 'Cuidar',
                            descricao:
                            'Cadastre e cuide do seu pet.',
                            onTap: _adicionarPet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // =====================================================
              // SOBRE O PETCARE
              // =====================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SobrePublico(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      EspacamentosApp.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withAlpha(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: CoresApp.primary.withAlpha(18),
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: CoresApp.primary,
                          ),
                        ),
                        const SizedBox(
                          width: EspacamentosApp.md,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conheça o PetCare',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: CoresApp.darkBlue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Entenda nossa proposta e como '
                                    'conectamos cuidado e solidariedade.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color:
                                  CoresApp.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: CoresApp.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraNavGeral(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _CardAdicionarPet extends StatelessWidget {
  const _CardAdicionarPet({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            EspacamentosApp.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CoresApp.primary.withAlpha(45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: CoresApp.primary,
                  size: 30,
                ),
              ),
              const SizedBox(
                width: EspacamentosApp.md,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar um pet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cadastre seu companheiro e comece '
                          'a organizar seus cuidados.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CoresApp.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcaoGeral extends StatelessWidget {
  const _AcaoGeral({
    required this.icon,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: CoresApp.primary,
                  size: 23,
                ),
              ),
              const SizedBox(
                height: EspacamentosApp.sm,
              ),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}