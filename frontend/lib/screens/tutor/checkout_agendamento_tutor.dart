
import 'package:flutter/material.dart';

import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';
import 'package:pet_care/screens/tutor/confirmacao_agendamento_tutor.dart';

const Color _turquesaCheckout = Color(0xFF27B8B0);
const Color _azulCheckout = Color(0xFF172A46);
const Color _fundoCheckout = Color(0xFFF5F7FA);
const Color _cinzaCheckout = Color(0xFF718096);

class CheckoutAgendamentoTutor extends StatelessWidget {
  final DadosAgendamento dados;
  final ValueChanged<DadosAgendamento>? onConfirmar;

  const CheckoutAgendamentoTutor({
    super.key,
    required this.dados,
    this.onConfirmar,
  });

  String get _dataFormatada =>
      '${dados.data.day.toString().padLeft(2, '0')}/'
          '${dados.data.month.toString().padLeft(2, '0')}/'
          '${dados.data.year}';

  void _irParaConfirmacao(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
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
      backgroundColor: _fundoCheckout,
      appBar: AppBar(
        backgroundColor: _fundoCheckout,
        foregroundColor: _azulCheckout,
        elevation: 0,
        title: const Text(
          'Revisar agendamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _EtapaCheckout(),
            const SizedBox(height: 24),
            const Text(
              'Quase lá!',
              style: TextStyle(
                color: _azulCheckout,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Confira os dados antes de concluir seu agendamento.',
              style: TextStyle(color: _cinzaCheckout, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event_available_outlined,
                          color: _turquesaCheckout, size: 23),
                      SizedBox(width: 10),
                      Text(
                        'Resumo da consulta',
                        style: TextStyle(
                          color: _azulCheckout,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LinhaResumo(
                    icone: Icons.pets_outlined,
                    rotulo: 'Pet',
                    valor: dados.nomePet,
                  ),
                  _LinhaResumo(
                    icone: Icons.medical_services_outlined,
                    rotulo: 'Atendimento',
                    valor: dados.tipoAtendimento,
                  ),
                  _LinhaResumo(
                    icone: Icons.person_outline,
                    rotulo: 'Profissional',
                    valor: dados.veterinario,
                  ),
                  _LinhaResumo(
                    icone: Icons.calendar_month_outlined,
                    rotulo: 'Data',
                    valor: _dataFormatada,
                  ),
                  _LinhaResumo(
                    icone: Icons.schedule_outlined,
                    rotulo: 'Horário',
                    valor: dados.horario,
                    ultimo: true,
                  ),
                  if (dados.urgente) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.priority_high_rounded,
                              color: Color(0xFFB96B12)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Atendimento marcado como urgente',
                              style: TextStyle(
                                color: Color(0xFF8C5010),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _turquesaCheckout),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta etapa é uma revisão do agendamento. O pagamento '
                          'e a disponibilidade real ainda não estão integrados.',
                      style: TextStyle(
                        color: _azulCheckout,
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => _irParaConfirmacao(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _turquesaCheckout,
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
                      'Confirmar agendamento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar e editar',
                style: TextStyle(
                  color: _azulCheckout,
                  fontWeight: FontWeight.w600,
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
    return Row(
      children: List.generate(3, (index) {
        final ativa = index == 2;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: _turquesaCheckout,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['Data', 'Detalhes', 'Revisão'][index],
                  style: TextStyle(
                    color: _azulCheckout,
                    fontSize: 12,
                    fontWeight:
                    ativa ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LinhaResumo extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final bool ultimo;

  const _LinhaResumo({
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.ultimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: _turquesaCheckout, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: _cinzaCheckout,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: _azulCheckout,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
