import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/notificacao_modelo.dart';

/// Mapeia os 12 tipos de notificação do backend para seus respectivos ícones.
/// Tipos desconhecidos retornam um ícone genérico de notificação.
IconData iconeParaTipoNotificacao(String tipo) {
  switch (tipo) {
    case 'chegada_paciente':
      return Icons.how_to_reg_outlined;
    case 'triagem_concluida':
      return Icons.fact_check_outlined;
    case 'tarefa_clinica_criada':
      return Icons.assignment_outlined;
    case 'dose_prescrita':
      return Icons.medication_outlined;
    case 'consulta_agendada':
      return Icons.calendar_month_outlined;
    case 'consulta_remarcada':
      return Icons.edit_calendar_outlined;
    case 'consulta_cancelada':
      return Icons.event_busy_outlined;
    case 'alta_orientacoes':
      return Icons.assignment_turned_in_outlined;
    case 'campanha_encerrada':
      return Icons.flag_outlined;
    case 'campanha_meta_atingida':
      return Icons.emoji_events_outlined;
    case 'lembrete_consulta':
      return Icons.alarm_outlined;
    case 'lembrete_vacina':
      return Icons.vaccines_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

/// Formata a data de criação em tempo relativo amigável em português.
String formatarTempoRelativo(DateTime criadoEm) {
  final agora = DateTime.now();
  final diferenca = agora.difference(criadoEm);

  if (diferenca.isNegative || diferenca.inSeconds < 60) {
    return 'Agora';
  }
  if (diferenca.inMinutes < 60) {
    return 'Há ${diferenca.inMinutes} min';
  }

  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dataCriacao = DateTime(criadoEm.year, criadoEm.month, criadoEm.day);
  final diferencaDias = hoje.difference(dataCriacao).inDays;

  if (diferencaDias == 0) {
    return 'Há ${diferenca.inHours} h';
  }
  if (diferencaDias == 1) {
    return 'Ontem';
  }
  if (diferencaDias >= 2 && diferencaDias <= 7) {
    return 'Há $diferencaDias dias';
  }

  final dia = criadoEm.day.toString().padLeft(2, '0');
  final mes = criadoEm.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

/// Componente visual para exibição de um item individual de notificação.
class ItemNotificacao extends StatelessWidget {
  const ItemNotificacao({
    super.key,
    required this.notificacao,
    required this.onTap,
  });

  final Notificacao notificacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final naoLida = !notificacao.lida;
    final icone = iconeParaTipoNotificacao(notificacao.tipo);
    final tempo = formatarTempoRelativo(notificacao.criadoEm);

    return Material(
      color: naoLida
          ? CoresApp.primary.withAlpha(18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(
                    EspacamentosApp.radiusMd,
                  ),
                ),
                child: Icon(
                  icone,
                  color: CoresApp.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacao.titulo,
                      style: TipografiaApp.bodyMedium.copyWith(
                        fontWeight:
                            naoLida ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xs),
                    Text(
                      notificacao.mensagem,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.sm),
                    Text(
                      tempo,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (naoLida) ...[
                const SizedBox(width: EspacamentosApp.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CoresApp.primary,
                      shape: BoxShape.circle,
                    ),
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

