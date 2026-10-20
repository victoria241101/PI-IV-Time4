// calendário para consultar, cancelar e reagendar consultas
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class CalendarioAgendamentos extends StatefulWidget {
  const CalendarioAgendamentos({
    super.key,
    required this.consultas,
    required this.dataInicial,
    this.onCancelar,
    this.onReagendar,
    this.onConsultaTap,
    this.mostrarFotoPet = false,
    this.mostrarMotivo = true,
  });

  final List<ConsultaRecepcao> consultas;
  final DateTime dataInicial;
  final ValueChanged<ConsultaRecepcao>? onCancelar;
  final void Function(
    ConsultaRecepcao consulta,
    String horario,
    String profissional,
  )?
  onReagendar;
  final ValueChanged<ConsultaRecepcao>? onConsultaTap;
  final bool mostrarFotoPet;
  final bool mostrarMotivo;

  @override
  State<CalendarioAgendamentos> createState() => _CalendarioAgendamentosState();
}

class _CalendarioAgendamentosState extends State<CalendarioAgendamentos> {
  late DateTime _mesVisivel;
  late DateTime _diaSelecionado;

  static const _meses = [
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

  static const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _diaSelecionado = DateUtils.dateOnly(widget.dataInicial);
    _mesVisivel = DateTime(_diaSelecionado.year, _diaSelecionado.month);
  }

  List<ConsultaRecepcao> get _consultasDoDia {
    final consultas =
        widget.consultas
            .where(
              (consulta) => DateUtils.isSameDay(consulta.data, _diaSelecionado),
            )
            .toList()
          ..sort((a, b) => a.horario.compareTo(b.horario));
    return consultas;
  }

