import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/icone_categoria_historico.dart';

class PaginaHistoricoPet extends StatelessWidget {
  const PaginaHistoricoPet({
    super.key,
    required this.nomePet,
    required this.registros,
    this.categoria,
  });

  final String nomePet;
  final List<RegistroHistoricoPet> registros;
  final CategoriaHistoricoPet? categoria;

  List<RegistroHistoricoPet> get _registrosVisiveis {
    if (categoria == null) return registros;
    return registros
        .where((registro) => registro.categoria == categoria)
        .toList(growable: false);
  }

  String get _titulo {
    if (categoria == null) return 'Histórico de $nomePet';
    return '${nomeCategoriaHistorico(categoria!)} de $nomePet';
  }

  @override
  Widget build(BuildContext context) {
    final itens = _registrosVisiveis;

    return Scaffold(
      appBar: AppBar(title: Text(_titulo)),
      body: itens.isEmpty
          ? _EstadoVazio(categoria: categoria)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                EspacamentosApp.pagePadding,
                EspacamentosApp.md,
                EspacamentosApp.pagePadding,
                EspacamentosApp.xxl,
              ),
              itemCount: itens.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: EspacamentosApp.md),
              itemBuilder: (context, index) {
                return _CartaoRegistro(registro: itens[index]);
              },
            ),
    );
  }
}

class _CartaoRegistro extends StatelessWidget {
  const _CartaoRegistro({required this.registro});

  final RegistroHistoricoPet registro;

  @override
  Widget build(BuildContext context) {
    final color = corCategoriaHistorico(registro.categoria);

    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeCategoriaHistorico(categoria: registro.categoria),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        registro.titulo,
                        style: TipografiaApp.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Text(registro.data, style: TipografiaApp.caption),
                  ],
                ),
                if (registro.descricao != null) ...[
                  const SizedBox(height: EspacamentosApp.xs),
                  Text(registro.descricao!, style: TipografiaApp.bodySmall),
                ],
                if (registro.status != null) ...[
                  const SizedBox(height: EspacamentosApp.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.sm,
                      vertical: EspacamentosApp.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(
                        EspacamentosApp.radiusFull,
                      ),
                    ),
                    child: Text(
                      registro.status!,
                      style: TipografiaApp.captionBold.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.categoria});

  final CategoriaHistoricoPet? categoria;

  @override
  Widget build(BuildContext context) {
    final label = categoria == null
        ? 'registros de saúde'
        : nomeCategoriaHistorico(categoria!).toLowerCase();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 44,
              color: CoresApp.iconDefault,
            ),
            const SizedBox(height: EspacamentosApp.md),
            Text(
              'Nenhum $label encontrado.',
              style: TipografiaApp.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
