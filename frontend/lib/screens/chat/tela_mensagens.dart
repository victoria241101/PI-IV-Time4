import 'dart:async';
import 'package:flutter/material.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/api_exception.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/chat/conversa_resumo_modelo.dart';
import 'package:pet_care/modelos/chat/mensagem_chat_modelo.dart';
import 'package:pet_care/services/chat_service.dart';
import 'package:pet_care/widgets/chat/bolha_mensagem.dart';

/// Tela de mensagens de uma conversa (Parte 5 da integração de Chat).
class TelaMensagens extends StatefulWidget {
  final ConversaResumo conversa;
  final ChatService? servico;

  const TelaMensagens({
    super.key,
    required this.conversa,
    this.servico,
  });

  @override
  State<TelaMensagens> createState() => _TelaMensagensState();
}

class _TelaMensagensState extends State<TelaMensagens>
    with WidgetsBindingObserver {
  late final ChatService _servico;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textoController = TextEditingController();

  List<MensagemChat> _mensagens = [];
  Set<String> _idsConhecidos = <String>{};

  bool _carregandoInicial = true;
  String? _erroInicial;
  bool _carregandoMaisHistorico = false;
  bool _temMaisHistorico = false;

  bool _enviando = false;
  bool _textoValido = false;
  String? _faixaErro;

  Timer? _timerPolling;
  bool _consultandoNovas = false;
  bool _mostrarPillNovaMensagem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _servico = widget.servico ?? ChatService();

    _textoController.addListener(_aoMudarTexto);
    _scrollController.addListener(_aoRolar);

    _carregarMensagensIniciais();
    _iniciarTimerPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _iniciarTimerPolling();
      _consultarNovasMensagens();
    } else {
      _cancelarTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelarTimer();
    _scrollController.removeListener(_aoRolar);
    _scrollController.dispose();
    _textoController.removeListener(_aoMudarTexto);
    _textoController.dispose();
    super.dispose();
  }

  void _aoMudarTexto() {
    final aparado = _textoController.text.trim();
    final valido = aparado.isNotEmpty && aparado.length <= 2000;
    if (valido != _textoValido) {
      setState(() {
        _textoValido = valido;
      });
    }
  }

  void _aoRolar() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final atual = _scrollController.offset;
    if (maxScroll - atual <= 40 && _mostrarPillNovaMensagem) {
      setState(() {
        _mostrarPillNovaMensagem = false;
      });
    }
  }

  void _iniciarTimerPolling() {
    _cancelarTimer();
    _timerPolling = Timer.periodic(const Duration(seconds: 5), (_) {
      _consultarNovasMensagens();
    });
  }

  void _cancelarTimer() {
    _timerPolling?.cancel();
    _timerPolling = null;
  }

  Future<void> _carregarMensagensIniciais() async {
    setState(() {
      _carregandoInicial = true;
      _erroInicial = null;
      _faixaErro = null;
    });

    try {
      final msgs = await _servico.listarMensagens(
        widget.conversa.id,
        limite: 50,
      );

      if (!mounted) return;

      setState(() {
        _mensagens = msgs;
        _idsConhecidos = msgs.map((m) => m.id).toSet();
        _temMaisHistorico = msgs.length == 50;
        _carregandoInicial = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

      try {
        await _servico.marcarLida(widget.conversa.id);
      } catch (_) {
        // falha ignorada, sem SnackBar
      }
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
        _erroInicial = msg;
        _carregandoInicial = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroInicial = 'Sem conexão com o servidor.';
        _carregandoInicial = false;
      });
    }
  }

  Future<void> _carregarMensagensAnteriores() async {
    if (_carregandoMaisHistorico || _mensagens.isEmpty) return;

    setState(() {
      _carregandoMaisHistorico = true;
    });

    final idMaisAntiga = _mensagens.first.id;
    final double maxScrollAntes = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0;
    final double offsetAntes =
        _scrollController.hasClients ? _scrollController.offset : 0;

    try {
      final anteriores = await _servico.listarMensagens(
        widget.conversa.id,
        limite: 50,
        antes: idMaisAntiga,
      );

      if (!mounted) return;

      final novasUnicas = anteriores
          .where((m) => !_idsConhecidos.contains(m.id))
          .toList();

      for (final m in novasUnicas) {
        _idsConhecidos.add(m.id);
      }

      setState(() {
        _mensagens = [...novasUnicas, ..._mensagens];
        _temMaisHistorico = anteriores.length == 50;
        _carregandoMaisHistorico = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final double maxScrollDepois =
              _scrollController.position.maxScrollExtent;
          final double delta = maxScrollDepois - maxScrollAntes;
          if (delta > 0) {
            _scrollController.jumpTo(offsetAntes + delta);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoMaisHistorico = false;
      });
    }
  }

  Future<void> _consultarNovasMensagens() async {
    if (_consultandoNovas || !mounted || _carregandoInicial) return;
    _consultandoNovas = true;

    try {
      final ultimaId = _mensagens.isNotEmpty ? _mensagens.last.id : null;
      final List<MensagemChat> novas;
      if (ultimaId != null) {
        novas = await _servico.listarMensagens(
          widget.conversa.id,
          depois: ultimaId,
          limite: 50,
        );
      } else {
        novas = await _servico.listarMensagens(
          widget.conversa.id,
          limite: 50,
        );
      }

      if (!mounted) return;

      final novasUnicas =
          novas.where((m) => !_idsConhecidos.contains(m.id)).toList();
      if (novasUnicas.isEmpty) {
        return;
      }

      for (final m in novasUnicas) {
        _idsConhecidos.add(m.id);
      }

      final bool estaNoFim = !_scrollController.hasClients ||
          (_scrollController.position.maxScrollExtent -
                  _scrollController.offset <=
              80);

      setState(() {
        _mensagens = [..._mensagens, ...novasUnicas];
        if (!estaNoFim) {
          _mostrarPillNovaMensagem = true;
        }
      });

      if (estaNoFim) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }

      final bool temDeOutros = novasUnicas.any((m) => !m.minha);
      if (temDeOutros) {
        try {
          await _servico.marcarLida(widget.conversa.id);
        } catch (_) {}
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        _cancelarTimer();
        setState(() {
          _faixaErro = 'Sua sessão expirou. Entre novamente.';
        });
      }
    } catch (_) {
      // Outros erros de rede: ignora em silêncio e mantém o timer
    } finally {
      _consultandoNovas = false;
    }
  }

  Future<void> _enviarMensagem() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty || texto.length > 2000 || _enviando) return;

    setState(() {
      _enviando = true;
      _faixaErro = null;
    });

    try {
      await _servico.enviarMensagem(widget.conversa.id, texto);

      // Busca as novas mensagens a partir do ID da última conhecida
      final ultimaId = _mensagens.isNotEmpty ? _mensagens.last.id : null;
      final List<MensagemChat> novas;
      if (ultimaId != null) {
        novas = await _servico.listarMensagens(
          widget.conversa.id,
          depois: ultimaId,
          limite: 50,
        );
      } else {
        novas = await _servico.listarMensagens(
          widget.conversa.id,
          limite: 50,
        );
      }

      if (!mounted) return;

      final novasUnicas =
          novas.where((m) => !_idsConhecidos.contains(m.id)).toList();
      for (final m in novasUnicas) {
        _idsConhecidos.add(m.id);
      }

      _textoController.clear();

      setState(() {
        _enviando = false;
        _faixaErro = null;
        _textoValido = false;
        if (novasUnicas.isNotEmpty) {
          _mensagens = [..._mensagens, ...novasUnicas];
        }
        _mostrarPillNovaMensagem = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
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
        _enviando = false;
        _faixaErro = msg;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _faixaErro = 'Sem conexão com o servidor.';
      });
    }
  }

  void _rolarParaOFim() {
    setState(() {
      _mostrarPillNovaMensagem = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _ehMesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatarSeparadorData(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataDia = DateTime(data.year, data.month, data.day);
    final diferencaDias = hoje.difference(dataDia).inDays;

    if (diferencaDias == 0) {
      return 'Hoje';
    } else if (diferencaDias == 1) {
      return 'Ontem';
    } else {
      final d = data.day.toString().padLeft(2, '0');
      final m = data.month.toString().padLeft(2, '0');
      final y = data.year.toString().padLeft(4, '0');
      return '$d/$m/$y';
    }
  }

  String get _nomeOutro {
    if (widget.conversa.outro.nome.trim().isNotEmpty) {
      return widget.conversa.outro.nome.trim();
    }
    if (widget.conversa.outro.ehSecretaria) {
      return 'Secretaria';
    }
    return 'Conversa';
  }

  String? get _subtituloPapel {
    if (widget.conversa.outro.ehSecretaria) {
      return 'Secretaria';
    }
    final papel = widget.conversa.outro.papel?.toUpperCase();
    switch (papel) {
      case 'USUARIO':
        return 'Tutor';
      case 'VETERINARIO':
        return 'Veterinário(a)';
      case 'ENFERMEIRO':
        return 'Enfermeiro(a)';
      case 'SECRETARIA':
        return 'Secretaria';
      default:
        return null;
    }
  }

  IconData get _iconeAvatar {
    if (widget.conversa.outro.ehSecretaria) {
      return Icons.support_agent_rounded;
    }
    switch (widget.conversa.outro.papel?.toUpperCase()) {
      case 'VETERINARIO':
        return Icons.medical_services_outlined;
      case 'ENFERMEIRO':
        return Icons.health_and_safety_outlined;
      case 'USUARIO':
      default:
        return Icons.person_outline;
    }
  }

  Color get _corAvatar {
    if (widget.conversa.outro.ehSecretaria) {
      return CoresApp.primary;
    }
    switch (widget.conversa.outro.papel?.toUpperCase()) {
      case 'VETERINARIO':
        return CoresApp.darkBlue;
      case 'ENFERMEIRO':
        return CoresApp.primaryDark;
      case 'USUARIO':
      default:
        return CoresApp.primary;
    }
  }

  bool get _exibirNomeRemetente =>
      widget.conversa.tipo == 'secretaria' &&
      (SessaoUsuario.instancia.ehEquipeClinica ||
          !widget.conversa.outro.ehSecretaria);

  @override
  Widget build(BuildContext context) {
    final subtitulo = _subtituloPapel;
    final corAvatar = _corAvatar;
    final iconeAvatar = _iconeAvatar;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: CoresApp.background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: CoresApp.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CoresApp.textPrimary),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: corAvatar.withAlpha(24),
                child: Icon(iconeAvatar, color: corAvatar, size: 20),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nomeOutro,
                      style: TipografiaApp.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo,
                        style: TipografiaApp.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _construirCorpoMensagens(),
                    if (_mostrarPillNovaMensagem)
                      Positioned(
                        bottom: EspacamentosApp.sm,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: InkWell(
                            onTap: _rolarParaOFim,
                            borderRadius: BorderRadius.circular(
                              EspacamentosApp.radiusFull,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: EspacamentosApp.md,
                                vertical: EspacamentosApp.xs,
                              ),
                              decoration: BoxDecoration(
                                color: CoresApp.primary,
                                borderRadius: BorderRadius.circular(
                                  EspacamentosApp.radiusFull,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_downward,
                                    color: CoresApp.textOnPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: EspacamentosApp.xs),
                                  Text(
                                    'Nova mensagem',
                                    style: TipografiaApp.captionBold.copyWith(
                                      color: CoresApp.textOnPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_faixaErro != null) _construirFaixaErro(),
              if (!_carregandoInicial && _erroInicial == null)
                _construirCampoEnvio(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCorpoMensagens() {
    if (_carregandoInicial) {
      return const Center(
        child: CircularProgressIndicator(color: CoresApp.primary),
      );
    }

    if (_erroInicial != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
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
                _erroInicial!,
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.statusCancelled,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EspacamentosApp.md),
              FilledButton.icon(
                onPressed: _carregarMensagensIniciais,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresApp.primary,
                  foregroundColor: CoresApp.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_mensagens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: CoresApp.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 34,
                  color: CoresApp.primary,
                ),
              ),
              const SizedBox(height: EspacamentosApp.md),
              Text(
                'Nenhuma mensagem ainda. Envie a primeira.',
                style: TipografiaApp.bodyMedium.copyWith(
                  color: CoresApp.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
        vertical: EspacamentosApp.sm,
      ),
      itemCount: _mensagens.length + (_temMaisHistorico ? 1 : 0),
      itemBuilder: (context, index) {
        if (_temMaisHistorico) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
              child: Center(
                child: _carregandoMaisHistorico
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CoresApp.primary,
                        ),
                      )
                    : TextButton(
                        onPressed: _carregarMensagensAnteriores,
                        style: TextButton.styleFrom(
                          foregroundColor: CoresApp.primary,
                          textStyle: TipografiaApp.captionBold,
                        ),
                        child: const Text('Carregar mensagens anteriores'),
                      ),
              ),
            );
          }
          return _construirItemMensagem(index - 1);
        }
        return _construirItemMensagem(index);
      },
    );
  }

  Widget _construirItemMensagem(int index) {
    final msg = _mensagens[index];
    final bool exibirSeparador;
    if (index == 0) {
      exibirSeparador = true;
    } else {
      final msgAnterior = _mensagens[index - 1];
      exibirSeparador = !_ehMesmoDia(msg.criadoEm, msgAnterior.criadoEm);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exibirSeparador)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.sm),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.sm,
                  vertical: EspacamentosApp.xs,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.surfaceSoft,
                  borderRadius:
                      BorderRadius.circular(EspacamentosApp.radiusFull),
                  border: Border.all(color: CoresApp.divider),
                ),
                child: Text(
                  _formatarSeparadorData(msg.criadoEm),
                  style: TipografiaApp.caption.copyWith(
                    color: CoresApp.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        BolhaMensagem(
          mensagem: msg,
          exibirNomeRemetente: _exibirNomeRemetente,
        ),
        const SizedBox(height: EspacamentosApp.xs),
      ],
    );
  }

  Widget _construirFaixaErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md,
        vertical: EspacamentosApp.sm,
      ),
      color: CoresApp.statusCancelled.withAlpha(24),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: CoresApp.statusCancelled,
            size: 18,
          ),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Text(
              _faixaErro!,
              style: TipografiaApp.caption.copyWith(
                color: CoresApp.statusCancelled,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 16,
              color: CoresApp.statusCancelled,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _faixaErro = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _construirCampoEnvio() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
        vertical: EspacamentosApp.sm,
      ),
      decoration: const BoxDecoration(
        color: CoresApp.surface,
        border: Border(
          top: BorderSide(color: CoresApp.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textoController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TipografiaApp.body,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: TipografiaApp.bodySmall,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.md,
                  vertical: EspacamentosApp.sm,
                ),
                filled: true,
                fillColor: CoresApp.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: EspacamentosApp.sm),
          IconButton.filled(
            onPressed: (_textoValido && !_enviando) ? _enviarMensagem : null,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CoresApp.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: CoresApp.primary,
              foregroundColor: CoresApp.textOnPrimary,
              disabledBackgroundColor: CoresApp.divider,
              disabledForegroundColor: CoresApp.iconDefault,
            ),
          ),
        ],
      ),
    );
  }
}

