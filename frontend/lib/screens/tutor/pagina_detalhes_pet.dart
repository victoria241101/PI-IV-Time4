import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/detalhes_pet.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/tutor/pagina_historico_pet.dart';
import 'package:pet_care/widgets/botao_navegacao_compacto.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/icone_categoria_historico.dart';

const Color _azulPet = Color(0xFF172A46);
const Color _turquesaPet = Color(0xFF27B8B0);
const Color _laranjaPet = Color(0xFFFFA45B);
const Color _fundoPet = Color(0xFFF5F7FA);
const Color _bordaPet = Color(0xFFE5EBF1);
const Color _fundoLaranjaPet = Color(0xFFFFF2E5);

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
    _carregar();
  }

  @override
  void didUpdateWidget(covariant PaginaDetalhesPet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pet.id != widget.pet.id ||
        oldWidget.carregarDetalhes != widget.carregarDetalhes) {
      _carregar();
    }
  }

  void _carregar() {
    debugPrint('Carregando detalhes do pet: ${widget.pet.id}');
    _detalhes = _buscarDetalhes();
  }

  Future<DetalhesPet> _buscarDetalhes() async {
    try {
      final detalhes = await widget.carregarDetalhes(widget.pet.id);

      debugPrint(
        'Detalhes carregados com sucesso para o pet: ${widget.pet.id}',
      );

      return detalhes;
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar detalhes do pet: $erro');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('ID do pet: ${widget.pet.id}');
      rethrow;
    }
  }

  void _tentarNovamente() {
    setState(_carregar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundoPet,
      appBar: AppBar(
        title: const Text('Informações do pet'),
        backgroundColor: _fundoPet,
        foregroundColor: _azulPet,
        elevation: 0,
      ),
      body: FutureBuilder<DetalhesPet>(
        future: _detalhes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: _turquesaPet,
              ),
            );
          }

          if (snapshot.hasData) {
            return _ConteudoDetalhesPet(
              detalhes: snapshot.data!,
            );
          }

          return _ConteudoResumoPet(
            pet: widget.pet,
            onRetry: _tentarNovamente,
          );
        },
      ),
    );
  }
}

class _AcoesRapidasPet extends StatelessWidget {
  const _AcoesRapidasPet({
    required this.nomePet,
    required this.registros,
  });

  final String nomePet;
  final List<RegistroHistoricoPet> registros;

  void _abrirHistorico(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaginaHistoricoPet(
          nomePet: nomePet,
          registros: registros,
        ),
      ),
    );
  }

  void _avisarFluxoPendente(BuildContext context, String fluxo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$fluxo ainda será implementado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações rápidas',
          style: TipografiaApp.heading3.copyWith(
            color: _azulPet,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Acesse os cuidados e acompanhe seu pet.',
          style: TipografiaApp.bodySmall.copyWith(
            color: CoresApp.textSecondary,
          ),
        ),
        const SizedBox(height: EspacamentosApp.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                (constraints.maxWidth - EspacamentosApp.sm) / 2;

            final items =
            <({String label, IconData icon, VoidCallback onTap})>[
              (
              label: 'Histórico de saúde',
              icon: Icons.history_rounded,
              onTap: () => _abrirHistorico(context),
              ),
              (
              label: 'Internações atuais',
              icon: Icons.local_hospital_outlined,
              onTap: () => _avisarFluxoPendente(
                context,
                'Acompanhamento de internações',
              ),
              ),
              (
              label: 'Falar com a clínica',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => _avisarFluxoPendente(
                context,
                'Chat com a clínica',
              ),
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
        ),
      ],
    );
  }
}

class _ConteudoResumoPet extends StatelessWidget {
  const _ConteudoResumoPet({
    required this.pet,
    required this.onRetry,
  });

