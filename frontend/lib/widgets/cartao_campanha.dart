import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class CartaoCampanha extends StatelessWidget {
  const CartaoCampanha({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorArrecadado,
    required this.meta,
    this.urgente = false,
    this.onTap,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorArrecadado;
  final double meta;
  final bool urgente;
  final VoidCallback? onTap;

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
          _ImagemCampanha(
            urgente: urgente,
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
                    color: Colors.black54,
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

                const SizedBox(height: EspacamentosApp.lg),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatarValor(valorArrecadado)} arrecadados',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Meta: ${_formatarValor(meta)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CoresApp.primary,
                    ),
                  ),
                ),

                const SizedBox(height: EspacamentosApp.xs),

                Text(
                  '$porcentagem% da meta alcançada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: EspacamentosApp.lg),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.volunteer_activism_outlined,
                    ),
                    label: const Text('Quero ajudar'),
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

class _ImagemCampanha extends StatelessWidget {
  const _ImagemCampanha({
    required this.urgente,
  });

  final bool urgente;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: CoresApp.background,
            child: const Center(
              child: Icon(
                Icons.pets_rounded,
                size: 56,
              ),
            ),
          ),

          if (urgente)
            Positioned(
              top: EspacamentosApp.md,
              right: EspacamentosApp.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.md,
                  vertical: EspacamentosApp.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Urgente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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