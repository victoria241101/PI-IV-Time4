
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';

class NotificacaoTutor {
  const NotificacaoTutor({
    required this.titulo,
    required this.descricao,
    required this.tempo,
    required this.icone,
    this.lida = false,
  });

  final String titulo;
  final String descricao;
  final String tempo;
  final IconData icone;
  final bool lida;

  NotificacaoTutor copiarComLeitura(bool valor) {
    return NotificacaoTutor(
      titulo: titulo,
      descricao: descricao,
      tempo: tempo,
      icone: icone,
      lida: valor,
    );
  }
}

class ModalNotificacoesTutor {
  ModalNotificacoesTutor._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PainelNotificacoesTutor(),
    );
  }
}

class _PainelNotificacoesTutor extends StatelessWidget {
  const _PainelNotificacoesTutor();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EspacamentosApp.radiusXl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: CoresApp.textSecondary.withAlpha(90),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: EspacamentosApp.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notificações',
                    style: TipografiaApp.heading3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar notificações',
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.md),
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: EspacamentosApp.xl,
              ),
              child: Text('Suas notificações aparecerão aqui.'),
            ),
          ],
        ),
      ),
    );
  }
}
