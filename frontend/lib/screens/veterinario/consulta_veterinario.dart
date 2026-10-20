// prontuario e atendimento veterinario da consulta
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class ConsultaVeterinario extends StatefulWidget {
  const ConsultaVeterinario({super.key, required this.consulta});

  final ConsultaRecepcao consulta;

  @override
  State<ConsultaVeterinario> createState() => _ConsultaVeterinarioState();
}

class _ConsultaVeterinarioState extends State<ConsultaVeterinario> {
  late final ProntuarioCompartilhado _prontuario;
  late final TextEditingController _descricaoController;
  late final TextEditingController _retornoController;
  late final TextEditingController _observacoesController;

  bool get _emConsulta =>
      widget.consulta.status == StatusConsultaRecepcao.emConsulta;
  bool get _finalizada =>
      widget.consulta.status == StatusConsultaRecepcao.finalizado;
  bool get _aguardandoVeterinario =>
      widget.consulta.status == StatusConsultaRecepcao.aguardandoVeterinario;

  @override
  void initState() {
    super.initState();
    _prontuario = AgendaClinica.instancia
        .prontuarioDa(widget.consulta)
        .copiar();
    _descricaoController = TextEditingController(
      text: _prontuario.descricaoConsulta,
    );
    _retornoController = TextEditingController(
      text: _prontuario.retornoRecomendado,
    );
    _observacoesController = TextEditingController(
      text: _prontuario.observacoes,
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _retornoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = widget.consulta;
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Consulta', style: TipografiaApp.heading3),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            EspacamentosApp.pagePadding,
            EspacamentosApp.sm,
            EspacamentosApp.pagePadding,
            EspacamentosApp.md,
          ),
          children: [
            _cabecalhoConsulta(consulta),
            const SizedBox(height: EspacamentosApp.md),
            _secaoTriagem(),
            if (_aguardandoVeterinario) ...[
              const SizedBox(height: EspacamentosApp.md),
              _aviso(
                Icons.medical_services_outlined,
                'Triagem concluída',
                'Inicie a consulta para registrar a avaliação e as condutas',
                CoresApp.primary,
              ),
            ] else if (!_finalizada && !_emConsulta) ...[
              const SizedBox(height: EspacamentosApp.md),
              _aviso(
                Icons.hourglass_top_rounded,
                'Aguardando triagem',
                'O prontuário será liberado para o veterinário quando a enfermagem concluir a triagem',
                CoresApp.accentOrangeDark,
              ),
            ],
            if (_emConsulta || _finalizada) ...[
              const SizedBox(height: EspacamentosApp.md),
              _secaoDescricao(),
              const SizedBox(height: EspacamentosApp.md),
              _secaoMedicamentos(),
              const SizedBox(height: EspacamentosApp.md),
              _secaoExames(),
              const SizedBox(height: EspacamentosApp.md),
              _secaoInternacao(),
              const SizedBox(height: EspacamentosApp.md),
              _secaoRetorno(),
              const SizedBox(height: EspacamentosApp.md),
              _secaoObservacoes(),
            ],
            const SizedBox(height: EspacamentosApp.xl),
          ],
        ),
      ),
      bottomNavigationBar: _barraAcoes(),
    );
  }

  Widget _cabecalhoConsulta(ConsultaRecepcao consulta) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text(
                      '${consulta.pet} · ${consulta.especie}',
                      style: TipografiaApp.bodyMedium,
                    ),
                    Text(
                      '${consulta.horario} · ${consulta.profissional} · ${consulta.sala}',
                      style: TipografiaApp.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          IndicadorStatus(
            label: consulta.status.rotulo,
            color: consulta.status.cor,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          _linhaInfo('Tutor', consulta.tutor),
        ],
      ),
    );
  }

  Widget _secaoTriagem() {
    final observacoes = _prontuario.observacoesTriagem.trim();
    return _secao(
      titulo: 'Informações da triagem',
      icone: Icons.monitor_heart_outlined,
      child: Text(
        observacoes.isEmpty
            ? 'A enfermagem ainda não registrou informações da triagem'
            : observacoes,
        style: TipografiaApp.bodySmall.copyWith(
          color: observacoes.isEmpty
              ? CoresApp.textSecondary
              : CoresApp.textPrimary,
        ),
      ),
    );
  }

  Widget _secaoDescricao() {
    return _secao(
      titulo: 'Consulta',
      icone: Icons.description_outlined,
      child: Column(
        children: [
          _campo(
            _descricaoController,
            label: 'Descrição da consulta',
            hint: 'Registre a avaliação e o que foi realizado',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _secaoMedicamentos() {
    return _secao(
      titulo: 'Medicações',
      icone: Icons.medication_outlined,
      trailing: _finalizada ? null : _adicionarBotao(_adicionarMedicamento),
      child: _prontuario.medicamentos.isEmpty
          ? Text('Nenhuma medicação registrada', style: TipografiaApp.bodySmall)
          : Column(
              children: [
                for (final medicamento in _prontuario.medicamentos)
                  _itemPlano(
                    medicamento.nome,
                    '${medicamento.dosagem} · ${medicamento.orientacao}',
                    Icons.medication_liquid_outlined,
                  ),
              ],
            ),
    );
  }

  Widget _secaoExames() {
    return _secao(
      titulo: 'Exames',
      icone: Icons.biotech_outlined,
      trailing: _finalizada ? null : _adicionarBotao(_adicionarExame),
      child: _prontuario.exames.isEmpty
          ? Text('Nenhum exame solicitado', style: TipografiaApp.bodySmall)
          : Column(
              children: [
                for (final exame in _prontuario.exames)
                  _itemPlano(
                    exame,
                    'Solicitado pelo veterinário',
                    Icons.biotech_outlined,
                  ),
              ],
            ),
    );
  }

  Widget _secaoInternacao() {
    return _secao(
      titulo: 'Indicação de internação',
      icone: Icons.local_hospital_outlined,
      child: _finalizada
          ? Text(
              _prontuario.internacao.isEmpty
                  ? 'Não indicada'
                  : _prontuario.internacao,
              style: TipografiaApp.bodySmall,
            )
          : DropdownButtonFormField<String>(
              initialValue: _prontuario.internacao,
              decoration: const InputDecoration(
                labelText: 'Conduta',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Não indicada')),
                DropdownMenuItem(
                  value: 'Programada (procedimento)',
                  child: Text('Programada · procedimento'),
                ),
                DropdownMenuItem(
                  value: 'Imediata (emergência)',
                  child: Text('Imediata · emergência'),
                ),
              ],
              onChanged: (valor) =>
                  setState(() => _prontuario.internacao = valor ?? ''),
            ),
    );
  }

  Widget _secaoRetorno() {
    return _secao(
      titulo: 'Recomendação de retorno',
      icone: Icons.event_repeat_outlined,
      child: _finalizada
          ? Text(
              _prontuario.retornoRecomendado.isEmpty
                  ? 'Nenhuma recomendação registrada'
                  : _prontuario.retornoRecomendado,
              style: TipografiaApp.bodySmall,
            )
          : _campo(
              _retornoController,
              label: 'Em quanto tempo o tutor deve voltar?',
              hint: 'Ex.: retorno em 15 dias',
            ),
    );
  }

  Widget _secaoObservacoes() {
    return _secao(
      titulo: 'Observações para a equipe',
      icone: Icons.notes_rounded,
      child: _finalizada
          ? Text(
              _prontuario.observacoes.isEmpty
                  ? 'Nenhuma observação registrada'
                  : _prontuario.observacoes,
              style: TipografiaApp.bodySmall,
            )
          : _campo(
              _observacoesController,
              label: 'Orientações para a enfermagem',
              hint: 'Cuidados e acompanhamento durante o tratamento',
              maxLines: 3,
            ),
    );
  }

  Widget _secao({
    required String titulo,
    required IconData icone,
    required Widget child,
    Widget? trailing,
  }) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: CoresApp.primary, size: 20),
              const SizedBox(width: EspacamentosApp.sm),
              Expanded(child: Text(titulo, style: TipografiaApp.bodyMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          child,
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController controller, {
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return IgnorePointer(
      ignoring: _finalizada,
      child: CampoFormularioApp(
        controller: controller,
        label: label,
        hint: hint,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _linhaInfo(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: EspacamentosApp.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(rotulo, style: TipografiaApp.caption),
          ),
          Expanded(child: Text(valor, style: TipografiaApp.captionBold)),
        ],
      ),
    );
  }

  Widget _aviso(IconData icone, String titulo, String descricao, Color cor) {
    return CartaoBase(
      color: cor.withAlpha(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TipografiaApp.bodyMedium),
                Text(descricao, style: TipografiaApp.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlano(String titulo, String descricao, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: CoresApp.darkBlue, size: 18),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TipografiaApp.bodyMedium),
                Text(descricao, style: TipografiaApp.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adicionarBotao(VoidCallback aoTocar) => IconButton(
    tooltip: 'Adicionar',
    onPressed: aoTocar,
    icon: const Icon(Icons.add_circle_outline_rounded, color: CoresApp.primary),
  );

  Widget _barraAcoes() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EspacamentosApp.pagePadding,
          EspacamentosApp.sm,
          EspacamentosApp.pagePadding,
          EspacamentosApp.md,
        ),
        child: _aguardandoVeterinario
            ? BotaoPrincipal(
                label: 'Iniciar consulta',
                icon: Icons.medical_services_outlined,
                expanded: true,
                onPressed: _iniciarConsulta,
            )
            : _emConsulta
            ? BotaoPrincipal(
                label: 'Finalizar consulta',
                icon: Icons.check_circle_outline_rounded,
                expanded: true,
                onPressed: _finalizarConsulta,
              )
            : _finalizada
            ? Text(
                'Consulta finalizada · prontuário compartilhado',
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _iniciarConsulta() {
    AgendaClinica.instancia.atualizarStatus(
      widget.consulta,
      StatusConsultaRecepcao.emConsulta,
    );
    setState(() {});
  }

  void _finalizarConsulta() {
    _atualizarProntuario();
    AgendaClinica.instancia.finalizarConsulta(
      widget.consulta,
      _prontuario,
    );
    _mensagem('Consulta finalizada e prontuário atualizado');
    Navigator.of(context).pop();
  }

  void _atualizarProntuario() {
    _prontuario
      ..descricaoConsulta = _descricaoController.text.trim()
      ..retornoRecomendado = _retornoController.text.trim()
      ..observacoes = _observacoesController.text.trim();
  }

  Future<void> _adicionarMedicamento() async {
    final campos = await _dialogoCampos(
      titulo: 'Adicionar medicação',
      rotulos: const ['Medicamento', 'Dose ou frequência', 'Orientações'],
    );
    if (campos == null || campos[0].isEmpty) return;
    setState(() {
      _prontuario.medicamentos.add(
        MedicamentoPrescrito(
          nome: campos[0],
          dosagem: campos[1],
          orientacao: campos[2],
        ),
      );
    });
  }

  Future<void> _adicionarExame() async {
    final campos = await _dialogoCampos(
      titulo: 'Solicitar exame',
      rotulos: const ['Nome do exame'],
    );
    if (campos == null || campos[0].isEmpty) return;
    setState(() => _prontuario.exames.add(campos[0]));
  }

  Future<List<String>?> _dialogoCampos({
    required String titulo,
    required List<String> rotulos,
  }) async {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => _DialogoCampos(titulo: titulo, rotulos: rotulos),
    );
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }
}

class _DialogoCampos extends StatefulWidget {
  const _DialogoCampos({required this.titulo, required this.rotulos});

  final String titulo;
  final List<String> rotulos;

  @override
  State<_DialogoCampos> createState() => _DialogoCamposState();
}

class _DialogoCamposState extends State<_DialogoCampos> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.rotulos.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo, style: TipografiaApp.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.rotulos.length; i++) ...[
            if (i > 0) const SizedBox(height: EspacamentosApp.sm),
            CampoFormularioApp(
              controller: _controllers[i],
              label: widget.rotulos[i],
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _controllers.map((controller) => controller.text.trim()).toList(),
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
