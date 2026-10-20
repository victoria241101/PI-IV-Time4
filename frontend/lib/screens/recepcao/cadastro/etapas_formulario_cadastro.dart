// formulários de dados do responsável e perfil do pet
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';

class DadosResponsavelCadastro extends StatelessWidget {
  const DadosResponsavelCadastro({
    super.key,
    required this.formKey,
    required this.nomeController,
    required this.cpfController,
    required this.telefoneController,
    required this.emailController,
    required this.enderecoController,
    required this.validarNome,
    required this.validarTelefone,
    required this.onContinuar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController cpfController;
  final TextEditingController telefoneController;
  final TextEditingController emailController;
  final TextEditingController enderecoController;
  final FormFieldValidator<String> validarNome;
  final FormFieldValidator<String> validarTelefone;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PassoCadastro(ativo: 0),
          const SizedBox(height: EspacamentosApp.md),
          SecaoCadastro(
            icon: Icons.person_outline_rounded,
            titulo: 'Informações do responsável',
            child: Column(
              children: [
                CampoFormularioApp(
                  controller: nomeController,
                  label: 'Nome completo',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: validarNome,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: cpfController,
                  label: 'CPF',
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
                CampoFormularioApp(
                  controller: telefoneController,
                  label: 'Celular',
                  hint: '(11) 99999-9999',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: validarTelefone,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: emailController,
                  label: 'E-mail',
                  hint: 'nome@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: enderecoController,
                  label: 'Endereço residencial',
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          BotaoPrincipal(
            label: 'Continuar para perfil do pet',
            icon: Icons.arrow_forward_rounded,
            expanded: true,
            onPressed: onContinuar,
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

class PerfilPetCadastro extends StatelessWidget {
  const PerfilPetCadastro({
    super.key,
    required this.formKey,
    required this.nomeResponsavel,
    required this.cpfResponsavel,
    required this.telefoneResponsavel,
    required this.emailResponsavel,
    required this.enderecoResponsavel,
    required this.nomePetController,
    required this.racaController,
    required this.idadeController,
    required this.condicoesController,
    required this.especie,
    required this.sexo,
    required this.castrado,
    required this.possuiMicrochip,
    required this.fotoSelecionada,
    required this.validarNomePet,
    required this.onEditarResponsavel,
    required this.onEspecieChanged,
    required this.onSexoChanged,
    required this.onCastradoChanged,
    required this.onMicrochipChanged,
    required this.onFotoTocada,
    required this.onFotoSelecionada,
    required this.onContinuar,
  });

  final GlobalKey<FormState> formKey;
  final String nomeResponsavel;
  final String cpfResponsavel;
  final String telefoneResponsavel;
  final String emailResponsavel;
  final String enderecoResponsavel;
  final TextEditingController nomePetController;
  final TextEditingController racaController;
  final TextEditingController idadeController;
  final TextEditingController condicoesController;
  final String especie;
  final String sexo;
  final bool castrado;
  final bool possuiMicrochip;
  final bool fotoSelecionada;
  final FormFieldValidator<String> validarNomePet;
  final VoidCallback onEditarResponsavel;
  final ValueChanged<String> onEspecieChanged;
  final ValueChanged<String> onSexoChanged;
  final ValueChanged<bool> onCastradoChanged;
  final ValueChanged<bool> onMicrochipChanged;
  final VoidCallback onFotoTocada;
  final VoidCallback onFotoSelecionada;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PassoCadastro(ativo: 1),
          const SizedBox(height: EspacamentosApp.md),
          SecaoCadastro(
            icon: Icons.person_outline_rounded,
            titulo: 'Responsável',
            trailing: TextButton(
              onPressed: onEditarResponsavel,
              child: const Text('Editar'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DadoCadastro(titulo: 'Nome completo', valor: nomeResponsavel),
                DadoCadastro(titulo: 'CPF', valor: cpfResponsavel),
                DadoCadastro(titulo: 'Celular', valor: telefoneResponsavel),
                if (emailResponsavel.isNotEmpty)
                  DadoCadastro(titulo: 'E-mail', valor: emailResponsavel),
                if (enderecoResponsavel.isNotEmpty)
                  DadoCadastro(titulo: 'Endereço', valor: enderecoResponsavel),
              ],
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          SecaoCadastro(
            icon: Icons.pets_rounded,
            titulo: 'Perfil clínico do pet',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeletorFotoPet(
                  selecionada: fotoSelecionada,
                  onFotoTocada: onFotoTocada,
                  onFotoSelecionada: onFotoSelecionada,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: nomePetController,
                  label: 'Nome do pet',
                  prefixIcon: Icons.pets_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: validarNomePet,
                ),
                const SizedBox(height: EspacamentosApp.md),
                Text('Espécie', style: TipografiaApp.captionBold),
                const SizedBox(height: EspacamentosApp.sm),
                OpcoesCadastro(
                  valores: const ['Cachorro', 'Gato', 'Exótico'],
                  selecionado: especie,
                  onSelecionar: onEspecieChanged,
                ),
                const SizedBox(height: EspacamentosApp.md),
                Text('Sexo', style: TipografiaApp.captionBold),
                const SizedBox(height: EspacamentosApp.sm),
                OpcoesCadastro(
                  valores: const ['Macho', 'Fêmea'],
                  selecionado: sexo,
                  onSelecionar: onSexoChanged,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: racaController,
                  label: 'Raça',
                  prefixIcon: Icons.search_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: EspacamentosApp.md),
                LinhaIdadeMicrochip(
                  idadeController: idadeController,
                  possuiMicrochip: possuiMicrochip,
                  onMicrochipChanged: onMicrochipChanged,
                ),
                const SizedBox(height: EspacamentosApp.md),
                SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: EspacamentosApp.sm,
                  ),
                  value: castrado,
                  onChanged: onCastradoChanged,
                  activeThumbColor: CoresApp.primary,
                  title: Text('Castrado(a)', style: TipografiaApp.bodyMedium),
                ),
                const SizedBox(height: EspacamentosApp.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Condições pré-existentes / alergias',
                        style: TipografiaApp.captionBold,
                      ),
                    ),
                    Text(
                      'Atenção',
                      style: TipografiaApp.captionBold.copyWith(
                        color: CoresApp.accentOrangeDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EspacamentosApp.sm),
                CampoFormularioApp(
                  controller: condicoesController,
                  label: 'Observações clínicas',
                  hint: 'Descreva condições ou alergias conhecidas',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          BotaoPrincipal(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            expanded: true,
            onPressed: onContinuar,
          ),
        ],
      ),
    );
  }
}

class LinhaIdadeMicrochip extends StatelessWidget {
  const LinhaIdadeMicrochip({
    super.key,
    required this.idadeController,
    required this.possuiMicrochip,
    required this.onMicrochipChanged,
  });

  final TextEditingController idadeController;
  final bool possuiMicrochip;
  final ValueChanged<bool> onMicrochipChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final idade = CampoFormularioApp(
          controller: idadeController,
          label: 'Idade ou nascimento',
          hint: 'Ex.: 2 anos e 3 meses',
        );
        final microchip = SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EspacamentosApp.sm,
          ),
          value: possuiMicrochip,
          onChanged: onMicrochipChanged,
          activeThumbColor: CoresApp.primary,
          title: Text('Possui microchip?', style: TipografiaApp.bodyMedium),
        );

        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              idade,
              const SizedBox(height: EspacamentosApp.md),
              microchip,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: idade),
            const SizedBox(width: EspacamentosApp.sm),
            Expanded(child: microchip),
          ],
        );
      },
    );
  }
}

