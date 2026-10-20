// prontuario compartilhado dos pacientes internados
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class ProntuarioInternacao extends StatefulWidget {
  const ProntuarioInternacao({
    super.key,
    required this.consulta,
    this.responsavel,
  });

  final ConsultaRecepcao consulta;
  final String? responsavel;

  @override
  State<ProntuarioInternacao> createState() => _ProntuarioInternacaoState();
}

class _ProntuarioInternacaoState extends State<ProntuarioInternacao> {
  final _agenda = AgendaClinica.instancia;

  String get _responsavel =>
      widget.responsavel ??
      SessaoUsuario.instancia.nomeUsuario ??
      widget.consulta.profissional;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _agenda,
      builder: (context, _) {
        final prontuario = _agenda.prontuarioDa(widget.consulta);
        return Scaffold(
          backgroundColor: CoresApp.background,
          appBar: AppBar(
            backgroundColor: CoresApp.background,
            elevation: 0,
            title: Text('Prontuário da internação', style: TipografiaApp.heading3),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              EspacamentosApp.pagePadding,
              EspacamentosApp.sm,
              EspacamentosApp.pagePadding,
              EspacamentosApp.md,
            ),
            children: [
              _cabecalho(prontuario),
              const SizedBox(height: EspacamentosApp.md),
              _secaoAdmissao(prontuario),
              const SizedBox(height: EspacamentosApp.md),
              _secaoProcedimentos(prontuario),
              const SizedBox(height: EspacamentosApp.md),
              _secaoMedicacoes(prontuario),
              const SizedBox(height: EspacamentosApp.md),
              _secaoNotas(prontuario),
              const SizedBox(height: EspacamentosApp.xl),
            ],
          ),
          bottomNavigationBar: _barraAcao(prontuario),
        );
      },
    );
  }

  Widget _cabecalho(ProntuarioCompartilhado prontuario) {
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarPet(
                fotoUrl: widget.consulta.fotoPet,
                nome: widget.consulta.pet,
                tamanho: 56,
              ),
              const SizedBox(width: EspacamentosApp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.consulta.pet} · ${widget.consulta.especie}',
                      style: TipografiaApp.bodyMedium,
                    ),
                    Text('Tutor: ${widget.consulta.tutor}', style: TipografiaApp.caption),
                    Text(
                      'Veterinário: ${widget.consulta.profissional}',
                      style: TipografiaApp.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          IndicadorStatus(
            label: prontuario.internacaoAtiva
                ? 'Internação ativa'
                : 'Internação finalizada',
            color: prontuario.internacaoAtiva
                ? CoresApp.primary
                : CoresApp.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _secaoAdmissao(ProntuarioCompartilhado prontuario) {
    return _secao(
      titulo: 'Admissão',
      icone: Icons.local_hospital_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaInfo('Tipo', prontuario.internacao),
          if (prontuario.internacaoIniciadaEm != null)
            _linhaInfo('Admitido em', _dataHora(prontuario.internacaoIniciadaEm!)),
          if (prontuario.internacaoFinalizadaEm != null)
            _linhaInfo(
              'Finalizada em',
              _dataHora(prontuario.internacaoFinalizadaEm!),
            ),
          if (prontuario.observacoesTriagem.isNotEmpty)
            _linhaInfo('Triagem', prontuario.observacoesTriagem),
          if (prontuario.descricaoConsulta.isNotEmpty)
            _linhaInfo('Resumo clínico', prontuario.descricaoConsulta),
        ],
      ),
    );
  }

  Widget _secaoProcedimentos(ProntuarioCompartilhado prontuario) {
    return _secao(
      titulo: 'Procedimentos',
      icone: Icons.medical_services_outlined,
      acao: prontuario.internacaoAtiva ? _botaoAdicionar(_adicionarProcedimento) : null,
      child: prontuario.procedimentosInternacao.isEmpty
          ? _textoVazio('Nenhum procedimento registrado')
          : Column(
              children: [
                for (final procedimento in prontuario.procedimentosInternacao)
                  _cartaoProcedimento(procedimento, prontuario.internacaoAtiva),
              ],
            ),
    );
  }

  Widget _cartaoProcedimento(
    ProcedimentoInternacao procedimento,
    bool internacaoAtiva,
  ) {
    final concluidoEm = procedimento.concluidoEm;
    return _cartaoItem(
      titulo: procedimento.nome,
      icone: Icons.event_note_outlined,
      linhas: [
        'Agendado: ${_dataHora(procedimento.agendadoPara)}',
        if (procedimento.detalhes.isNotEmpty) procedimento.detalhes,
        if (concluidoEm != null) 'Concluído: ${_dataHora(concluidoEm)}',
        if (procedimento.detalhesConclusao.isNotEmpty)
          'Detalhes da conclusão: ${procedimento.detalhesConclusao}',
      ],
      acao: internacaoAtiva && concluidoEm == null
          ? OutlinedButton.icon(
              onPressed: () => _concluirProcedimento(procedimento),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Registrar conclusão'),
            )
          : null,
    );
  }

  Widget _secaoMedicacoes(ProntuarioCompartilhado prontuario) {
    return _secao(
      titulo: 'Medicações',
      icone: Icons.medication_outlined,
      acao: prontuario.internacaoAtiva
          ? _botaoAdicionar(_adicionarMedicacao)
          : null,
      child: prontuario.medicacoesInternacao.isEmpty
          ? _textoVazio('Nenhuma medicação registrada')
          : Column(
              children: [
                for (final medicacao in prontuario.medicacoesInternacao)
                  _cartaoMedicacao(medicacao, prontuario.internacaoAtiva),
              ],
            ),
    );
  }

  Widget _cartaoMedicacao(MedicacaoInternacao medicacao, bool internacaoAtiva) {
    return _cartaoItem(
      titulo: medicacao.nome,
      icone: Icons.medication_liquid_outlined,
      linhas: [
        'Dose: ${medicacao.dosagem}',
        'Frequência: ${medicacao.frequencia}',
        if (medicacao.detalhes.isNotEmpty) medicacao.detalhes,
      ],
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (medicacao.administracoes.isEmpty)
            _textoVazio('Nenhuma administração registrada')
          else ...[
            const Divider(height: EspacamentosApp.lg),
            for (final dose in medicacao.administracoes)
              _linhaInfo(
                _dataHora(dose.realizadaEm),
                [
                  'Administrado por ${dose.responsavel}',
                  if (dose.observacao.isNotEmpty) dose.observacao,
                ].join(' · '),
              ),
          ],
          if (internacaoAtiva) ...[
            const SizedBox(height: EspacamentosApp.sm),
            OutlinedButton.icon(
              onPressed: () => _registrarAdministracao(medicacao),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Registrar administração'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _secaoNotas(ProntuarioCompartilhado prontuario) {
    return _secao(
      titulo: 'Acompanhamento da equipe',
      icone: Icons.notes_rounded,
      acao: prontuario.internacaoAtiva ? _botaoAdicionar(_adicionarNota) : null,
      child: prontuario.notasInternacao.isEmpty
          ? _textoVazio('Nenhuma atualização registrada')
          : Column(
              children: [
                for (final nota in prontuario.notasInternacao)
                  _cartaoItem(
                    titulo: nota.texto,
                    icone: Icons.chat_bubble_outline_rounded,
                    linhas: ['${nota.autor} · ${_dataHora(nota.registradaEm)}'],
                  ),
              ],
            ),
    );
  }

  Widget _secao({
    required String titulo,
    required IconData icone,
    required Widget child,
    Widget? acao,
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
              ?acao,
            ],
          ),
          const SizedBox(height: EspacamentosApp.md),
          child,
        ],
      ),
    );
  }

  Widget _cartaoItem({
    required String titulo,
    required IconData icone,
    required List<String> linhas,
    Widget? acao,
    Widget? conteudo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: CartaoBase(
        color: CoresApp.surfaceSoft,
        padding: const EdgeInsets.all(EspacamentosApp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: CoresApp.darkBlue, size: 18),
                const SizedBox(width: EspacamentosApp.sm),
                Expanded(child: Text(titulo, style: TipografiaApp.bodyMedium)),
              ],
            ),
            for (final linha in linhas) ...[
              const SizedBox(height: EspacamentosApp.xs),
              Text(linha, style: TipografiaApp.caption),
            ],
            if (conteudo != null) ...[
              const SizedBox(height: EspacamentosApp.sm),
              conteudo,
            ],
            if (acao != null) ...[
              const SizedBox(height: EspacamentosApp.sm),
              Align(alignment: Alignment.centerLeft, child: acao),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaInfo(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(rotulo, style: TipografiaApp.caption),
        ),
        Expanded(child: Text(valor, style: TipografiaApp.captionBold)),
      ],
    ),
  );

  Widget _textoVazio(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.xs),
    child: Text(texto, style: TipografiaApp.caption),
  );

  Widget _botaoAdicionar(VoidCallback aoTocar) => IconButton(
    tooltip: 'Adicionar',
    onPressed: aoTocar,
    icon: const Icon(Icons.add_circle_outline_rounded, color: CoresApp.primary),
  );

  Widget _barraAcao(ProntuarioCompartilhado prontuario) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EspacamentosApp.pagePadding,
          EspacamentosApp.sm,
          EspacamentosApp.pagePadding,
          EspacamentosApp.md,
        ),
        child: prontuario.internacaoAtiva
            ? BotaoPrincipal(
                label: 'Finalizar internação',
                icon: Icons.check_circle_outline_rounded,
                expanded: true,
                backgroundColor: CoresApp.danger,
                onPressed: _finalizarInternacao,
              )
            : Text(
                'Internação finalizada · prontuário compartilhado',
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall,
              ),
      ),
    );
  }

  Future<void> _adicionarProcedimento() async {
    final campos = await _dialogoCampos(
      titulo: 'Adicionar procedimento',
      rotulos: const ['Procedimento', 'Detalhes (opcional)'],
    );
    if (campos == null || campos[0].isEmpty || !mounted) return;
    final agendadoPara = await _selecionarDataHora();
    if (agendadoPara == null || !mounted) return;
    _agenda.adicionarProcedimentoInternacao(
      widget.consulta,
      ProcedimentoInternacao(
        nome: campos[0],
        detalhes: campos[1],
        agendadoPara: agendadoPara,
      ),
    );
  }

  Future<void> _concluirProcedimento(ProcedimentoInternacao procedimento) async {
    final campos = await _dialogoCampos(
      titulo: 'Concluir procedimento',
      rotulos: const ['Detalhes da conclusão (opcional)'],
    );
    if (campos == null || !mounted) return;
    final concluidoEm = await _selecionarDataHora();
    if (concluidoEm == null || !mounted) return;
    _agenda.concluirProcedimentoInternacao(
      widget.consulta,
      procedimento,
      concluidoEm: concluidoEm,
      detalhes: campos[0],
    );
  }

  Future<void> _adicionarMedicacao() async {
    final campos = await _dialogoCampos(
      titulo: 'Adicionar medicação',
      rotulos: const [
        'Medicação',
        'Dose',
        'Frequência ou horário',
        'Detalhes (opcional)',
      ],
    );
    if (campos == null || campos[0].isEmpty) return;
    _agenda.adicionarMedicacaoInternacao(
      widget.consulta,
      MedicacaoInternacao(
        nome: campos[0],
        dosagem: campos[1],
        frequencia: campos[2],
        detalhes: campos[3],
      ),
    );
  }

  Future<void> _registrarAdministracao(MedicacaoInternacao medicacao) async {
    final campos = await _dialogoCampos(
      titulo: 'Registrar administração',
      rotulos: const ['Quem administrou', 'Observação (opcional)'],
      valoresIniciais: [_responsavel, ''],
    );
    if (campos == null || campos[0].isEmpty || !mounted) return;
    final realizadaEm = await _selecionarDataHora();
    if (realizadaEm == null || !mounted) return;
    _agenda.registrarAdministracaoMedicacao(
      widget.consulta,
      medicacao,
      AdministracaoMedicacao(
        realizadaEm: realizadaEm,
        responsavel: campos[0],
        observacao: campos[1],
      ),
    );
  }

  Future<void> _adicionarNota() async {
    final campos = await _dialogoCampos(
      titulo: 'Adicionar atualização',
      rotulos: const ['Nota de acompanhamento'],
      maxLines: 4,
    );
    if (campos == null || campos[0].isEmpty) return;
    _agenda.adicionarNotaInternacao(
      widget.consulta,
      NotaInternacao(
        texto: campos[0],
        autor: _responsavel,
        registradaEm: DateTime.now(),
      ),
    );
  }

  Future<void> _finalizarInternacao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar internação?'),
        content: Text(
          'A internação de ${widget.consulta.pet} será encerrada e ficará registrada no prontuário',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmar == true) _agenda.finalizarInternacao(widget.consulta);
  }

  Future<List<String>?> _dialogoCampos({
    required String titulo,
    required List<String> rotulos,
    List<String> valoresIniciais = const [],
    int maxLines = 1,
  }) =>
      showDialog<List<String>>(
        context: context,
        builder: (_) => _DialogoCamposInternacao(
          titulo: titulo,
          rotulos: rotulos,
          valoresIniciais: valoresIniciais,
          maxLines: maxLines,
        ),
      );

  Future<DateTime?> _selecionarDataHora() async {
    final inicial = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data == null || !mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
    );
    if (hora == null) return null;
    return DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
  }
}

class _DialogoCamposInternacao extends StatefulWidget {
  const _DialogoCamposInternacao({
    required this.titulo,
    required this.rotulos,
    required this.valoresIniciais,
    required this.maxLines,
  });

  final String titulo;
  final List<String> rotulos;
  final List<String> valoresIniciais;
  final int maxLines;

  @override
  State<_DialogoCamposInternacao> createState() =>
      _DialogoCamposInternacaoState();
}

class _DialogoCamposInternacaoState extends State<_DialogoCamposInternacao> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.rotulos.length,
      (index) => TextEditingController(
        text: index < widget.valoresIniciais.length
            ? widget.valoresIniciais[index]
            : '',
      ),
    );
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.rotulos.length; index++) ...[
              if (index > 0) const SizedBox(height: EspacamentosApp.sm),
              TextField(
                controller: _controllers[index],
                maxLines: widget.maxLines,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.rotulos[index],
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
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
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

String _dataHora(DateTime dataHora) {
  final dia = dataHora.day.toString().padLeft(2, '0');
  final mes = dataHora.month.toString().padLeft(2, '0');
  final hora = dataHora.hour.toString().padLeft(2, '0');
  final minuto = dataHora.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${dataHora.year} às $hora:$minuto';
}
