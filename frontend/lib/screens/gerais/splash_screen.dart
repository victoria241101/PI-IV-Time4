import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/tutor/inicio_tutor.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logo;
  late final Animation<double> _nome;

  static const int _quantidadePegadas = 6;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _logo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.68,
        0.84,
        curve: Curves.easeOutBack,
      ),
    );

    _nome = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.80,
        0.96,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
    _finalizarSplash();
  }

  Future<void> _finalizarSplash() async {
    await Future.delayed(
      const Duration(milliseconds: 4400),
    );

    await SessaoUsuario.instancia.carregar();

    if (!mounted) return;

    if (SessaoUsuario.instancia.estaLogado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InicioTutor(
            saudacao: 'Olá,',
            nomeTutor:
            SessaoUsuario.instancia.nomeUsuario ?? 'Tutor',
            pets: const [
              ResumoPet(
                id: 'pet-001',
                name: 'Mel',
                species: 'Cachorro',
                breed: 'Golden Retriever',
                age: '3 anos',
                weight: 25.5,
              ),
              ResumoPet(
                id: 'pet-002',
                name: 'Luna',
                species: 'Gato',
                breed: 'Siamês',
                age: '2 anos',
                weight: 4.2,
              ),
            ],
            proximaConsulta: const ResumoConsulta(
              id: 'consulta-001',
              type: 'Consulta veterinária',
              date: '15/10/2026',
              time: '14:00',
              vetName: 'Dra. Ana Oliveira',
              petName: 'Mel',
              status: 'Confirmada',
              instructions:
              'Chegar com 10 minutos de antecedência.',
              clinicAddress:
              'Rua das Flores, 120 - Campinas/SP',
            ),
            banners: const [],
            onConfirmarConsulta: (consultaId) async {
              return const ResumoConsulta(
                id: 'consulta-001',
                type: 'Consulta veterinária',
                date: '15/10/2026',
                time: '14:00',
                vetName: 'Dra. Ana Oliveira',
                petName: 'Mel',
                status: 'Confirmada',
                instructions:
                'Chegar com 10 minutos de antecedência.',
                clinicAddress:
                'Rua das Flores, 120 - Campinas/SP',
              );
            },
            carregarDetalhesPet: (petId) async {
              throw UnimplementedError(
                'Detalhes do pet ainda não estão conectados ao backend.',
              );
            },
            onAgendarNovaConsulta: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Agendamento ainda não está conectado ao backend.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onNotificacoes: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notificações ainda não estão disponíveis.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const InicioPublico(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largura = constraints.maxWidth;
            final altura = constraints.maxHeight;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Elementos decorativos discretos.
                    Positioned(
                      top: altura * 0.16,
                      left: -largura * 0.22,
                      child: _circuloDecorativo(
                        tamanho: largura * 0.55,
                        cor: CoresApp.primary.withAlpha(12),
                      ),
                    ),
                    Positioned(
                      bottom: altura * 0.14,
                      right: -largura * 0.20,
                      child: _circuloDecorativo(
                        tamanho: largura * 0.48,
                        cor: CoresApp.darkBlue.withAlpha(9),
                      ),
                    ),

                    // Passos distribuídos ao longo de uma caminhada.
                    ..._construirPegadas(
                      largura: largura,
                      altura: altura,
                    ),

                    // Logo simples: patinha turquesa + nome em bold.
                    Center(
                      child: Transform.scale(
                        scale: _logo.value.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: _logo.value.clamp(0.0, 1.0),
                          child: _construirLogo(),
                        ),
                      ),
                    ),

                    // Assinatura abaixo da marca.
                    Positioned(
                      top: altura / 2 + 36,
                      left: 16,
                      right: 16,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          10 * (1 - _nome.value),
                        ),
                        child: Opacity(
                          opacity: _nome.value.clamp(0.0, 1.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: CoresApp.primary,
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Cuidar também é uma forma de amar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CoresApp.textSecondary
                                      .withAlpha(210),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _construirLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.pets_rounded,
          size: 32,
          color: CoresApp.primary,
        ),
        const SizedBox(width: 8),
        const Text(
          'PetCare',
          style: TextStyle(
            fontSize: 27,
            height: 1.1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: CoresApp.darkBlue,
          ),
        ),
      ],
    );
  }

  List<Widget> _construirPegadas({
    required double largura,
    required double altura,
  }) {
    final List<Widget> pegadas = [];

    // Caminho diagonal com alternância lateral mais perceptível.
    // O último passo se aproxima da lateral esquerda da logo.
    final pontos = <Offset>[
      Offset(largura * 0.14, altura * 0.76),
      Offset(largura * 0.28, altura * 0.68),
      Offset(largura * 0.23, altura * 0.59),
      Offset(largura * 0.39, altura * 0.54),
      Offset(largura * 0.34, altura * 0.46),
      Offset(largura * 0.42, altura * 0.43),
    ];

    for (int i = 0; i < _quantidadePegadas; i++) {
      // Intervalos separados para cada passo.
      final inicio = 0.035 + i * 0.108;
      final fim = inicio + 0.065;

      final progresso = Interval(
        inicio,
        fim,
        curve: Curves.easeOutCubic,
      ).transform(_controller.value);

      // As pegadas desaparecem gradualmente antes da logo.
      final opacidadeSaida = 1.0 -
          Curves.easeIn.transform(
            ((_controller.value - 0.62) / 0.08)
                .clamp(0.0, 1.0),
          );

      if (_controller.value < inicio) {
        continue;
      }

      final ponto = pontos[i];

      // Orientação alternada para sugerir passos reais.
      final rotacao = i.isEven ? -0.32 : 0.32;

      pegadas.add(
        Positioned(
          left: ponto.dx - 22,
          top: ponto.dy - 22,
          child: Opacity(
            opacity: progresso.clamp(0.0, 1.0) *
                opacidadeSaida.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rotacao,
              child: Transform.scale(
                scale: 0.75 +
                    progresso.clamp(0.0, 1.0) * 0.25,
                child: Icon(
                  Icons.pets_rounded,
                  size: 44,
                  color: i.isEven
                      ? CoresApp.primary
                      : CoresApp.darkBlue,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pegadas;
  }

  Widget _circuloDecorativo({
    required double tamanho,
    required Color cor,
  }) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
      ),
    );
  }
}
