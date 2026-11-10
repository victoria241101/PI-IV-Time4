// etapa final do cadastro para encaminhamento ou agendamento de consulta
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/widgets/cartao_opcao_app.dart';
import 'package:pet_care/screens/recepcao/cadastro/etapas_formulario_cadastro.dart';

class EncaminhamentoCadastro extends StatelessWidget {
  const EncaminhamentoCadastro({
    super.key,
    required this.nomePet,
    required this.nomeResponsavel,
    required this.encaminhamento,
    required this.dataConsulta,
    required this.horarioConsulta,
    required this.profissionalConsulta,
    required this.profissionais,
    required this.onEncaminhamentoChanged,
    required this.onSelecionarData,
    required this.onSelecionarHorario,
    required this.onProfissionalChanged,
    required this.onConfirmar,
    this.campoIndicacao,
  });

  final Widget? campoIndicacao;
  final String nomePet;
  final String nomeResponsavel;
  final String encaminhamento;
  final String dataConsulta;
  final String horarioConsulta;
  final String profissionalConsulta;
  final List<String> profissionais;
  final ValueChanged<String> onEncaminhamentoChanged;
  final VoidCallback onSelecionarData;
  final VoidCallback onSelecionarHorario;
  final ValueChanged<String> onProfissionalChanged;
  final VoidCallback onConfirmar;

  bool get _agendando => encaminhamento != 'Triagem';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PassoCadastro(ativo: 1, concluido: true),
        const SizedBox(height: EspacamentosApp.md),
        CartaoClinica(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: CoresApp.surfaceSoft,
                child: Icon(Icons.pets_rounded, color: CoresApp.primary),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomePet, style: TipografiaApp.bodyMedium),
                    Text(
                      'Responsável: $nomeResponsavel',
                      style: TipografiaApp.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: EspacamentosApp.lg),
        Text('Como deseja continuar?', style: TipografiaApp.heading3),
        const SizedBox(height: EspacamentosApp.md),
        CartaoOpcaoApp(
          icon: Icons.health_and_safety_outlined,
          titulo: 'Encaminhar para triagem agora',
          descricao: 'O paciente entra na fila de triagem da clínica',
          selecionado: encaminhamento == 'Triagem',
          onTap: () => onEncaminhamentoChanged('Triagem'),
        ),
        const SizedBox(height: EspacamentosApp.md),
        CartaoOpcaoApp(
          icon: Icons.medical_services_outlined,
          titulo: 'Agendar consulta',
          descricao: 'Escolha a data, o horário e o veterinário',
          selecionado: encaminhamento == 'Agendar consulta',
          onTap: () => onEncaminhamentoChanged('Agendar consulta'),
        ),
        const SizedBox(height: EspacamentosApp.md),
        CartaoOpcaoApp(
          icon: Icons.local_hospital_outlined,
          titulo: 'Agendar internação',
          descricao: 'Vincule a um prontuário com indicação do veterinário',
          selecionado: encaminhamento == 'Agendar internação',
          onTap: () => onEncaminhamentoChanged('Agendar internação'),
        ),
        if (_agendando) ...[
          const SizedBox(height: EspacamentosApp.md),
          if (encaminhamento == 'Agendar internação' && campoIndicacao != null)
            campoIndicacao!,
          _seletoresAgendamento(),
          const SizedBox(height: EspacamentosApp.sm),
          Text(
            encaminhamento == 'Agendar internação'
                ? 'O agendamento reserva uma data; a internação começa após a admissão do paciente.'
                : 'No dia marcado, confirme a chegada para o paciente seguir à triagem',
            style: TipografiaApp.caption,
          ),
        ],
        const SizedBox(height: EspacamentosApp.md),
        BotaoClinica(
          label: _agendando
              ? 'Confirmar agendamento'
              : 'Registrar e enviar à triagem',
          icon: _agendando
              ? Icons.calendar_month_outlined
              : Icons.arrow_forward_rounded,
          expanded: true,
          onPressed: onConfirmar,
        ),
      ],
    );
  }

  Widget _seletoresAgendamento() {
    return CartaoClinica(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data e horário do agendamento',
            style: TipografiaApp.bodyMedium,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelecionarData,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(dataConsulta),
                ),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSelecionarHorario,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(horarioConsulta),
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          DropdownButtonFormField<String>(
            initialValue: profissionalConsulta,
            decoration: const InputDecoration(
              labelText: 'Veterinário',
              border: OutlineInputBorder(),
            ),
            items: profissionais
                .map((nome) => DropdownMenuItem(value: nome, child: Text(nome)))
                .toList(),
            onChanged: (nome) {
              if (nome != null) onProfissionalChanged(nome);
            },
          ),
        ],
      ),
    );
  }
}
