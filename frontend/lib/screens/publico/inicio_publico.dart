import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/doacao/doacao.dart';

import 'package:pet_care/widgets/publicos/cabecalho_publico.dart';
import 'package:pet_care/widgets/cartao_campanha.dart';
import '../../widgets/publicos/barra_nav_publica.dart';

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
      setState(() {
        _currentIndex = 1;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const Doacao(),
        ),
      );

      return;
    }

    if (index == 2) {
      if (SessaoUsuario.instancia.estaLogado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil em desenvolvimento.',
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    }
  }

  void _abrirCampanhas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Doacao(),
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
                height: EspacamentosApp.xl,
              ),

              // ==========================================
              // APRESENTAÇÃO
              // ==========================================

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
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.pets_rounded,
                        color: CoresApp.accentOrange,
                        size: 36,
                      ),

                      const SizedBox(
                        height: EspacamentosApp.md,
                      ),

                      const Text(
                        'Cuide. Ajude. Transforme.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: EspacamentosApp.sm,
                      ),

                      const Text(
                        'Conectamos pessoas a animais que precisam de cuidados e apoio.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                        height: EspacamentosApp.lg,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _abrirCampanhas,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CoresApp.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: EspacamentosApp.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Conheça as campanhas',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // ==========================================
              // COMO AJUDAR
              // ==========================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Como você pode ajudar?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    const Text(
                      'Pequenas ações podem fazer uma grande diferença.',
                      style: TextStyle(
                        color: CoresApp.textSecondary,
                        fontSize: 14,
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
                            'Ajude um animal em tratamento.',
                            onTap: _abrirCampanhas,
                          ),
                        ),

                        const SizedBox(
                          width: EspacamentosApp.sm,
                        ),

                        Expanded(
                          child: _AcaoPublica(
                            icon: Icons.search_rounded,
                            titulo: 'Conhecer',
                            descricao:
                            'Veja casos que precisam de apoio.',
                            onTap: _abrirCampanhas,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    _AcaoPublica(
                      icon: Icons.favorite_rounded,
                      titulo: 'Acompanhar',
                      descricao:
                      'Veja histórias e atualizações dos animais atendidos.',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Acompanhamento em desenvolvimento.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              // ==========================================
              // CAMPANHAS EM DESTAQUE
              // ==========================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Campanhas em destaque',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: _abrirCampanhas,
                      child: const Text(
                        'Ver todas',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              SizedBox(
                height: 440,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspacamentosApp.pagePadding,
                  ),
                  children: [
                    SizedBox(
                      width: 320,
                      child: CartaoCampanha(
                        nomeAnimal: 'Bobby',
                        titulo: 'Tratamento veterinário',
                        valorArrecadado: 850,
                        meta: 1500,
                        urgente: true,
                        onTap: _abrirCampanhas,
                      ),
                    ),

                    const SizedBox(
                      width: EspacamentosApp.md,
                    ),

                    SizedBox(
                      width: 320,
                      child: CartaoCampanha(
                        nomeAnimal: 'Luna',
                        titulo: 'Cirurgia e recuperação',
                        valorArrecadado: 620,
                        meta: 1200,
                        urgente: false,
                        onTap: _abrirCampanhas,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),
            ],
          ),
        ),
      ),

      // ==========================================
      // NAVEGAÇÃO PÚBLICA
      // ==========================================

      bottomNavigationBar: BarraNavPublica(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ======================================================
// CARD DE AÇÃO
// ======================================================

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(
          EspacamentosApp.md,
        ),
        decoration: BoxDecoration(
          color: CoresApp.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withAlpha(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: CoresApp.primary,
              size: 28,
            ),

            const SizedBox(
              height: EspacamentosApp.sm,
            ),

            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CoresApp.darkBlue,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              descricao,
              style: const TextStyle(
                fontSize: 12,
                color: CoresApp.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}