  @override
  Widget build(BuildContext context) {
    final consultasDoDia = _consultasDoDia;
    final grupos = _agruparPorHorario(consultasDoDia);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agendamentos', style: TipografiaApp.heading2),
          const SizedBox(height: EspacamentosApp.xs),
          Text(
            'Escolha um dia para ver os horários e atendimentos',
            style: TipografiaApp.bodySmall,
          ),
          const SizedBox(height: EspacamentosApp.md),
          _calendario(),
          const SizedBox(height: EspacamentosApp.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  _tituloDiaSelecionado(),
                  style: TipografiaApp.heading3.copyWith(fontSize: 16),
                ),
              ),
              Text(
                _textoQuantidade(consultasDoDia.length),
                style: TipografiaApp.caption,
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.sm),
          if (grupos.isEmpty)
            _semAgendamentos()
          else
            for (final grupo in grupos.entries)
              _grupoHorario(grupo.key, grupo.value),
        ],
      ),
    );
  }

  Widget _calendario() {
    final primeiroDiaDoMes = DateTime(_mesVisivel.year, _mesVisivel.month);
    final inicioGrade = primeiroDiaDoMes.subtract(
      Duration(days: primeiroDiaDoMes.weekday - 1),
    );

    return CartaoBase(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.md,
        EspacamentosApp.sm,
        EspacamentosApp.md,
        EspacamentosApp.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_meses[_mesVisivel.month - 1]} ${_mesVisivel.year}',
                  style: TipografiaApp.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mês anterior',
                visualDensity: VisualDensity.compact,
                onPressed: () => _mudarMes(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                visualDensity: VisualDensity.compact,
                onPressed: () => _mudarMes(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.xs),
          Row(
            children: [
              for (final dia in _diasSemana)
                Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: TipografiaApp.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 42,
            ),
            itemBuilder: (context, index) {
              final dia = DateUtils.dateOnly(
                inicioGrade.add(Duration(days: index)),
              );
              final pertenceAoMes = dia.month == _mesVisivel.month;
              final selecionado = DateUtils.isSameDay(dia, _diaSelecionado);
              final hoje = DateUtils.isSameDay(dia, DateTime.now());
              final quantidade = widget.consultas
                  .where((consulta) => DateUtils.isSameDay(consulta.data, dia))
                  .length;

              return InkWell(
                onTap: () {
                  setState(() {
                    _diaSelecionado = dia;
                    if (!pertenceAoMes) {
                      _mesVisivel = DateTime(dia.year, dia.month);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(EspacamentosApp.radiusFull),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selecionado
                          ? CoresApp.darkBlue
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: hoje && !selecionado
                          ? Border.all(color: CoresApp.primary)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          dia.day.toString(),
                          style: TipografiaApp.caption.copyWith(
                            color: !pertenceAoMes
                                ? CoresApp.textSecondary.withAlpha(100)
                                : selecionado
                                ? Colors.white
                                : CoresApp.textPrimary,
                            fontWeight: selecionado
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (quantidade > 0)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: selecionado
                                    ? Colors.white
                                    : CoresApp.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesVisivel = DateTime(_mesVisivel.year, _mesVisivel.month + delta);
      _diaSelecionado = DateTime(_mesVisivel.year, _mesVisivel.month, 1);
    });
  }

  String _tituloDiaSelecionado() {
    const dias = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    return '${dias[_diaSelecionado.weekday - 1]}, ${_diaSelecionado.day} de ${_meses[_diaSelecionado.month - 1]}';
  }

  String _textoQuantidade(int total) {
    final plural = total == 1 ? '' : 's';
    return '$total agendamento$plural';
  }

  Map<String, List<ConsultaRecepcao>> _agruparPorHorario(
    List<ConsultaRecepcao> consultas,
  ) {
    final grupos = <String, List<ConsultaRecepcao>>{};
    for (final consulta in consultas) {
      grupos.putIfAbsent(consulta.horario, () => []).add(consulta);
    }
    return grupos;
  }

  Widget _grupoHorario(String horario, List<ConsultaRecepcao> consultas) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: EspacamentosApp.md),
              child: Text(
                horario,
                style: TipografiaApp.captionBold.copyWith(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < consultas.length; i++) ...[
                  _cartaoAgendamento(consultas[i]),
                  if (i != consultas.length - 1)
                    const SizedBox(height: EspacamentosApp.xs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoAgendamento(ConsultaRecepcao consulta) {
    return InkWell(
      onTap: () => widget.onConsultaTap == null
          ? _abrirDetalhes(consulta)
          : widget.onConsultaTap!(consulta),
      borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
      child: CartaoBase(
        padding: const EdgeInsets.all(EspacamentosApp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.mostrarFotoPet) ...[
                  AvatarPet(
                    fotoUrl: consulta.fotoPet,
                    nome: consulta.pet,
                    tamanho: 40,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${consulta.pet} · ${consulta.especie}',
                        style: TipografiaApp.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(consulta.profissional, style: TipografiaApp.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.xs),
            Row(
              children: [
                IndicadorStatus(
                  label: consulta.status.rotulo,
                  color: consulta.status.cor,
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CoresApp.iconDefault,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _semAgendamentos() {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, color: CoresApp.primary),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Text(
              'Nenhum agendamento para este dia',
              style: TipografiaApp.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirDetalhes(ConsultaRecepcao consulta) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.xl,
            EspacamentosApp.md,
            EspacamentosApp.xl,
            EspacamentosApp.xl,
          ),
          decoration: const BoxDecoration(
            color: CoresApp.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EspacamentosApp.radiusXl),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoresApp.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: EspacamentosApp.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${consulta.pet} · ${consulta.especie}',
                        style: TipografiaApp.heading3,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: CoresApp.primary,
                      size: 18,
                    ),
                    const SizedBox(width: EspacamentosApp.xs),
                    Text(
                      '${_formatarData(consulta.data)} · ${consulta.horario}',
                      style: TipografiaApp.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: EspacamentosApp.md),
                CartaoBase(
                  padding: const EdgeInsets.all(EspacamentosApp.md),
                  child: Column(
                    children: [
                      _detalhe(
                        'Status',
                        child: IndicadorStatus(
                          label: consulta.status.rotulo,
                          color: consulta.status.cor,
                        ),
                      ),
                      _detalhe('Tutor', text: consulta.tutor),
                      _detalhe('Veterinário', text: consulta.profissional),
                      _detalhe(
                        'Sala',
                        text: consulta.sala,
                        last: !widget.mostrarMotivo,
                      ),
                      if (widget.mostrarMotivo)
                        _detalhe(
                          'Atendimento',
                          text: consulta.motivo,
                          last: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: EspacamentosApp.md),
                if (consulta.status != StatusConsultaRecepcao.emConsulta &&
                    consulta.status != StatusConsultaRecepcao.finalizado &&
                    widget.onReagendar != null)
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final escolha = await _abrirReagendamento(consulta);
                      if (escolha == null || !mounted) return;
                      widget.onReagendar?.call(
                        consulta,
                        escolha.horario,
                        escolha.profissional,
                      );
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Reagendar consulta'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                if (consulta.status != StatusConsultaRecepcao.emConsulta &&
                    consulta.status != StatusConsultaRecepcao.finalizado &&
                    widget.onCancelar != null) ...[
                  const SizedBox(height: EspacamentosApp.xs),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirmar = await _confirmarCancelamento(consulta);
                      if (confirmar && mounted) {
                        widget.onCancelar?.call(consulta);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Cancelar consulta'),
                    style: TextButton.styleFrom(
                      foregroundColor: CoresApp.danger,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<_OpcaoReagendamento?> _abrirReagendamento(ConsultaRecepcao consulta) {
    return showModalBottomSheet<_OpcaoReagendamento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioReagendamento(
        consulta: consulta,
        consultas: widget.consultas,
      ),
    );
  }

  Future<bool> _confirmarCancelamento(ConsultaRecepcao consulta) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancelar consulta?'),
            content: Text(
              'A consulta de ${consulta.pet} em ${_formatarData(consulta.data)} às ${consulta.horario} será removida',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Manter'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: CoresApp.danger),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _detalhe(
    String titulo, {
    String? text,
    Widget? child,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : EspacamentosApp.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(titulo, style: TipografiaApp.caption),
          ),
          Expanded(
            child:
                child ??
                Text(
                  text ?? '',
                  style: TipografiaApp.captionBold.copyWith(fontSize: 11),
                ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day} de ${_meses[data.month - 1]} de ${data.year}';
  }
}

class _OpcaoReagendamento {
  const _OpcaoReagendamento(this.horario, this.profissional);

  final String horario;
  final String profissional;
}

class _FormularioReagendamento extends StatefulWidget {
  const _FormularioReagendamento({
    required this.consulta,
    required this.consultas,
  });

  final ConsultaRecepcao consulta;
  final List<ConsultaRecepcao> consultas;

  @override
  State<_FormularioReagendamento> createState() =>
      _FormularioReagendamentoState();
}

class _FormularioReagendamentoState extends State<_FormularioReagendamento> {
  static const _profissionais = ['Dra. Camila', 'Dr. Silva', 'Dra. Beatriz'];
  static const _horarios = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
  ];

  late String _profissional;
  late String _horario;

  @override
  void initState() {
    super.initState();
    _profissional = widget.consulta.profissional;
    _horario = widget.consulta.horario;
  }

  bool _disponivel(String profissional, String horario) {
    final inicioNovo = _minutos(horario);
    return !widget.consultas.any((consulta) {
      if (consulta.id == widget.consulta.id ||
          consulta.profissional != profissional ||
          !DateUtils.isSameDay(consulta.data, widget.consulta.data)) {
        return false;
      }
      final inicioExistente = _minutos(consulta.horario);
      return inicioNovo < inicioExistente + consulta.duracaoMinutos &&
          inicioExistente < inicioNovo + widget.consulta.duracaoMinutos;
    });
  }

  int _minutos(String horario) {
    final partes = horario.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  List<String> get _horariosDisponiveis => _horarios
      .where((horario) => _disponivel(_profissional, horario))
      .toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: EspacamentosApp.pagePadding,
          right: EspacamentosApp.pagePadding,
          bottom: MediaQuery.viewInsetsOf(context).bottom + EspacamentosApp.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(EspacamentosApp.xl),
          decoration: const BoxDecoration(
            color: CoresApp.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EspacamentosApp.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reagendar consulta', style: TipografiaApp.heading2),
              const SizedBox(height: EspacamentosApp.xs),
              Text(
                'A consulta continua no dia ${widget.consulta.data.day} · escolha um horário livre para o veterinário',
                style: TipografiaApp.bodySmall,
              ),
              const SizedBox(height: EspacamentosApp.md),
              DropdownButtonFormField<String>(
                key: ValueKey(_profissional),
                initialValue: _profissional,
                decoration: const InputDecoration(
                  labelText: 'Veterinário',
                  filled: true,
                  fillColor: CoresApp.surface,
                  border: OutlineInputBorder(),
                ),
                items: _profissionais
                    .map(
                      (profissional) => DropdownMenuItem(
                        value: profissional,
                        child: Text(profissional),
                      ),
                    )
                    .toList(),
                onChanged: (profissional) {
                  if (profissional == null) return;
                  setState(() {
                    _profissional = profissional;
                    final disponiveis = _horariosDisponiveis;
                    if (!disponiveis.contains(_horario) &&
                        disponiveis.isNotEmpty) {
                      _horario = disponiveis.first;
                    }
                  });
                },
              ),
              const SizedBox(height: EspacamentosApp.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('$_profissional-$_horario'),
                initialValue: _horariosDisponiveis.contains(_horario)
                    ? _horario
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Novo horário',
                  filled: true,
                  fillColor: CoresApp.surface,
                  border: OutlineInputBorder(),
                ),
                items: _horariosDisponiveis
                    .map(
                      (horario) => DropdownMenuItem(
                        value: horario,
                        child: Text(horario),
                      ),
                    )
                    .toList(),
                onChanged: _horariosDisponiveis.isEmpty
                    ? null
                    : (horario) {
                        if (horario != null) {
                          setState(() => _horario = horario);
                        }
                      },
              ),
              const SizedBox(height: EspacamentosApp.md),
              BotaoPrincipal(
                label: 'Salvar alteração',
                icon: Icons.event_available_rounded,
                expanded: true,
                onPressed: _horariosDisponiveis.contains(_horario)
                    ? () => Navigator.pop(
                        context,
                        _OpcaoReagendamento(_horario, _profissional),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
