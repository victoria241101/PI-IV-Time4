// Card de atendimento compartilhado; cada fluxo fornece a sua própria ação.
import 'package:flutter/material.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/indicador_status.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

class CartaoAtendimento extends StatelessWidget {
  const CartaoAtendimento({
    super.key,
    required this.consulta,
    this.onTap,
    this.acao,
    this.onAcao,
    this.iconeAcao = Icons.arrow_forward_rounded,
    this.acaoSecundaria = false,
    this.mostrarSala = false,
  });
  final ConsultaRecepcao consulta;
  final VoidCallback? onTap;
  final String? acao;
  final VoidCallback? onAcao;
  final IconData iconeAcao;
  final bool acaoSecundaria;
  final bool mostrarSala;
  @override
  Widget build(BuildContext context) => CartaoClinica(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: EspacamentosApp.sm,
          runSpacing: EspacamentosApp.xs,
          children: [
            Text(
              consulta.horario,
              style: TipografiaApp.bodyMedium.copyWith(
                color: CoresApp.primaryDark,
              ),
            ),
            IndicadorStatus(
              label: consulta.status.rotulo,
              color: consulta.status.cor,
            ),
            if (consulta.emergencia)
              const IndicadorStatus(
                label: 'Emergência',
                color: CoresApp.danger,
              ),
          ],
        ),
        const SizedBox(height: EspacamentosApp.sm),
        Row(
          children: [
            AvatarPet(
              fotoUrl: consulta.fotoPet,
              nome: consulta.pet,
              tamanho: 48,
            ),
            const SizedBox(width: EspacamentosApp.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(consulta.pet, style: TipografiaApp.heading3),
                  Text(
                    '${consulta.especie} · ${consulta.tutor}',
                    style: TipografiaApp.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspacamentosApp.sm),
        Text(
          'Veterinário: ${consulta.profissional}${mostrarSala ? ' · ${consulta.sala}' : ''}',
          style: TipografiaApp.caption,
        ),
        if (acao != null) ...[
          const SizedBox(height: EspacamentosApp.sm),
          if (acaoSecundaria)
            OutlinedButton.icon(
              onPressed: onAcao,
              icon: Icon(iconeAcao),
              label: Text(acao!),
              style: OutlinedButton.styleFrom(
                foregroundColor: CoresApp.primaryDark,
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            BotaoClinica(
              label: acao!,
              icon: iconeAcao,
              expanded: true,
              onPressed: onAcao,
            ),
        ],
      ],
    ),
  );
}