class PassoCadastro extends StatelessWidget {
  const PassoCadastro({super.key, required this.ativo, this.concluido = false});

  final int ativo;
  final bool concluido;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacamentosApp.md,
        vertical: EspacamentosApp.sm + 2,
      ),
      child: Row(
        children: [
          _etapa(
            numero: 1,
            titulo: 'Responsável',
            ativa: ativo == 0,
            concluida: ativo > 0 || concluido,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(
                horizontal: EspacamentosApp.sm,
              ),
              color: ativo > 0 || concluido
                  ? CoresApp.primaryLight
                  : CoresApp.divider,
            ),
          ),
          _etapa(
            numero: 2,
            titulo: 'Perfil do pet',
            ativa: ativo == 1,
            concluida: concluido && ativo > 1,
          ),
        ],
      ),
    );
  }

  Widget _etapa({
    required int numero,
    required String titulo,
    required bool ativa,
    required bool concluida,
  }) {
    final cor = ativa || concluida ? CoresApp.darkBlue : CoresApp.iconDefault;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: cor,
          child: Icon(
            concluida ? Icons.check_rounded : Icons.circle,
            size: concluida ? 14 : 7,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: EspacamentosApp.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ETAPA $numero',
              style: TipografiaApp.caption.copyWith(fontSize: 9),
            ),
            Text(titulo, style: TipografiaApp.captionBold.copyWith(color: cor)),
          ],
        ),
      ],
    );
  }
}

