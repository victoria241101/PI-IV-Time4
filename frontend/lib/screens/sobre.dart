import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class Sobre extends StatelessWidget {
  const Sobre({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CoresApp.darkBlue,
          ),
        ),
        title: const Text(
          'Sobre o PetCare',
          style: TextStyle(
            color: CoresApp.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.sm,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: CoresApp.accentOrange,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      height: EspacamentosApp.lg,
                    ),
                    const Text(
                      'Cuidar também é uma forma de amar.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),
                    const Text(
                      'O PetCare foi pensado para aproximar '
                          'tutores, clínicas e pessoas dispostas a '
                          'ajudar animais que precisam de cuidados.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              const Text(
                'O que é o PetCare?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              const Text(
                'Uma plataforma para centralizar o cuidado '
                    'veterinário e facilitar a conexão entre tutores '
                    'e clínicas.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              const _ItemSobre(
                icone: Icons.favorite_outline_rounded,
                titulo: 'Cuidado',
                descricao:
                'Organize informações e acompanhe os cuidados '
                    'dos seus pets.',
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              const _ItemSobre(
                icone: Icons.calendar_month_outlined,
                titulo: 'Praticidade',
                descricao:
                'Tenha acesso aos principais recursos '
                    'veterinários em um só lugar.',
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              const _ItemSobre(
                icone: Icons.volunteer_activism_outlined,
                titulo: 'Solidariedade',
                descricao:
                'Apoie campanhas de animais resgatados com '
                    'mais transparência e segurança.',
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  EspacamentosApp.md,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: CoresApp.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nas campanhas, a visualização é pública, '
                            'mas a doação exige autenticação para garantir '
                            'segurança e rastreabilidade.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
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
      ),
    );
  }
}

class _ItemSobre extends StatelessWidget {
  const _ItemSobre({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CoresApp.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icone,
              color: CoresApp.primary,
              size: 22,
            ),
          ),
          const SizedBox(
            width: EspacamentosApp.md,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    height: 1.4,
                    color: CoresApp.textSecondary,
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