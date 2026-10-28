
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';

typedef ConfirmarNovoAgendamento = void Function(
    DadosAgendamento dados,
    );

typedef ConfirmarReagendamento = void Function(
    String consultaId,
    DadosAgendamento novosDados,
    );

const Color _turquesaConsultas = Color(0xFF27B8B0);

const List<String> profissionaisDisponiveis = [
  'Dra. Ana Silva',
  'Dr. Bruno Costa',
  'Dra. Mariana Oliveira',
];

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
  final List<String> nomesPets;
  final ValueChanged<ResumoConsulta>? onConsultaTap;
  final ValueChanged<DateTime>? onAgendarTap;
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

  static const List<String> _filtros = [
    'Todos os profissionais',
    ...profissionaisDisponiveis,
    'Clínica geral',
    'Dermatologia',
    'Odontologia',
    'Vacinação',
  ];

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

  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();
    _mesAtual = DateTime(hoje.year, hoje.month);
  }

  bool _ehDataPassada(DateTime data) {
    final hoje = DateTime.now();

    return DateTime(data.year, data.month, data.day).isBefore(
      DateTime(hoje.year, hoje.month, hoje.day),
    );
  }

  bool _temDisponibilidade(DateTime data) {
    if (_ehDataPassada(data) || data.weekday == DateTime.sunday) {
      return false;
    }

    // Disponibilidade simulada para testes da interface.
    // Substituir pela disponibilidade real quando integrada ao backend.
    final indice = _filtros.indexOf(_filtro);
    return (data.day + indice) % 3 != 0;
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

    setState(() => _dataSelecionada = data);
    widget.onAgendarTap?.call(data);
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  void _continuarAgendamento() {
    final data = _dataSelecionada;
    if (data == null) return;

    final profissionalInicial =
    profissionaisDisponiveis.contains(_filtro) ? _filtro : null;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesAgendamentoTutor(
          dataSelecionada: data,
          nomesPets: widget.nomesPets,
          veterinarioInicial: profissionalInicial,
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
        foregroundColor: CoresApp.darkBlue,
        elevation: 0,
        title: const Text(
          'Consultas',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.sm,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalhoDestaque(),
              const SizedBox(height: EspacamentosApp.xl),
              _tituloSecao(
                'Escolha uma data',
                'Encontre o melhor horário para seu pet.',
              ),
              const SizedBox(height: EspacamentosApp.md),
              _cartaoCalendario(),
              const SizedBox(height: EspacamentosApp.xl),
              _tituloSecao(
                'Profissional',
                'Filtre por veterinário ou especialidade.',
              ),
              const SizedBox(height: EspacamentosApp.md),
              _campoFiltro(),
              const SizedBox(height: EspacamentosApp.lg),
              if (_dataSelecionada != null) ...[
                _resumoDataSelecionada(),
                const SizedBox(height: EspacamentosApp.md),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _dataSelecionada == null
                      ? null
                      : _continuarAgendamento,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continuar agendamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    CoresApp.darkBlue.withAlpha(70),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EspacamentosApp.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push<void>(
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoresApp.darkBlue,
                    side: BorderSide(
                      color: CoresApp.darkBlue.withAlpha(50),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EspacamentosApp.lg),
              _avisoInformativo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoDestaque() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CoresApp.darkBlue,
            Color(0xFF174C60),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoresApp.darkBlue.withAlpha(25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _turquesaConsultas.withAlpha(35),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'CUIDADO E BEM-ESTAR',
                    style: TextStyle(
                      color: Color(0xFF8CE5DD),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: EspacamentosApp.md),
                const Text(
                  'A saúde do seu pet em boas mãos.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.sm),
                const Text(
                  'Agende uma consulta de forma simples e organizada.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: EspacamentosApp.sm),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _turquesaConsultas.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFF8CE5DD),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: CoresApp.darkBlue,
          ),
        ),
        const SizedBox(height: EspacamentosApp.xs),
        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
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

    final deslocamentoInicial = primeiroDia.weekday - 1;
    final totalCelulas =
        ((deslocamentoInicial + quantidadeDias + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: CoresApp.darkBlue.withAlpha(12),
        ),
      ),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
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
                    ? _turquesaConsultas
                    : disponivel
                    ? _turquesaConsultas.withAlpha(22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: disponivel ? () => _selecionarData(data) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dia',
                        style: TextStyle(
                          fontSize: 13,
                          color: selecionado
                              ? Colors.white
                              : disponivel
                              ? CoresApp.darkBlue
                              : CoresApp.textSecondary.withAlpha(100),
                          fontWeight: selecionado || disponivel
                              ? FontWeight.w700
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
                              ? _turquesaConsultas
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
                cor: _turquesaConsultas,
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
    );
  }

  Widget _campoFiltro() {
    return DropdownButtonFormField<String>(
      initialValue: _filtro,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.medical_services_outlined,
          color: _turquesaConsultas,
        ),
        filled: true,
        fillColor: Colors.white,
        hintText: 'Veterinário ou especialidade',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.md,
          vertical: EspacamentosApp.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: CoresApp.darkBlue.withAlpha(20),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: CoresApp.darkBlue.withAlpha(20),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: _turquesaConsultas,
            width: 1.5,
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
        color: _turquesaConsultas.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _turquesaConsultas.withAlpha(65),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: _turquesaConsultas,
            size: 28,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data selecionada',
                  style: TextStyle(
                    color: CoresApp.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  _formatarData(_dataSelecionada!),
                  style: const TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (profissionaisDisponiveis.contains(_filtro)) ...[
                  const SizedBox(height: 4),
                  Text(
                    _filtro,
                    style: const TextStyle(
                      color: CoresApp.darkBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: _turquesaConsultas,
          ),
        ],
      ),
    );
  }

  Widget _avisoInformativo() {
    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CoresApp.darkBlue.withAlpha(12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _turquesaConsultas,
            size: 23,
          ),
          SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antes de confirmar',
                  style: TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Você poderá revisar os dados do pet, do atendimento, '
                      'do profissional e do horário antes de concluir.',
                  style: TextStyle(
                    color: CoresApp.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
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
            style: const TextStyle(
              color: CoresApp.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: CoresApp.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

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
        foregroundColor: CoresApp.darkBlue,
        elevation: 0,
        title: const Text(
          'Minhas consultas',
          style: TextStyle(
            color: CoresApp.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _turquesaConsultas,
          unselectedLabelColor: CoresApp.textSecondary,
          indicatorColor: _turquesaConsultas,
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
              const Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: _turquesaConsultas,
              ),
              const SizedBox(height: EspacamentosApp.md),
              Text(
                mensagemVazia,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CoresApp.textSecondary,
                  fontSize: 13,
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
      separatorBuilder: (_, _) =>
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

    if (status.contains('cancelada')) return Colors.red.shade700;

    if (status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida')) {
      return Colors.green.shade700;
    }

    if (status.contains('pendente')) return Colors.orange.shade800;

    return _turquesaConsultas;
  }

  @override
  Widget build(BuildContext context) {
    final corStatus = _corStatus();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: CoresApp.darkBlue.withAlpha(12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                    backgroundColor: _turquesaConsultas.withAlpha(25),
                    backgroundImage: consulta.petPhotoUrl != null
                        ? NetworkImage(consulta.petPhotoUrl!)
                        : null,
                    child: consulta.petPhotoUrl == null
                        ? const Icon(
                      Icons.pets_rounded,
                      color: _turquesaConsultas,
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
                          style: const TextStyle(
                            color: CoresApp.darkBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.xs),
                        Text(
                          consulta.petName,
                          style: const TextStyle(
                            color: CoresApp.textSecondary,
                            fontSize: 12,
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
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.md),
              const Divider(height: 1),
              const SizedBox(height: EspacamentosApp.md),
              _LinhaInformacao(
                icone: Icons.calendar_today_outlined,
                texto: '${consulta.date} • ${consulta.time}',
              ),
              const SizedBox(height: EspacamentosApp.sm),
              _LinhaInformacao(
                icone: Icons.medical_services_outlined,
                texto: consulta.vetName,
              ),
              if (onTap != null) ...[
                const SizedBox(height: EspacamentosApp.sm),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _turquesaConsultas,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaInformacao extends StatelessWidget {
  const _LinhaInformacao({
    required this.icone,
    required this.texto,
  });

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          size: 17,
          color: _turquesaConsultas,
        ),
        const SizedBox(width: EspacamentosApp.sm),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: CoresApp.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
