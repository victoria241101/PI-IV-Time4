
import 'package:flutter/material.dart';

import 'package:pet_care/screens/tutor/detalhes_agendamento_tutor.dart';

const Color _turquesaConfirmacao = Color(0xFF27B8B0);
const Color _azulConfirmacao = Color(0xFF172A46);
const Color _fundoConfirmacao = Color(0xFFF5F7FA);
const Color _cinzaConfirmacao = Color(0xFF718096);

class ConfirmacaoAgendamentoTutor extends StatefulWidget {
  final DadosAgendamento dados;
  final ValueChanged<DadosAgendamento>? onConfirmar;

  const ConfirmacaoAgendamentoTutor({
    super.key,
    required this.dados,
    this.onConfirmar,
  });

  @override
  State<ConfirmacaoAgendamentoTutor> createState() =>
      _ConfirmacaoAgendamentoTutorState();
}

class _ConfirmacaoAgendamentoTutorState
    extends State<ConfirmacaoAgendamentoTutor> {
  bool _confirmado = false;

  String get _dataFormatada =>
      '${widget.dados.data.day.toString().padLeft(2, '0')}/'
          '${widget.dados.data.month.toString().padLeft(2, '0')}/'
          '${widget.dados.data.year}';

  void _finalizar() {
    if (_confirmado) return;

    if (widget.onConfirmar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir: o fluxo de consultas não recebeu '
                'a ação de confirmação.',
          ),
        ),
      );
      return;
    }

    widget.onConfirmar!(widget.dados);

    setState(() => _confirmado = true);

    // Volta à tela de consultas, removendo confirmação e detalhes.
    // O callback do chamador não deve executar Navigator.pop().
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoConfirmacao,
      appBar: AppBar(
        backgroundColor: _fundoConfirmacao,
        foregroundColor: _azulConfirmacao,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Confirmação',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F7F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _turquesaConfirmacao,
                size: 66,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tudo pronto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _azulConfirmacao,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Revise os dados abaixo e finalize para registrar o agendamento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _cinzaConfirmacao,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        color: _turquesaConfirmacao,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Resumo do agendamento',
                        style: TextStyle(
                          color: _azulConfirmacao,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ItemConfirmacao(
                    rotulo: 'Pet',
                    valor: widget.dados.nomePet,
                  ),
                  _ItemConfirmacao(
                    rotulo: 'Tipo de atendimento',
                    valor: widget.dados.tipoAtendimento,
                  ),
                  _ItemConfirmacao(
                    rotulo: 'Profissional',
                    valor: widget.dados.veterinario,
                  ),
                  _ItemConfirmacao(
                    rotulo: 'Data',
                    valor: _dataFormatada,
                  ),
                  _ItemConfirmacao(
                    rotulo: 'Horário',
                    valor: widget.dados.horario,
                  ),
                  _ItemConfirmacao(
                    rotulo: 'Prioridade',
                    valor: widget.dados.urgente ? 'Urgente' : 'Normal',
                    ultimo: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _turquesaConfirmacao),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A confirmação registra os dados no fluxo atual do aplicativo. '
                          'A persistência no banco e a confirmação de disponibilidade '
                          'dependem da integração com o backend.',
                      style: TextStyle(
                        color: _azulConfirmacao,
                        fontSize: 12,
                        height: 1.5,
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
                onPressed: _confirmado ? null : _finalizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _turquesaConfirmacao,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _turquesaConfirmacao,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Concluir agendamento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar ao checkout',
                style: TextStyle(
                  color: _azulConfirmacao,
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

class _ItemConfirmacao extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool ultimo;

  const _ItemConfirmacao({
    required this.rotulo,
    required this.valor,
    this.ultimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(
                color: _cinzaConfirmacao,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _azulConfirmacao,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
