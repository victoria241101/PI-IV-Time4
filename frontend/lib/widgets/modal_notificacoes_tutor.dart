
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

class _PainelNotificacoesTutor extends StatefulWidget {
  const _PainelNotificacoesTutor();

  @override
  State<_PainelNotificacoesTutor> createState() =>
      _PainelNotificacoesTutorState();
}

class _PainelNotificacoesTutorState
    extends State<_PainelNotificacoesTutor> {
  late final List<NotificacaoTutor> _notificacoes = [
    const NotificacaoTutor(
      titulo: 'Consulta próxima',
      descricao: 'Confira a data e o horário da próxima consulta.',
      tempo: 'Há 10 min',
      icone: Icons.calendar_month_outlined,
    ),
    const NotificacaoTutor(
      titulo: 'Consulta confirmada',
      descricao: 'O agendamento foi confirmado com sucesso.',
      tempo: 'Ontem',
      icone: Icons.check_circle_outline,
      lida: true,
    ),
    const NotificacaoTutor(
      titulo: 'Lembrete de vacinação',
      descricao: 'Confira os cuidados preventivos do seu pet.',
      tempo: 'Há 2 dias',
      icone: Icons.vaccines_outlined,
    ),
  ];

  int get _quantidadeNaoLidas =>
      _notificacoes.where((notificacao) => !notificacao.lida).length;

  void _marcarComoLida(int index) {
    if (_notificacoes[index].lida) return;

    setState(() {
      _notificacoes[index] =
          _notificacoes[index].copiarComLeitura(true);
    });
  }

  void _marcarTodasComoLidas() {
    setState(() {
      for (var i = 0; i < _notificacoes.length; i++) {
        _notificacoes[i] =
            _notificacoes[i].copiarComLeitura(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.32,
      maxChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: CoresApp.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EspacamentosApp.radiusXl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: EspacamentosApp.sm),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: CoresApp.textSecondary.withAlpha(90),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EspacamentosApp.pagePadding,
                  EspacamentosApp.sm,
                  EspacamentosApp.sm,
                  EspacamentosApp.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Notificações',
                            style: TipografiaApp.heading3,
                          ),
                          if (_quantidadeNaoLidas > 0) ...[
                            const SizedBox(width: EspacamentosApp.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: EspacamentosApp.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CoresApp.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_quantidadeNaoLidas',
                                style: TipografiaApp.bodySmall.copyWith(
                                  color: CoresApp.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar notificações',
                    ),
                  ],
                ),
              ),
              if (_quantidadeNaoLidas > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.pagePadding,
                    ),
                    child: TextButton(
                      onPressed: _marcarTodasComoLidas,
                      child: const Text('Marcar todas como lidas'),
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: _notificacoes.isEmpty
                    ? Center(
                  child: Text(
                    'Você não tem notificações.',
                    style: TipografiaApp.bodySmall,
                  ),
                )
                    : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(
                    EspacamentosApp.pagePadding,
                  ),
                  itemCount: _notificacoes.length,
                  separatorBuilder: (_, _) =>
                  const SizedBox(height: EspacamentosApp.sm),
                  itemBuilder: (context, index) {
                    final notificacao = _notificacoes[index];

                    return _ItemNotificacao(
                      notificacao: notificacao,
                      onTap: () => _marcarComoLida(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemNotificacao extends StatelessWidget {
  const _ItemNotificacao({
    required this.notificacao,
    required this.onTap,
  });

  final NotificacaoTutor notificacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final naoLida = !notificacao.lida;

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
                  notificacao.icone,
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
                      notificacao.descricao,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.sm),
                    Text(
                      notificacao.tempo,
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
