import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/doacao/doacao.dart';
import 'package:pet_care/screens/sobre.dart';

import 'package:pet_care/widgets/publicos/barra_nav_publica.dart';
import 'package:pet_care/widgets/publicos/cabecalho_publico.dart';

class InicioPublico extends StatefulWidget {
  const InicioPublico({super.key});

  @override
  State<InicioPublico> createState() => _InicioPublicoState();
}

class _InicioPublicoState extends State<InicioPublico> {
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
          builder: (_) => const Doacao(publica: true),
        ),
      );
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

  void _abrirLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _adicionarPet() {
    _abrirLogin();
  }

  void _abrirCampanhas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Doacao(publica: true),
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
              const CabecalhoPublico(),

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
                              borderRadius: BorderRadius.circular(16),
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
                      'Tenha os cuidados dos seus companheiros '
                          'organizados em um só lugar.',
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
              // COMO AJUDAR
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
                          child: _AcaoPublica(
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
                          child: _AcaoPublica(
                            icon: Icons.pets_rounded,
                            titulo: 'Cuidar',
                            descricao:
                            'Organize os cuidados do seu pet.',
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
              // SOBRE O PETCARE — RESUMO
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
                        builder: (_) => const Sobre(),
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
                            borderRadius: BorderRadius.circular(15),
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
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BarraNavPublica(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Entre ou crie sua conta para cadastrar '
                          'seu companheiro.',
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

class _AcaoPublica extends StatelessWidget {
  const _AcaoPublica({
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
            crossAxisAlignment: CrossAxisAlignment.start,
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