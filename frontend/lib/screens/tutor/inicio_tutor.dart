import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/dados_banner.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';

import 'package:pet_care/screens/tutor/pagina_detalhes_pet.dart';
import 'package:pet_care/screens/tutor/perfil_tutor.dart';
import 'package:pet_care/screens/tutor/consultas_tutor.dart';
import 'package:pet_care/screens/tutor/conversas_tutor.dart';

import 'package:pet_care/widgets/botao_acao_com_icone.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/carrossel_banners.dart';
import 'package:pet_care/widgets/cartao_proxima_consulta.dart';
import 'package:pet_care/widgets/lista_horizontal_pets.dart';
import 'package:pet_care/widgets/modal_detalhes_consulta.dart';
import 'package:pet_care/widgets/titulo_secao.dart';
import 'package:pet_care/widgets/modal_notificacoes_tutor.dart';
import 'package:pet_care/widgets/barra_nav_tutor.dart';

import '../doacao/doacao.dart';

typedef ConfirmarConsulta = Future<ResumoConsulta> Function(
    String consultaId,
    );

typedef AcaoConsulta = Future<void> Function(String consultaId);

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
    this.consultas = const [],
    this.onAgendamentoConfirmado,
    this.onReagendamentoConfirmado,
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

  final List<ResumoConsulta> consultas;

  final ConfirmarNovoAgendamento? onAgendamentoConfirmado;
  final ConfirmarReagendamento? onReagendamentoConfirmado;

  @override
  State<InicioTutor> createState() => _EstadoInicioTutor();
}

class _EstadoInicioTutor extends State<InicioTutor> {
  int _currentNavIndex = 0;

  bool _confirmandoConsulta = false;

  late ResumoConsulta _proximaConsulta;
  late List<ResumoConsulta> _consultas;

  String? _consultaIdParaReagendar;

  @override
  void initState() {
    super.initState();

    _proximaConsulta = widget.proximaConsulta;
    _consultas = List<ResumoConsulta>.from(widget.consultas);

    _sincronizarProximaConsulta();
  }

  @override
  void didUpdateWidget(covariant InicioTutor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.proximaConsulta != widget.proximaConsulta) {
      _proximaConsulta = widget.proximaConsulta;
    }

