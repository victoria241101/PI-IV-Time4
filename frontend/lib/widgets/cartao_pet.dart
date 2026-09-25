import 'package:flutter/material.dart';

import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';

/// Cartão resumido de pet no começo do home tutor

class CartaoPet extends StatelessWidget {
  const CartaoPet({
    super.key,
    required this.pet,
    required this.largura,
    this.onTap,
  });

  final ResumoPet pet;
  final double largura;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: largura,
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.md - 4,
          vertical: EspacamentosApp.sm,
        ),
        decoration: BoxDecoration(
          color: CoresApp.surface,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusXxl),
          boxShadow: EspacamentosApp.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: CoresApp.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: pet.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        pet.photoUrl!,
                        fit: BoxFit.cover,
                        width: 52,
                        height: 52,
                        errorBuilder: (_, _, _) => _iconePet(),
                      ),
                    )
                  : _iconePet(),
            ),
            const SizedBox(width: EspacamentosApp.md - 4),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pet.name,
                    style: TipografiaApp.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _raca,
                    style: TipografiaApp.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _idadeEPeso,
                    style: TipografiaApp.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconePet() {
    return Icon(
      Icons.pets_rounded,
      size: 22,
      color: CoresApp.primary,
      semanticLabel: pet.name,
    );
  }

  String get _raca => pet.breed ?? pet.species;

  String get _idadeEPeso {
    final parts = <String>[];
    if (pet.age != null) {
      parts.add(pet.age!);
    }
    if (pet.weight != null) {
      final peso = pet.weight! % 1 == 0
          ? pet.weight!.toStringAsFixed(0)
          : pet.weight!.toStringAsFixed(1).replaceAll('.', ',');
      parts.add('$peso kg');
    }
    return parts.join(' • ');
  }
}
