import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
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
  late final Animation<double> _patinhas;
  late final Animation<double> _logo;
  late final Animation<double> _nome;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _patinhas = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.55,
        curve: Curves.easeInOut,
      ),
    );

    _logo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.50,
        0.75,
        curve: Curves.elasticOut,
      ),
    );

    _nome = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.70,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    _finalizarSplash();
  }

  Future<void> _finalizarSplash() async {
    await Future.delayed(
      const Duration(milliseconds: 3200),
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
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.colorScheme.surface,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - _patinhas.value,
                child: Stack(
                  children: [
                    _patinha(
                      context,
                      left: 55,
                      top: 230,
                      dx: 0.8,
                      dy: 0.5,
                    ),
                    _patinha(
                      context,
                      right: 55,
                      top: 300,
                      dx: -0.8,
                      dy: 0.35,
                    ),
                    _patinha(
                      context,
                      left: 85,
                      bottom: 260,
                      dx: 0.6,
                      dy: -0.5,
                    ),
                    _patinha(
                      context,
                      right: 80,
                      bottom: 220,
                      dx: -0.6,
                      dy: -0.5,
                    ),
                  ],
                ),
              ),

              Transform.scale(
                scale: _logo.value,
                child: Opacity(
                  opacity: _logo.value.clamp(0.0, 1.0),
                  child: Icon(
                    Icons.pets,
                    size: 82,
                    color: tema.colorScheme.primary,
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).size.height / 2 + 65,
                child: Opacity(
                  opacity: _nome.value,
                  child: Text(
                    'PetCare',
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _patinha(
      BuildContext context, {
        double? left,
        double? right,
        double? top,
        double? bottom,
        required double dx,
        required double dy,
      }) {
    final tema = Theme.of(context);
    final deslocamento = 1 - _patinhas.value;

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Transform.translate(
        offset: Offset(
          dx * 100 * deslocamento,
          dy * 100 * deslocamento,
        ),
        child: Icon(
          Icons.pets,
          size: 28,
          color: tema.colorScheme.primary.withValues(
            alpha: 0.55,
          ),
        ),
      ),
    );
  }
}