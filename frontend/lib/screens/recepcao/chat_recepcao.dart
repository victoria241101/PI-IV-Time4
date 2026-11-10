import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/chat/lista_conversas.dart';

class ChatRecepcao extends StatelessWidget {
  const ChatRecepcao({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
      ),
      child: ListaConversas(
        titulo: 'Chat da equipe',
        onAbrirConversa: (conversa) {
          // provisório até a Parte 5
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A tela de mensagens chega na próxima etapa.',
              ),
            ),
          );
        },
      ),
    );
  }
}
