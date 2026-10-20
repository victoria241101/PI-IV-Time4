// consultas, agenda, clientes e chat do veterinario
import 'package:flutter/material.dart';

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
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/barra_navegacao_app.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class InicioVeterinario extends StatefulWidget {
  const InicioVeterinario({super.key, this.profissional});

  final String? profissional;

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

  String get _saudacao {
    final hora = TimeOfDay.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
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

  String get _nomeUsuario =>
      SessaoUsuario.instancia.nomeUsuario ?? _profissionalAtual;

  List<ConsultaRecepcao> get _consultasDoVeterinario =>
      AgendaClinica.instancia.consultas
          .where((consulta) => consulta.profissional == _profissionalAtual)
          .toList()
        ..sort((a, b) {
          final porData = a.data.compareTo(b.data);
          return porData != 0 ? porData : a.horario.compareTo(b.horario);
        });

  List<ConsultaRecepcao> get _consultasAtivasDeHoje => _consultasDoVeterinario
      .where(
        (consulta) =>
            DateUtils.isSameDay(consulta.data, _hoje) &&
            consulta.status != StatusConsultaRecepcao.finalizado,
      )
      .toList();

  void _abrirConsulta(ConsultaRecepcao consulta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConsultaVeterinario(consulta: consulta),
      ),
    );
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final consultas = _consultasDoVeterinario;
    final consultasAtivasHoje = _consultasAtivasDeHoje;

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
                  _listaDeConsultas(consultasAtivasHoje),
                  CalendarioAgendamentos(
                    consultas: consultas
                        .where(
                          (consulta) =>
                              consulta.status !=
                              StatusConsultaRecepcao.finalizado,
                        )
                        .toList(),
                    dataInicial: _hoje,
                    onConsultaTap: _abrirConsulta,
                    mostrarFotoPet: true,
                    mostrarMotivo: false,
                  ),
                  ClientesVeterinario(
                    consultas: consultas,
                    profissional: _profissionalAtual,
                  ),
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
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Clientes',
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

  Widget _listaDeConsultas(List<ConsultaRecepcao> consultas) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xl,
      ),
      children: [
        Text('Consultas do dia', style: TipografiaApp.heading2),
        const SizedBox(height: EspacamentosApp.xs),
        Text(_dataFormatada(_hoje), style: TipografiaApp.bodySmall),
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
    return CartaoBase(
      onTap: () => _abrirConsulta(consulta),
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              consulta.horario,
              style: TipografiaApp.bodyMedium.copyWith(
                color: CoresApp.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: EspacamentosApp.sm),
          AvatarPet(fotoUrl: consulta.fotoPet, nome: consulta.pet, tamanho: 48),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${consulta.pet} · ${consulta.especie}',
                        style: TipografiaApp.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: CoresApp.iconDefault,
                    ),
                  ],
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  consulta.tutor,
                  style: TipografiaApp.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: EspacamentosApp.xs),
                IndicadorStatus(
                  label: consulta.status.rotulo,
                  color: consulta.status.cor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return CartaoBase(
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

  String _dataFormatada(DateTime data) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${data.day} de ${meses[data.month - 1]} de ${data.year}';
  }
}