    if (oldWidget.consultas != widget.consultas) {
      _consultas = List<ResumoConsulta>.from(widget.consultas);
      _sincronizarProximaConsulta();
    }
  }

  void _sincronizarProximaConsulta() {
    final indice = _consultas.indexWhere(
          (consulta) => consulta.id == _proximaConsulta.id,
    );

    if (indice >= 0) {
      _consultas[indice] = _proximaConsulta;
    } else {
      _consultas.insert(0, _proximaConsulta);
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  // ============================================================
  // NAVEGAÇÃO PRINCIPAL DO TUTOR
  // ============================================================

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() {
          _currentNavIndex = 0;
          _consultaIdParaReagendar = null;
        });
        break;

      case 1:
        setState(() {
          _currentNavIndex = 1;
        });
        break;

      case 2:
        setState(() {
          _currentNavIndex = 2;
          _consultaIdParaReagendar = null;
        });
        break;

      case 3:
        setState(() {
          _currentNavIndex = 3;
          _consultaIdParaReagendar = null;
        });
        break;

      case 4:
        setState(() {
          _currentNavIndex = 4;
          _consultaIdParaReagendar = null;
        });
        break;

      default:
        setState(() {
          _currentNavIndex = 0;
          _consultaIdParaReagendar = null;
        });
        break;
    }
  }

  void _abrirAbaConsultas() {
    setState(() {
      _currentNavIndex = 1;
      _consultaIdParaReagendar = null;
    });
  }

  // ============================================================
  // AGENDAMENTO
  // ============================================================

  void _onAgendamentoConfirmado(DadosAgendamento dados) {
    final consulta = ResumoConsulta(
      id: 'consulta-${DateTime.now().microsecondsSinceEpoch}',
      type: dados.tipoAtendimento,
      date: _formatarData(dados.data),
      time: dados.horario,
      vetName: dados.veterinario,
      petName: dados.nomePet,
      status: 'Agendada',
      instructions: dados.urgente
          ? 'Atendimento marcado como urgente.'
          : 'Consulte as orientações da clínica antes do atendimento.',
      clinicAddress: 'Endereço a confirmar',
    );

    setState(() {
      _consultas = [..._consultas, consulta];
    });

    widget.onAgendamentoConfirmado?.call(dados);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Agendamento adicionado à lista de consultas.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // REAGENDAMENTO
  // ============================================================

  void _abrirFluxoReagendamento() {
    setState(() {
      _consultaIdParaReagendar = _proximaConsulta.id;
      _currentNavIndex = 1;
    });
  }

  void _onReagendamentoConfirmado(
      String consultaId,
      DadosAgendamento novosDados,
      ) {
    final indice = _consultas.indexWhere(
          (consulta) => consulta.id == consultaId,
    );

    if (indice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível localizar essa consulta.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final consultaAnterior = _consultas[indice];

    final consultaAtualizada = ResumoConsulta(
      id: consultaAnterior.id,
      type: novosDados.tipoAtendimento,
      date: _formatarData(novosDados.data),
      time: novosDados.horario,
      vetName: novosDados.veterinario,
      petName: novosDados.nomePet,
      status: 'Reagendada',
      instructions: novosDados.urgente
          ? 'Atendimento marcado como urgente.'
          : consultaAnterior.instructions,
      clinicAddress: consultaAnterior.clinicAddress,
    );

    setState(() {
      _consultas = List<ResumoConsulta>.from(_consultas);
      _consultas[indice] = consultaAtualizada;

      if (_proximaConsulta.id == consultaId) {
        _proximaConsulta = consultaAtualizada;
      }

      _consultaIdParaReagendar = null;
    });

    widget.onReagendamentoConfirmado?.call(
      consultaId,
      novosDados,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Consulta reagendada com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DETALHES DA CONSULTA
  // ============================================================

  void _onAppointmentDetails() {
    ModalDetalhesConsulta.show(
      context,
      appointment: _proximaConsulta,
      onReschedule: () {
        Navigator.of(context).pop();
        _abrirFluxoReagendamento();
      },
      onCancel: widget.onCancelarConsulta == null
          ? null
          : () async {
        Navigator.of(context).pop();

        await widget.onCancelarConsulta!(
          _proximaConsulta.id,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitação de cancelamento enviada.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // ============================================================
  // DETALHES DO PET
  // ============================================================

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

  // ============================================================
  // CONFIRMAR CONSULTA
  // ============================================================

  Future<void> _onConfirmAppointment() async {
    if (_confirmandoConsulta) return;

    setState(() {
      _confirmandoConsulta = true;
    });

    try {
      final consultaAtualizada = await widget.onConfirmarConsulta(
        _proximaConsulta.id,
      );

      if (!mounted) return;

      setState(() {
        _proximaConsulta = consultaAtualizada;
        _confirmandoConsulta = false;

        final indice = _consultas.indexWhere(
              (consulta) => consulta.id == consultaAtualizada.id,
        );

        if (indice >= 0) {
          _consultas[indice] = consultaAtualizada;
        } else {
          _consultas.insert(0, consultaAtualizada);
        }
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Consulta confirmada para '
                  '${consultaAtualizada.date} '
                  'às ${consultaAtualizada.time}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _confirmandoConsulta = false;
      });

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

  // ============================================================
  // TELA INICIAL
  // ============================================================

  Widget _construirInicio() {
    return SingleChildScrollView(
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
            onNotificationTap: () {
              if (widget.onNotificacoes != null) {
                widget.onNotificacoes!();
              } else {
                ModalNotificacoesTutor.show(context);
              }
            },
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
              onPressed: _abrirAbaConsultas,
              semanticLabel: 'Agendar nova consulta',
            ),
          ),

          const SizedBox(height: EspacamentosApp.xl),

          const TituloSecao(title: 'Novidades'),

          const SizedBox(height: EspacamentosApp.md),

          CarrosselBanners(
            banners: widget.banners,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO DA ABA SELECIONADA
  // ============================================================

  Widget _construirTelaAtual() {
    switch (_currentNavIndex) {
      case 0:
        return _construirInicio();

      case 1:
        return ConsultasTutor(
          consultas: _consultas,
          nomesPets: widget.pets.map((pet) => pet.name).toList(),
          consultaIdParaReagendar: _consultaIdParaReagendar,
          onAgendamentoConfirmado: _onAgendamentoConfirmado,
          onReagendamentoConfirmado: _onReagendamentoConfirmado,
        );

      case 2:
        return const ConversasTutor();

      case 3:
        return const Doacao();

      case 4:
        return const PerfilTutor();

      default:
        return _construirInicio();
    }
  }

  // ============================================================
  // BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: _construirTelaAtual(),
      ),
      bottomNavigationBar: BarraNavTutor(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}