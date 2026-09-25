import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/tutor/pagina_historico_pet.dart';
import 'package:pet_care/widgets/botao_navegacao_compacto.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/icone_categoria_historico.dart';

typedef CarregarDetalhesPet = Future<DetalhesPet> Function(String petId);

class PaginaDetalhesPet extends StatefulWidget {
  const PaginaDetalhesPet({
    super.key,
    required this.pet,
    required this.carregarDetalhes,
  });

  final ResumoPet pet;
  final CarregarDetalhesPet carregarDetalhes;

  @override
  State<PaginaDetalhesPet> createState() => _PaginaDetalhesPetState();
}

class _PaginaDetalhesPetState extends State<PaginaDetalhesPet> {
  late Future<DetalhesPet> _detalhes;

  @override
  void initState() {
    super.initState();
    _detalhes = widget.carregarDetalhes(widget.pet.id);
  }

  void _tentarNovamente() {
    setState(() {
      _detalhes = widget.carregarDetalhes(widget.pet.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informações do pet')),
      body: FutureBuilder<DetalhesPet>(
        future: _detalhes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _ErroCarregamento(onRetry: _tentarNovamente);
          }

          return _ConteudoDetalhesPet(detalhes: snapshot.data!);
        },
      ),
    );
  }
}

class _ConteudoDetalhesPet extends StatelessWidget {
  const _ConteudoDetalhesPet({required this.detalhes});

  final DetalhesPet detalhes;

  @override
  Widget build(BuildContext context) {
    final pet = detalhes.pet;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _CabecalhoPet(pet: pet)),
          const SizedBox(height: EspacamentosApp.xl),
          Row(
            children: [
              Expanded(
                child: _DadoDestaque(
                  value: pet.age ?? 'Não informado',
                  label: 'Idade',
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: _DadoDestaque(
                  value: _formatarPeso(pet.weight),
                  label: 'Peso',
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.xl),
          Text('Histórico de saúde', style: TipografiaApp.heading3),
          const SizedBox(height: EspacamentosApp.md),
          _AtalhosHistorico(detalhes: detalhes),
          const SizedBox(height: EspacamentosApp.xl),
          _InformacoesBasicas(detalhes: detalhes),
          if (detalhes.proximaConsulta != null) ...[
            const SizedBox(height: EspacamentosApp.md),
            _ProximaConsulta(detalhes: detalhes),
          ],
          if (detalhes.lembretes.isNotEmpty) ...[
            const SizedBox(height: EspacamentosApp.xl),
            Text('Lembretes de cuidado', style: TipografiaApp.heading3),
            const SizedBox(height: EspacamentosApp.md),
            _ListaLembretes(lembretes: detalhes.lembretes),
          ],
        ],
      ),
    );
  }

  String _formatarPeso(double? peso) {
    if (peso == null) return 'Não informado';
    final value = peso % 1 == 0
        ? peso.toStringAsFixed(0)
        : peso.toStringAsFixed(1).replaceAll('.', ',');
    return '$value kg';
  }
}

class _CabecalhoPet extends StatelessWidget {
  const _CabecalhoPet({required this.pet});

  final ResumoPet pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: CoresApp.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: pet.photoUrl == null
                ? Container(
                    color: CoresApp.primary.withAlpha(24),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 42,
                      color: CoresApp.primary,
                    ),
                  )
                : Image.network(
                    pet.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: CoresApp.primary.withAlpha(24),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 42,
                        color: CoresApp.primary,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: EspacamentosApp.md),
        Text(pet.name, style: TipografiaApp.heading1),
        const SizedBox(height: EspacamentosApp.xs),
        Text(pet.breed ?? pet.species, style: TipografiaApp.bodySmall),
      ],
    );
  }
}

class _DadoDestaque extends StatelessWidget {
  const _DadoDestaque({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.sm,
        vertical: EspacamentosApp.md,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TipografiaApp.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EspacamentosApp.xs),
          Text(label, style: TipografiaApp.caption),
        ],
      ),
    );
  }
}

class _AtalhosHistorico extends StatelessWidget {
  const _AtalhosHistorico({required this.detalhes});

