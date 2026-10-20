// etapas de identificação do tutor e escolha do pet
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/etapas_formulario_cadastro.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/cartao_opcao_app.dart';

class CabecalhoEtapaCadastro extends StatelessWidget {
  const CabecalhoEtapaCadastro({
    super.key,
    required this.titulo,
    required this.mostrarVoltar,
    required this.mostrarAjuda,
    required this.onVoltar,
    required this.onAjuda,
  });

  final String titulo;
  final bool mostrarVoltar;
  final bool mostrarAjuda;
  final VoidCallback onVoltar;
  final VoidCallback onAjuda;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (mostrarVoltar)
          IconButton(
            tooltip: 'Voltar',
            onPressed: onVoltar,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: CoresApp.surface,
              foregroundColor: CoresApp.darkBlue,
            ),
          ),
        if (mostrarVoltar) const SizedBox(width: EspacamentosApp.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADMISSÃO',
                style: TipografiaApp.captionBold.copyWith(
                  letterSpacing: 1,
                  color: CoresApp.textSecondary,
                ),
              ),
              const SizedBox(height: EspacamentosApp.xs),
              Text(titulo, style: TipografiaApp.heading2),
            ],
          ),
        ),
        if (mostrarAjuda)
          IconButton(
            tooltip: 'Ajuda',
            onPressed: onAjuda,
            icon: const Icon(Icons.help_outline_rounded),
          ),
      ],
    );
  }
}

class InicioCadastroRecepcao extends StatelessWidget {
  const InicioCadastroRecepcao({
    super.key,
    required this.onResponsavelExistente,
    required this.onNovoResponsavel,
  });

  final VoidCallback onResponsavelExistente;
  final VoidCallback onNovoResponsavel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O responsável já possui cadastro na clínica?',
          style: TipografiaApp.body,
        ),
        const SizedBox(height: EspacamentosApp.md),
        CartaoOpcaoApp(
          icon: Icons.person_search_outlined,
          titulo: 'Sim, já tem cadastro',
          descricao: 'Localize pelo CPF e escolha um pet',
          onTap: onResponsavelExistente,
        ),
        const SizedBox(height: EspacamentosApp.md),
        CartaoOpcaoApp(
          icon: Icons.person_add_alt_1_rounded,
          titulo: 'Não, é a primeira vez',
          descricao: 'Cadastre o responsável e o perfil do pet',
          onTap: onNovoResponsavel,
        ),
      ],
    );
  }
}

class CpfResponsavelCadastro extends StatelessWidget {
  const CpfResponsavelCadastro({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onBuscar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe o CPF para consultar o responsável e os pets vinculados',
            style: TipografiaApp.bodySmall,
          ),
          const SizedBox(height: EspacamentosApp.md),
          CampoFormularioApp(
            controller: controller,
            label: 'CPF do responsável',
            hint: '000.000.000-00',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: _validarCpf,
          ),
          const SizedBox(height: EspacamentosApp.md),
          BotaoPrincipal(
            label: 'Buscar responsável',
            icon: Icons.search_rounded,
            expanded: true,
            onPressed: onBuscar,
          ),
        ],
      ),
    );
  }

  String? _validarCpf(String? value) {
    final cpf = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return cpf.length == 11 ? null : 'Informe os 11 números do CPF';
  }
}

class PetsResponsavelCadastro extends StatelessWidget {
  const PetsResponsavelCadastro({
    super.key,
    required this.nomeResponsavel,
    required this.cpfMascarado,
    required this.petSelecionado,
    required this.onPetSelecionado,
    required this.onContinuar,
    required this.onCadastrarPet,
  });

  final String nomeResponsavel;
  final String cpfMascarado;
  final String? petSelecionado;
  final ValueChanged<String> onPetSelecionado;
  final VoidCallback onContinuar;
  final VoidCallback onCadastrarPet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PassoCadastro(ativo: 1),
        const SizedBox(height: EspacamentosApp.md),
        Text('Responsável localizado', style: TipografiaApp.heading3),
        const SizedBox(height: EspacamentosApp.sm),
        CartaoBase(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF1D8),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: CoresApp.darkBlue,
                ),
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomeResponsavel, style: TipografiaApp.bodyMedium),
                    Text('CPF · $cpfMascarado', style: TipografiaApp.caption),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: CoresApp.primary),
            ],
          ),
        ),
        const SizedBox(height: EspacamentosApp.lg),
        Text('Escolha um pet', style: TipografiaApp.heading3),
        const SizedBox(height: EspacamentosApp.sm),
        CartaoOpcaoApp(
          icon: Icons.pets_rounded,
          titulo: 'Mel',
          descricao: 'Cachorra · Golden Retriever · 3 anos',
          selecionado: petSelecionado == 'Mel',
          onTap: () => onPetSelecionado('Mel'),
          compacto: true,
        ),
        const SizedBox(height: EspacamentosApp.sm),
        CartaoOpcaoApp(
          icon: Icons.pets_rounded,
          titulo: 'Luna',
          descricao: 'Gata · Siamês · 2 anos',
          selecionado: petSelecionado == 'Luna',
          onTap: () => onPetSelecionado('Luna'),
          compacto: true,
        ),
        const SizedBox(height: EspacamentosApp.md),
        BotaoPrincipal(
          label: 'Continuar com pet selecionado',
          icon: Icons.arrow_forward_rounded,
          expanded: true,
          onPressed: onContinuar,
        ),
        const SizedBox(height: EspacamentosApp.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCadastrarPet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar outro pet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CoresApp.darkBlue,
              padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.md),
            ),
          ),
        ),
      ],
    );
  }
}

class SucessoCadastroRecepcao extends StatelessWidget {
  const SucessoCadastroRecepcao({
    super.key,
    required this.consulta,
    required this.nomePet,
    required this.dataFormatada,
    required this.onNovoCadastro,
  });

  final ConsultaRecepcao? consulta;
  final String nomePet;
  final String dataFormatada;
  final VoidCallback onNovoCadastro;

  @override
  Widget build(BuildContext context) {
    final agendada = consulta?.status == StatusConsultaRecepcao.agendada;

    return CartaoBase(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: CoresApp.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          Text(
            agendada ? 'Consulta agendada' : 'Paciente aguardando triagem',
            style: TipografiaApp.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          Text(
            agendada
                ? '${consulta!.pet} · $dataFormatada às ${consulta!.horario} · ${consulta!.profissional} · na chegada, confirme o tutor para iniciar o fluxo de triagem'
                : '$nomePet foi registrado na fila de triagem · depois da triagem, o veterinário dará continuidade ao atendimento',
            style: TipografiaApp.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EspacamentosApp.lg),
          BotaoPrincipal(
            label: 'Novo cadastro',
            icon: Icons.person_add_alt_1_rounded,
            expanded: true,
            onPressed: onNovoCadastro,
          ),
        ],
      ),
    );
  }
}
