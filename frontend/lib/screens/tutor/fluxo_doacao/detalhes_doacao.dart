import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/screens/tutor/doar.dart';

class DetalhesDoacao extends StatelessWidget {
  const DetalhesDoacao({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorArrecadado,
    required this.meta,
    this.urgente = false,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorArrecadado;
  final double meta;
  final bool urgente;

  double get progresso {
    if (meta <= 0) return 0;

    return (valorArrecadado / meta).clamp(0.0, 1.0);
  }

  int get porcentagem => (progresso * 100).round();

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cabecalho(
                onVoltar: () => Navigator.of(context).pop(),
              ),

              _ImagemAnimal(
                urgente: urgente,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: EspacamentosApp.lg),

                    Text(
                      nomeAnimal,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CoresApp.darkBlue,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xs),

                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: CoresApp.darkBlue,
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.lg),

                    _Secao(
                      titulo: 'Sobre o caso',
                      child: Text(
                        'Bobby foi resgatado após sofrer uma lesão '
                            'ortopédica e precisa realizar uma cirurgia para '
                            'garantir sua recuperação e qualidade de vida.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    _Secao(
                      titulo: 'Responsável',
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CoresApp.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: CoresApp.darkBlue,
                            ),
                          ),
                          const SizedBox(
                            width: EspacamentosApp.md,
                          ),
                          const Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dra. Ana Oliveira',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: CoresApp.darkBlue,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Médica-veterinária responsável',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    _Secao(
                      titulo: 'Orçamento',
                      child: Container(
                        padding: const EdgeInsets.all(
                          EspacamentosApp.lg,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _LinhaOrcamento(
                              descricao: 'Cirurgia',
                              valor: 1500,
                            ),
                            const SizedBox(
                              height: EspacamentosApp.md,
                            ),
                            _LinhaOrcamento(
                              descricao: 'Medicamentos',
                              valor: 300,
                            ),
                            const SizedBox(
                              height: EspacamentosApp.md,
                            ),
                            _LinhaOrcamento(
                              descricao: 'Exames',
                              valor: 200,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: EspacamentosApp.md,
                              ),
                              child: Divider(
                                color: CoresApp.divider,
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: CoresApp.darkBlue,
                                  ),
                                ),
                                Text(
                                  _formatarValor(meta),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CoresApp.darkBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    _Secao(
                      titulo: 'Progresso da campanha',
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatarValor(valorArrecadado)} arrecadados',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: CoresApp.darkBlue,
                                ),
                              ),
                              Text(
                                'Meta ${_formatarValor(meta)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CoresApp.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progresso,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                CoresApp.accentOrange,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: EspacamentosApp.xs,
                          ),

                          Text(
                            '$porcentagem% da meta alcançada',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CoresApp.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    _Secao(
                      titulo: 'Atualizações',
                      child: Column(
                        children: [
                          _Atualizacao(
                            data: '02/10/2026',
                            texto:
                            'Bobby realizou os exames necessários '
                                'para a cirurgia.',
                          ),
                          const SizedBox(
                            height: EspacamentosApp.md,
                          ),
                          _Atualizacao(
                            data: '30/09/2026',
                            texto:
                            'A equipe veterinária confirmou a '
                                'necessidade do procedimento.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    _Secao(
                      titulo: 'Apoio recente',
                      child: Column(
                        children: [
                          _ApoioRecente(
                            nome: 'Maria',
                            valor: 50,
                          ),
                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),
                          _ApoioRecente(
                            nome: 'João',
                            valor: 100,
                          ),
                          const SizedBox(
                            height: EspacamentosApp.sm,
                          ),
                          _ApoioRecente(
                            nome: 'Doação anônima',
                            valor: 80,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EspacamentosApp.xl),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Próxima tela: Doar
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CoresApp.darkBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(
                          Icons.volunteer_activism_outlined,
                        ),
                        label: const Text(
                          'Quero ajudar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.onVoltar,
  });

  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.pagePadding,
        vertical: EspacamentosApp.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onVoltar,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CoresApp.darkBlue,
            ),
          ),
          const SizedBox(width: EspacamentosApp.xs),
          const Text(
            'Detalhes da campanha',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CoresApp.darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagemAnimal extends StatelessWidget {
  const _ImagemAnimal({
    required this.urgente,
  });

  final bool urgente;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 230,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: CoresApp.background,
            child: const Icon(
              Icons.pets_rounded,
              size: 72,
              color: CoresApp.darkBlue,
            ),
          ),
          if (urgente)
            Positioned(
              top: EspacamentosApp.md,
              right: EspacamentosApp.pagePadding,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.md,
                  vertical: EspacamentosApp.xs,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.accentOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Urgente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.child,
  });

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
        const SizedBox(height: EspacamentosApp.md),
        child,
      ],
    );
  }
}

class _LinhaOrcamento extends StatelessWidget {
  const _LinhaOrcamento({
    required this.descricao,
    required this.valor,
  });

  final String descricao;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          descricao,
          style: const TextStyle(
            fontSize: 14,
            color: CoresApp.textPrimary,
          ),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CoresApp.darkBlue,
          ),
        ),
      ],
    );
  }
}

class _Atualizacao extends StatelessWidget {
  const _Atualizacao({
    required this.data,
    required this.texto,
  });

  final String data;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: CoresApp.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: CoresApp.textSecondary,
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

class _ApoioRecente extends StatelessWidget {
  const _ApoioRecente({
    required this.nome,
    required this.valor,
  });

  final String nome;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: CoresApp.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            size: 19,
            color: CoresApp.accentOrange,
          ),
        ),
        const SizedBox(width: EspacamentosApp.md),
        Expanded(
          child: Text(
            nome,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
      ],
    );
  }
}