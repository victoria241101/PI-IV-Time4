import 'dart:async';
import 'package:flutter/material.dart';

import 'package:pet_care/core/api_exception.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/chat/contato_chat_modelo.dart';
import 'package:pet_care/services/chat_service.dart';

/// Modal bottom sheet para seleção de contato e início de nova conversa.
class SeletorContato extends StatefulWidget {
  final ChatService servico;

  const SeletorContato({
    super.key,
    required this.servico,
  });

  @override
  State<SeletorContato> createState() => _SeletorContatoState();
}

class _SeletorContatoState extends State<SeletorContato> {
  final TextEditingController _buscaController = TextEditingController();
  Timer? _debounceTimer;

  List<ContatoChat> _contatos = [];
  bool _carregando = true;
  String? _erroCarregamento;
  String? _mensagemErroAcao;
  String? _contatoAberturaId;

  @override
  void initState() {
    super.initState();
    _carregarContatos();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _onBuscaAlterada(String valor) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _carregarContatos(busca: valor.trim());
      }
    });
  }

  Future<void> _carregarContatos({String? busca}) async {
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final lista = await widget.servico.listarContatos(busca: busca);
      if (!mounted) return;
      setState(() {
        _contatos = lista;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCarregamento = e.mensagem;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erroCarregamento = 'Falha ao carregar contatos.';
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarContato(ContatoChat contato) async {
    final idChave = contato.ehSecretaria ? 'secretaria' : (contato.usuarioId ?? '');
    setState(() {
      _contatoAberturaId = idChave;
      _mensagemErroAcao = null;
    });

    try {
      final conversaAberta = await widget.servico.abrirConversa(
        secretaria: contato.ehSecretaria,
        usuarioId: contato.usuarioId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(conversaAberta);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _contatoAberturaId = null;
        _mensagemErroAcao = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contatoAberturaId = null;
        _mensagemErroAcao = 'Não foi possível iniciar a conversa.';
      });
    }
  }

  String _descricaoPapel(ContatoChat contato) {
    if (contato.ehSecretaria) return 'Secretaria';
    final papel = contato.papel;
    if (papel == null || papel.isEmpty) return '';
    switch (papel.toUpperCase()) {
      case 'USUARIO':
        return 'Tutor';
      case 'VETERINARIO':
        return 'Veterinário(a)';
      case 'ENFERMEIRO':
        return 'Enfermeiro(a)';
      case 'SECRETARIA':
        return 'Secretaria';
      default:
        return papel;
    }
  }

  Widget _iconeContato(ContatoChat contato) {
    IconData icone;
    Color cor;
    if (contato.ehSecretaria) {
      icone = Icons.support_agent_rounded;
      cor = CoresApp.primary;
    } else {
      switch (contato.papel?.toUpperCase()) {
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
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EspacamentosApp.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md + viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CoresApp.divider,
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusSm),
                ),
              ),
            ),
            const SizedBox(height: EspacamentosApp.md),
            Row(
              children: [
                Text(
                  'Nova conversa',
                  style: TipografiaApp.heading3,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close_rounded, color: CoresApp.iconDefault),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.sm),
            TextField(
              controller: _buscaController,
              onChanged: _onBuscaAlterada,
              decoration: InputDecoration(
                hintText: 'Buscar contato...',
                hintStyle: TipografiaApp.bodySmall,
                prefixIcon: const Icon(Icons.search, color: CoresApp.iconDefault),
                suffixIcon: _buscaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: CoresApp.iconDefault),
                        onPressed: () {
                          _buscaController.clear();
                          _onBuscaAlterada('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: CoresApp.surfaceSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.md,
                  vertical: EspacamentosApp.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                  borderSide: const BorderSide(color: CoresApp.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                  borderSide: const BorderSide(color: CoresApp.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                  borderSide: const BorderSide(color: CoresApp.primary),
                ),
              ),
            ),
            if (_mensagemErroAcao != null) ...[
              const SizedBox(height: EspacamentosApp.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EspacamentosApp.sm + 2),
                decoration: BoxDecoration(
                  color: CoresApp.statusCancelled.withAlpha(20),
                  borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                  border: Border.all(
                    color: CoresApp.statusCancelled.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: CoresApp.statusCancelled,
                      size: 20,
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Expanded(
                      child: Text(
                        _mensagemErroAcao!,
                        style: TipografiaApp.captionBold.copyWith(
                          color: CoresApp.statusCancelled,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: EspacamentosApp.md),
            Expanded(
              child: _construirConteudo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: CoresApp.primary),
      );
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _erroCarregamento!,
              textAlign: TextAlign.center,
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.statusCancelled,
              ),
            ),
            const SizedBox(height: EspacamentosApp.sm),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CoresApp.primary,
                foregroundColor: CoresApp.textOnPrimary,
              ),
              onPressed: () => _carregarContatos(busca: _buscaController.text.trim()),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_contatos.isEmpty) {
      return Center(
        child: Text(
          'Nenhum contato encontrado.',
          style: TipografiaApp.bodySmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: _contatos.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: CoresApp.divider,
      ),
      itemBuilder: (context, index) {
        final contato = _contatos[index];
        final idChave = contato.ehSecretaria ? 'secretaria' : (contato.usuarioId ?? '');
        final selecionado = _contatoAberturaId == idChave;

        return ListTile(
          onTap: _contatoAberturaId != null ? null : () => _selecionarContato(contato),
          leading: _iconeContato(contato),
          title: Text(
            contato.nome,
            style: TipografiaApp.bodyMedium,
          ),
          subtitle: Text(
            _descricaoPapel(contato),
            style: TipografiaApp.caption,
          ),
          trailing: selecionado
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CoresApp.primary,
                  ),
                )
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: CoresApp.iconDefault,
                ),
        );
      },
    );
  }
}

