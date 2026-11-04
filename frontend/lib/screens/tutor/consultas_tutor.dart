
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';
import 'package:pet_care/services/veterinarios_service.dart';
import 'package:pet_care/services/agendamentos_service.dart';
import 'package:pet_care/services/pets_service.dart';
import 'package:pet_care/controle/sessao_usuario.dart';

typedef ConfirmarNovoAgendamento = void Function(
    DadosAgendamento dados,
    );

typedef ConfirmarReagendamento = void Function(
    String consultaId,
    DadosAgendamento novosDados,
    );

const Color _turquesaConsultas = Color(0xFF27B8B0);
const Color _laranjaConsultas = Color(0xFFFFA45B);
const Color _azulConsultas = Color(0xFF172A46);
const Color _fundoSuaveConsultas = Color(0xFFEAF8F6);


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

  String? _veterinarioSelecionado;
  String? _especialidadeSelecionada;

  List<Map<String, dynamic>> _veterinarios = [];

  bool _carregandoVeterinarios = true;
  String? _erroVeterinarios;

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

    _carregarVeterinarios();
  }

  Future<void> _carregarVeterinarios() async {
    setState(() {
      _carregandoVeterinarios = true;
      _erroVeterinarios = null;
    });

    try {
      final service = VeterinariosService(
        baseUrl: 'http://localhost:3000',
      );

      final veterinarios = await service.listarVeterinarios();

      if (!mounted) return;

      setState(() {
        _veterinarios = veterinarios;
        _carregandoVeterinarios = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _carregandoVeterinarios = false;
        _erroVeterinarios =
            'Não foi possível carregar os veterinários.';
      });
    }
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

    // Disponibilidade simulada até a integração com o backend.
    // O calendário mantém o comportamento visual original.
    return data.day % 3 != 0;
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

    String? nomeVeterinario;
    for (final vet in _veterinarios) {
      if (vet['_id']?.toString() == _veterinarioSelecionado) {
        nomeVeterinario = vet['nome']?.toString();
        break;
      }
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesAgendamentoTutor(
          dataSelecionada: data,
          nomesPets: widget.nomesPets,
          veterinarioInicial: nomeVeterinario,
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

              // O POST /agendamentos já foi concluído na tela de confirmação.
              // O callback é opcional no teste isolado.
              callback?.call(dados);
            }

            // A navegação após salvar é responsabilidade da tela de
            // confirmação. Não faça pop aqui: o callback é chamado enquanto
            // a confirmação ainda está aberta.
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
        foregroundColor: _azulConsultas,
        elevation: 0,
        title: const Text(
          'Consultas',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: _azulConsultas,
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

              // CALENDÁRIO: visual mantido.
              _cartaoCalendario(),

              const SizedBox(height: EspacamentosApp.xl),
              _tituloSecao(
                'Profissional',
                'Escolha o veterinário e a especialidade.',
              ),
              const SizedBox(height: EspacamentosApp.md),

              // FILTRO 1: NOME DO VETERINÁRIO.
              _campoVeterinario(),

              const SizedBox(height: EspacamentosApp.md),

              // FILTRO 2: ESPECIALIDADE.
              _campoEspecialidade(),

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
                    backgroundColor: _turquesaConsultas,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    _turquesaConsultas.withAlpha(75),
                    disabledForegroundColor: Colors.white,
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
                    foregroundColor: _azulConsultas,
                    side: BorderSide(
                      color: _azulConsultas.withAlpha(45),
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

  Widget _campoVeterinario() {
    final veterinariosFiltrados = _veterinarios.where((vet) {
      if (_especialidadeSelecionada == null) return true;

      return vet['especialidade'] ==
          _especialidadeSelecionada;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_especialidadeSelecionada),
          initialValue: _veterinarioSelecionado,
          isExpanded: true,
          decoration: _decoracaoFiltro(
            rotulo: 'Nome do veterinário',
            icone: Icons.person_search_outlined,
          ),
          hint: Text(
            _carregandoVeterinarios
                ? 'Carregando veterinários...'
                : 'Todos os veterinários',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos os veterinários'),
            ),
            ...veterinariosFiltrados.map(
              (vet) => DropdownMenuItem<String>(
                value: vet['_id'].toString(),
                child: Text(
                  vet['nome'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _carregandoVeterinarios ||
                  _erroVeterinarios != null
              ? null
              : (valor) {
                  setState(() {
                    _veterinarioSelecionado = valor;
                  });
                },
        ),
        if (_erroVeterinarios != null) ...[
          const SizedBox(height: 8),
          Text(
            _erroVeterinarios!,
            style: const TextStyle(color: Colors.red),
          ),
          TextButton(
            onPressed: _carregarVeterinarios,
            child: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }

  Widget _campoEspecialidade() {
    final especialidades = _veterinarios
        .map((vet) => vet['especialidade'].toString())
        .toSet()
        .toList()
      ..sort();

    return DropdownButtonFormField<String>(
      initialValue: _especialidadeSelecionada,
      isExpanded: true,
      decoration: _decoracaoFiltro(
        rotulo: 'Especialidade',
        icone: Icons.medical_services_outlined,
      ),
      hint: const Text('Todas as especialidades'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Todas as especialidades'),
        ),
        ...especialidades.map(
          (especialidade) => DropdownMenuItem<String>(
            value: especialidade,
            child: Text(especialidade),
          ),
        ),
      ],
      onChanged: _carregandoVeterinarios ||
              _erroVeterinarios != null
          ? null
          : (valor) {
              setState(() {
                _especialidadeSelecionada = valor;
                _veterinarioSelecionado = null;
              });
            },
    );
  }

  InputDecoration _decoracaoFiltro({
    required String rotulo,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(
        color: CoresApp.textSecondary,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icone,
        color: _turquesaConsultas,
      ),
      filled: true,
      fillColor: CoresApp.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md,
        vertical: EspacamentosApp.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: _azulConsultas.withAlpha(20),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: _azulConsultas.withAlpha(20),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: CoresApp.primary,
          width: 1.5,
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
            _azulConsultas,
            Color(0xFF174C60),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _azulConsultas.withAlpha(25),
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
                    color: _laranjaConsultas.withAlpha(35),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'CUIDADO E BEM-ESTAR',
                    style: TextStyle(
                      color: _laranjaConsultas,
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
              color: _turquesaConsultas,
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
            color: _azulConsultas,
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

  // Calendário mantido com o layout e as cores originais.
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
          color: _azulConsultas.withAlpha(12),
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
                color: _azulConsultas,
              ),
              Expanded(
                child: Text(
                  '${_meses[_mesAtual.month - 1]} ${_mesAtual.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _azulConsultas,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                onPressed: () => _mudarMes(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: _azulConsultas,
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
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
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
                    ? _fundoSuaveConsultas
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: disponivel
                      ? () => _selecionarData(data)
                      : null,
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
                              ? _azulConsultas
                              : CoresApp.textSecondary
                              .withAlpha(100),
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
                              ? _laranjaConsultas
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
              _LegendaCalendario(
                cor: _laranjaConsultas,
                texto: 'Data selecionada',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumoDataSelecionada() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: _fundoSuaveConsultas,
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
                    color: _azulConsultas,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_veterinarioSelecionado != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _veterinarios
                        .firstWhere(
                          (vet) => vet['_id'] == _veterinarioSelecionado,
                          orElse: () => {'nome': 'Veterinário'},
                        )['nome']
                        .toString(),
                  ),
                ],
                if (_especialidadeSelecionada != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _especialidadeSelecionada!,
                    style: const TextStyle(
                      color: CoresApp.textSecondary,
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
        color: CoresApp.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _azulConsultas.withAlpha(12),
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
                    color: _azulConsultas,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Você poderá revisar os dados do pet, do atendimento, '
                      'do profissional e do horário antes de concluir. '
                      'Os horários disponíveis são consultados no servidor.',
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
  List<ResumoConsulta> _consultas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarConsultas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tipoLegivel(String valor) {
    const tipos = {
      'consulta_geral': 'Consulta geral',
      'vacinacao': 'Vacinação',
      'dermatologia': 'Dermatologia',
      'odontologia': 'Odontologia',
      'retorno': 'Retorno',
      'exames_laboratoriais': 'Exames laboratoriais',
    };
    return tipos[valor] ?? valor;
  }

  String _statusLegivel(String valor) {
    const status = {
      'agendada': 'Confirmada',
      'chegada_confirmada': 'Chegada confirmada',
      'em_triagem': 'Em triagem',
      'aguardando_veterinario': 'Aguardando veterinário',
      'em_consulta': 'Em consulta',
      'realizada': 'Realizada',
      'concluida': 'Concluída',
      'cancelada': 'Cancelada',
    };
    return status[valor.toLowerCase()] ?? valor;
  }

  Future<void> _carregarConsultas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = SessaoUsuario.instancia.token ??
          const String.fromEnvironment('TOKEN_TESTE');
      if (token.isEmpty) {
        throw StateError('Token não encontrado. Faça login novamente.');
      }

      final agendamentosService = AgendamentosService(
        baseUrl: 'http://localhost:3000',
        token: token,
      );
      final petsService = PetsService(baseUrl: 'http://localhost:3000');
      final veterinariosService = VeterinariosService(
        baseUrl: 'http://localhost:3000',
      );

      final resultados = await Future.wait<dynamic>([
        agendamentosService.listarAgendamentos(),
        petsService.listarPets(),
        veterinariosService.listarVeterinarios(),
      ]);

      final agendamentos = resultados[0] as List<dynamic>;
      final pets = resultados[1] as List;
      final veterinarios = resultados[2] as List;

      final nomesPets = <String, String>{};
      for (final item in pets) {
        if (item is! Map) continue;
        final id = (item['_id'] ?? item['id'])?.toString();
        final nome = item['nome']?.toString();
        if (id != null && nome != null) nomesPets[id] = nome;
      }

      final nomesVeterinarios = <String, String>{};
      for (final item in veterinarios) {
        if (item is! Map) continue;
        final id = (item['_id'] ?? item['id'])?.toString();
        final nome = item['nome']?.toString();
        if (id != null && nome != null) nomesVeterinarios[id] = nome;
      }

      final lista = <ResumoConsulta>[];
      for (final item in agendamentos) {
        if (item is! Map) continue;
        final id = (item['_id'] ?? item['id'] ?? '').toString();
        final petId = (item['petId'] ?? '').toString();
        final veterinarioId = (item['veterinarioId'] ?? '').toString();
        final dataHora = (item['dataHora'] ?? '').toString();
        final tipo = (item['tipo'] ?? 'consulta_geral').toString();
        final status = (item['status'] ?? 'agendada').toString();

        // O backend envia dataHora no formato AAAA-MM-DDTHH:mm:ss,
        // representando a hora local da clínica, sem fuso horário.
        String data = dataHora;
        String horario = '';
        if (dataHora.length >= 16 && dataHora[10] == 'T') {
          final ano = dataHora.substring(0, 4);
          final mes = dataHora.substring(5, 7);
          final dia = dataHora.substring(8, 10);
          data = '$dia/$mes/$ano';
          horario = dataHora.substring(11, 16);
        }

        lista.add(ResumoConsulta(
          id: id,
          type: _tipoLegivel(tipo),
          date: data,
          time: horario,
          vetName: nomesVeterinarios[veterinarioId] ??
              'Veterinário ($veterinarioId)',
          petName: nomesPets[petId] ?? 'Pet ($petId)',
          status: _statusLegivel(status),
        ));
      }

      if (!mounted) return;
      setState(() {
        _consultas = lista;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar as consultas: $erro';
      });
    }
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
    final proximas = _consultas
        .where((consulta) => !_ehHistorico(consulta))
        .toList();
    final historico = _consultas.where(_ehHistorico).toList();

    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: _azulConsultas,
        elevation: 0,
        title: const Text(
          'Minhas consultas',
          style: TextStyle(
            color: _azulConsultas,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar consultas',
            onPressed: _carregando ? null : _carregarConsultas,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: CoresApp.primary,
          unselectedLabelColor: CoresApp.textSecondary,
          indicatorColor: CoresApp.accentOrange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _carregarConsultas,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
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
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _fundoSuaveConsultas,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 38,
                  color: _turquesaConsultas,
                ),
              ),
              const SizedBox(height: EspacamentosApp.md),
              Text(
                mensagemVazia,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CoresApp.textSecondary,
                  fontSize: 13,
                  height: 1.5,
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

    if (status.contains('cancelada')) {
      return CoresApp.statusCancelled;
    }

    if (status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida')) {
      return CoresApp.statusConfirmed;
    }

    if (status.contains('pendente')) {
      return CoresApp.statusPending;
    }

    return CoresApp.primary;
  }

  @override
  Widget build(BuildContext context) {
    final corStatus = _corStatus();

    return Card(
      color: CoresApp.surfaceSoft,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _azulConsultas.withAlpha(12),
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
                    backgroundColor: _fundoSuaveConsultas,
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
                            color: _azulConsultas,
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
                  const SizedBox(width: 6),
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
                    color: CoresApp.accentOrange,
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
          color: CoresApp.primary,
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
