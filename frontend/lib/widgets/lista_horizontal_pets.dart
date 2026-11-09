import 'package:flutter/material.dart';

import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/cartao_pet.dart';

class ListaHorizontalPets extends StatelessWidget {
  const ListaHorizontalPets({
    super.key,
    required this.pets,
    this.onPetTap,
    this.onAdicionarTap,
  });

  final List<ResumoPet> pets;
  final void Function(ResumoPet pet)? onPetTap;
  final VoidCallback? onAdicionarTap;

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
        itemCount: pets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(
          width: EspacamentosApp.md,
        ),
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _CartaoAdicionarPet(
              largura: larguraCartao,
              onTap: onAdicionarTap,
            );
          }

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

class _CartaoAdicionarPet extends StatelessWidget {
  const _CartaoAdicionarPet({
    required this.largura,
    required this.onTap,
  });

  final double largura;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: largura,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CoresApp.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CoresApp.primary.withAlpha(45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: CoresApp.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar pet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cadastre um novo companheiro',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: CoresApp.textSecondary,
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