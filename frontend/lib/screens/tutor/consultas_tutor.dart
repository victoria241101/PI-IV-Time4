
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';

typedef ConfirmarNovoAgendamento = void Function(
    DadosAgendamento dados,
    );

typedef ConfirmarReagendamento = void Function(
    String consultaId,
    DadosAgendamento novosDados,
    );

class ConsultasTutor extends StatefulWidget {
  const ConsultasTutor({
    super.key,
    required this.consultas,
    required this.nomesPets,
    this.onConsultaTap,
    this.onAgendarTap,
    this.consultaIdParaReagendar,
    this.onAgendamentoConfirmado,
    this.onReagendamentoConfirmado,
  });

  final List<ResumoConsulta> consultas;
  final ValueChanged<ResumoConsulta>? onConsultaTap;
  final ValueChanged<DateTime>? onAgendarTap;
  final List<String> nomesPets;
  final String? consultaIdParaReagendar;
  final ConfirmarNovoAgendamento? onAgendamentoConfirmado;
  final ConfirmarReagendamento? onReagendamentoConfirmado;

  @override
  State<ConsultasTutor> createState() => _ConsultasTutorState();
}

class _ConsultasTutorState extends State<ConsultasTutor> {
  late DateTime _mesAtual;
  DateTime? _dataSelecionada;
  String _filtro = 'Todos os profissionais';

