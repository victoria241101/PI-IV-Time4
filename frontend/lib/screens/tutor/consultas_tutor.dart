
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';

class ConsultasTutor extends StatefulWidget {
  const ConsultasTutor({
    super.key,
    required this.consultas,
    this.onConsultaTap,
  });

  final List<ResumoConsulta> consultas;
  final ValueChanged<ResumoConsulta>? onConsultaTap;

  @override
  State<ConsultasTutor> createState() => _ConsultasTutorState();
}

class _ConsultasTutorState extends State<ConsultasTutor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _ehHistorico(ResumoConsulta consulta) {
    final status = consulta.status.toLowerCase();

    return status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida') ||
        status.contains('cancelada');
  }

  @override
  Widget build(BuildContext context) {
    final proximas = widget.consultas
        .where((consulta) => !_ehHistorico(consulta))
        .toList();

    final historico = widget.consultas
        .where(_ehHistorico)
        .toList();

    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        title: Text(
          'Minhas consultas',
          style: TipografiaApp.heading3,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CoresApp.primary,
          unselectedLabelColor: CoresApp.textSecondary,
          indicatorColor: CoresApp.primary,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListaConsultas(
            consultas: proximas,
            mensagemVazia: 'Você não tem consultas próximas.',
            onConsultaTap: widget.onConsultaTap,
          ),
          _ListaConsultas(
            consultas: historico,
            mensagemVazia: 'Seu histórico de consultas aparecerá aqui.',
            onConsultaTap: widget.onConsultaTap,
          ),
        ],
      ),
    );
  }
}

class _ListaConsultas extends StatelessWidget {
  const _ListaConsultas({
    required this.consultas,
    required this.mensagemVazia,
    this.onConsultaTap,
  });

  final List<ResumoConsulta> consultas;
  final String mensagemVazia;
  final ValueChanged<ResumoConsulta>? onConsultaTap;

  @override
  Widget build(BuildContext context) {
    if (consultas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: CoresApp.textSecondary,
              ),
              const SizedBox(height: EspacamentosApp.md),
              Text(
                mensagemVazia,
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
      itemCount: consultas.length,
      separatorBuilder: (_, _) =>
      const SizedBox(height: EspacamentosApp.md),
      itemBuilder: (context, index) {
        final consulta = consultas[index];

        return _CartaoConsulta(
          consulta: consulta,
          onTap: onConsultaTap == null
              ? null
              : () => onConsultaTap!(consulta),
        );
      },
    );
  }
}

class _CartaoConsulta extends StatelessWidget {
  const _CartaoConsulta({
    required this.consulta,
    this.onTap,
  });

  final ResumoConsulta consulta;
  final VoidCallback? onTap;

  Color _corStatus() {
    final status = consulta.status.toLowerCase();

    if (status.contains('cancelada')) {
      return Colors.red.shade700;
    }

    if (status.contains('realizada') ||
        status.contains('concluída') ||
        status.contains('concluida')) {
      return Colors.green.shade700;
    }

    if (status.contains('pendente')) {
      return Colors.orange.shade800;
    }

    return CoresApp.primary;
  }

  @override
  Widget build(BuildContext context) {
    final corStatus = _corStatus();

    return Card(
      color: CoresApp.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        side: BorderSide(
          color: CoresApp.textSecondary.withAlpha(35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EspacamentosApp.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(EspacamentosApp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: CoresApp.primary.withAlpha(25),
                    backgroundImage: consulta.petPhotoUrl != null
                        ? NetworkImage(consulta.petPhotoUrl!)
                        : null,
                    child: consulta.petPhotoUrl == null
                        ? Icon(
                      Icons.pets,
                      color: CoresApp.primary,
                    )
                        : null,
                  ),
                  const SizedBox(width: EspacamentosApp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consulta.type,
                          style: TipografiaApp.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: EspacamentosApp.xs),
                        Text(
                          consulta.petName,
                          style: TipografiaApp.bodySmall.copyWith(
                            color: CoresApp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacamentosApp.sm,
                      vertical: EspacamentosApp.xs,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus.withAlpha(22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      consulta.status,
                      style: TipografiaApp.bodySmall.copyWith(
                        color: corStatus,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.md),
              const Divider(height: 1),
              const SizedBox(height: EspacamentosApp.md),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: CoresApp.textSecondary,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      '${consulta.date} • ${consulta.time}',
                      style: TipografiaApp.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacamentosApp.sm),
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 17,
                    color: CoresApp.textSecondary,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      consulta.vetName,
                      style: TipografiaApp.bodySmall,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CoresApp.textSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