  final ResumoPet pet;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final peso = pet.weight == null
        ? 'Não informado'
        : '${pet.weight!.toStringAsFixed(
      pet.weight! % 1 == 0 ? 0 : 1,
    ).replaceAll('.', ',')} kg';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CabecalhoPet(pet: pet),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DadoDestaque(
                  value: pet.age ?? 'Não informado',
                  label: 'Idade',
                  icone: Icons.cake_outlined,
                  cor: _turquesaPet,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: _DadoDestaque(
                  value: peso,
                  label: 'Peso',
                  icone: Icons.monitor_weight_outlined,
                  cor: _laranjaPet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AcoesRapidasPet(
            nomePet: pet.name,
            registros: const [],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _bordaPet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _turquesaPet,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  'Informações adicionais',
                  style: TipografiaApp.heading3.copyWith(
                    color: _azulPet,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Os dados básicos do seu pet estão disponíveis, '
                      'mas não foi possível carregar o histórico de saúde '
                      'e as demais informações neste momento.',
                  style: TipografiaApp.bodyMedium.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                BotaoPrincipal(
                  label: 'Tentar novamente',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarregamentoDetalhes extends StatelessWidget {
  const _CarregamentoDetalhes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: _laranjaPet,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Buscando informações...',
            style: TipografiaApp.bodyMedium.copyWith(
              color: _azulPet,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Preparando a ficha do seu pet',
            style: TipografiaApp.caption.copyWith(
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConteudoDetalhesPet extends StatelessWidget {
  const _ConteudoDetalhesPet({
    required this.detalhes,
  });

  final DetalhesPet detalhes;

  String _formatarPeso(double? peso) {
    if (peso == null) return 'Não informado';

    final valor = peso % 1 == 0
        ? peso.toStringAsFixed(0)
        : peso.toStringAsFixed(1).replaceAll('.', ',');

    return '$valor kg';
  }

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
          _CabecalhoPet(pet: pet),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _DadoDestaque(
                  value: pet.age ?? 'Não informado',
                  label: 'Idade',
                  icone: Icons.cake_outlined,
                  cor: _turquesaPet,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: _DadoDestaque(
                  value: _formatarPeso(pet.weight),
                  label: 'Peso',
                  icone: Icons.monitor_weight_outlined,
                  cor: _laranjaPet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AcoesRapidasPet(
            nomePet: detalhes.pet.name,
            registros: detalhes.registros,
          ),
          const SizedBox(height: 28),
          _TituloSecaoPet(
            titulo: 'Histórico de saúde',
            subtitulo: 'Acompanhe os cuidados e registros do seu pet.',
          ),
          const SizedBox(height: EspacamentosApp.md),
          _AtalhosHistorico(detalhes: detalhes),
          const SizedBox(height: 28),
          _TituloSecaoPet(
            titulo: 'Informações básicas',
            subtitulo: 'Dados importantes da ficha do seu pet.',
          ),
          const SizedBox(height: EspacamentosApp.md),
          _InformacoesBasicas(detalhes: detalhes),
          if (detalhes.proximaConsulta != null) ...[
            const SizedBox(height: 22),
            _ProximaConsulta(detalhes: detalhes),
          ],
          if (detalhes.lembretes.isNotEmpty) ...[
            const SizedBox(height: 28),
            _TituloSecaoPet(
              titulo: 'Lembretes de cuidado',
              subtitulo: 'Fique de olho nos próximos cuidados.',
            ),
            const SizedBox(height: EspacamentosApp.md),
            _ListaLembretes(lembretes: detalhes.lembretes),
          ],
        ],
      ),
    );
  }
}

class _CabecalhoPet extends StatelessWidget {
  const _CabecalhoPet({required this.pet});

  final ResumoPet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _bordaPet),
        boxShadow: [
          BoxShadow(
            color: _azulPet.withAlpha(9),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 116,
                height: 116,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _turquesaPet,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: pet.photoUrl == null
                        ? Container(
                      color: _turquesaPet.withAlpha(24),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 48,
                        color: _turquesaPet,
                      ),
                    )
                        : Image.network(
                      pet.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: _turquesaPet.withAlpha(24),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 48,
                          color: _turquesaPet,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _laranjaPet,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            pet.name,
            textAlign: TextAlign.center,
            style: TipografiaApp.heading1.copyWith(
              color: _azulPet,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pet.breed ?? pet.species,
            textAlign: TextAlign.center,
            style: TipografiaApp.bodySmall.copyWith(
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _fundoLaranjaPet,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets_rounded,
                  color: Color(0xFFAD6928),
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'Meu companheiro',
                  style: TextStyle(
                    color: Color(0xFFAD6928),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DadoDestaque extends StatelessWidget {
  const _DadoDestaque({
    required this.value,
    required this.label,
    required this.icone,
    required this.cor,
  });

  final String value;
  final String label;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.sm,
        vertical: EspacamentosApp.md,
      ),
      child: Column(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: cor.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icone,
              color: cor,
              size: 21,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TipografiaApp.heading3.copyWith(
              color: _azulPet,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TipografiaApp.caption.copyWith(
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecaoPet extends StatelessWidget {
  const _TituloSecaoPet({
    required this.titulo,
    required this.subtitulo,
  });

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TipografiaApp.heading3.copyWith(
            color: _azulPet,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitulo,
          style: TipografiaApp.bodySmall.copyWith(
            color: CoresApp.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: _laranjaPet,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class _AtalhosHistorico extends StatelessWidget {
  const _AtalhosHistorico({required this.detalhes});

  final DetalhesPet detalhes;

  void _abrir(
      BuildContext context, {
        CategoriaHistoricoPet? categoria,
      }) {
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
        final itemWidth =
            (constraints.maxWidth - EspacamentosApp.sm) / 2;

        final items =
        <({String label, IconData icon, VoidCallback onTap})>[
          (
          label: 'Vacinas',
          icon: Icons.vaccines_outlined,
          onTap: () => _abrir(
            context,
            categoria: CategoriaHistoricoPet.vacina,
          ),
          ),
          (
          label: 'Medicamentos',
          icon: Icons.medication_outlined,
          onTap: () => _abrir(
            context,
            categoria: CategoriaHistoricoPet.medicamento,
          ),
          ),
          (
          label: 'Exames',
          icon: Icons.science_outlined,
          onTap: () => _abrir(
            context,
            categoria: CategoriaHistoricoPet.exame,
          ),
          ),
          (
          label: 'Histórico completo',
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
          _LinhaInformacao(
            icone: Icons.transgender_rounded,
            label: 'Sexo',
            value: detalhes.sexo,
          ),
          const Divider(height: 28, color: _bordaPet),
          _LinhaInformacao(
            icone: Icons.cake_outlined,
            label: 'Nascimento',
            value: detalhes.dataNascimento,
          ),
          const Divider(height: 28, color: _bordaPet),
          _LinhaInformacao(
            icone: Icons.memory_rounded,
            label: 'Microchip',
            value: detalhes.microchip,
          ),
        ],
      ),
    );
  }
}

class _LinhaInformacao extends StatelessWidget {
  const _LinhaInformacao({
    required this.icone,
    required this.label,
    required this.value,
  });

  final IconData icone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _fundoPet,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icone,
            size: 18,
            color: _turquesaPet,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TipografiaApp.caption.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TipografiaApp.bodyMedium.copyWith(
                    color: _azulPet,
                    fontWeight: FontWeight.w700,
                  ),
                  softWrap: true,
                ),
              ],
            ),
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

    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bordaPet),
        boxShadow: [
          BoxShadow(
            color: _azulPet.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _turquesaPet.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _turquesaPet,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Próxima consulta',
                  style: TipografiaApp.heading3.copyWith(
                    color: _azulPet,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: _laranjaPet,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            consulta.type,
            style: TipografiaApp.bodyMedium.copyWith(
              color: _azulPet,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: _turquesaPet,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  consulta.date,
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.schedule_rounded,
                color: _turquesaPet,
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                consulta.time,
                style: TipografiaApp.bodySmall.copyWith(
                  color: _azulPet,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
    final cor = corCategoriaHistorico(lembrete.categoria);

    return Container(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      decoration: BoxDecoration(
        color: cor.withAlpha(14),
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
        border: Border.all(color: cor.withAlpha(35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeCategoriaHistorico(
            categoria: lembrete.categoria,
            size: 21,
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lembrete.titulo,
                  style: TipografiaApp.bodyMedium.copyWith(
                    color: _azulPet,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: _laranjaPet,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        lembrete.prazo,
                        style: TipografiaApp.captionBold.copyWith(
                          color: cor,
                        ),
                      ),
                    ),
                  ],
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
  const _ErroCarregamento({
    required this.onRetry,
    required this.mensagem,
  });

  final VoidCallback onRetry;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacamentosApp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _fundoLaranjaPet,
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 39,
                color: _laranjaPet,
              ),
            ),
            const SizedBox(height: EspacamentosApp.lg),
            Text(
              'Ops! Algo não saiu como esperado',
              style: TipografiaApp.heading3.copyWith(
                color: _azulPet,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspacamentosApp.sm),
            Text(
              mensagem,
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspacamentosApp.lg),
            SizedBox(
              width: double.infinity,
              child: BotaoPrincipal(
                label: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}