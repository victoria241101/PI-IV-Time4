
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
  static const Color _laranja = CoresApp.accentOrange;
  static const Color _creme = Color(0xFFFFF2E5);

  final TextEditingController _valorController =
  TextEditingController();

  final FocusNode _valorFocusNode = FocusNode();

  double? _valorSelecionado;

  @override
  void dispose() {
    _valorController.dispose();
    _valorFocusNode.dispose();
    super.dispose();
  }

  // =====================================================
  // FORMATAÇÃO
  // =====================================================

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

  // =====================================================
  // SELEÇÃO DOS VALORES SUGERIDOS
  // =====================================================

  void _selecionarValor(double valor) {
    _valorFocusNode.unfocus();

    setState(() {
      _valorSelecionado = valor;
      _valorController.text =
          valor.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  // =====================================================
  // VALIDAÇÃO DO VALOR
  // =====================================================

  double? _obterValor() {
    var texto = _valorController.text
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (texto.isEmpty) return null;

    final ultimaVirgula = texto.lastIndexOf(',');
    final ultimoPonto = texto.lastIndexOf('.');

    if (ultimaVirgula >= 0 && ultimoPonto >= 0) {
      if (ultimaVirgula > ultimoPonto) {
        texto = texto.replaceAll('.', '').replaceAll(',', '.');
      } else {
        texto = texto.replaceAll(',', '');
      }
    } else if (ultimaVirgula >= 0) {
      texto = texto.replaceAll(',', '.');
    }

    final valor = double.tryParse(texto);

    if (valor == null || !valor.isFinite || valor <= 0) {
      return null;
    }

    if ((valor * 100 - (valor * 100).round()).abs() > 0.000001) {
      return null;
    }

    return valor;
  }

  // =====================================================
  // NAVEGAÇÃO
  // =====================================================

  void _continuar() {
    final valor = _obterValor();

    if (valor == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Informe um valor válido, com até duas casas decimais.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    _valorFocusNode.unfocus();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutDoacao(
          nomeAnimal: widget.nomeAnimal,
          titulo: widget.titulo,
          meta: widget.meta,
          valorDoacao: valor,
        ),
      ),
    );
  }

  // =====================================================
  // TELA
  // =====================================================

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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CoresApp.darkBlue,
          ),
        ),
        title: const Text(
          'Fazer uma doação',
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
            EspacamentosApp.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EtapaDoacao(),

              const SizedBox(height: EspacamentosApp.xl),

              const Text(
                'Faça a diferença',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xs),

              const Text(
                'Escolha quanto deseja contribuir para ajudar '
                    'um animal a receber os cuidados necessários.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // CAMPANHA SELECIONADA

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EspacamentosApp.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _laranja.withAlpha(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CoresApp.darkBlue.withAlpha(8),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _creme,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: _laranja,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomeAnimal,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: CoresApp.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.titulo,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                          const SizedBox(height: EspacamentosApp.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _creme,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Campanha selecionada',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _laranja,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.xs),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _laranja,
                      size: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              // VALOR PERSONALIZADO

              const Text(
                'Qual será o valor da sua doação?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xs),

              const Text(
                'Escolha um valor sugerido ou digite outro.',
                style: TextStyle(
                  fontSize: 13,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              TextField(
                controller: _valorController,
                focusNode: _valorFocusNode,
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
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: EspacamentosApp.md,
                    vertical: 19,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha(20),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: Colors.black.withAlpha(20),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(
                      color: _laranja,
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              const Text(
                'Escolha um valor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              Wrap(
                spacing: EspacamentosApp.sm,
                runSpacing: EspacamentosApp.sm,
                children: [
                  _ValorSugestao(
                    valor: 20,
                    selecionado: _valorSelecionado == 20,
                    formatarValor: _formatarValor,
                    onPressed: () => _selecionarValor(20),
                  ),
                  _ValorSugestao(
                    valor: 50,
                    selecionado: _valorSelecionado == 50,
                    formatarValor: _formatarValor,
                    onPressed: () => _selecionarValor(50),
                  ),
                  _ValorSugestao(
                    valor: 100,
                    selecionado: _valorSelecionado == 100,
                    formatarValor: _formatarValor,
                    onPressed: () => _selecionarValor(100),
                  ),
                  _ValorSugestao(
                    valor: 200,
                    selecionado: _valorSelecionado == 200,
                    formatarValor: _formatarValor,
                    onPressed: () => _selecionarValor(200),
                  ),
                ],
              ),

              const SizedBox(height: EspacamentosApp.xl),

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
                      child: Text(
                        'Você poderá revisar o valor antes de continuar. '
                            'O pagamento ainda é demonstrativo neste MVP; '
                            'nenhum valor real será cobrado.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              SizedBox(
                width: double.infinity,
                height: 57,
                child: ElevatedButton(
                  onPressed: _continuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Revisar doação',
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
      ),
    );
  }
}

// =====================================================
// INDICADOR DE ETAPAS
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
            estado: _EstadoEtapa.atual,
          ),
        ),
        _ConectorEtapa(),
        Expanded(
          child: _ItemEtapa(
            numero: '2',
            titulo: 'Revisão',
            estado: _EstadoEtapa.futura,
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
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
          child: Center(
            child: estado == _EstadoEtapa.concluida
                ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
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
  const _ConectorEtapa();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: 17,
        height: 2,
        color: Colors.black.withAlpha(22),
      ),
    );
  }
}

// =====================================================
// VALORES SUGERIDOS
// =====================================================

class _ValorSugestao extends StatelessWidget {
  const _ValorSugestao({
    required this.valor,
    required this.selecionado,
    required this.formatarValor,
    required this.onPressed,
  });

  final double valor;
  final bool selecionado;
  final String Function(double) formatarValor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const laranja = CoresApp.accentOrange;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selecionado
            ? Colors.white
            : CoresApp.darkBlue,
        backgroundColor: selecionado
            ? laranja
            : Colors.white,
        side: BorderSide(
          color: selecionado
              ? laranja
              : CoresApp.darkBlue.withAlpha(45),
          width: selecionado ? 1.6 : 1,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        formatarValor(valor),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