  final List<String> _filtros = const [
    'Todos os profissionais',
    'Dra. Ana Silva',
    'Dr. Bruno Costa',
    'Clínica geral',
    'Dermatologia',
    'Odontologia',
    'Vacinação',
  ];

  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();
    _mesAtual = DateTime(hoje.year, hoje.month);
  }

  static const List<String> _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  bool _ehDataPassada(DateTime data) {
    final hoje = DateTime.now();
    final dataSemHora = DateTime(data.year, data.month, data.day);
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    return dataSemHora.isBefore(hojeSemHora);
  }

  bool _temDisponibilidade(DateTime data) {
    if (_ehDataPassada(data) || data.weekday == DateTime.sunday) {
      return false;
    }

    // Disponibilidade fictícia para testes de interface.
    // Será substituída pela disponibilidade real futuramente.
    final indiceFiltro = _filtros.indexOf(_filtro);
    return (data.day + indiceFiltro) % 3 != 0;
  }

  void _mudarMes(int quantidade) {
    setState(() {
      _mesAtual = DateTime(
        _mesAtual.year,
        _mesAtual.month + quantidade,
      );
      _dataSelecionada = null;
    });
  }

  void _selecionarData(DateTime data) {
    if (!_temDisponibilidade(data)) return;

    setState(() {
      _dataSelecionada = data;
    });
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  void _continuarAgendamento() {
    final data = _dataSelecionada;
    if (data == null) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesAgendamentoTutor(
          dataSelecionada: data,
          nomesPets: widget.nomesPets,
          onContinuar: (dados) {
            final consultaId = widget.consultaIdParaReagendar;

            if (consultaId != null) {
              final callback = widget.onReagendamentoConfirmado;

              if (callback == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'O reagendamento ainda não está conectado.',
                    ),
                  ),
                );
                return;
              }

              callback(consultaId, dados);
            } else {
              final callback = widget.onAgendamentoConfirmado;

              if (callback == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'O agendamento ainda não está conectado.',
                    ),
                  ),
                );
                return;
              }

              callback(dados);
            }

            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        title: Text(
          'Consultas',
          style: TipografiaApp.heading3,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Encontre um horário para seu pet.',
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textSecondary,
                ),
              ),
              const SizedBox(height: EspacamentosApp.xl),

              _tituloSecao(
                'Calendário',
                'Selecione uma data disponível',
              ),
              const SizedBox(height: EspacamentosApp.md),

              _cartaoCalendario(),

              const SizedBox(height: EspacamentosApp.xl),

              _tituloSecao(
                'Profissional',
                'Filtre por veterinário ou especialidade',
              ),
              const SizedBox(height: EspacamentosApp.md),

              _campoFiltro(),

              const SizedBox(height: EspacamentosApp.xl),

              if (_dataSelecionada != null)
                _resumoDataSelecionada(),

              const SizedBox(height: EspacamentosApp.md),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _MinhasConsultasTutor(
                          consultas: widget.consultas,
                          onConsultaTap: widget.onConsultaTap,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Minhas consultas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CoresApp.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        EspacamentosApp.radiusLg,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _dataSelecionada == null
                      ? null
                      : _continuarAgendamento,
                  child: const Text('Continuar agendamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TipografiaApp.heading3),
        const SizedBox(height: EspacamentosApp.xs),
        Text(
          subtitulo,
          style: TipografiaApp.bodySmall.copyWith(
            color: CoresApp.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _cartaoCalendario() {
    final primeiroDia = DateTime(
      _mesAtual.year,
      _mesAtual.month,
      1,
    );

    final quantidadeDias = DateTime(
      _mesAtual.year,
      _mesAtual.month + 1,
      0,
    ).day;

    // Converte domingo = 7 para segunda-feira = 0.
    final deslocamentoInicial = primeiroDia.weekday - 1;
    final totalCelulas = ((deslocamentoInicial + quantidadeDias + 6) ~/ 7) * 7;

    return Card(
      color: CoresApp.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        side: BorderSide(
          color: CoresApp.textSecondary.withAlpha(35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.md),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  onPressed: () => _mudarMes(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_meses[_mesAtual.month - 1]} ${_mesAtual.year}',
                    textAlign: TextAlign.center,
                    style: TipografiaApp.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  onPressed: () => _mudarMes(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.sm),

            const Row(
              children: [
                _DiaSemana('SEG'),
                _DiaSemana('TER'),
                _DiaSemana('QUA'),
                _DiaSemana('QUI'),
                _DiaSemana('SEX'),
                _DiaSemana('SÁB'),
                _DiaSemana('DOM'),
              ],
            ),

            const SizedBox(height: EspacamentosApp.sm),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCelulas,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final dia = index - deslocamentoInicial + 1;

                if (dia < 1 || dia > quantidadeDias) {
                  return const SizedBox.shrink();
                }

                final data = DateTime(
                  _mesAtual.year,
                  _mesAtual.month,
                  dia,
                );

                final disponivel = _temDisponibilidade(data);
                final selecionado = _dataSelecionada != null &&
                    _dataSelecionada!.year == data.year &&
                    _dataSelecionada!.month == data.month &&
                    _dataSelecionada!.day == data.day;

                return Material(
                  color: selecionado
                      ? CoresApp.primary
                      : disponivel
                      ? CoresApp.primary.withAlpha(22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: disponivel ? () => _selecionarData(data) : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dia',
                          style: TipografiaApp.bodySmall.copyWith(
                            color: selecionado
                                ? Colors.white
                                : disponivel
                                ? CoresApp.primary
                                : CoresApp.textSecondary.withAlpha(110),
                            fontWeight: selecionado || disponivel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selecionado
                                ? Colors.white
                                : disponivel
                                ? CoresApp.primary
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: EspacamentosApp.md),
            const Divider(),
            const SizedBox(height: EspacamentosApp.sm),

            const Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendaCalendario(
                  cor: CoresApp.primary,
                  texto: 'Disponível',
                ),
                _LegendaCalendario(
                  cor: Colors.grey,
                  texto: 'Indisponível',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoFiltro() {
    return DropdownButtonFormField<String>(
      value: _filtro,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: CoresApp.surface,
        hintText: 'Veterinário ou especialidade',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
          borderSide: BorderSide(
            color: CoresApp.textSecondary.withAlpha(60),
          ),
        ),
      ),
      items: _filtros.map((filtro) {
        return DropdownMenuItem<String>(
          value: filtro,
          child: Text(
            filtro,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (novoFiltro) {
        if (novoFiltro == null) return;

        setState(() {
          _filtro = novoFiltro;

          if (_dataSelecionada != null &&
              !_temDisponibilidade(_dataSelecionada!)) {
            _dataSelecionada = null;
          }
        });
      },
    );
  }

  Widget _resumoDataSelecionada() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        border: Border.all(
          color: CoresApp.primary.withAlpha(55),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: CoresApp.primary,
            size: 26,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data selecionada',
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  _formatarData(_dataSelecionada!),
                  style: TipografiaApp.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: CoresApp.primary,
          ),
        ],
      ),
    );
  }
}

class _DiaSemana extends StatelessWidget {
  const _DiaSemana(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            texto,
            style: TipografiaApp.bodySmall.copyWith(
              color: CoresApp.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendaCalendario extends StatelessWidget {
  const _LegendaCalendario({
    required this.cor,
    required this.texto,
  });

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: cor.withAlpha(150),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TipografiaApp.bodySmall.copyWith(
            color: CoresApp.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Página separada para acompanhar consultas futuras e histórico.
class _MinhasConsultasTutor extends StatefulWidget {
  const _MinhasConsultasTutor({
    required this.consultas,
    this.onConsultaTap,
  });

  final List<ResumoConsulta> consultas;
  final ValueChanged<ResumoConsulta>? onConsultaTap;

  @override
  State<_MinhasConsultasTutor> createState() =>
      _MinhasConsultasTutorState();
}

class _MinhasConsultasTutorState extends State<_MinhasConsultasTutor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _ehHistorico(ResumoConsulta consulta) {
    final status = consulta.status.toLowerCase();

    return status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida') ||
        status.contains('cancelada');
  }

  @override
  Widget build(BuildContext context) {
    final proximas = widget.consultas
        .where((consulta) => !_ehHistorico(consulta))
        .toList();

    final historico = widget.consultas
        .where(_ehHistorico)
        .toList();

    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        title: Text(
          'Minhas consultas',
          style: TipografiaApp.heading3,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CoresApp.primary,
          unselectedLabelColor: CoresApp.textSecondary,
          indicatorColor: CoresApp.primary,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListaConsultas(
            consultas: proximas,
            mensagemVazia: 'Você não tem consultas próximas.',
            onConsultaTap: widget.onConsultaTap,
          ),
          _ListaConsultas(
            consultas: historico,
            mensagemVazia: 'Seu histórico de consultas aparecerá aqui.',
            onConsultaTap: widget.onConsultaTap,
          ),
        ],
      ),
    );
  }
}

class _ListaConsultas extends StatelessWidget {
  const _ListaConsultas({
    required this.consultas,
    required this.mensagemVazia,
    this.onConsultaTap,
  });

  final List<ResumoConsulta> consultas;
  final String mensagemVazia;
  final ValueChanged<ResumoConsulta>? onConsultaTap;

  @override
  Widget build(BuildContext context) {
    if (consultas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: CoresApp.textSecondary,
              ),
              const SizedBox(height: EspacamentosApp.md),
              Text(
                mensagemVazia,
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
      itemCount: consultas.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: EspacamentosApp.md),
      itemBuilder: (context, index) {
        final consulta = consultas[index];

        return _CartaoConsulta(
          consulta: consulta,
          onTap: onConsultaTap == null
              ? null
              : () => onConsultaTap!(consulta),
        );
      },
    );
  }
}

class _CartaoConsulta extends StatelessWidget {
  const _CartaoConsulta({
    required this.consulta,
    this.onTap,
  });

  final ResumoConsulta consulta;
  final VoidCallback? onTap;

  Color _corStatus() {
    final status = consulta.status.toLowerCase();

    if (status.contains('cancelada')) {
      return Colors.red.shade700;
    }

    if (status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida')) {
      return Colors.green.shade700;
    }

    if (status.contains('pendente')) {
      return Colors.orange.shade800;
    }

    return CoresApp.primary;
  }

  @override
  Widget build(BuildContext context) {
    final corStatus = _corStatus();

    return Card(
      color: CoresApp.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        side: BorderSide(
          color: CoresApp.textSecondary.withAlpha(35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: CoresApp.primary.withAlpha(25),
                    backgroundImage: consulta.petPhotoUrl != null
                        ? NetworkImage(consulta.petPhotoUrl!)
                        : null,
                    child: consulta.petPhotoUrl == null
                        ? Icon(
                      Icons.pets,
                      color: CoresApp.primary,
                    )
                        : null,
                  ),
                  const SizedBox(width: EspacamentosApp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consulta.type,
                          style: TipografiaApp.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.xs),
                        Text(
                          consulta.petName,
                          style: TipografiaApp.bodySmall.copyWith(
                            color: CoresApp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.sm,
                      vertical: EspacamentosApp.xs,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus.withAlpha(22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      consulta.status,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: corStatus,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.md),
              const Divider(height: 1),
              const SizedBox(height: EspacamentosApp.md),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: CoresApp.textSecondary,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      '${consulta.date} • ${consulta.time}',
                      style: TipografiaApp.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.sm),
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 17,
                    color: CoresApp.textSecondary,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      consulta.vetName,
                      style: TipografiaApp.bodySmall,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CoresApp.textSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
