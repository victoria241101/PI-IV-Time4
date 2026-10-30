import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/screens/tutor/checkout_agendamento_tutor.dart';

class DadosAgendamento {
  final DateTime data;
  final String nomePet;
  final String tipoAtendimento;
  final String veterinario;
  final String horario;
  final bool urgente;

  const DadosAgendamento({
    required this.data,
    required this.nomePet,
    required this.tipoAtendimento,
    required this.veterinario,
    required this.horario,
    required this.urgente,
  });
}

class DetalhesAgendamentoTutor extends StatefulWidget {
  final DateTime dataSelecionada;
  final List<String> nomesPets;
  final String? veterinarioInicial;
  final ValueChanged<DadosAgendamento>? onContinuar;

  const DetalhesAgendamentoTutor({
    super.key,
    required this.dataSelecionada,
    this.nomesPets = const ['Luna', 'Max', 'Mel'],
    this.veterinarioInicial,
    this.onContinuar,
  });

  @override
  State<DetalhesAgendamentoTutor> createState() =>
      _DetalhesAgendamentoTutorState();
}

class _DetalhesAgendamentoTutorState
    extends State<DetalhesAgendamentoTutor> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _data;
  String? _pet;
  String? _tipoAtendimento;
  String? _veterinario;
  String? _horario;
  bool _urgente = false;

  final List<String> _tiposAtendimento = const [
    'Consulta geral',
    'Dermatologia',
    'Odontologia',
    'Vacinação',
    'Retorno',
  ];

  final List<String> _veterinarios = const [
    'Qualquer veterinário',
    'Dra. Ana Silva',
    'Dr. Bruno Costa',
    'Dra. Mariana Oliveira',
  ];

  final List<String> _horarios = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
  ];

  @override
  void initState() {
    super.initState();

    _data = widget.dataSelecionada;
    _pet = widget.nomesPets.isNotEmpty ? widget.nomesPets.first : null;

    _veterinario = widget.veterinarioInicial != null &&
        _veterinarios.contains(widget.veterinarioInicial)
        ? widget.veterinarioInicial
        : 'Qualquer veterinário';

    _tipoAtendimento = _tiposAtendimento.first;
  }

  String get _dataFormatada =>
      '${_data.day.toString().padLeft(2, '0')}/'
          '${_data.month.toString().padLeft(2, '0')}/${_data.year}';

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicial = _data.isBefore(hoje) ? hoje : _data;

    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoje,
      lastDate: DateTime(agora.year + 1),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CoresApp.primary,
              onPrimary: CoresApp.surface,
              secondary: CoresApp.accentOrange,
              onSecondary: CoresApp.darkBlue,
              surface: CoresApp.surface,
              onSurface: CoresApp.darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _data = data;
        _horario = null;
      });
    }
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    if (_horario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Selecione um horário para continuar.',
          ),
          backgroundColor: CoresApp.darkBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    final dados = DadosAgendamento(
      data: _data,
      nomePet: _pet!,
      tipoAtendimento: _tipoAtendimento!,
      veterinario: _veterinario!,
      horario: _horario!,
      urgente: _urgente,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutAgendamentoTutor(
          dados: dados,
          onConfirmar: (dadosConfirmados) {
            widget.onContinuar?.call(dadosConfirmados);
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
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.darkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Agendar consulta',
          style: TextStyle(
            color: CoresApp.darkBlue,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _progresso(),
              const SizedBox(height: 28),
              const Text(
                'Vamos cuidar do seu pet!',
                style: TextStyle(
                  color: CoresApp.darkBlue,
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Preencha os detalhes do atendimento e escolha o horário ideal.',
                style: TextStyle(
                  color: CoresApp.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TituloSecao(
                      icone: Icons.calendar_month_rounded,
                      titulo: 'Informações da consulta',
                      subtitulo: 'Defina quem será atendido e por quem.',
                    ),
                    const SizedBox(height: 23),
                    const _RotuloCampo('Data da consulta'),
                    const SizedBox(height: 9),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selecionarData,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: CoresApp.background,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: CoresApp.divider),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: CoresApp.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: CoresApp.primary,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 13),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      _dataFormatada,
                                      style: const TextStyle(
                                        color: CoresApp.darkBlue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_calendar_rounded,
                                color: CoresApp.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _RotuloCampo('Qual pet será atendido?'),
                    const SizedBox(height: 9),
                    _dropdown<String>(
                      value: _pet,
                      items: widget.nomesPets,
                      hint: 'Selecione seu pet',
                      icone: Icons.pets_rounded,
                      onChanged: (value) => setState(() => _pet = value),
                    ),
                    const SizedBox(height: 22),
                    const _RotuloCampo('Tipo de atendimento'),
                    const SizedBox(height: 9),
                    _dropdown<String>(
                      value: _tipoAtendimento,
                      items: _tiposAtendimento,
                      hint: 'Selecione o atendimento',
                      icone: Icons.medical_services_rounded,
                      onChanged: (value) {
                        setState(() => _tipoAtendimento = value);
                      },
                    ),
                    const SizedBox(height: 22),
                    const _RotuloCampo('Profissional'),
                    const SizedBox(height: 9),
                    _dropdown<String>(
                      value: _veterinario,
                      items: _veterinarios,
                      hint: 'Selecione o profissional',
                      icone: Icons.person_rounded,
                      onChanged: (value) {
                        setState(() => _veterinario = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: CoresApp.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'O profissional selecionado será mantido nas próximas etapas.',
                            style: TextStyle(
                              color: CoresApp.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TituloSecao(
                      icone: Icons.schedule_rounded,
                      titulo: 'Escolha um horário',
                      subtitulo: 'Selecione uma das opções disponíveis.',
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _horarios.map((horario) {
                        final selecionado = _horario == horario;

                        return _OpcaoHorario(
                          horario: horario,
                          selecionado: selecionado,
                          onTap: () {
                            setState(() => _horario = horario);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CoresApp.surfaceSoft,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: CoresApp.accentOrange.withAlpha(75),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: CoresApp.accentOrangeDark,
                            size: 18,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Os horários são ilustrativos. A disponibilidade ainda não está conectada ao backend.',
                              style: TextStyle(
                                color: CoresApp.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _cartao(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: CoresApp.primary,
                  activeThumbColor: CoresApp.surface,
                  inactiveTrackColor: CoresApp.divider,
                  title: const Text(
                    'Atendimento urgente',
                    style: TextStyle(
                      color: CoresApp.darkBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      'Indique se seu pet precisa de atenção prioritária.',
                      style: TextStyle(
                        color: CoresApp.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  secondary: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _urgente
                          ? CoresApp.surfaceSoft
                          : CoresApp.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: _urgente
                          ? CoresApp.accentOrange
                          : CoresApp.textSecondary,
                      size: 25,
                    ),
                  ),
                  value: _urgente,
                  onChanged: (value) {
                    setState(() => _urgente = value);
                  },
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.primary,
                    foregroundColor: CoresApp.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar para revisão',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 21),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: CoresApp.textSecondary,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Confira os dados antes de confirmar.',
                    style: TextStyle(
                      color: CoresApp.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progresso() {
    const etapas = ['Data', 'Detalhes', 'Revisão'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoresApp.divider),
      ),
      child: Row(
        children: List.generate(etapas.length, (index) {
          final atual = index == 1;
          final concluida = index < 1;

          final cor = atual
              ? CoresApp.accentOrange
              : concluida
              ? CoresApp.primary
              : CoresApp.divider;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == etapas.length - 1 ? 0 : 10,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: atual ? 7 : 5,
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: atual
                          ? [
                        BoxShadow(
                          color: CoresApp.accentOrange.withAlpha(65),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (concluida) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: CoresApp.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (atual) ...[
                        const Icon(
                          Icons.circle,
                          color: CoresApp.accentOrange,
                          size: 9,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          etapas[index],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: atual
                                ? CoresApp.accentOrangeDark
                                : concluida
                                ? CoresApp.darkBlue
                                : CoresApp.textSecondary,
                            fontSize: 12,
                            fontWeight: atual || concluida
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _cartao({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: CoresApp.divider),
        boxShadow: [
          BoxShadow(
            color: CoresApp.darkBlue.withAlpha(9),
            blurRadius: 17,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required IconData icone,
    required ValueChanged<T?> onChanged,
  }) {
    final valorValido = items.contains(value) ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: valorValido,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: CoresApp.textSecondary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: CoresApp.background,
        prefixIcon: Icon(
          icone,
          color: CoresApp.primary,
          size: 21,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: CoresApp.textSecondary,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: CoresApp.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: CoresApp.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: CoresApp.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CoresApp.darkBlue,
              fontSize: 14,
            ),
          ),
        ),
      )
          .toList(),
      validator: (value) =>
      value == null ? 'Selecione uma opção' : null,
      onChanged: onChanged,
    );
  }
}

class _RotuloCampo extends StatelessWidget {
  final String texto;

  const _RotuloCampo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: CoresApp.darkBlue,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: CoresApp.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icone,
            color: CoresApp.primary,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: CoresApp.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitulo,
                style: const TextStyle(
                  color: CoresApp.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpcaoHorario extends StatelessWidget {
  const _OpcaoHorario({
    required this.horario,
    required this.selecionado,
    required this.onTap,
  });

  final String horario;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selecionado
                ? CoresApp.primary
                : CoresApp.background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selecionado
                  ? CoresApp.primary
                  : CoresApp.divider,
              width: selecionado ? 1.5 : 1,
            ),
            boxShadow: selecionado
                ? [
              BoxShadow(
                color: CoresApp.primary.withAlpha(35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            horario,
            style: TextStyle(
              color: selecionado
                  ? CoresApp.surface
                  : CoresApp.darkBlue,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}