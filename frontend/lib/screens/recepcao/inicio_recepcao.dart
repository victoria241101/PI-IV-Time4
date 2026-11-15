import 'package:pet_care/screens/recepcao/agenda/novo_agendamento_api.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
// tela principal da recepção com agenda, cadastro, calendário e chat
import 'package:flutter/material.dart';
import 'package:pet_care/screens/recepcao/cadastro/central_cadastros_recepcao.dart';
import 'package:pet_care/widgets/clinica/layout_clinica.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/agenda_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/calendario_agendamentos.dart';
import 'package:pet_care/screens/recepcao/chat_recepcao.dart';
import 'package:pet_care/widgets/modal_notificacoes_tutor.dart';

/// Tela principal do fluxo de recepção / secretaria.
class InicioRecepcao extends StatefulWidget {
  const InicioRecepcao({super.key});

  @override
  State<InicioRecepcao> createState() => _InicioRecepcaoState();
}

class _InicioRecepcaoState extends State<InicioRecepcao> {
  int _abaAtual = 0;
  final Set<String> _salvando = {};
  late final DateTime _hoje;
  late final List<ConsultaRecepcao> _consultas;
  late DateTime _dataInicialAgenda;
  final int _versaoCalendario = 0;

  @override
  void initState() {
    super.initState();
    _hoje = DateUtils.dateOnly(DateTime.now());
    _dataInicialAgenda = _hoje;
    _consultas = AgendaClinica.instancia.consultas;
    AgendaClinica.instancia.addListener(_atualizarAgendaCompartilhada);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && SessaoUsuario.instancia.estaLogado) _carregarAgenda();
    });
  }

  Future<void> _carregarAgenda([DateTime? dia]) async {
    try {
      await AgendaClinica.instancia.carregarDia(dia ?? _hoje);
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    }
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

  Future<void> _confirmarChegada(ConsultaRecepcao consulta) async {
    if (!_salvando.add(consulta.id)) return;
    try {
      {
        await AgendaClinica.instancia.servico.confirmarChegada(consulta.id);
      }
      if (!mounted) return;
      AgendaClinica.instancia.atualizarStatus(
        consulta,
        StatusConsultaRecepcao.aguardandoTriagem,
      );
      _mensagem('Chegada confirmada · ${consulta.pet} está aguardando triagem');
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      _salvando.remove(consulta.id);
    }
  }

  Future<void> _cancelarConsulta(ConsultaRecepcao consulta) async {
    if (!_salvando.add(consulta.id)) return;
    try {
      {
        await AgendaClinica.instancia.servico.agendamentos.cancelarAgendamento(
          consultaId: consulta.id,
        );
      }
      if (!mounted) return;
      AgendaClinica.instancia.removerConsulta(consulta);
      _mensagem('Consulta de ${consulta.pet} cancelada');
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      _salvando.remove(consulta.id);
    }
  }

  Future<void> _reagendarConsulta(
    ConsultaRecepcao consulta,
    String horario,
    String profissional,
  ) async {
    if (!_salvando.add(consulta.id)) return;
    try {
      if (profissional != consulta.profissional) {
        throw StateError(
          'A remarcação permite alterar o horário, mantendo o veterinário.',
        );
      }
      final dia =
          '${consulta.data.year.toString().padLeft(4, '0')}-${consulta.data.month.toString().padLeft(2, '0')}-${consulta.data.day.toString().padLeft(2, '0')}';
      await AgendaClinica.instancia.servico.agendamentos.remarcarAgendamento(
        consultaId: consulta.id,
        dataHora: '${dia}T$horario:00',
        duracaoMinutos: consulta.duracaoMinutos,
      );
      if (!mounted) return;
      consulta.horario = horario;
      AgendaClinica.instancia.notificarAlteracao();
      _mensagem('Consulta de ${consulta.pet} atualizada');
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      _salvando.remove(consulta.id);
    }
  }

  Future<void> _novoAgendamento(DateTime dia) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NovoAgendamentoApi(dia: dia)),
    );
    if (!mounted || salvo != true) return;
    _mensagem('Agendamento confirmado pela API');
    await _carregarAgenda(dia);
  }

  @override
  Widget build(BuildContext context) {
    final consultasDeHoje = _consultas
        .where((consulta) => DateUtils.isSameDay(consulta.data, _hoje))
        .toList();

    return LayoutClinica(
      nomePadrao: 'Recepção',
      abaAtual: _abaAtual,
      onSelecionarAba: (index) {
        setState(() => _abaAtual = index);
        if (index == 0 && SessaoUsuario.instancia.estaLogado) _carregarAgenda();
      },
      onNotificacao: () => ModalNotificacoesTutor.show(context),
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
          onSelecionarDia: _carregarAgenda,
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
