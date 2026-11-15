// consultas, agenda, clientes e chat do veterinario
import 'package:flutter/material.dart';
import 'package:pet_care/core/formatadores/data_app.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/agenda/calendario_agendamentos.dart';
import 'package:pet_care/screens/recepcao/chat_recepcao.dart';
import 'package:pet_care/screens/veterinario/clientes_veterinario.dart';
import 'package:pet_care/screens/veterinario/consulta_veterinario.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/widgets/clinica/layout_clinica.dart';
import 'package:pet_care/widgets/clinica/cartao_atendimento.dart';
import 'package:pet_care/widgets/modal_notificacoes_tutor.dart';

class InicioVeterinario extends StatefulWidget {
  const InicioVeterinario({
    super.key,
    this.profissional,
    this.mostrarTodasConsultas = false,
    this.descricaoClientes,
    this.paginaConsultaBuilder,
    this.filtroConsultas,
    this.terceiraAbaBuilder,
    this.terceiraAbaItem,
    this.rotuloAcaoConsulta,
    this.resumoHojeBuilder,
  });

  final String? profissional;
  final bool mostrarTodasConsultas;
  final String? descricaoClientes;
  final Widget Function(ConsultaRecepcao consulta)? paginaConsultaBuilder;
  final bool Function(ConsultaRecepcao consulta)? filtroConsultas;
  final Widget Function(List<ConsultaRecepcao> consultas)? terceiraAbaBuilder;
  final BottomNavigationBarItem? terceiraAbaItem;
  final String? Function(ConsultaRecepcao consulta)? rotuloAcaoConsulta;
  final Widget Function(List<ConsultaRecepcao> consultas)? resumoHojeBuilder;

  @override
  State<InicioVeterinario> createState() => _InicioVeterinarioState();
}

class _InicioVeterinarioState extends State<InicioVeterinario> {
  int _abaAtual = 0;
  late final DateTime _hoje;

  @override
  void initState() {
    super.initState();
    _hoje = DateUtils.dateOnly(DateTime.now());
    AgendaClinica.instancia.addListener(_atualizarAgenda);
  }

  @override
  void dispose() {
    AgendaClinica.instancia.removeListener(_atualizarAgenda);
    super.dispose();
  }

  void _atualizarAgenda() {
    if (mounted) setState(() {});
  }

  String get _profissionalAtual {
    if (widget.profissional != null) return widget.profissional!;
    final nome = _chaveProfissional(SessaoUsuario.instancia.nomeUsuario ?? '');
    if (nome.isNotEmpty) {
      for (final consulta in AgendaClinica.instancia.consultas) {
        final profissional = _chaveProfissional(consulta.profissional);
        if (profissional == nome || profissional.contains(nome)) {
          return consulta.profissional;
        }
      }
    }
    return 'Dra. Camila';
  }

  String _chaveProfissional(String nome) =>
      nome.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  List<ConsultaRecepcao> get _consultasDoPerfil {
    final consultas = AgendaClinica.instancia.consultas
        .where(
          (consulta) =>
              widget.mostrarTodasConsultas ||
              consulta.profissional == _profissionalAtual,
        )
        .toList();
    consultas.sort((a, b) {
      final porData = a.data.compareTo(b.data);
      return porData != 0 ? porData : a.horario.compareTo(b.horario);
    });
    return consultas;
  }

  List<ConsultaRecepcao> get _consultasVisiveis => _consultasDoPerfil
      .where((consulta) => widget.filtroConsultas?.call(consulta) ?? true)
      .toList();

  List<ConsultaRecepcao> get _consultasAtivasDeHoje => _consultasVisiveis
      .where(
        (consulta) =>
            DateUtils.isSameDay(consulta.data, _hoje) &&
            consulta.status != StatusConsultaRecepcao.finalizado,
      )
      .toList();

