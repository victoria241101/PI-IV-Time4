import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/doacao/checkout_doacao.dart';

class Doar extends StatefulWidget {
  const Doar({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.meta,
  });

  final String nomeAnimal;
  final String titulo;
  final double meta;

  @override
  State<Doar> createState() => _DoarState();
}

class _DoarState extends State<Doar> {
  final TextEditingController _valorController = TextEditingController();

  double? _valorSelecionado;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  void _selecionarValor(double valor) {
    setState(() {
      _valorSelecionado = valor;
      _valorController.text = valor.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  double? _obterValor() {
    final texto = _valorController.text.trim();

    if (texto.isEmpty) {
      return null;
    }

    final valor = double.tryParse(
      texto.replaceAll('.', '').replaceAll(',', '.'),
    );

    return valor;
  }

  void _continuar() {
    final valor = _obterValor();

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um valor válido para continuar.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutDoacao(
          nomeAnimal: widget.nomeAnimal,
          titulo: widget.titulo,
          meta: widget.meta,
          valorDoacao: valor,
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CoresApp.darkBlue,
          ),
        ),
        title: const Text(
          'Fazer uma doação',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            EspacamentosApp.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  EspacamentosApp.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CoresApp.primary.withAlpha(35),
                  ),
                ),
                child: Row(
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
                        size: 25,
                      ),
                    ),
                    const SizedBox(
                      width: EspacamentosApp.md,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomeAnimal,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CoresApp.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.titulo,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CoresApp.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              const Text(
                'Escolha o valor da sua doação',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xs,
              ),

              const Text(
                'Cada contribuição ajuda a transformar o cuidado em recuperação.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              const Text(
                'Valor da doação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              TextField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9,.]'),
                  ),
                ],
                onChanged: (_) {
                  if (_valorSelecionado != null) {
                    setState(() {
                      _valorSelecionado = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withAlpha(40),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.withAlpha(40),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: CoresApp.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.lg,
              ),

              const Text(
                'Ou escolha um valor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              Wrap(
                spacing: EspacamentosApp.sm,
                runSpacing: EspacamentosApp.sm,
                children: [
                  _ValorSugestao(
                    valor: 20,
                    selecionado: _valorSelecionado == 20,
                    onPressed: () => _selecionarValor(20),
                  ),
                  _ValorSugestao(
                    valor: 50,
                    selecionado: _valorSelecionado == 50,
                    onPressed: () => _selecionarValor(50),
                  ),
                  _ValorSugestao(
                    valor: 100,
                    selecionado: _valorSelecionado == 100,
                    onPressed: () => _selecionarValor(100),
                  ),
                  _ValorSugestao(
                    valor: 200,
                    selecionado: _valorSelecionado == 200,
                    onPressed: () => _selecionarValor(200),
                  ),
                ],
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(
                  EspacamentosApp.md,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: CoresApp.primary,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sua contribuição será destinada à campanha selecionada.',
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
                height: EspacamentosApp.md,
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
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
      ),
    );
  }
}

class _ValorSugestao extends StatelessWidget {
  const _ValorSugestao({
    required this.valor,
    required this.selecionado,
    required this.onPressed,
  });

  final double valor;
  final bool selecionado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor:
        selecionado ? Colors.white : CoresApp.darkBlue,
        backgroundColor:
        selecionado ? CoresApp.primary : Colors.white,
        side: BorderSide(
          color: selecionado
              ? CoresApp.primary
              : CoresApp.darkBlue.withAlpha(80),
          width: selecionado ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Text(
        'R\$ ${valor.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}