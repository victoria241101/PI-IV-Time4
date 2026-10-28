
import 'package:flutter/material.dart';

import 'package:pet_care/screens/tutor/checkout_agendamento_tutor.dart';

const Color _turquesa = Color(0xFF27B8B0);
const Color _azulEscuro = Color(0xFF172A46);
const Color _fundo = Color(0xFFF5F7FA);
const Color _textoSecundario = Color(0xFF718096);

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
    final inicial = _data.isBefore(DateTime(agora.year, agora.month, agora.day))
        ? DateTime(agora.year, agora.month, agora.day)
        : _data;

    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(agora.year + 1),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _turquesa,
            onPrimary: Colors.white,
            onSurface: _azulEscuro,
          ),
        ),
        child: child!,
      ),
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
        const SnackBar(content: Text('Selecione um horário para continuar.')),
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
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        foregroundColor: _azulEscuro,
        elevation: 0,
        title: const Text(
          'Agendar consulta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _progresso(),
              const SizedBox(height: 24),
              const Text(
                'Detalhes do atendimento',
                style: TextStyle(
                  color: _azulEscuro,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confira as informações e escolha o melhor horário para seu pet.',
                style: TextStyle(color: _textoSecundario, height: 1.5),
              ),
              const SizedBox(height: 22),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RotuloCampo('Data da consulta'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selecionarData,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _fundo,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE1E7EE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: _turquesa),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dataFormatada,
                                style: const TextStyle(
                                  color: _azulEscuro,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_outlined,
                                color: _textoSecundario),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _RotuloCampo('Qual pet será atendido?'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _pet,
                      items: widget.nomesPets,
                      hint: 'Selecione seu pet',
                      onChanged: (value) => setState(() => _pet = value),
                    ),
                    const SizedBox(height: 20),
                    const _RotuloCampo('Tipo de atendimento'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _tipoAtendimento,
                      items: _tiposAtendimento,
                      hint: 'Selecione o atendimento',
                      onChanged: (value) =>
                          setState(() => _tipoAtendimento = value),
                    ),
                    const SizedBox(height: 20),
                    const _RotuloCampo('Profissional'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _veterinario,
                      items: _veterinarios,
                      hint: 'Selecione o profissional',
                      onChanged: (value) =>
                          setState(() => _veterinario = value),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O profissional selecionado será mantido nas próximas etapas.',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha um horário',
                      style: TextStyle(
                        color: _azulEscuro,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Horários ilustrativos — a disponibilidade ainda não está conectada ao backend.',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _horarios.map((horario) {
                        final selecionado = _horario == horario;
                        return InkWell(
                          onTap: () => setState(() => _horario = horario),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selecionado
                                  ? _turquesa
                                  : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selecionado
                                    ? _turquesa
                                    : const Color(0xFFE1E7EE),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              horario,
                              style: TextStyle(
                                color: selecionado
                                    ? Colors.white
                                    : _azulEscuro,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: _fundo,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        activeColor: _turquesa,
                        title: const Text(
                          'Atendimento urgente',
                          style: TextStyle(
                            color: _azulEscuro,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Indique se seu pet precisa de atenção prioritária.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                        value: _urgente,
                        onChanged: (value) =>
                            setState(() => _urgente = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _turquesa,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar para checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progresso() {
    const etapas = ['Data', 'Detalhes', 'Revisão'];
    return Row(
      children: List.generate(etapas.length, (index) {
        final atual = index == 1;
        final concluida = index < 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: concluida || atual
                        ? _turquesa
                        : const Color(0xFFE1E7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  etapas[index],
                  style: TextStyle(
                    color: atual || concluida
                        ? _azulEscuro
                        : _textoSecundario,
                    fontSize: 12,
                    fontWeight:
                    atual ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _cartao({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: _azulEscuro.withValues(alpha: 0.035),
            blurRadius: 16,
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
    required ValueChanged<T?> onChanged,
  }) {
    final valorValido = items.contains(value) ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: valorValido,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: _fundo,
        hintText: hint,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E7EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E7EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _turquesa, width: 1.5),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(
          item.toString(),
          overflow: TextOverflow.ellipsis,
        ),
      ))
          .toList(),
      validator: (value) => value == null ? 'Selecione uma opção' : null,
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
        color: _azulEscuro,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}
