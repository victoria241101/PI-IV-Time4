import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';

String nomeCategoriaHistorico(CategoriaHistoricoPet categoria) {
  return switch (categoria) {
    CategoriaHistoricoPet.vacina => 'Vacinas',
    CategoriaHistoricoPet.medicamento => 'Medicamentos',
    CategoriaHistoricoPet.exame => 'Exames',
  };
}

IconData iconeCategoriaHistorico(CategoriaHistoricoPet categoria) {
  return switch (categoria) {
    CategoriaHistoricoPet.vacina => Icons.vaccines_outlined,
    CategoriaHistoricoPet.medicamento => Icons.medication_outlined,
    CategoriaHistoricoPet.exame => Icons.science_outlined,
  };
}

Color corCategoriaHistorico(CategoriaHistoricoPet categoria) {
  return switch (categoria) {
    CategoriaHistoricoPet.vacina => CoresApp.primary,
    CategoriaHistoricoPet.medicamento => const Color(0xFFD97706),
    CategoriaHistoricoPet.exame => const Color(0xFF3B82F6),
  };
}

class IconeCategoriaHistorico extends StatelessWidget {
  const IconeCategoriaHistorico({
    super.key,
    required this.categoria,
    this.size = 22,
  });

  final CategoriaHistoricoPet categoria;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = corCategoriaHistorico(categoria);

    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
      ),
      child: Icon(
        iconeCategoriaHistorico(categoria),
        size: size,
        color: color,
        semanticLabel: nomeCategoriaHistorico(categoria),
      ),
    );
  }
}
