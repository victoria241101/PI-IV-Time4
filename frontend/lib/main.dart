// inicializacao e rotas principais do aplicativo
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/comportamento_rolagem.dart';
import 'package:pet_care/core/tema/tema_app.dart';
import 'package:pet_care/screens/autenticacao/cadastro.dart';
import 'package:pet_care/screens/autenticacao/login.dart';
import 'package:pet_care/screens/enfermeiro/inicio_enfermeiro.dart';
import 'package:pet_care/screens/revisao_fluxos_temporaria.dart';
import 'package:pet_care/screens/publico/inicio_publico.dart';
import 'package:pet_care/screens/recepcao/inicio_recepcao.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

void main() {
  // Após a revisão, restaure InicioEnfermeiro como home e remova o import temporário.
  runApp(const AplicativoVeterinaria(home: RevisaoFluxosTemporaria()));
}

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({super.key, required this.home});

  // ============================================================
  // DIRECIONAMENTO INICIAL
  // ============================================================

  Future<void> _abrirInicio(BuildContext context) async {
    await SessaoUsuario.instancia.carregar();

    if (!context.mounted) return;

    final sessao = SessaoUsuario.instancia;

    final Widget destino;

    if (!sessao.estaLogado) {
      destino = const InicioPublico();
    } else if (sessao.ehTutor) {
      destino = _construirInicioTutor(context);
    } else {
      destino = const InicioGeral();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => destino,
      ),
    );
  }

  Widget _construirDestinoAutenticado(BuildContext context) {
    final sessao = SessaoUsuario.instancia;

    if (sessao.ehTutor) {
      return _construirInicioTutor(context);
    }

    return const InicioGeral();
  }

  // ============================================================
  // INÍCIO DO TUTOR
  // ============================================================

  Widget _construirInicioTutor(BuildContext context) {
    final sessao = SessaoUsuario.instancia;

    return InicioTutor(
      saudacao: 'Olá,',
      nomeTutor: sessao.nomeUsuario ?? 'Tutor',
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
        instructions: 'Chegar com 10 minutos de antecedência.',
        clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
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
          instructions: 'Chegar com 10 minutos de antecedência.',
          clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
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
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ComportamentoRolagemApp(),
      theme: TemaApp.light,
      home: Builder(
        builder: (context) {
          return SplashScreen(
            onConcluida: () => _abrirInicio(context),
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/inicio-publico': (context) => const InicioPublico(),
        '/inicio-geral': (context) => const InicioGeral(),
        '/inicio-autenticado': (context) => _construirDestinoAutenticado(context),
        '/campanhas': (context) => const Doacao(publica: true),
        '/sobre': (context) => const Sobre(),
        '/recepcao': (context) => const InicioRecepcao(),
        '/veterinario': (context) => const InicioVeterinario(),
        '/enfermeiro': (context) => const InicioEnfermeiro(),
      },
    );
  }
}
