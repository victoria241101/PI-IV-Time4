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
  String _formaPagamento = 'pix';
  bool _processando = false;

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _confirmarDoacao() {
    if (_processando) return;

    setState(() {
      _processando = true;
    });

    // Fluxo visual do MVP.
    // O pagamento real será conectado ao backend posteriormente.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ConfirmacaoDoacao(
            nomeAnimal: widget.nomeAnimal,
            titulo: widget.titulo,
            valorDoacao: widget.valorDoacao,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        leading: IconButton(
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
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.sm,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confira os detalhes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xs,
              ),

              const Text(
                'Revise sua contribuição antes de confirmar.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              _ResumoCampanha(
                nomeAnimal: widget.nomeAnimal,
                titulo: widget.titulo,
                valorDoacao: widget.valorDoacao,
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              const Text(
                'Forma de pagamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              _OpcaoPagamento(
                titulo: 'Pix',
                descricao: 'Pagamento instantâneo',
                icone: Icons.pix_rounded,
                selecionado: _formaPagamento == 'pix',
                onTap: () {
                  setState(() {
                    _formaPagamento = 'pix';
                  });
                },
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              _OpcaoPagamento(
                titulo: 'Cartão',
                descricao: 'Crédito ou débito',
                icone: Icons.credit_card_rounded,
                selecionado: _formaPagamento == 'cartao',
                onTap: () {
                  setState(() {
                    _formaPagamento = 'cartao';
                  });
                },
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  EspacamentosApp.md,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CoresApp.primary.withAlpha(25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: CoresApp.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta é uma etapa de demonstração. '
                            'O processamento real do pagamento será '
                            'conectado ao backend posteriormente.',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  EspacamentosApp.lg,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black.withAlpha(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Valor da doação',
                          style: TextStyle(
                            fontSize: 14,
                            color: CoresApp.textSecondary,
                          ),
                        ),
                        Text(
                          _formatarValor(widget.valorDoacao),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CoresApp.darkBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    Divider(
                      height: 1,
                      color: Colors.black.withAlpha(10),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.md,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.volunteer_activism_outlined,
                          color: CoresApp.primary,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sua contribuição ajudará '
                                '${widget.nomeAnimal}.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processando
                      ? null
                      : _confirmarDoacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    disabledBackgroundColor:
                    CoresApp.darkBlue.withAlpha(100),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _processando
                      ? const SizedBox(
                    width: 22,
                    height: 22,
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
                        'Confirmar doação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.check_rounded,
                        size: 20,
                      ),
                    ],
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

class _ResumoCampanha extends StatelessWidget {
  const _ResumoCampanha({
    required this.nomeAnimal,
    required this.titulo,
    required this.valorDoacao,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorDoacao;

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        EspacamentosApp.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withAlpha(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: CoresApp.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: CoresApp.primary,
              size: 30,
            ),
          ),

          const SizedBox(
            width: EspacamentosApp.md,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatarValor(valorDoacao),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CoresApp.primary,
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

class _OpcaoPagamento extends StatelessWidget {
  const _OpcaoPagamento({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(
          EspacamentosApp.md,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? CoresApp.primary.withAlpha(12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado
                ? CoresApp.primary
                : Colors.black.withAlpha(15),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selecionado
                    ? CoresApp.primary.withAlpha(22)
                    : CoresApp.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                color: selecionado
                    ? CoresApp.primary
                    : CoresApp.textSecondary,
              ),
            ),

            const SizedBox(
              width: EspacamentosApp.md,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
                ],
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado
                      ? CoresApp.primary
                      : CoresApp.textSecondary
                      .withAlpha(80),
                  width: 2,
                ),
              ),
              child: selecionado
                  ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: CoresApp.primary,
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}