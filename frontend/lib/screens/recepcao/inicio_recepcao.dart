// tela principal da recepção com agenda, cadastro, calendário e chat
import 'package:flutter/material.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/screens/recepcao/cadastro/central_cadastros_recepcao.dart';
import 'package:pet_care/widgets/clinica/layout_clinica.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/agenda_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/calendario_agendamentos.dart';
import 'package:pet_care/screens/recepcao/chat_recepcao.dart';

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
    if (consulta.prontuarioOrigemId != null &&
        _consultas.any(
          (c) => c.prontuarioOrigemId == consulta.prontuarioOrigemId,
        )) {
      return false;
    }
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

  Future<void> _novoAgendamento(DateTime dia) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: CoresApp.background,
          appBar: cabecalhoClinica('Novo agendamento'),
          body: CadastroRecepcao(
            dataInicial: dia,
            onRegistrarConsulta: _registrarConsulta,
          ),
        ),
      ),
    );
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

    return LayoutClinica(
      nomePadrao: 'Recepção',
      abaAtual: _abaAtual,
      onSelecionarAba: (index) => setState(() => _abaAtual = index),
      onNotificacao: () => _mensagem('Você está em dia com as notificações'),
      terceiraAba: const BottomNavigationBarItem(
        icon: Icon(Icons.person_add_alt_1_outlined),
        label: 'Cadastro',
      ),
      paginas: [
        AgendaRecepcao(
          consultas: consultasDeHoje,
          onConfirmarChegada: _confirmarChegada,
        ),
        CalendarioAgendamentos(
          key: ValueKey(_versaoCalendario),
          consultas: _consultas,
          dataInicial: _dataInicialAgenda,
          mostrarCabecalho: false,
          onNovoAgendamento: _novoAgendamento,
          onCancelar: _cancelarConsulta,
          onReagendar: _reagendarConsulta,
        ),
        const CentralCadastrosRecepcao(),
        const ChatRecepcao(),
      ],
    );
  }
}
