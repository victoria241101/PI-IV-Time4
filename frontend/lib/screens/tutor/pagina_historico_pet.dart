import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/icone_categoria_historico.dart';

const Color _turquesaHistorico = Color(0xFF27B8B0);
const Color _azulHistorico = Color(0xFF172A46);
const Color _laranjaHistorico = Color(0xFFFFA45B);
const Color _fundoLaranjaHistorico = Color(0xFFFFF2E5);

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
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: _azulHistorico,
        elevation: 0,
        title: Text(
          _titulo,
          style: TipografiaApp.heading3.copyWith(
            color: _azulHistorico,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: itens.isEmpty
          ? _EstadoVazio(
        nomePet: nomePet,
        categoria: categoria,
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          EspacamentosApp.pagePadding,
          EspacamentosApp.md,
          EspacamentosApp.pagePadding,
          EspacamentosApp.xxl,
        ),
        itemCount: itens.length,
        separatorBuilder: (_, _) => const SizedBox(
          height: EspacamentosApp.md,
        ),
        itemBuilder: (context, index) {
          return _CartaoRegistro(
            registro: itens[index],
          );
        },
      ),
    );
  }
}

class _CartaoRegistro extends StatelessWidget {
  const _CartaoRegistro({
    required this.registro,
  });

  final RegistroHistoricoPet registro;

  @override
  Widget build(BuildContext context) {
    final corCategoria = corCategoriaHistorico(registro.categoria);

    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeCategoriaHistorico(
            categoria: registro.categoria,
          ),
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
                          color: _azulHistorico,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Text(
                      registro.data,
                      style: TipografiaApp.caption.copyWith(
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (registro.descricao != null) ...[
                  const SizedBox(height: EspacamentosApp.xs),
                  Text(
                    registro.descricao!,
                    style: TipografiaApp.bodySmall.copyWith(
                      color: CoresApp.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (registro.status != null) ...[
                  const SizedBox(height: EspacamentosApp.md),
                  Wrap(
                    spacing: EspacamentosApp.sm,
                    runSpacing: EspacamentosApp.xs,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EspacamentosApp.sm,
                          vertical: EspacamentosApp.xs,
                        ),
                        decoration: BoxDecoration(
                          color: corCategoria.withAlpha(20),
                          borderRadius: BorderRadius.circular(
                            EspacamentosApp.radiusFull,
                          ),
                        ),
                        child: Text(
                          registro.status!,
                          style: TipografiaApp.captionBold.copyWith(
                            color: corCategoria,
                          ),
                        ),
                      ),
                      if (_statusMereceDestaque(registro.status!))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EspacamentosApp.sm,
                            vertical: EspacamentosApp.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _fundoLaranjaHistorico,
                            borderRadius: BorderRadius.circular(
                              EspacamentosApp.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Atenção',
                            style: TipografiaApp.captionBold.copyWith(
                              color: const Color(0xFF9A5A16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _statusMereceDestaque(String status) {
    final normalizado = status.toLowerCase();

    return normalizado.contains('pendente') ||
        normalizado.contains('atenção') ||
        normalizado.contains('atencao') ||
        normalizado.contains('agendado');
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.nomePet,
    required this.categoria,
  });

  final String nomePet;
  final CategoriaHistoricoPet? categoria;

  @override
  Widget build(BuildContext context) {
    final descricao = categoria == null
        ? 'registros de saúde'
        : nomeCategoriaHistorico(categoria!).toLowerCase();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _turquesaHistorico.withAlpha(20),
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 42,
                color: _turquesaHistorico,
              ),
            ),
            const SizedBox(height: EspacamentosApp.lg),
            Text(
              'Nenhum registro encontrado',
              textAlign: TextAlign.center,
              style: TipografiaApp.heading3.copyWith(
                color: _azulHistorico,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: EspacamentosApp.sm),
            Text(
              'Ainda não há $descricao para $nomePet.',
              textAlign: TextAlign.center,
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: EspacamentosApp.lg),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _laranjaHistorico,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}