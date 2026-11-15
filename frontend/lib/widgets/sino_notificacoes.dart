import 'package:flutter/material.dart';

import 'package:pet_care/controle/contador_notificacoes.dart';
import 'package:pet_care/core/tema/cores_app.dart';

/// Ícone de sino com badge indicativo de notificações não lidas e polling automático.
class SinoNotificacoes extends StatefulWidget {
  const SinoNotificacoes({
    super.key,
    required this.onPressed,
    this.cor = CoresApp.darkBlue,
    this.tamanhoIcone = 25.0,
    this.icone = Icons.notifications_none_rounded,
  });

  /// Ação disparada ao tocar no sino de notificações.
  final VoidCallback? onPressed;

  /// Cor principal do ícone de sino.
  final Color cor;

  /// Dimensão do ícone de sino.
  final double tamanhoIcone;

  /// Ícone a ser exibido.
  final IconData icone;

  @override
  State<SinoNotificacoes> createState() => _SinoNotificacoesState();
}

class _SinoNotificacoesState extends State<SinoNotificacoes> {
  final ContadorNotificacoes _contador = ContadorNotificacoes.instancia;

  @override
  void initState() {
    super.initState();
    _contador.iniciar();
  }

  @override
  void dispose() {
    _contador.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _contador,
      builder: (context, _) {
        final naoLidas = _contador.naoLidas;
        final temNaoLidas = naoLidas > 0;
        final textoRotulo = naoLidas > 9 ? '9+' : '$naoLidas';
        final textoDescricao = temNaoLidas
            ? 'Notificações, $naoLidas não ${naoLidas == 1 ? "lida" : "lidas"}'
            : 'Notificações';

        return Semantics(
          label: textoDescricao,
          button: true,
          child: IconButton(
            onPressed: widget.onPressed,
            tooltip: textoDescricao,
            color: widget.cor,
            iconSize: widget.tamanhoIcone,
            icon: Badge(
              isLabelVisible: temNaoLidas,
              backgroundColor: Colors.red,
              label: Text(
                textoRotulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Icon(
                widget.icone,
                size: widget.tamanhoIcone,
                color: widget.cor,
              ),
            ),
          ),
        );
      },
    );
  }
}

