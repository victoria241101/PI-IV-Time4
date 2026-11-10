import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/api_exception.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/chat/conversa_resumo_modelo.dart';
import 'package:pet_care/services/chat_service.dart';
import 'package:pet_care/widgets/chat/seletor_contato.dart';
import 'package:pet_care/widgets/item_notificacao.dart';

/// Lista de conversas do usuário com suporte a pull-to-refresh e estados visuais completos.
class ListaConversas extends StatefulWidget {
  final void Function(ConversaResumo conversa) onAbrirConversa;
  final String? titulo;
  final ChatService? servico;
  final bool exibirBotaoNovaConversa;

  const ListaConversas({
    super.key,
    required this.onAbrirConversa,
    this.titulo,
    this.servico,
    this.exibirBotaoNovaConversa = true,
  });

  @override
  State<ListaConversas> createState() => _ListaConversasState();
}

class _ListaConversasState extends State<ListaConversas> {
  late final ChatService _servico;

  List<ConversaResumo> _conversas = [];
  bool _carregando = true;
  String? _mensagemErro;
  bool _deslogado = false;

  @override
  void initState() {
    super.initState();
    _servico = widget.servico ?? ChatService();
    _carregarConversas();
  }

  Future<void> _carregarConversas() async {
    final sessao = SessaoUsuario.instancia;
    if (!sessao.estaLogado || sessao.token == null || sessao.token!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _deslogado = true;
        _carregando = false;
        _mensagemErro = null;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _mensagemErro = null;
      _deslogado = false;
    });

    try {
      final conversas = await _servico.listarConversas();
      if (!mounted) return;
      setState(() {
        _conversas = conversas;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg;
      if (e.statusCode == 401) {
        msg = 'Sua sessão expirou. Entre novamente.';
      } else if (e.statusCode == 0) {
        msg = 'Sem conexão com o servidor.';
      } else {
        msg = e.mensagem;
      }
      setState(() {
        _mensagemErro = msg;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensagemErro = 'Sem conexão com o servidor.';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirSeletorContato() async {
    final conversaAberta = await showModalBottomSheet<ConversaAberta>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SeletorContato(servico: _servico),
    );

    if (conversaAberta != null && mounted) {
      await _carregarConversas();
      if (!mounted) return;

      ConversaResumo resumo;
      try {
        resumo = _conversas.firstWhere((c) => c.id == conversaAberta.id);
      } catch (_) {
        resumo = ConversaResumo(
          id: conversaAberta.id,
          tipo: conversaAberta.tipo,
          outro: conversaAberta.outro,
          ultimaMensagem: null,
          ultimaMensagemEm: null,
          naoLidas: 0,
        );
      }
      widget.onAbrirConversa(resumo);
    }
  }

  String _obterNomeOutro(ConversaResumo conversa) {
    if (conversa.outro.nome.isNotEmpty) {
      return conversa.outro.nome;
    }
    if (conversa.outro.ehSecretaria) {
      return 'Secretaria';
    }
    return 'Conversa';
  }

  Widget _iconeConversa(ConversaResumo conversa) {
    IconData icone;
    Color cor;
    if (conversa.outro.ehSecretaria) {
      icone = Icons.support_agent_rounded;
      cor = CoresApp.primary;
    } else {
      switch (conversa.outro.papel?.toUpperCase()) {
        case 'VETERINARIO':
          icone = Icons.medical_services_outlined;
          cor = CoresApp.darkBlue;
          break;
        case 'ENFERMEIRO':
          icone = Icons.health_and_safety_outlined;
          cor = CoresApp.primaryDark;
          break;
        case 'USUARIO':
        default:
          icone = Icons.person_outline;
          cor = CoresApp.accentOrange;
          break;
      }
    }

    return CircleAvatar(
      backgroundColor: cor.withAlpha(24),
      child: Icon(icone, color: cor, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.titulo != null || widget.exibirBotaoNovaConversa) ...[
          Row(
            children: [
              if (widget.titulo != null)
                Text(
                  widget.titulo!,
                  style: TipografiaApp.heading2,
                ),
              const Spacer(),
              if (widget.exibirBotaoNovaConversa && !_deslogado)
                FilledButton.icon(
                  onPressed: _abrirSeletorContato,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova conversa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CoresApp.primary,
                    foregroundColor: CoresApp.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.md,
                      vertical: EspacamentosApp.xs,
                    ),
                    textStyle: TipografiaApp.captionBold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
        ],
        Expanded(
          child: _construirCorpo(),
        ),
      ],
    );
  }

  Widget _construirCorpo() {
    if (_deslogado) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: CoresApp.iconDefault,
            ),
            const SizedBox(height: EspacamentosApp.md),
            Text(
              'Entre para ver suas conversas.',
              style: TipografiaApp.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: CoresApp.primary),
      );
    }

    if (_mensagemErro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: CoresApp.statusCancelled,
            ),
            const SizedBox(height: EspacamentosApp.sm),
            Text(
              _mensagemErro!,
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.statusCancelled,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspacamentosApp.md),
            FilledButton.icon(
              onPressed: _carregarConversas,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: CoresApp.primary,
                foregroundColor: CoresApp.textOnPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_conversas.isEmpty) {
      return RefreshIndicator(
        color: CoresApp.primary,
        onRefresh: _carregarConversas,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: CoresApp.surfaceSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 38,
                        color: CoresApp.primary,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.md),
                    Text(
                      'Nenhuma conversa ainda',
                      style: TipografiaApp.heading3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: EspacamentosApp.xs),
                    Text(
                      'Inicie uma conversa tocando em Nova conversa.',
                      style: TipografiaApp.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: CoresApp.primary,
      onRefresh: _carregarConversas,
      child: ListView.separated(
        itemCount: _conversas.length,
        separatorBuilder: (_, __) => const SizedBox(height: EspacamentosApp.sm),
        itemBuilder: (context, index) {
          final conversa = _conversas[index];
          final nomeOutro = _obterNomeOutro(conversa);
          final temNaoLidas = conversa.naoLidas > 0;

          final ultimaMsgTexto = conversa.ultimaMensagem?.texto ??
              'Nenhuma mensagem ainda';

          final dataReferencia = conversa.ultimaMensagemEm ??
              conversa.ultimaMensagem?.criadoEm;
          final tempoTexto = dataReferencia != null
              ? formatarTempoRelativo(dataReferencia)
              : '';

          return Material(
            color: temNaoLidas
                ? CoresApp.primary.withAlpha(16)
                : CoresApp.surface,
            borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
            child: InkWell(
              onTap: () => widget.onAbrirConversa(conversa),
              borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(EspacamentosApp.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                  border: Border.all(
                    color: temNaoLidas
                        ? CoresApp.primary.withAlpha(50)
                        : CoresApp.divider,
                  ),
                ),
                child: Row(
                  children: [
                    _iconeConversa(conversa),
                    const SizedBox(width: EspacamentosApp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nomeOutro,
                                  style: TipografiaApp.bodyMedium.copyWith(
                                    fontWeight: temNaoLidas
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tempoTexto.isNotEmpty)
                                Text(
                                  tempoTexto,
                                  style: TipografiaApp.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: EspacamentosApp.xs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ultimaMsgTexto,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TipografiaApp.bodySmall.copyWith(
                                    color: temNaoLidas
                                        ? CoresApp.textPrimary
                                        : CoresApp.textSecondary,
                                    fontWeight: temNaoLidas
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (temNaoLidas)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: EspacamentosApp.sm,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CoresApp.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    conversa.naoLidas.toString(),
                                    style: TipografiaApp.captionBold.copyWith(
                                      color: CoresApp.textOnPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

