import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/internacao_pet.dart';
import 'package:pet_care/widgets/cartao_base.dart';

class PaginaInternacoesPet extends StatelessWidget {
  const PaginaInternacoesPet({
    super.key,
    required this.nomePet,
    required this.internacoes,
    this.aoFalarComClinica,
  });

  final String nomePet;
  final List<InternacaoPet> internacoes;
  final VoidCallback? aoFalarComClinica;

  List<InternacaoPet> get _internacoesAtivas {
    return internacoes
        .where((internacao) => internacao.estaAtiva)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final internacoesAtivas = _internacoesAtivas;

    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.darkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Internações',
          style: TipografiaApp.heading3.copyWith(
            color: CoresApp.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: internacoesAtivas.isEmpty
            ? _EstadoSemInternacao(nomePet: nomePet)
            : ListView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.md,
            EspacamentosApp.pagePadding,
            EspacamentosApp.xxl,
          ),
          children: [
            _CabecalhoInternacoes(
              nomePet: nomePet,
              quantidade: internacoesAtivas.length,
            ),
            const SizedBox(height: EspacamentosApp.lg),
            for (final internacao in internacoesAtivas) ...[
              _CartaoInternacao(
                internacao: internacao,
                aoFalarComClinica: aoFalarComClinica,
              ),
              const SizedBox(height: EspacamentosApp.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _CabecalhoInternacoes extends StatelessWidget {
  const _CabecalhoInternacoes({
    required this.nomePet,
    required this.quantidade,
  });

  final String nomePet;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acompanhamento clínico',
          style: TipografiaApp.heading2.copyWith(
            color: CoresApp.darkBlue,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: EspacamentosApp.xs),
        Text(
          'Consulte as informações e as atualizações clínicas '
              'de $nomePet.',
          style: TipografiaApp.bodySmall.copyWith(
            color: CoresApp.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: EspacamentosApp.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(EspacamentosApp.md),
          decoration: BoxDecoration(
            color: CoresApp.primary.withAlpha(12),
            borderRadius: BorderRadius.circular(
              EspacamentosApp.radiusLg,
            ),
            border: Border.all(
              color: CoresApp.primary.withAlpha(35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CoresApp.surface,
                  borderRadius: BorderRadius.circular(
                    EspacamentosApp.radiusMd,
                  ),
                ),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: CoresApp.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$quantidade ${quantidade == 1 ? 'internação ativa' : 'internações ativas'}',
                      style: TipografiaApp.bodyMedium.copyWith(
                        color: CoresApp.darkBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xs),
                    Text(
                      'Acompanhamento de $nomePet',
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.health_and_safety_outlined,
                color: CoresApp.primary,
                size: 25,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartaoInternacao extends StatelessWidget {
  const _CartaoInternacao({
    required this.internacao,
    required this.aoFalarComClinica,
  });

  final InternacaoPet internacao;
  final VoidCallback? aoFalarComClinica;

  String get _status {
    return switch (internacao.status) {
      StatusInternacaoPet.aguardandoAdmissao => 'Aguardando admissão',
      StatusInternacaoPet.internado => 'Em internação',
      StatusInternacaoPet.altaConcedida => 'Alta concedida',
      StatusInternacaoPet.encerrada => 'Encerrada',
    };
  }

  Color get _corStatus {
    return switch (internacao.status) {
      StatusInternacaoPet.aguardandoAdmissao => const Color(0xFFB7791F),
      StatusInternacaoPet.internado => CoresApp.primary,
      StatusInternacaoPet.altaConcedida => const Color(0xFF238568),
      StatusInternacaoPet.encerrada => CoresApp.textSecondary,
    };
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CartaoBase(
          padding: const EdgeInsets.all(EspacamentosApp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CoresApp.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(
                        EspacamentosApp.radiusMd,
                      ),
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: CoresApp.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: EspacamentosApp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Internação',
                          style: TipografiaApp.heading3.copyWith(
                            color: CoresApp.darkBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.xs),
                        Text(
                          'Entrada em ${_formatarData(internacao.dataEntrada)}',
                          style: TipografiaApp.bodySmall.copyWith(
                            color: CoresApp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: EspacamentosApp.xs),
                  _SeloStatus(
                    texto: _status,
                    cor: _corStatus,
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.lg),
              const Divider(height: 1),
              const SizedBox(height: EspacamentosApp.lg),
              _InformacaoInternacao(
                icone: Icons.assignment_outlined,
                rotulo: 'Motivo',
                valor: internacao.motivo,
              ),
              if (internacao.veterinarioResponsavel != null) ...[
                const SizedBox(height: EspacamentosApp.md),
                _InformacaoInternacao(
                  icone: Icons.person_outline_rounded,
                  rotulo: 'Veterinário responsável',
                  valor: internacao.veterinarioResponsavel!,
                ),
              ],
              if (internacao.dataPrevisaoAlta != null) ...[
                const SizedBox(height: EspacamentosApp.md),
                _InformacaoInternacao(
                  icone: Icons.event_outlined,
                  rotulo: 'Previsão de alta',
                  valor: _formatarData(internacao.dataPrevisaoAlta!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EspacamentosApp.md),
        CartaoBase(
          padding: const EdgeInsets.all(EspacamentosApp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color: CoresApp.primary,
                    size: 23,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      'Estado clínico',
                      style: TipografiaApp.heading3.copyWith(
                        color: CoresApp.darkBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EspacamentosApp.md),
                decoration: BoxDecoration(
                  color: CoresApp.surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    EspacamentosApp.radiusMd,
                  ),
                ),
                child: Text(
                  internacao.resumoAtual,
                  style: TipografiaApp.bodyMedium.copyWith(
                    color: CoresApp.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              if (internacao.ultimaAtualizacao != null) ...[
                const SizedBox(height: EspacamentosApp.md),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: CoresApp.textSecondary,
                    ),
                    const SizedBox(width: EspacamentosApp.xs),
                    Expanded(
                      child: Text(
                        'Atualizado em '
                            '${_formatarData(internacao.ultimaAtualizacao!)}',
                        style: TipografiaApp.bodySmall.copyWith(
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (internacao.atualizacoes.isNotEmpty) ...[
          const SizedBox(height: EspacamentosApp.xl),
          Text(
            'Atualizações clínicas',
            style: TipografiaApp.heading3.copyWith(
              color: CoresApp.darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: EspacamentosApp.xs),
          Text(
            'Registros compartilhados pela equipe responsável.',
            style: TipografiaApp.bodySmall.copyWith(
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          for (var i = 0; i < internacao.atualizacoes.length; i++) ...[
            _ItemAtualizacao(
              atualizacao: internacao.atualizacoes[i],
              dataFormatada: _formatarData(
                internacao.atualizacoes[i].dataHora,
              ),
              ultima: i == internacao.atualizacoes.length - 1,
            ),
            if (i < internacao.atualizacoes.length - 1)
              const SizedBox(height: EspacamentosApp.md),
          ],
        ],
        const SizedBox(height: EspacamentosApp.lg),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: aoFalarComClinica ??
                    () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'O chat com a clínica será implementado neste fluxo.',
                      ),
                    ),
                  );
                },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Falar com a clínica'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoresApp.darkBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  EspacamentosApp.radiusMd,
                ),
              ),
              textStyle: TipografiaApp.button.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({
    required this.texto,
    required this.cor,
  });

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.sm,
        vertical: EspacamentosApp.xs,
      ),
      decoration: BoxDecoration(
        color: cor.withAlpha(18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: TipografiaApp.bodySmall.copyWith(
          color: cor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InformacaoInternacao extends StatelessWidget {
  const _InformacaoInternacao({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icone,
          size: 20,
          color: CoresApp.primary,
        ),
        const SizedBox(width: EspacamentosApp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textSecondary,
                ),
              ),
              const SizedBox(height: EspacamentosApp.xs),
              Text(
                valor,
                style: TipografiaApp.bodyMedium.copyWith(
                  color: CoresApp.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemAtualizacao extends StatelessWidget {
  const _ItemAtualizacao({
    required this.atualizacao,
    required this.dataFormatada,
    required this.ultima,
  });

  final AtualizacaoInternacaoPet atualizacao;
  final String dataFormatada;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note_outlined,
                  color: CoresApp.primary,
                  size: 21,
                ),
              ),
              if (!ultima)
                Container(
                  width: 2,
                  height: 22,
                  color: CoresApp.primary.withAlpha(35),
                ),
            ],
          ),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atualizacao.titulo,
                  style: TipografiaApp.bodyMedium.copyWith(
                    color: CoresApp.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  atualizacao.descricao,
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.sm),
                Text(
                  dataFormatada,
                  style: TipografiaApp.bodySmall.copyWith(
                    color: CoresApp.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (atualizacao.responsavel != null) ...[
                  const SizedBox(height: EspacamentosApp.xs),
                  Text(
                    'Responsável: ${atualizacao.responsavel}',
                    style: TipografiaApp.bodySmall.copyWith(
                      color: CoresApp.textSecondary,
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

class _EstadoSemInternacao extends StatelessWidget {
  const _EstadoSemInternacao({
    required this.nomePet,
  });

  final String nomePet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspacamentosApp.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(14),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  size: 44,
                  color: CoresApp.primary,
                ),
              ),
              const SizedBox(height: EspacamentosApp.lg),
              Text(
                'Tudo tranquilo por aqui',
                textAlign: TextAlign.center,
                style: TipografiaApp.heading2.copyWith(
                  color: CoresApp.darkBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: EspacamentosApp.sm),
              Text(
                'Não há internações em andamento registradas para '
                    '$nomePet.',
                textAlign: TextAlign.center,
                style: TipografiaApp.bodyMedium.copyWith(
                  color: CoresApp.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: EspacamentosApp.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.md,
                  vertical: EspacamentosApp.sm,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: CoresApp.primary.withAlpha(35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: CoresApp.primary,
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Text(
                      'Nenhuma internação ativa',
                      style: TipografiaApp.bodySmall.copyWith(
                        color: CoresApp.primary,
                        fontWeight: FontWeight.w700,
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