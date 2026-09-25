import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/modelos/dados_banner.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/tutor/pagina_detalhes_pet.dart';
import 'package:pet_care/widgets/botao_acao_com_icone.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/carrossel_banners.dart';
import 'package:pet_care/widgets/cartao_proxima_consulta.dart';
import 'package:pet_care/widgets/lista_horizontal_pets.dart';
import 'package:pet_care/widgets/modal_detalhes_consulta.dart';
import 'package:pet_care/widgets/titulo_secao.dart';

typedef ConfirmarConsulta = Future<ResumoConsulta> Function(String consultaId);
typedef AcaoConsulta = Future<void> Function(String consultaId);

/// Home do tutor.
///
/// Recebe dados prontos e ações por injeção. A tela não conhece mocks, APIs ou
/// qualquer implementação de back-end.
class InicioTutor extends StatefulWidget {
  const InicioTutor({
    super.key,
    required this.saudacao,
    required this.nomeTutor,
    required this.pets,
    required this.proximaConsulta,
    required this.banners,
    required this.onConfirmarConsulta,
    required this.carregarDetalhesPet,
    this.onReagendarConsulta,
    this.onCancelarConsulta,
    this.onAgendarNovaConsulta,
    this.onNotificacoes,
  });

  final String saudacao;
  final String nomeTutor;
  final List<ResumoPet> pets;
  final ResumoConsulta proximaConsulta;
  final List<DadosBanner> banners;
  final ConfirmarConsulta onConfirmarConsulta;
  final CarregarDetalhesPet carregarDetalhesPet;
  final AcaoConsulta? onReagendarConsulta;
  final AcaoConsulta? onCancelarConsulta;
  final VoidCallback? onAgendarNovaConsulta;
  final VoidCallback? onNotificacoes;

  @override
  State<InicioTutor> createState() => _EstadoInicioTutor();
}

class _EstadoInicioTutor extends State<InicioTutor> {
  int _currentNavIndex = 0;
  bool _confirmandoConsulta = false;
  late ResumoConsulta _proximaConsulta;

  @override
  void initState() {
    super.initState();
    _proximaConsulta = widget.proximaConsulta;
  }

  @override
  void didUpdateWidget(covariant InicioTutor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proximaConsulta != widget.proximaConsulta) {
      _proximaConsulta = widget.proximaConsulta;
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
  }

  void _onAppointmentDetails() {
    ModalDetalhesConsulta.show(
      context,
      appointment: _proximaConsulta,
      onReschedule: widget.onReagendarConsulta == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await widget.onReagendarConsulta!(_proximaConsulta.id);
            },
      onCancel: widget.onCancelarConsulta == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await widget.onCancelarConsulta!(_proximaConsulta.id);
            },
    );
  }

  void _abrirDetalhesPet(ResumoPet pet) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaginaDetalhesPet(
          pet: pet,
          carregarDetalhes: widget.carregarDetalhesPet,
        ),
      ),
    );
  }

  Future<void> _onConfirmAppointment() async {
    if (_confirmandoConsulta) return;

    setState(() => _confirmandoConsulta = true);

    try {
      final consultaAtualizada = await widget.onConfirmarConsulta(
        _proximaConsulta.id,
      );
      if (!mounted) return;

      setState(() {
        _proximaConsulta = consultaAtualizada;
        _confirmandoConsulta = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: EspacamentosApp.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consulta confirmada!',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Nos vemos em ${consultaAtualizada.date} às '
                        '${consultaAtualizada.time}.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirmandoConsulta = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível confirmar a consulta. Tente novamente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
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
              CabecalhoApp(
                greeting: widget.saudacao,
                name: widget.nomeTutor,
                onNotificationTap: widget.onNotificacoes,
              ),
              const SizedBox(height: EspacamentosApp.xl),
              const TituloSecao(title: 'Meus pets'),
              const SizedBox(height: EspacamentosApp.md),
              ListaHorizontalPets(
                pets: widget.pets,
                onPetTap: _abrirDetalhesPet,
              ),
              const SizedBox(height: EspacamentosApp.xl),
              const TituloSecao(title: 'Próxima consulta'),
              const SizedBox(height: EspacamentosApp.md),
              CartaoProximaConsulta(
                appointment: _proximaConsulta,
                onDetailsTap: _onAppointmentDetails,
                onConfirmTap: _onConfirmAppointment,
                isConfirming: _confirmandoConsulta,
              ),
              const SizedBox(height: EspacamentosApp.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: BotaoAcaoComIcone(
                  icon: Icons.calendar_month_outlined,
                  label: 'Agendar nova consulta',
                  onPressed: widget.onAgendarNovaConsulta,
                  semanticLabel: 'Agendar nova consulta',
                ),
              ),
              const SizedBox(height: EspacamentosApp.xl),
              const TituloSecao(title: 'Novidades'),
              const SizedBox(height: EspacamentosApp.md),
              CarrosselBanners(banners: widget.banners),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Consultas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism_rounded),
            label: 'Doações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
