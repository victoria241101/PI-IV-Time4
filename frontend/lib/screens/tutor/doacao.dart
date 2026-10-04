import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/barra_nav_tutor.dart';
import 'package:pet_care/widgets/cartao_campanha.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';

class Doacao extends StatefulWidget {
  const Doacao({super.key});

  @override
  State<Doacao> createState() => _DoacaoState();
}

class _DoacaoState extends State<Doacao> {
  int _currentNavIndex = 2;

  void _onNavTap(int index) {
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

  void _abrirCampanha(String nomeAnimal) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Campanha de $nomeAnimal selecionada.',
          ),
          behavior: SnackBarBehavior.floating,
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
            top: EspacamentosApp.lg,
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              const CabecalhoApp(
                greeting: 'Cuide. Ajude. Transforme.',
                name: '',
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // Título principal
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Doações',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                    height: 1.15,
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.sm),

              // Descrição
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Ajude animais que precisam de cuidados veterinários.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // Título da seção
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Campanhas ativas',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              // Campanhas
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  children: [
                    CartaoCampanha(
                      nomeAnimal: 'Bobby',
                      titulo: 'Cirurgia ortopédica de emergência',
                      valorArrecadado: 1250,
                      meta: 2000,
                      urgente: true,
                      onTap: () => _abrirCampanha('Bobby'),
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    CartaoCampanha(
                      nomeAnimal: 'Luna',
                      titulo: 'Tratamento veterinário',
                      valorArrecadado: 400,
                      meta: 850,
                      onTap: () => _abrirCampanha('Luna'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BarraNavTutor(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}