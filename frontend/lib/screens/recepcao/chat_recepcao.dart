// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Integra lista e abertura de conversas ao fluxo da recepção reutilizando o chat existente.
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/chat/tela_mensagens.dart';
import 'package:pet_care/widgets/chat/lista_conversas.dart';

class ChatRecepcao extends StatelessWidget {
  const ChatRecepcao({super.key});

  // Monta a área da recepção reutilizando a lista de conversas compartilhada pelo app.
  @override
  Widget build(BuildContext context) {
    // Mantém o chat alinhado ao espaçamento das demais telas da recepção.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
      ),
      // O cabeçalho compacto preserva espaço para a própria lista de conversas.
      child: ListaConversas(
        titulo: 'Chat da equipe',
        compactarCabecalho: true,
        // Selecionar uma conversa abre a tela de mensagens correspondente.
        onAbrirConversa: (conversa) async {
          // Aguarda o retorno para que a recepção volte ao contexto anterior.
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TelaMensagens(conversa: conversa),
            ),
          );
        },
      ),
    );
  }
}
