import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';

class Doar extends StatelessWidget {
  const Doar({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.meta,
  });

  final String nomeAnimal;
  final String titulo;
  final double meta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CoresApp.darkBlue,
          ),
        ),
        title: const Text(
          'Fazer uma doação',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CoresApp.darkBlue,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          EspacamentosApp.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: CoresApp.darkBlue,
              ),
            ),
            const SizedBox(height: EspacamentosApp.xl),
            const Text(
              'Escolha o valor da sua doação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CoresApp.darkBlue,
              ),
            ),
            const SizedBox(height: EspacamentosApp.md),
            const Text(
              'Valor da doação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CoresApp.textSecondary,
              ),
            ),
            const SizedBox(height: EspacamentosApp.sm),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: CoresApp.darkBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: EspacamentosApp.lg),
            Wrap(
              spacing: EspacamentosApp.sm,
              runSpacing: EspacamentosApp.sm,
              children: [
                _ValorSugestao(valor: 'R\$ 20'),
                _ValorSugestao(valor: 'R\$ 50'),
                _ValorSugestao(valor: 'R\$ 100'),
                _ValorSugestao(valor: 'R\$ 200'),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Próxima etapa: checkout.',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoresApp.darkBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Continuar',
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
    );
  }
}

class _ValorSugestao extends StatelessWidget {
  const _ValorSugestao({
    required this.valor,
  });

  final String valor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: CoresApp.darkBlue,
        side: const BorderSide(
          color: CoresApp.darkBlue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        valor,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}