  void _abrirConsulta(ConsultaRecepcao consulta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            widget.paginaConsultaBuilder?.call(consulta) ??
            ConsultaVeterinario(consulta: consulta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultas = _consultasDoPerfil;
    final consultasVisiveis = _consultasVisiveis;
    final consultasAtivasHoje = _consultasAtivasDeHoje;

    return LayoutClinica(
      nomePadrao: _profissionalAtual,
      abaAtual: _abaAtual,
      onSelecionarAba: (index) => setState(() => _abaAtual = index),
      onNotificacao: () => ModalNotificacoesTutor.show(context),
      terceiraAba:
          widget.terceiraAbaItem ??
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Clientes',
          ),
      paginas: [
        _listaDeConsultas(consultasAtivasHoje),
        CalendarioAgendamentos(
          consultas: consultasVisiveis
              .where((c) => c.status != StatusConsultaRecepcao.finalizado)
              .toList(),
          dataInicial: _hoje,
          onConsultaTap: _abrirConsulta,
          mostrarFotoPet: true,
          mostrarMotivo: false,
        ),
        widget.terceiraAbaBuilder?.call(consultas) ??
            ClientesVeterinario(
              consultas: consultas,
              profissional: _profissionalAtual,
              descricao: widget.descricaoClientes,
            ),
        const ChatRecepcao(),
      ],
    );
  }

  Widget _listaDeConsultas(List<ConsultaRecepcao> consultas) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xl,
      ),
      children: [
        _resumoHoje(),
        const SizedBox(height: EspacamentosApp.md),
        const SizedBox(height: EspacamentosApp.xs),
        Text(formatarDataExtensa(_hoje), style: TipografiaApp.bodySmall),
        const SizedBox(height: EspacamentosApp.md),
        Row(
          children: [
            Expanded(
              child: Text('Atendimentos', style: TipografiaApp.heading3),
            ),
            Text(
              '${consultas.length} consulta${consultas.length == 1 ? '' : 's'}',
              style: TipografiaApp.caption,
            ),
          ],
        ),
        const SizedBox(height: EspacamentosApp.sm),
        if (consultas.isEmpty)
          _vazio()
        else
          for (final consulta in consultas) ...[
            _cartaoConsulta(consulta),
            const SizedBox(height: EspacamentosApp.sm),
          ],
      ],
    );
  }

  Widget _cartaoConsulta(ConsultaRecepcao consulta) {
    final personalizada = widget.rotuloAcaoConsulta;
    final acao = personalizada != null
        ? personalizada(consulta)
        : switch (consulta.status) {
            StatusConsultaRecepcao.aguardandoVeterinario => 'Iniciar consulta',
            StatusConsultaRecepcao.emConsulta => 'Continuar consulta',
            _ => null,
          };
    return CartaoAtendimento(
      consulta: consulta,
      onTap: () => _abrirConsulta(consulta),
      acao: acao ?? (personalizada != null ? 'Ver triagem' : 'Ver atendimento'),
      acaoSecundaria: acao == null,
      iconeAcao: acao == null
          ? Icons.description_outlined
          : Icons.arrow_forward_rounded,
      onAcao: () => _abrirConsulta(consulta),
    );
  }

  Widget _resumoHoje() {
    final consultas = _consultasDoPerfil
        .where((c) => DateUtils.isSameDay(c.data, _hoje))
        .toList();
    if (widget.resumoHojeBuilder != null) {
      return widget.resumoHojeBuilder!(consultas);
    }
    return ResumoClinica(
      titulo: 'Suas consultas',
      indicadores: [
        (
          consultas
              .where((c) => c.status != StatusConsultaRecepcao.finalizado)
              .length,
          'Em acompanhamento',
        ),
        (
          consultas
              .where((c) => c.status == StatusConsultaRecepcao.finalizado)
              .length,
          'Finalizadas',
        ),
      ],
    );
  }

  Widget _vazio() {
    return CartaoClinica(
      padding: const EdgeInsets.all(EspacamentosApp.xl),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 36,
            color: CoresApp.iconDefault,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          Text('Nenhuma consulta hoje', style: TipografiaApp.bodyMedium),
        ],
      ),
    );
  }
}
