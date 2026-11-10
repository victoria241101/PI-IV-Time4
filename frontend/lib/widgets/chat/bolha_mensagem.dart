import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/chat/mensagem_chat_modelo.dart';

/// Bolha de mensagem individual do chat.
/// Alinha à direita se [mensagem.minha], à esquerda caso contrário.
/// Exibe hora em formato HH:mm e opcionalmente o nome do remetente no topo da bolha alheia.
class BolhaMensagem extends StatelessWidget {
  final MensagemChat mensagem;
  final bool exibirNomeRemetente;

  const BolhaMensagem({
    super.key,
    required this.mensagem,
    this.exibirNomeRemetente = false,
  });

  String _formatarHora(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final minha = mensagem.minha;
    final horaTexto = _formatarHora(mensagem.criadoEm);

    final deveExibirNome = !minha &&
        exibirNomeRemetente &&
        mensagem.remetenteNome.trim().isNotEmpty;

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deveExibirNome)
              Padding(
                padding: const EdgeInsets.only(
                  left: EspacamentosApp.xs,
                  right: EspacamentosApp.xs,
                  bottom: EspacamentosApp.xs,
                ),
                child: Text(
                  mensagem.remetenteNome.trim(),
                  style: TipografiaApp.captionBold.copyWith(
                    color: CoresApp.darkBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EspacamentosApp.md,
                vertical: EspacamentosApp.sm,
              ),
              decoration: BoxDecoration(
                color: minha ? CoresApp.primary : CoresApp.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(EspacamentosApp.radiusMd),
                  topRight: const Radius.circular(EspacamentosApp.radiusMd),
                  bottomLeft: Radius.circular(
                    minha ? EspacamentosApp.radiusMd : EspacamentosApp.xs,
                  ),
                  bottomRight: Radius.circular(
                    minha ? EspacamentosApp.xs : EspacamentosApp.radiusMd,
                  ),
                ),
                border: minha ? null : Border.all(color: CoresApp.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mensagem.texto,
                    style: TipografiaApp.bodyMedium.copyWith(
                      color: minha
                          ? CoresApp.textOnPrimary
                          : CoresApp.textPrimary,
                    ),
                  ),
                  const SizedBox(height: EspacamentosApp.xs),
                  Text(
                    horaTexto,
                    style: TipografiaApp.caption.copyWith(
                      fontSize: 10,
                      color: minha
                          ? CoresApp.textOnPrimary.withAlpha(200)
                          : CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

