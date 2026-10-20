// conversas da recepção com a equipe da clínica
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';

class ChatRecepcao extends StatefulWidget {
  const ChatRecepcao({super.key});

  @override
  State<ChatRecepcao> createState() => _ChatRecepcaoState();
}

class _ChatRecepcaoState extends State<ChatRecepcao> {
  final _conversas = <_Conversa>[
    _Conversa(
      nome: 'Recepção',
      descricao: 'Canal da equipe de recepção',
      icone: Icons.people_alt_outlined,
      cor: CoresApp.primary,
      mensagens: [
        _Mensagem('Bom dia! A sala 01 está liberada', false),
        _Mensagem('Obrigada, vou encaminhar o próximo paciente', true),
      ],
    ),
    _Conversa(
      nome: 'Dra. Camila',
      descricao: 'Veterinária',
      icone: Icons.medical_services_outlined,
      cor: CoresApp.darkBlue,
      mensagens: [
        _Mensagem('Pode encaminhar o próximo da fila', false),
        _Mensagem('Max já está em atendimento na sala 02', true),
      ],
    ),
    _Conversa(
      nome: 'Dr. Silva',
      descricao: 'Veterinário',
      icone: Icons.medical_services_outlined,
      cor: CoresApp.darkBlue,
      mensagens: [_Mensagem('Me avise quando o tutor do Oliver chegar', false)],
    ),
    _Conversa(
      nome: 'Dra. Beatriz',
      descricao: 'Veterinária',
      icone: Icons.medical_services_outlined,
      cor: CoresApp.darkBlue,
      mensagens: [
        _Mensagem(
          'Consulta da Bella finalizada · prontuário atualizado',
          false,
        ),
      ],
    ),
  ];

  _Conversa? _conversaSelecionada;
  final _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversa = _conversaSelecionada;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
      ),
      child: conversa == null ? _listaConversas() : _abrirConversa(conversa),
    );
  }

  Widget _listaConversas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chat da equipe', style: TipografiaApp.heading2),
        const SizedBox(height: EspacamentosApp.xs),
        Text(
          'Fale com a recepção e com os veterinários',
          style: TipografiaApp.bodySmall,
        ),
        const SizedBox(height: EspacamentosApp.md),
        Expanded(
          child: ListView.separated(
            itemCount: _conversas.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: EspacamentosApp.sm),
            itemBuilder: (context, index) {
              final conversa = _conversas[index];
              final ultimaMensagem = conversa.mensagens.isEmpty
                  ? 'Comece uma conversa'
                  : conversa.mensagens.last.texto;
              return InkWell(
                onTap: () => setState(() => _conversaSelecionada = conversa),
                borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
                child: CartaoBase(
                  padding: const EdgeInsets.all(EspacamentosApp.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: conversa.cor.withAlpha(24),
                        child: Icon(conversa.icone, color: conversa.cor),
                      ),
                      const SizedBox(width: EspacamentosApp.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversa.nome,
                              style: TipografiaApp.bodyMedium,
                            ),
                            Text(
                              conversa.descricao,
                              style: TipografiaApp.caption,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ultimaMensagem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TipografiaApp.caption.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: CoresApp.iconDefault,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _abrirConversa(_Conversa conversa) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Voltar às conversas',
              onPressed: () => setState(() => _conversaSelecionada = null),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: conversa.cor.withAlpha(24),
              child: Icon(conversa.icone, color: conversa.cor, size: 18),
            ),
            const SizedBox(width: EspacamentosApp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conversa.nome, style: TipografiaApp.bodyMedium),
                  Text(conversa.descricao, style: TipografiaApp.caption),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: EspacamentosApp.md),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.sm),
            itemCount: conversa.mensagens.length,
            itemBuilder: (context, index) => _bolha(conversa.mensagens[index]),
          ),
        ),
        const SizedBox(height: EspacamentosApp.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _mensagemController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(conversa),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem',
                  hintStyle: TipografiaApp.bodySmall,
                  filled: true,
                  fillColor: CoresApp.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: EspacamentosApp.md,
                    vertical: EspacamentosApp.sm + 2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      EspacamentosApp.radiusFull,
                    ),
                    borderSide: const BorderSide(color: CoresApp.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      EspacamentosApp.radiusFull,
                    ),
                    borderSide: const BorderSide(color: CoresApp.divider),
                  ),
                ),
              ),
            ),
            const SizedBox(width: EspacamentosApp.xs),
            IconButton.filled(
              tooltip: 'Enviar mensagem',
              onPressed: () => _enviar(conversa),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bolha(_Mensagem mensagem) {
    return Align(
      alignment: mensagem.enviada
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: EspacamentosApp.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.md,
          vertical: EspacamentosApp.sm,
        ),
        decoration: BoxDecoration(
          color: mensagem.enviada ? const Color(0xFFDDF7F4) : CoresApp.surface,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
          border: Border.all(
            color: mensagem.enviada
                ? CoresApp.primary.withAlpha(35)
                : CoresApp.divider,
          ),
        ),
        child: Text(mensagem.texto, style: TipografiaApp.bodySmall),
      ),
    );
  }

  void _enviar(_Conversa conversa) {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      conversa.mensagens.add(_Mensagem(texto, true));
      _mensagemController.clear();
    });
  }
}

class _Conversa {
  _Conversa({
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.cor,
    required this.mensagens,
  });

  final String nome;
  final String descricao;
  final IconData icone;
  final Color cor;
  final List<_Mensagem> mensagens;
}

class _Mensagem {
  const _Mensagem(this.texto, this.enviada);

  final String texto;
  final bool enviada;
}
