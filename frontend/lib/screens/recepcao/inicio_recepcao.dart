// tela principal da recepção com agenda, cadastro, calendário e chat
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/agenda_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/calendario_agendamentos.dart';
import 'package:pet_care/screens/recepcao/chat_recepcao.dart';
import 'package:pet_care/widgets/barra_navegacao_app.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';

/// Tela principal do fluxo de recepção / secretaria.
class InicioRecepcao extends StatefulWidget {
  const InicioRecepcao({super.key});

  @override
  State<InicioRecepcao> createState() => _InicioRecepcaoState();
}

class _InicioRecepcaoState extends State<InicioRecepcao> {
  int _abaAtual = 0;
  late final DateTime _hoje;
  late final List<ConsultaRecepcao> _consultas;
  late DateTime _dataInicialAgenda;
  int _versaoCalendario = 0;

  @override
  void initState() {
    super.initState();
    _hoje = DateUtils.dateOnly(DateTime.now());
    _dataInicialAgenda = _hoje;
    _consultas = AgendaClinica.instancia.consultas;
    AgendaClinica.instancia.addListener(_atualizarAgendaCompartilhada);
  }

  @override
  void dispose() {
    AgendaClinica.instancia.removeListener(_atualizarAgendaCompartilhada);
    super.dispose();
  }

  void _atualizarAgendaCompartilhada() {
    if (mounted) setState(() {});
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(EspacamentosApp.md),
        ),
      );
  }

  String get _saudacao {
    final hora = TimeOfDay.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _nomeUsuario {
    final nome = SessaoUsuario.instancia.nomeUsuario;
    return (nome != null && nome.isNotEmpty) ? nome : 'Recepção';
  }

  void _confirmarChegada(ConsultaRecepcao consulta) {
    setState(
      () => AgendaClinica.instancia.atualizarStatus(
        consulta,
        StatusConsultaRecepcao.aguardandoTriagem,
      ),
    );
    _mensagem('Chegada confirmada · ${consulta.pet} está aguardando triagem');
  }

  void _cancelarConsulta(ConsultaRecepcao consulta) {
    setState(() => AgendaClinica.instancia.removerConsulta(consulta));
    _mensagem('Consulta de ${consulta.pet} cancelada');
  }

  void _reagendarConsulta(
    ConsultaRecepcao consulta,
    String horario,
    String profissional,
  ) {
    setState(() {
      consulta.horario = horario;
      consulta.profissional = profissional;
      consulta.sala = profissional == 'Dr. Silva' ? 'Sala 01' : 'Sala 02';
      AgendaClinica.instancia.notificarAlteracao();
    });
    _mensagem('Consulta de ${consulta.pet} atualizada');
  }

  bool _registrarConsulta(ConsultaRecepcao consulta) {
    if (consulta.status == StatusConsultaRecepcao.agendada) {
      final novoInicio = _minutosDoDia(consulta.horario);
      final novoFim = novoInicio + consulta.duracaoMinutos;
      final conflito = _consultas.any((existente) {
        if (!DateUtils.isSameDay(existente.data, consulta.data) ||
            existente.profissional != consulta.profissional ||
            existente.status == StatusConsultaRecepcao.finalizado) {
          return false;
        }
        final inicioExistente = _minutosDoDia(existente.horario);
        final fimExistente = inicioExistente + existente.duracaoMinutos;
        return novoInicio < fimExistente && inicioExistente < novoFim;
      });
      if (conflito) return false;
    }

    setState(() {
      AgendaClinica.instancia.adicionarConsulta(consulta);
      _dataInicialAgenda = DateUtils.dateOnly(consulta.data);
      _versaoCalendario++;
      _abaAtual = consulta.status == StatusConsultaRecepcao.agendada ? 1 : 0;
    });
    _mensagem(
      consulta.status == StatusConsultaRecepcao.agendada
          ? 'Consulta de ${consulta.pet} adicionada à agenda'
          : '${consulta.pet} está aguardando triagem',
    );
    return true;
  }

  int _minutosDoDia(String horario) {
    final partes = horario.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  @override
  Widget build(BuildContext context) {
    final consultasDeHoje = _consultas
        .where((consulta) => DateUtils.isSameDay(consulta.data, _hoje))
        .toList();

    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: EspacamentosApp.md,
                bottom: EspacamentosApp.xs,
              ),
              child: AnimatedBuilder(
                animation: SessaoUsuario.instancia,
                builder: (context, _) => CabecalhoApp(
                  greeting: _saudacao,
                  name: _nomeUsuario,
                  onNotificationTap: () =>
                      _mensagem('Você está em dia com as notificações'),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _abaAtual,
                children: [
                  AgendaRecepcao(
                    consultas: consultasDeHoje,
                    onConfirmarChegada: _confirmarChegada,
                  ),
                  CalendarioAgendamentos(
                    key: ValueKey(_versaoCalendario),
                    consultas: _consultas,
                    dataInicial: _dataInicialAgenda,
                    onCancelar: _cancelarConsulta,
                    onReagendar: _reagendarConsulta,
                  ),
                  CadastroRecepcao(onRegistrarConsulta: _registrarConsulta),
                  const ChatRecepcao(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraNavegacaoApp(
        currentIndex: _abaAtual,
        onTap: (index) => setState(() => _abaAtual = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today_rounded),
            label: 'Hoje',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_outlined),
            activeIcon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Cadastro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
