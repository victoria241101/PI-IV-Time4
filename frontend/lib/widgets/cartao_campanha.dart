
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
    this.imagemUrl,
    this.onTap,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorArrecadado;
  final double meta;
  final bool urgente;

  /// URL da imagem do animal.
  /// Pode ser preenchida quando as imagens estiverem disponíveis.
  final String? imagemUrl;

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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagemCampanha(
            urgente: urgente,
            imagemUrl: imagemUrl,
          ),
          Padding(
            padding: const EdgeInsets.all(EspacamentosApp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeAnimal,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: CoresApp.textPrimary,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatarValor(valorArrecadado)} arrecadados',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CoresApp.darkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Flexible(
                      child: Text(
                        'Meta: ${_formatarValor(meta)}',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspacamentosApp.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 9,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CoresApp.accentOrange,
                    ),
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  '$porcentagem% da meta alcançada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoresApp.darkBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.volunteer_activism_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      'Quero ajudar',
                      style: TextStyle(
                        fontSize: 15,
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
    );
  }
}

class _ImagemCampanha extends StatelessWidget {
  const _ImagemCampanha({
    required this.urgente,
    this.imagemUrl,
  });

  final bool urgente;
  final String? imagemUrl;

  @override
  Widget build(BuildContext context) {
    final possuiImagem = imagemUrl != null &&
        imagemUrl!.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (possuiImagem)
            Image.network(
              imagemUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _placeholderImagem();
              },
            )
          else
            _placeholderImagem(),

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
                  color: CoresApp.accentOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
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

  Widget _placeholderImagem() {
    return Container(
      color: CoresApp.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 38,
              color: CoresApp.darkBlue,
            ),
          ),
          const SizedBox(height: EspacamentosApp.sm),
          Text(
            'Foto do animal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