class SecaoCadastro extends StatelessWidget {
  const SecaoCadastro({
    super.key,
    required this.icon,
    required this.titulo,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String titulo;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CartaoBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(
                    EspacamentosApp.radiusFull,
                  ),
                ),
                child: Icon(icon, color: CoresApp.primary, size: 17),
              ),
              const SizedBox(width: EspacamentosApp.sm),
              Expanded(child: Text(titulo, style: TipografiaApp.bodyMedium)),
              ?trailing,
            ],
          ),
          const Divider(height: EspacamentosApp.lg),
          child,
        ],
      ),
    );
  }
}

class DadoCadastro extends StatelessWidget {
  const DadoCadastro({super.key, required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TipografiaApp.caption),
          const SizedBox(height: 2),
          Text(
            valor.isEmpty ? 'Não informado' : valor,
            style: TipografiaApp.bodyMedium.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class SeletorFotoPet extends StatelessWidget {
  const SeletorFotoPet({
    super.key,
    required this.selecionada,
    required this.onFotoTocada,
    required this.onFotoSelecionada,
  });

  final bool selecionada;
  final VoidCallback onFotoTocada;
  final VoidCallback onFotoSelecionada;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onFotoTocada,
          borderRadius: BorderRadius.circular(EspacamentosApp.radiusFull),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DF),
              shape: BoxShape.circle,
              border: Border.all(color: CoresApp.divider, width: 1.5),
            ),
            child: Icon(
              selecionada
                  ? Icons.check_circle_outline_rounded
                  : Icons.add_a_photo_outlined,
              color: CoresApp.darkBlue,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: EspacamentosApp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto do pet', style: TipografiaApp.bodyMedium),
              TextButton.icon(
                onPressed: onFotoSelecionada,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  selecionada ? 'Foto selecionada' : 'Selecionar',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OpcoesCadastro extends StatelessWidget {
  const OpcoesCadastro({
    super.key,
    required this.valores,
    required this.selecionado,
    required this.onSelecionar,
  });

  final List<String> valores;
  final String selecionado;
  final ValueChanged<String> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: EspacamentosApp.sm,
      runSpacing: EspacamentosApp.sm,
      children: valores.map((valor) {
        final ativo = valor == selecionado;
        return ChoiceChip(
          label: Text(valor),
          selected: ativo,
          onSelected: (_) => onSelecionar(valor),
          labelStyle: TipografiaApp.captionBold.copyWith(
            color: ativo ? CoresApp.darkBlue : CoresApp.textSecondary,
          ),
          selectedColor: const Color(0xFFE0F7FA),
          side: BorderSide(
            color: ativo ? CoresApp.primary : CoresApp.divider,
            width: ativo ? 1.5 : 1,
          ),
          shape: const StadiumBorder(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
