import 'package:flutter/material.dart';

import 'package:pet_care/controle/contador_notificacoes.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/api_exception.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/notificacao_modelo.dart';
import 'package:pet_care/services/notificacoes_service.dart';
import 'package:pet_care/widgets/item_notificacao.dart';

/// Ponto de entrada público para exibir o painel modal de notificações.
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

class _PainelNotificacoesTutorState extends State<_PainelNotificacoesTutor> {
  final NotificacoesService _servico = NotificacoesService();

  List<Notificacao> _notificacoes = [];
  bool _carregando = true;
  bool _carregandoMais = false;
  bool _marcandoTodas = false;
  bool _temMais = false;
  String? _mensagemErro;
  String? _mensagemSemLogin;

  @override
  void initState() {
    super.initState();
    ContadorNotificacoes.instancia.addListener(_aoAtualizarContador);

    if (!SessaoUsuario.instancia.estaLogado) {
      _carregando = false;
      _mensagemSemLogin = 'Entre para ver suas notificações.';
    } else {
      _carregarNotificacoes();
    }
  }

  @override
  void dispose() {
    ContadorNotificacoes.instancia.removeListener(_aoAtualizarContador);
    super.dispose();
  }

  void _aoAtualizarContador() {
    if (mounted) setState(() {});
  }

  int get _quantidadeNaoLidas {
    final naoLidasLocais =
        _notificacoes.where((notificacao) => !notificacao.lida).length;
    final naoLidasContador = ContadorNotificacoes.instancia.naoLidas;
    return naoLidasContador > 0 ? naoLidasContador : naoLidasLocais;
  }

  String _formatarErro(Object erro) {
    if (erro is ApiException) {
      if (erro.statusCode == 401) {
        return 'Sua sessão expirou. Entre novamente.';
      }
      if (erro.statusCode == 0) {
        return 'Sem conexão com o servidor.';
      }
      return erro.mensagem;
    }
    return 'Não foi possível carregar as notificações.';
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _carregarNotificacoes() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final resultado = await _servico.listar(limite: 20);
      if (!mounted) return;

      setState(() {
        _notificacoes = resultado.notificacoes;
        _temMais = resultado.notificacoes.length >= 20;
        _carregando = false;
      });

      ContadorNotificacoes.instancia.definirNaoLidas(resultado.naoLidas);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagemErro = _formatarErro(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_temMais || _notificacoes.isEmpty) return;

    setState(() => _carregandoMais = true);

    try {
      final ultimoId = _notificacoes.last.id;
      final resultado = await _servico.listar(limite: 20, antes: ultimoId);
      if (!mounted) return;

      setState(() {
        final idsExistentes = _notificacoes.map((n) => n.id).toSet();
        for (final item in resultado.notificacoes) {
          if (!idsExistentes.contains(item.id)) {
            _notificacoes.add(item);
            idsExistentes.add(item.id);
          }
        }
        _temMais = resultado.notificacoes.length >= 20;
      });

      ContadorNotificacoes.instancia.definirNaoLidas(resultado.naoLidas);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem(_formatarErro(e));
    } finally {
      if (mounted) {
        setState(() => _carregandoMais = false);
      }
    }
  }

  Future<void> _marcarComoLida(Notificacao item) async {
    if (item.lida) return;

    try {
      await _servico.marcarLida(item.id);
      if (!mounted) return;

      setState(() {
        final index = _notificacoes.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notificacoes[index] = item.copiarComLida(true);
        }
      });

      final atual = ContadorNotificacoes.instancia.naoLidas;
      ContadorNotificacoes.instancia.definirNaoLidas(atual > 0 ? atual - 1 : 0);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem(_formatarErro(e));
    }
  }

  Future<void> _marcarTodasComoLidas() async {
    if (_marcandoTodas) return;

    setState(() => _marcandoTodas = true);

    try {
      await _servico.marcarTodasLidas();
      if (!mounted) return;

      setState(() {
        for (var i = 0; i < _notificacoes.length; i++) {
          if (!_notificacoes[i].lida) {
            _notificacoes[i] = _notificacoes[i].copiarComLida(true);
          }
        }
      });

      ContadorNotificacoes.instancia.definirNaoLidas(0);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem(_formatarErro(e));
    } finally {
      if (mounted) {
        setState(() => _marcandoTodas = false);
      }
    }
  }

  Future<bool> _confirmarExclusao(Notificacao item) async {
    try {
      await _servico.excluir(item.id);
      return true;
    } catch (e) {
      if (mounted) {
        _mostrarMensagem(_formatarErro(e));
      }
      return false;
    }
  }

  void _aoExcluir(Notificacao item) {
    final eraNaoLida = !item.lida;
    setState(() {
      _notificacoes.removeWhere((n) => n.id == item.id);
    });

    if (eraNaoLida) {
      final atual = ContadorNotificacoes.instancia.naoLidas;
      ContadorNotificacoes.instancia.definirNaoLidas(atual > 0 ? atual - 1 : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = _quantidadeNaoLidas;

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
                          if (naoLidas > 0) ...[
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
                                '$naoLidas',
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
              if (naoLidas > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.pagePadding,
                    ),
                    child: TextButton(
                      onPressed: _marcandoTodas ? null : _marcarTodasComoLidas,
                      child: const Text('Marcar todas como lidas'),
                    ),
                  ),
                ),
              const Divider(height: 1),
              Expanded(
                child: _construirConteudo(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirConteudo(ScrollController scrollController) {
    if (_mensagemSemLogin != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Text(
            _mensagemSemLogin!,
            style: TipografiaApp.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mensagemErro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _mensagemErro!,
                style: TipografiaApp.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EspacamentosApp.md),
              ElevatedButton(
                onPressed: _carregarNotificacoes,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificacoes.isEmpty) {
      return Center(
        child: Text(
          'Você não tem notificações.',
          style: TipografiaApp.bodySmall,
        ),
      );
    }

    final totalItens = _notificacoes.length + (_temMais ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
      itemCount: totalItens,
      separatorBuilder: (_, _) => const SizedBox(height: EspacamentosApp.sm),
      itemBuilder: (context, index) {
        if (index == _notificacoes.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.sm),
            child: Center(
              child: _carregandoMais
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OutlinedButton(
                      onPressed: _carregarMais,
                      child: const Text('Carregar mais'),
                    ),
            ),
          );
        }

        final notificacao = _notificacoes[index];

        return Dismissible(
          key: ValueKey(notificacao.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmarExclusao(notificacao),
          onDismissed: (_) => _aoExcluir(notificacao),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: EspacamentosApp.md),
            decoration: BoxDecoration(
              color: CoresApp.danger.withAlpha(40),
              borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
            ),
            child: const Icon(Icons.delete_outline, color: CoresApp.danger),
          ),
          child: ItemNotificacao(
            notificacao: notificacao,
            onTap: () => _marcarComoLida(notificacao),
          ),
        );
      },
    );
  }
}
