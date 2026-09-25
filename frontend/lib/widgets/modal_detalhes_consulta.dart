import 'package:flutter/material.dart';

import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/core/cores_app.dart';
import 'package:pet_care/core/espacamentos_app.dart';
import 'package:pet_care/core/tipografia_app.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/indicador_status.dart';

/// Modal com detalhes de uma consulta.
///
/// recebe [ResumoConsulta] e callbacks
/// para reagendar e cancelar.
class ModalDetalhesConsulta extends StatelessWidget {
  const ModalDetalhesConsulta({
    super.key,
    required this.appointment,
    this.onReschedule,
    this.onCancel,
  });

  final ResumoConsulta appointment;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  /// Exibe o modal
  static void show(
    BuildContext context, {
    required ResumoConsulta appointment,
    VoidCallback? onReschedule,
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoresApp.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EspacamentosApp.radiusXl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ModalDetalhesConsulta(
            appointment: appointment,
            onReschedule: onReschedule,
            onCancel: onCancel,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Indicador de arraste
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: EspacamentosApp.lg),
              decoration: BoxDecoration(
                color: CoresApp.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título e status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detalhes da consulta', style: TipografiaApp.heading2),
              IndicadorStatus(label: appointment.status),
            ],
          ),
          const SizedBox(height: EspacamentosApp.xl),

          // Pet
          _buildInfoRow(
            icon: Icons.pets_rounded,
            label: 'Pet',
            value: appointment.petName,
            photoUrl: appointment.petPhotoUrl,
          ),
          const SizedBox(height: EspacamentosApp.md),

          // Tipo da consulta
          _buildInfoRow(
            icon: Icons.medical_services_outlined,
            label: 'Tipo',
            value: appointment.type,
          ),
          const SizedBox(height: EspacamentosApp.md),

          // Data e horário
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Data',
            value: appointment.date,
          ),
          const SizedBox(height: EspacamentosApp.md),

          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Horário',
            value: appointment.time,
          ),
          const SizedBox(height: EspacamentosApp.md),

          // Veterinário
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Veterinário(a)',
            value: appointment.vetName,
            photoUrl: appointment.vetPhotoUrl,
          ),
          const SizedBox(height: EspacamentosApp.xl),

          // Orientações
          if (appointment.instructions != null) ...[
            Text(
              'Orientações',
              style: TipografiaApp.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: EspacamentosApp.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(EspacamentosApp.md),
              decoration: BoxDecoration(
                color: CoresApp.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(EspacamentosApp.radiusMd),
              ),
              child: Text(
                appointment.instructions!,
                style: TipografiaApp.bodySmall.copyWith(
                  color: CoresApp.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: EspacamentosApp.xl),
          ],

          // Endereço
          if (appointment.clinicAddress != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: CoresApp.primary,
                  size: 20,
                  semanticLabel: 'Localização',
                ),
                const SizedBox(width: EspacamentosApp.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Endereço', style: TipografiaApp.captionBold),
                      const SizedBox(height: 2),
                      Text(
                        appointment.clinicAddress!,
                        style: TipografiaApp.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.xl),
          ],

          // Ações
          BotaoPrincipal(
            label: 'Reagendar consulta',
            icon: Icons.calendar_month_outlined,
            onPressed: onReschedule,
            expanded: true,
          ),
          const SizedBox(height: EspacamentosApp.md),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'Cancelar consulta',
              button: true,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoresApp.danger,
                  side: BorderSide(color: CoresApp.danger.withAlpha(120)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      EspacamentosApp.radiusMd,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cancelar consulta',
                  style: TipografiaApp.button.copyWith(color: CoresApp.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? photoUrl,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(EspacamentosApp.sm),
          decoration: BoxDecoration(
            color: CoresApp.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(EspacamentosApp.radiusSm),
          ),
          child: photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                    EspacamentosApp.radiusSm - 2,
                  ),
                  child: Image.network(
                    photoUrl,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(icon, size: 20, color: CoresApp.primary),
        ),
        const SizedBox(width: EspacamentosApp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TipografiaApp.caption),
              Text(value, style: TipografiaApp.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
