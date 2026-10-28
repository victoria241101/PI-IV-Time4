
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class ConfirmacaoDoacao extends StatelessWidget {
  const ConfirmacaoDoacao({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorDoacao,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorDoacao;

  static const Color _laranja = CoresApp.accentOrange;
  static const Color _creme = Color(0xFFFFF2E5);

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

  void _voltarParaCampanhas(BuildContext context) {
    // Retorna à primeira rota do fluxo atual.
    // Assim, evita voltar à tela de valor ou ao checkout.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(
                EspacamentosApp.pagePadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      EspacamentosApp.pagePadding * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: EspacamentosApp.md),

                      const _EtapaDoacao(),

                      const Spacer(),

                      // ÍCONE DE CONCLUSÃO

                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: _laranja.withAlpha(24),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: CoresApp.darkBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 53,
                          ),
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.xl),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _creme,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: _laranja,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ETAPA CONCLUÍDA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: _laranja,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.md),

                      const Text(
                        'Tudo pronto!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          color: CoresApp.darkBlue,
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.sm),

                      const Text(
                        'Você percorreu todas as etapas do fluxo '
                            'demonstrativo de doação do PetCare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: CoresApp.textSecondary,
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.xl),

                      // RESUMO

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          EspacamentosApp.lg,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: CoresApp.darkBlue.withAlpha(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CoresApp.darkBlue.withAlpha(8),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VALOR INFORMADO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: CoresApp.textSecondary,
                              ),
                            ),

                            const SizedBox(height: EspacamentosApp.xs),

                            Text(
                              _formatarValor(valorDoacao),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                color: CoresApp.darkBlue,
                              ),
                            ),

                            const SizedBox(height: EspacamentosApp.lg),

                            Divider(
                              height: 1,
                              color: Colors.black.withAlpha(12),
                            ),

                            const SizedBox(height: EspacamentosApp.lg),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _creme,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    size: 29,
                                    color: _laranja,
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
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: CoresApp.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.lg),

                      // AVISO DE TRANSPARÊNCIA

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          EspacamentosApp.md,
                        ),
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
                                    'Confirmação demonstrativa',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: CoresApp.darkBlue,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Nenhum pagamento real foi processado '
                                        'e nenhuma cobrança foi realizada. '
                                        'O valor acima representa apenas o '
                                        'valor informado durante o teste.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.55,
                                      color: CoresApp.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      const SizedBox(height: EspacamentosApp.xl),

                      // VOLTAR ÀS CAMPANHAS

                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton.icon(
                          onPressed: () => _voltarParaCampanhas(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CoresApp.darkBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Voltar às campanhas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: EspacamentosApp.sm),

                      TextButton(
                        onPressed: () => Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                        ),
                        child: const Text(
                          'Voltar ao início do aplicativo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CoresApp.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            estado: _EstadoEtapa.concluida,
          ),
        ),
        _ConectorEtapa(concluido: true),
        Expanded(
          child: _ItemEtapa(
            numero: '3',
            titulo: 'Confirmação',
            estado: _EstadoEtapa.atual,
          ),
        ),
      ],
    );
  }
}

enum _EstadoEtapa {
  atual,
  concluida,
  futura,
}

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
            color: ativa
                ? CoresApp.accentOrange
                : Colors.white,
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
