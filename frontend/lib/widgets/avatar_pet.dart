// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Foto ou representação padrão do pet.
// foto reutilizavel dos pets
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

class AvatarPet extends StatelessWidget {
  const AvatarPet({
    super.key,
    required this.fotoUrl,
    required this.nome,
    this.tamanho = 48,
  });

  final String? fotoUrl;
  final String nome;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    // URL vazia ou nula usa a representação padrão do pet.
    final url = fotoUrl;
    return ClipOval(
      child: url == null || url.isEmpty
          ? _avatarVazio()
          : Image.network(
              url,
              width: tamanho,
              height: tamanho,
              fit: BoxFit.cover,
              semanticLabel: 'Foto de $nome',
              // Falha no download também cai no avatar neutro, sem quebrar o layout.
              errorBuilder: (_, _, _) => _avatarVazio(),
            ),
    );
  }

  // O placeholder mantém tamanho e alinhamento iguais à foto carregada.
  Widget _avatarVazio() => Container(
    width: tamanho,
    height: tamanho,
    color: CoresApp.primary.withAlpha(25),
    alignment: Alignment.center,
    child: Icon(
      Icons.pets_rounded,
      color: CoresApp.primary,
      size: tamanho * 0.48,
    ),
  );
}