  final DetalhesPet detalhes;

  void _abrir(BuildContext context, {CategoriaHistoricoPet? categoria}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaginaHistoricoPet(
          nomePet: detalhes.pet.name,
          registros: detalhes.registros,
          categoria: categoria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - EspacamentosApp.sm) / 2;
        final items = <({String label, IconData icon, VoidCallback onTap})>[
          (
            label: 'Vacinas',
            icon: Icons.vaccines_outlined,
            onTap: () =>
                _abrir(context, categoria: CategoriaHistoricoPet.vacina),
          ),
          (
            label: 'Medicamentos',
            icon: Icons.medication_outlined,
            onTap: () =>
                _abrir(context, categoria: CategoriaHistoricoPet.medicamento),
          ),
          (
            label: 'Exames',
            icon: Icons.science_outlined,
            onTap: () =>
                _abrir(context, categoria: CategoriaHistoricoPet.exame),
          ),
          (
            label: 'Histórico',
            icon: Icons.history_rounded,
            onTap: () => _abrir(context),
          ),
        ];

        return Wrap(
          spacing: EspacamentosApp.sm,
          runSpacing: EspacamentosApp.sm,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: BotaoNavegacaoCompacto(
                  onPressed: item.onTap,
                  icon: item.icon,
                  label: item.label,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InformacoesBasicas extends StatelessWidget {
  const _InformacoesBasicas({required this.detalhes});

  final DetalhesPet detalhes;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 21,
                color: CoresApp.primary,
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Text('Informações básicas', style: TipografiaApp.heading3),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          _LinhaInformacao(label: 'Sexo', value: detalhes.sexo),
          const Divider(height: EspacamentosApp.xl),
          _LinhaInformacao(label: 'Nascimento', value: detalhes.dataNascimento),
          const Divider(height: EspacamentosApp.xl),
          _LinhaInformacao(label: 'Microchip', value: detalhes.microchip),
        ],
      ),
    );
  }
}

class _LinhaInformacao extends StatelessWidget {
  const _LinhaInformacao({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TipografiaApp.bodySmall),
        const SizedBox(width: EspacamentosApp.md),
        Expanded(
          child: Text(
            value,
            style: TipografiaApp.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProximaConsulta extends StatelessWidget {
  const _ProximaConsulta({required this.detalhes});

  final DetalhesPet detalhes;

  @override
  Widget build(BuildContext context) {
    final consulta = detalhes.proximaConsulta!;

    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: CoresApp.primary,
                size: 20,
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Text(
                'Próxima consulta',
                style: TipografiaApp.captionBold.copyWith(
                  color: CoresApp.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          Text(consulta.type, style: TipografiaApp.bodyMedium),
          const SizedBox(height: EspacamentosApp.xs),
          Text(
            '${consulta.date} às ${consulta.time}',
            style: TipografiaApp.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ListaLembretes extends StatelessWidget {
  const _ListaLembretes({required this.lembretes});

  final List<LembretePet> lembretes;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        children: [
          for (var index = 0; index < lembretes.length; index++) ...[
            _LembreteItem(lembrete: lembretes[index]),
            if (index != lembretes.length - 1)
              const SizedBox(height: EspacamentosApp.sm),
          ],
        ],
      ),
    );
  }
}

class _LembreteItem extends StatelessWidget {
  const _LembreteItem({required this.lembrete});

  final LembretePet lembrete;

  @override
  Widget build(BuildContext context) {
    final color = corCategoriaHistorico(lembrete.categoria);

    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.sm + 4),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Row(
        children: [
          IconeCategoriaHistorico(categoria: lembrete.categoria, size: 19),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lembrete.titulo,
                  style: TipografiaApp.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lembrete.prazo,
                  style: TipografiaApp.captionBold.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroCarregamento extends StatelessWidget {
  const _ErroCarregamento({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: CoresApp.danger,
            ),
            const SizedBox(height: EspacamentosApp.md),
            Text(
              'Não foi possível carregar as informações do pet.',
              style: TipografiaApp.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspacamentosApp.md),
            BotaoPrincipal(
              label: 'Tentar novamente',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
