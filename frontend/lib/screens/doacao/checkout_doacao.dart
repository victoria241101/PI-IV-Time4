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
  String _formaPagamento = 'Pix';

  bool _processando = false;

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _confirmarDoacao() async {
    setState(() {
      _processando = true;
    });

    // Simulação de processamento do pagamento.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _processando = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmacaoDoacao(
          nomeAnimal: widget.nomeAnimal,
          titulo: widget.titulo,
          valorDoacao: widget.valorDoacao,
        ),
      ),
    );
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
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            EspacamentosApp.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revise sua doação',
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
                'Confira os detalhes antes de confirmar sua contribuição.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              _ResumoCampanha(
                nomeAnimal: widget.nomeAnimal,
                titulo: widget.titulo,
                valor: widget.valorDoacao,
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              const Text(
                'Forma de pagamento',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              _OpcaoPagamento(
                titulo: 'Pix',
                subtitulo: 'Pagamento instantâneo',
                icone: Icons.pix_rounded,
                selecionado: _formaPagamento == 'Pix',
                onTap: () {
                  setState(() {
                    _formaPagamento = 'Pix';
                  });
                },
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              _OpcaoPagamento(
                titulo: 'Cartão',
                subtitulo: 'Crédito ou débito',
                icone: Icons.credit_card_rounded,
                selecionado: _formaPagamento == 'Cartão',
                onTap: () {
                  setState(() {
                    _formaPagamento = 'Cartão';
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
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CoresApp.primary.withAlpha(35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: CoresApp.primary,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta etapa é uma simulação para o projeto PetCare. Nenhuma cobrança real será realizada.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
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

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _processando
                      ? null
                      : _confirmarDoacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    CoresApp.darkBlue.withAlpha(120),
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
                      : Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirmar doação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatarValor(widget.valorDoacao),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
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
    required this.valor,
  });

  final String nomeAnimal;
  final String titulo;
  final double valor;

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        EspacamentosApp.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withAlpha(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: CoresApp.primary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: EspacamentosApp.md,
          ),

          Divider(
            color: Colors.grey.withAlpha(35),
            height: 1,
          ),

          const SizedBox(
            height: EspacamentosApp.md,
          ),

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
                _formatarValor(valor),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcaoPagamento extends StatelessWidget {
  const _OpcaoPagamento({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.selecionado,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
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
              ? CoresApp.primary.withAlpha(18)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado
                ? CoresApp.primary
                : Colors.grey.withAlpha(45),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selecionado
                    ? CoresApp.primary
                    : CoresApp.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icone,
                color: selecionado
                    ? Colors.white
                    : CoresApp.darkBlue,
                size: 22,
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
                      fontWeight: FontWeight.w800,
                      color: CoresApp.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selecionado
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selecionado
                  ? CoresApp.primary
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}