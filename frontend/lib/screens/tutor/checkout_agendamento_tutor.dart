import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';
import 'package:pet_care/screens/tutor/confirmacao_agendamento_tutor.dart';

class CheckoutAgendamentoTutor extends StatelessWidget {
  const CheckoutAgendamentoTutor({
    super.key,
    required this.dados,
    this.onConfirmar,
  });

  final DadosAgendamento dados;
  final ValueChanged<DadosAgendamento>? onConfirmar;

  String get _dataFormatada =>
      '${dados.data.day.toString().padLeft(2, '0')}/'
          '${dados.data.month.toString().padLeft(2, '0')}/'
          '${dados.data.year}';

  void _irParaConfirmacao(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmacaoAgendamentoTutor(
          dados: dados,
          onConfirmar: onConfirmar,
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
        title: const Text(
          'Revisar agendamento',
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
            const _EtapaCheckout(),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.surfaceSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 16,
                      color: CoresApp.accentOrangeDark,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'ETAPA FINAL DE REVISÃO',
                      style: TextStyle(
                        color: CoresApp.accentOrangeDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quase lá!',
              style: TextStyle(
                color: CoresApp.darkBlue,
                fontSize: 29,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Confira os dados com atenção antes de concluir '
                  'o agendamento do seu pet.',
              style: TextStyle(
                color: CoresApp.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _CartaoResumo(
              dados: dados,
              dataFormatada: _dataFormatada,
            ),
            const SizedBox(height: 18),
            _AvisoCheckout(urgente: dados.urgente),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _irParaConfirmacao(context),
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
                      'Confirmar agendamento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
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
                  'Voltar e editar',
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

class _EtapaCheckout extends StatelessWidget {
  const _EtapaCheckout();

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
                    if (index < 2) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: CoresApp.primary,
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: CoresApp.accentOrange,
                          shape: BoxShape.circle,
                        ),
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

class _CartaoResumo extends StatelessWidget {
  const _CartaoResumo({
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
                      'Resumo da consulta',
                      style: TextStyle(
                        color: CoresApp.darkBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Confira os detalhes selecionados',
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
          _LinhaResumo(
            icone: Icons.pets_outlined,
            rotulo: 'Pet',
            valor: dados.nomePet,
          ),
          _LinhaResumo(
            icone: Icons.medical_services_outlined,
            rotulo: 'Tipo de atendimento',
            valor: dados.tipoAtendimento,
          ),
          _LinhaResumo(
            icone: Icons.person_outline_rounded,
            rotulo: 'Profissional',
            valor: dados.veterinario,
          ),
          _LinhaResumo(
            icone: Icons.calendar_month_outlined,
            rotulo: 'Data',
            valor: dataFormatada,
          ),
          _LinhaResumo(
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
        ],
      ),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  const _LinhaResumo({
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
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

class _AvisoCheckout extends StatelessWidget {
  const _AvisoCheckout({
    required this.urgente,
  });

  final bool urgente;

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
                  'Antes de continuar',
                  style: TextStyle(
                    color: CoresApp.darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Esta etapa revisa os dados do agendamento. '
                      'A disponibilidade real, o pagamento e a persistência '
                      'no banco dependem da integração com o backend.',
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