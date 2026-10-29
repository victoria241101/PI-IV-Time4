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

enum _FiltroHistorico {
  todos,
  vacina,
  procedimento,
  consulta,
  internacao,
  medicamento,
  exame,
}

class PaginaHistoricoPet extends StatefulWidget {
  const PaginaHistoricoPet({
    super.key,
    required this.nomePet,
    required this.registros,
    this.categoria,
  });

  final String nomePet;
  final List<RegistroHistoricoPet> registros;
  final CategoriaHistoricoPet? categoria;

  @override
  State<PaginaHistoricoPet> createState() => _PaginaHistoricoPetState();
}

class _PaginaHistoricoPetState extends State<PaginaHistoricoPet> {
  late _FiltroHistorico _filtroSelecionado;

  @override
  void initState() {
    super.initState();
    _filtroSelecionado = _filtroInicial(widget.categoria);
  }

  @override
  void didUpdateWidget(covariant PaginaHistoricoPet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.categoria != widget.categoria) {
      _filtroSelecionado = _filtroInicial(widget.categoria);
    }
  }

  _FiltroHistorico _filtroInicial(CategoriaHistoricoPet? categoria) {
    if (categoria == null) return _FiltroHistorico.todos;

    return switch (categoria) {
      CategoriaHistoricoPet.vacina => _FiltroHistorico.vacina,
      CategoriaHistoricoPet.medicamento => _FiltroHistorico.medicamento,
      CategoriaHistoricoPet.exame => _FiltroHistorico.exame,
      CategoriaHistoricoPet.procedimento => _FiltroHistorico.procedimento,
      CategoriaHistoricoPet.consulta => _FiltroHistorico.consulta,
      CategoriaHistoricoPet.internacao => _FiltroHistorico.internacao,
    };
  }

  List<RegistroHistoricoPet> get _registrosVisiveis {
    if (_filtroSelecionado == _FiltroHistorico.todos) {
      return widget.registros;
    }

    final categoria = switch (_filtroSelecionado) {
      _FiltroHistorico.todos => null,
      _FiltroHistorico.vacina => CategoriaHistoricoPet.vacina,
      _FiltroHistorico.procedimento => CategoriaHistoricoPet.procedimento,
      _FiltroHistorico.consulta => CategoriaHistoricoPet.consulta,
      _FiltroHistorico.internacao => CategoriaHistoricoPet.internacao,
      _FiltroHistorico.medicamento => CategoriaHistoricoPet.medicamento,
      _FiltroHistorico.exame => CategoriaHistoricoPet.exame,
    };

    return widget.registros
        .where((registro) => registro.categoria == categoria)
        .toList(growable: false);
  }

  String get _titulo => 'Histórico de ${widget.nomePet}';

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
      body: Column(
        children: [
          _FiltrosHistorico(
            selecionado: _filtroSelecionado,
            onSelecionar: (filtro) {
              setState(() {
                _filtroSelecionado = filtro;
              });
            },
          ),
          Expanded(
            child: itens.isEmpty
                ? _EstadoVazio(
              nomePet: widget.nomePet,
              filtro: _filtroSelecionado,
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
          ),
        ],
      ),
    );
  }
}

class _FiltrosHistorico extends StatelessWidget {
  const _FiltrosHistorico({
    required this.selecionado,
    required this.onSelecionar,
  });

  final _FiltroHistorico selecionado;
  final ValueChanged<_FiltroHistorico> onSelecionar;

  static const _opcoes = <({String titulo, _FiltroHistorico filtro})>[
    (titulo: 'Todos', filtro: _FiltroHistorico.todos),
    (titulo: 'Vacinas', filtro: _FiltroHistorico.vacina),
    (titulo: 'Procedimentos', filtro: _FiltroHistorico.procedimento),
    (titulo: 'Consultas', filtro: _FiltroHistorico.consulta),
    (titulo: 'Internações', filtro: _FiltroHistorico.internacao),
    (titulo: 'Medicamentos', filtro: _FiltroHistorico.medicamento),
    (titulo: 'Exames', filtro: _FiltroHistorico.exame),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacamentosApp.pagePadding,
          vertical: EspacamentosApp.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _opcoes.length,
        separatorBuilder: (_, _) => const SizedBox(
          width: EspacamentosApp.sm,
        ),
        itemBuilder: (context, index) {
          final opcao = _opcoes[index];
          final ativo = selecionado == opcao.filtro;

          return ChoiceChip(
            label: Text(opcao.titulo),
            selected: ativo,
            onSelected: (_) => onSelecionar(opcao.filtro),
            selectedColor: _turquesaHistorico.withAlpha(30),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: ativo ? _turquesaHistorico : const Color(0xFFE5EBF1),
            ),
            labelStyle: TipografiaApp.captionBold.copyWith(
              color: ativo ? _azulHistorico : CoresApp.textSecondary,
            ),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
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
                const SizedBox(height: 4),
                Text(
                  nomeCategoriaHistorico(registro.categoria),
                  style: TipografiaApp.caption.copyWith(
                    color: corCategoria,
                  ),
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
    required this.filtro,
  });

  final String nomePet;
  final _FiltroHistorico filtro;

  String get _descricao {
    return switch (filtro) {
      _FiltroHistorico.todos => 'registros de saúde',
      _FiltroHistorico.vacina => 'vacinas',
      _FiltroHistorico.procedimento => 'procedimentos',
      _FiltroHistorico.consulta => 'consultas',
      _FiltroHistorico.internacao => 'internações',
      _FiltroHistorico.medicamento => 'medicamentos',
      _FiltroHistorico.exame => 'exames',
    };
  }

  @override
  Widget build(BuildContext context) {
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
              'Ainda não há $_descricao para $nomePet.',
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