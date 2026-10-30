
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/doacao/confirmacao_doacao.dart';

class CheckoutDoacao extends StatefulWidget {
  const CheckoutDoacao({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.meta,
    required this.valorDoacao,
  });

  final String nomeAnimal;
  final String titulo;
  final double meta;
  final double valorDoacao;

  @override
  State<CheckoutDoacao> createState() => _CheckoutDoacaoState();
}

class _CheckoutDoacaoState extends State<CheckoutDoacao> {
  static const Color _laranja = CoresApp.accentOrange;
  static const Color _creme = Color(0xFFFFF2E5);

  String _formaPagamento = 'pix';
  bool _processando = false;

  String _formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();

    for (var i = 0; i < inteiro.length; i++) {
      buffer.write(inteiro[i]);

      final restantes = inteiro.length - i - 1;

      if (restantes > 0 && restantes % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  Future<void> _confirmarDoacao() async {
    if (_processando) return;

    setState(() {
      _processando = true;
    });

    // Demonstração do fluxo. Nenhuma cobrança é realizada.
    await Future<void>.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ConfirmacaoDoacao(
          nomeAnimal: widget.nomeAnimal,
          titulo: widget.titulo,
          valorDoacao: widget.valorDoacao,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _processando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _processando
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CoresApp.darkBlue,
          ),
        ),
        title: const Text(
          'Revisar doação',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.sm,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EtapaDoacao(),

              const SizedBox(height: EspacamentosApp.xl),

              const Text(
                'Confira os detalhes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xs),

              const Text(
                'Revise sua contribuição e escolha uma forma de pagamento.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              _ResumoCampanha(
                nomeAnimal: widget.nomeAnimal,
                titulo: widget.titulo,
                valorDoacao: widget.valorDoacao,
                formatarValor: _formatarValor,
              ),

              const SizedBox(height: EspacamentosApp.xl),

              const Text(
                'Forma de pagamento',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xs),

              const Text(
                'Selecione uma opção para continuar.',
                style: TextStyle(
                  fontSize: 13,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              _OpcaoPagamento(
                titulo: 'Pix',
                descricao: 'Pagamento instantâneo',
                detalhe: 'Seleção demonstrativa',
                icone: Icons.pix_rounded,
                selecionado: _formaPagamento == 'pix',
                onTap: _processando
                    ? null
                    : () {
                  setState(() {
                    _formaPagamento = 'pix';
                  });
                },
              ),

              const SizedBox(height: EspacamentosApp.sm),

              _OpcaoPagamento(
                titulo: 'Cartão',
                descricao: 'Crédito ou débito',
                detalhe: 'Seleção demonstrativa',
                icone: Icons.credit_card_rounded,
                selecionado: _formaPagamento == 'cartao',
                onTap: _processando
                    ? null
                    : () {
                  setState(() {
                    _formaPagamento = 'cartao';
                  });
                },
              ),

              const SizedBox(height: EspacamentosApp.lg),

              // AVISO DO MVP

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EspacamentosApp.md),
                decoration: BoxDecoration(
                  color: _creme,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _laranja.withAlpha(45),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _laranja,
                      size: 22,
                    ),
                    SizedBox(width: EspacamentosApp.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pagamento demonstrativo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CoresApp.darkBlue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'O Pix e o cartão ainda não estão integrados '
                                'a um serviço de pagamento. Continuar exibirá '
                                'a confirmação do fluxo de teste, sem cobrança.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // TOTAL

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EspacamentosApp.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _laranja.withAlpha(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _laranja.withAlpha(10),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total da contribuição',
                            style: TextStyle(
                              fontSize: 14,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          _formatarValor(widget.valorDoacao),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: CoresApp.darkBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    Divider(
                      height: 1,
                      color: Colors.black.withAlpha(12),
                    ),

                    const SizedBox(height: EspacamentosApp.md),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: _laranja,
                          size: 20,
                        ),
                        const SizedBox(width: EspacamentosApp.sm),
                        Expanded(
                          child: Text(
                            'Sua contribuição está associada à campanha '
                                'de ${widget.nomeAnimal}.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    SizedBox(
                      width: double.infinity,
                      height: 57,
                      child: ElevatedButton(
                        onPressed:
                        _processando ? null : _confirmarDoacao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CoresApp.darkBlue,
                          disabledBackgroundColor:
                          CoresApp.darkBlue.withAlpha(150),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: _processando
                            ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: EspacamentosApp.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              const Center(
                child: Text(
                  'Nenhum valor real será cobrado nesta demonstração.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// INDICADOR DAS ETAPAS
// =====================================================

class _EtapaDoacao extends StatelessWidget {
  const _EtapaDoacao();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ItemEtapa(
            numero: '1',
            titulo: 'Doação',
            estado: _EstadoEtapa.concluida,
          ),
        ),
        _ConectorEtapa(concluido: true),
        Expanded(
          child: _ItemEtapa(
            numero: '2',
            titulo: 'Revisão',
            estado: _EstadoEtapa.atual,
          ),
        ),
        _ConectorEtapa(),
        Expanded(
          child: _ItemEtapa(
            numero: '3',
            titulo: 'Confirmação',
            estado: _EstadoEtapa.futura,
          ),
        ),
      ],
    );
  }
}

enum _EstadoEtapa { atual, concluida, futura }

class _ItemEtapa extends StatelessWidget {
  const _ItemEtapa({
    required this.numero,
    required this.titulo,
    required this.estado,
  });

  final String numero;
  final String titulo;
  final _EstadoEtapa estado;

  @override
  Widget build(BuildContext context) {
    final ativa = estado != _EstadoEtapa.futura;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativa ? CoresApp.accentOrange : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: ativa
                  ? CoresApp.accentOrange
                  : Colors.black.withAlpha(28),
              width: 1.5,
            ),
          ),
          child: estado == _EstadoEtapa.concluida
              ? const Icon(
            Icons.check_rounded,
            size: 19,
            color: Colors.white,
          )
              : Text(
            numero,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ativa
                  ? Colors.white
                  : CoresApp.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: ativa ? FontWeight.w800 : FontWeight.w600,
            color: ativa
                ? CoresApp.darkBlue
                : CoresApp.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ConectorEtapa extends StatelessWidget {
  const _ConectorEtapa({
    this.concluido = false,
  });

  final bool concluido;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: 17,
        height: 2,
        color: concluido
            ? CoresApp.accentOrange
            : Colors.black.withAlpha(22),
      ),
    );
  }
}

// =====================================================
// RESUMO DA CAMPANHA
// =====================================================

class _ResumoCampanha extends StatelessWidget {
  const _ResumoCampanha({
    required this.nomeAnimal,
    required this.titulo,
    required this.valorDoacao,
    required this.formatarValor,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorDoacao;
  final String Function(double) formatarValor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: CoresApp.accentOrange.withAlpha(35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: CoresApp.accentOrange,
              size: 29,
            ),
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeAnimal,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.sm),
                Text(
                  formatarValor(valorDoacao),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.accentOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// OPÇÕES DE PAGAMENTO
// =====================================================

class _OpcaoPagamento extends StatelessWidget {
  const _OpcaoPagamento({
    required this.titulo,
    required this.descricao,
    required this.detalhe,
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final String descricao;
  final String detalhe;
  final IconData icone;
  final bool selecionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const laranja = CoresApp.accentOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(EspacamentosApp.md),
          decoration: BoxDecoration(
            color: selecionado
                ? const Color(0xFFFFF7EF)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selecionado
                  ? laranja
                  : Colors.black.withAlpha(15),
              width: selecionado ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selecionado
                      ? laranja.withAlpha(22)
                      : CoresApp.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icone,
                  color: selecionado
                      ? laranja
                      : CoresApp.textSecondary,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descricao,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalhe,
                      style: const TextStyle(
                        fontSize: 10,
                        color: laranja,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selecionado ? laranja : Colors.transparent,
                  border: Border.all(
                    color: selecionado
                        ? laranja
                        : CoresApp.textSecondary.withAlpha(90),
                    width: 1.7,
                  ),
                ),
                child: selecionado
                    ? const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
