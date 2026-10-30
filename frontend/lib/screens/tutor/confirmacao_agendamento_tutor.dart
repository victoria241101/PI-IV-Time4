import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';

class ConfirmacaoAgendamentoTutor extends StatefulWidget {
  const ConfirmacaoAgendamentoTutor({
    super.key,
    required this.dados,
    this.onConfirmar,
  });

  final DadosAgendamento dados;
  final ValueChanged<DadosAgendamento>? onConfirmar;

  @override
  State<ConfirmacaoAgendamentoTutor> createState() =>
      _ConfirmacaoAgendamentoTutorState();
}

class _ConfirmacaoAgendamentoTutorState
    extends State<ConfirmacaoAgendamentoTutor> {
  bool _confirmado = false;
  bool _finalizando = false;

  String get _dataFormatada =>
      '${widget.dados.data.day.toString().padLeft(2, '0')}/'
          '${widget.dados.data.month.toString().padLeft(2, '0')}/'
          '${widget.dados.data.year}';

  void _finalizar() {
    if (_finalizando || _confirmado) return;

    final callback = widget.onConfirmar;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir: a confirmação do agendamento '
                'ainda não está conectada.',
          ),
        ),
      );
      return;
    }

    setState(() => _finalizando = true);

    try {
      callback(widget.dados);

      if (!mounted) return;

      setState(() {
        _confirmado = true;
        _finalizando = false;
      });

      // Retorna pelas telas de confirmação e detalhes até a tela
      // de consultas, preservando o fluxo de navegação existente.
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (_) {
      if (!mounted) return;

      setState(() => _finalizando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir o agendamento. Tente novamente.',
          ),
        ),
      );
    }
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Confirmação',
          style: TextStyle(
            color: CoresApp.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            const _EtapasConfirmacao(),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: CoresApp.primary,
                  size: 66,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tudo pronto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoresApp.darkBlue,
                fontSize: 29,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Confira o resumo e finalize para registrar '
                  'o agendamento do seu pet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoresApp.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            _CartaoConfirmacao(
              dados: widget.dados,
              dataFormatada: _dataFormatada,
            ),
            const SizedBox(height: 18),
            const _AvisoConfirmacao(),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _finalizando || _confirmado
                    ? null
                    : _finalizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoresApp.primary,
                  foregroundColor: CoresApp.surface,
                  disabledBackgroundColor:
                  CoresApp.primary.withAlpha(150),
                  disabledForegroundColor: CoresApp.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_finalizando)
                      const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoresApp.surface,
                        ),
                      )
                    else
                      const Icon(Icons.check_rounded),
                    const SizedBox(width: 9),
                    Text(
                      _finalizando
                          ? 'Finalizando...'
                          : 'Concluir agendamento',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _finalizando || _confirmado
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoresApp.darkBlue,
                  side: BorderSide(
                    color: CoresApp.darkBlue.withAlpha(35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: const Text(
                  'Voltar ao checkout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtapasConfirmacao extends StatelessWidget {
  const _EtapasConfirmacao();

  @override
  Widget build(BuildContext context) {
    const etapas = ['Data', 'Detalhes', 'Revisão'];

    return Row(
      children: List.generate(etapas.length, (index) {
        final atual = index == 2;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == etapas.length - 1 ? 0 : 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: atual
                        ? CoresApp.accentOrange
                        : CoresApp.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (atual) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: CoresApp.accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ] else ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: CoresApp.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        etapas[index],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: atual
                              ? CoresApp.accentOrangeDark
                              : CoresApp.darkBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

class _CartaoConfirmacao extends StatelessWidget {
  const _CartaoConfirmacao({
    required this.dados,
    required this.dataFormatada,
  });

  final DadosAgendamento dados;
  final String dataFormatada;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: CoresApp.divider),
        boxShadow: [
          BoxShadow(
            color: CoresApp.darkBlue.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: CoresApp.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo do agendamento',
                      style: TextStyle(
                        color: CoresApp.darkBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Revise os dados antes de concluir',
                      style: TextStyle(
                        color: CoresApp.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(
            height: 1,
            color: CoresApp.divider,
          ),
          const SizedBox(height: 20),
          _ItemConfirmacao(
            icone: Icons.pets_outlined,
            rotulo: 'Pet',
            valor: dados.nomePet,
          ),
          _ItemConfirmacao(
            icone: Icons.medical_services_outlined,
            rotulo: 'Tipo de atendimento',
            valor: dados.tipoAtendimento,
          ),
          _ItemConfirmacao(
            icone: Icons.person_outline_rounded,
            rotulo: 'Profissional',
            valor: dados.veterinario,
          ),
          _ItemConfirmacao(
            icone: Icons.calendar_month_outlined,
            rotulo: 'Data',
            valor: dataFormatada,
          ),
          _ItemConfirmacao(
            icone: Icons.schedule_rounded,
            rotulo: 'Horário',
            valor: dados.horario,
            ultimo: !dados.urgente,
          ),
          if (dados.urgente) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CoresApp.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: CoresApp.accentOrange.withAlpha(80),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    color: CoresApp.accentOrangeDark,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Atendimento marcado como urgente',
                      style: TextStyle(
                        color: CoresApp.accentOrangeDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: CoresApp.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: CoresApp.accentOrangeDark,
                  size: 21,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Confira se todas as informações estão corretas '
                        'antes de concluir.',
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
    );
  }
}

class _ItemConfirmacao extends StatelessWidget {
  const _ItemConfirmacao({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.ultimo = false,
  });

  final IconData icone;
  final String rotulo;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ultimo ? 0 : 19,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CoresApp.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icone,
              color: CoresApp.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: CoresApp.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _AvisoConfirmacao extends StatelessWidget {
  const _AvisoConfirmacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.surfaceSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: CoresApp.primary.withAlpha(35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: CoresApp.primary,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importante',
                  style: TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'A confirmação registra os dados no fluxo atual '
                      'do aplicativo. A persistência no banco e a '
                      'confirmação de disponibilidade dependem da '
                      'integração com o backend.',
                  style: TextStyle(
                    color: CoresApp.textSecondary,
                    fontSize: 12,
                    height: 1.55,
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