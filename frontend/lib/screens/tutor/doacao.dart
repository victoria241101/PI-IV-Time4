import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class Doacao extends StatelessWidget {
  const Doacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Doações',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: EspacamentosApp.pagePadding,
            right: EspacamentosApp.pagePadding,
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: EspacamentosApp.sm),

              const Text(
                'Ajude um animal que precisa de cuidados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: EspacamentosApp.xl),

              const Text(
                'Campanhas de doação',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: EspacamentosApp.md),

              _CartaoCampanha(
                imagem: 'assets/images/bobby.jpg',
                nomeAnimal: 'Bobby',
                titulo: 'Cirurgia ortopédica de emergência',
                valorArrecadado: 1280,
                meta: 2000,
              ),

              const SizedBox(height: EspacamentosApp.lg),

              _CartaoCampanha(
                imagem: 'assets/images/luna.jpg',
                nomeAnimal: 'Luna',
                titulo: 'Tratamento veterinário',
                valorArrecadado: 850,
                meta: 1500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoCampanha extends StatelessWidget {
  const _CartaoCampanha({
    required this.imagem,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorArrecadado,
    required this.meta,
  });

  final String imagem;
  final String nomeAnimal;
  final String titulo;
  final double valorArrecadado;
  final double meta;

  double get progresso {
    if (meta <= 0) return 0;

    return (valorArrecadado / meta).clamp(0.0, 1.0);
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.asset(
              imagem,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: CoresApp.background,
                  child: const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(EspacamentosApp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeAnimal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.xs),

                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.md),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatarValor(valorArrecadado),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'de ${_formatarValor(meta)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: EspacamentosApp.sm),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CoresApp.primary,
                    ),
                  ),
                ),

                const SizedBox(height: EspacamentosApp.lg),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Próximo passo:
                      // abrir detalhes da campanha.
                    },
                    child: const Text('Ver campanha'),
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