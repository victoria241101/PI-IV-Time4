import 'package:flutter/material.dart';

import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/widgets/cartao_pet.dart';

/// Lista deslizável de pets
///
/// Recebe uma lista de [ResumoPet] e callbacks.
class ListaHorizontalPets extends StatelessWidget {
  const ListaHorizontalPets({super.key, required this.pets, this.onPetTap});

  final List<ResumoPet> pets;
  final void Function(ResumoPet pet)? onPetTap;

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.sizeOf(context).width;
    final larguraCartao = (larguraTela * 0.66).clamp(225.0, 270.0);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.pagePadding,
        ),
        itemCount: pets.length,
        separatorBuilder: (_, _) => const SizedBox(width: EspacamentosApp.md),
        itemBuilder: (context, index) {
          final pet = pets[index];
          return CartaoPet(
            pet: pet,
            largura: larguraCartao,
            onTap: onPetTap != null ? () => onPetTap!(pet) : null,
          );
        },
      ),
    );
  }
}
