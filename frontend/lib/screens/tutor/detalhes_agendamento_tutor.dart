
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class DadosAgendamento {
  const DadosAgendamento({
    required this.data,
    required this.nomePet,
    required this.tipoAtendimento,
    required this.veterinario,
    required this.horario,
    required this.urgente,
  });

  final DateTime data;
  final String nomePet;
  final String tipoAtendimento;
  final String veterinario;
  final String horario;
  final bool urgente;
}

class DetalhesAgendamentoTutor extends StatefulWidget {
  const DetalhesAgendamentoTutor({
    super.key,
    required this.dataSelecionada,
    this.nomesPets = const ['Luna', 'Max', 'Mel'],
    this.onContinuar,
  });

  final DateTime dataSelecionada;
  final List<String> nomesPets;
  final ValueChanged<DadosAgendamento>? onContinuar;

  @override
  State<DetalhesAgendamentoTutor> createState() =>
      _DetalhesAgendamentoTutorState();
}

class _DetalhesAgendamentoTutorState
    extends State<DetalhesAgendamentoTutor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _nomePet;
  String? _tipoAtendimento;
  String? _veterinario;
  String? _horario;
  bool _urgente = false;

  final List<String> _tiposAtendimento = const [
    'Consulta geral',
    'Vacinação',
    'Dermatologia',
    'Odontologia',
    'Retorno',
    'Exames',
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

  String get _dataFormatada {
    final data = widget.dataSelecionada;

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  void initState() {
    super.initState();

    if (widget.nomesPets.length == 1) {
      _nomePet = widget.nomesPets.first;
    }
  }

  void _continuar() {
    final formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) return;

    final dados = DadosAgendamento(
      data: widget.dataSelecionada,
      nomePet: _nomePet!,
      tipoAtendimento: _tipoAtendimento!,
      veterinario: _veterinario!,
      horario: _horario!,
      urgente: _urgente,
    );

    if (widget.onContinuar != null) {
      widget.onContinuar!(dados);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Seleção validada. A próxima etapa será implementada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        title: Text(
          'Detalhes do agendamento',
          style: TipografiaApp.heading3,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              EspacamentosApp.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _indicadorEtapa(),
                const SizedBox(height: EspacamentosApp.xl),
                _resumoData(),
                const SizedBox(height: EspacamentosApp.xl),

                Text(
                  'Vamos organizar a consulta',
                  style: TipografiaApp.heading3,
                ),
                const SizedBox(height: EspacamentosApp.sm),
                Text(
                  'Escolha os detalhes do atendimento do seu pet.',
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.xl),

                _tituloCampo('Qual pet será atendido?'),
                const SizedBox(height: EspacamentosApp.sm),
                _seletor(
                  valor: _nomePet,
                  dica: 'Selecione seu pet',
                  icone: Icons.pets_outlined,
                  opcoes: widget.nomesPets,
                  aoMudar: (valor) {
                    setState(() => _nomePet = valor);
                  },
                ),

                const SizedBox(height: EspacamentosApp.lg),

                _tituloCampo('Tipo de atendimento'),
                const SizedBox(height: EspacamentosApp.sm),
                _seletor(
                  valor: _tipoAtendimento,
                  dica: 'Selecione o atendimento',
                  icone: Icons.medical_services_outlined,
                  opcoes: _tiposAtendimento,
                  aoMudar: (valor) {
                    setState(() => _tipoAtendimento = valor);
                  },
                ),

                const SizedBox(height: EspacamentosApp.lg),

                _tituloCampo('Veterinário'),
                const SizedBox(height: EspacamentosApp.sm),
                _seletor(
                  valor: _veterinario,
                  dica: 'Escolha um profissional',
                  icone: Icons.person_search_outlined,
                  opcoes: _veterinarios,
                  aoMudar: (valor) {
                    setState(() => _veterinario = valor);
                  },
                ),

                const SizedBox(height: EspacamentosApp.lg),

                _tituloCampo('Horário disponível'),
                const SizedBox(height: EspacamentosApp.sm),
                _gradeHorarios(),

                const SizedBox(height: EspacamentosApp.lg),
                _cartaoUrgencia(),

                const SizedBox(height: EspacamentosApp.xl),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _continuar,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continuar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CoresApp.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          EspacamentosApp.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: EspacamentosApp.md),

                Center(
                  child: Text(
                    'Você poderá revisar os dados antes de confirmar.',
                    textAlign: TextAlign.center,
                    style: TipografiaApp.bodySmall.copyWith(
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicadorEtapa() {
    return Row(
      children: [
        _etapa('1', 'Data', concluida: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: CoresApp.primary,
          ),
        ),
        _etapa('2', 'Detalhes', atual: true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: CoresApp.textSecondary.withAlpha(45),
          ),
        ),
        _etapa('3', 'Revisão'),
      ],
    );
  }

  Widget _etapa(
      String numero,
      String texto, {
        bool concluida = false,
        bool atual = false,
      }) {
    final destacada = concluida || atual;

    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor:
          destacada ? CoresApp.primary : CoresApp.surface,
          child: concluida
              ? const Icon(
            Icons.check,
            color: Colors.white,
            size: 17,
          )
              : Text(
            numero,
            style: TipografiaApp.bodySmall.copyWith(
              color: destacada
                  ? Colors.white
                  : CoresApp.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          texto,
          style: TipografiaApp.bodySmall.copyWith(
            color: destacada
                ? CoresApp.primary
                : CoresApp.textSecondary,
            fontWeight:
            atual ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _resumoData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(
          EspacamentosApp.radiusLg,
        ),
        border: Border.all(
          color: CoresApp.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: CoresApp.primary,
            size: 30,
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
                  _dataFormatada,
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

  Widget _tituloCampo(String titulo) {
    return Text(
      titulo,
      style: TipografiaApp.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _seletor({
    required String? valor,
    required String dica,
    required IconData icone,
    required List<String> opcoes,
    required ValueChanged<String?> aoMudar,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      isExpanded: true,
      validator: (valorSelecionado) {
        if (valorSelecionado == null) {
          return 'Selecione uma opção.';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icone),
        filled: true,
        fillColor: CoresApp.surface,
        hintText: dica,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.md,
          vertical: EspacamentosApp.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EspacamentosApp.radiusLg,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EspacamentosApp.radiusLg,
          ),
          borderSide: BorderSide(
            color: CoresApp.textSecondary.withAlpha(60),
          ),
        ),
      ),
      items: opcoes.map((opcao) {
        return DropdownMenuItem<String>(
          value: opcao,
          child: Text(
            opcao,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: aoMudar,
    );
  }

  Widget _gradeHorarios() {
    return FormField<String>(
      validator: (_) {
        if (_horario == null) {
          return 'Selecione um horário.';
        }
        return null;
      },
      builder: (estado) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _horarios.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
              ),
              itemBuilder: (context, index) {
                final horario = _horarios[index];
                final selecionado = _horario == horario;

                return OutlinedButton(
                  onPressed: () {
                    setState(() => _horario = horario);
                    estado.didChange(horario);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: selecionado
                        ? CoresApp.primary
                        : CoresApp.surface,
                    foregroundColor: selecionado
                        ? Colors.white
                        : CoresApp.textPrimary,
                    side: BorderSide(
                      color: selecionado
                          ? CoresApp.primary
                          : CoresApp.textSecondary.withAlpha(60),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(horario),
                );
              },
            ),
            if (estado.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  estado.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cartaoUrgencia() {
    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(
          EspacamentosApp.radiusLg,
        ),
        border: Border.all(
          color: _urgente
              ? Colors.orange.withAlpha(150)
              : CoresApp.textSecondary.withAlpha(45),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisa de atendimento urgente?',
                  style: TipografiaApp.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Informe se o caso precisa de atenção prioritária.',
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _urgente,
            activeTrackColor: CoresApp.primary,
            onChanged: (valor) {
              setState(() => _urgente = valor);
            },
          ),
        ],
      ),
    );
  }
}
