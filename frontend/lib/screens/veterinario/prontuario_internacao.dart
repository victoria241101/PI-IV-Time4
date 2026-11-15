// Prontuário compartilhado: evolução do pet, cuidados e dados da admissão.
import 'package:flutter/material.dart';
import 'package:pet_care/widgets/clinica/dialogo_campos_clinica.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
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
      SessaoUsuario.instancia.nomeUsuario ??
      widget.responsavel ??
      widget.consulta.profissional;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnimatedBuilder(
        animation: _agenda,
        builder: (context, _) {
          final prontuario = _agenda.prontuarioDa(widget.consulta);
          return Scaffold(
            backgroundColor: CoresApp.background,
            appBar: cabecalhoClinica('Prontuário da internação'),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EspacamentosApp.pagePadding,
                    EspacamentosApp.sm,
                    EspacamentosApp.pagePadding,
                    EspacamentosApp.sm,
                  ),
                  child: _cabecalho(prontuario),
                ),
                TabBar(
                  labelColor: CoresApp.primaryDark,
                  unselectedLabelColor: CoresApp.textSecondary,
                  indicatorColor: CoresApp.primaryDark,
                  labelStyle: TipografiaApp.captionBold,
                  tabs: const [
                    Tab(text: 'Evolução'),
                    Tab(text: 'Cuidados'),
                    Tab(text: 'Admissão'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _pagina([_secaoNotas(prontuario)]),
                      _pagina([
                        _secaoProcedimentos(prontuario),
                        const SizedBox(height: EspacamentosApp.sm),
                        _secaoMedicacoes(prontuario),
                      ]),
                      _pagina([_secaoAdmissao(prontuario)]),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _barraAcao(prontuario),
          );
        },
      ),
    );
  }

  Widget _pagina(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(EspacamentosApp.pagePadding),
    children: children,
  );

  Widget _cabecalho(ProntuarioCompartilhado prontuario) {
    return CartaoClinica(
      color: CoresApp.darkBlue,
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
                      style: TipografiaApp.heading3.copyWith(
                        color: CoresApp.textOnDarkBlue,
                      ),
                    ),
                    Text(
                      'Tutor: ${widget.consulta.tutor}',
                      style: TipografiaApp.caption.copyWith(
                        color: CoresApp.textOnDarkBlue,
                      ),
                    ),
                    Text(
                      'Veterinário: ${widget.consulta.profissional}',
                      style: TipografiaApp.caption.copyWith(
                        color: CoresApp.textOnDarkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: EspacamentosApp.sm),
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
            _linhaInfo(
              'Admitido em',
              _dataHora(prontuario.internacaoIniciadaEm!),
            ),
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
      acao: prontuario.internacaoAtiva
          ? _botaoAdicionar(_adicionarProcedimento)
          : null,
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

  Widget _secaoNotas(ProntuarioCompartilhado prontuario) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (prontuario.internacaoAtiva) ...[
        BotaoClinica(
          label: 'Adicionar nota',
          icon: Icons.edit_note_rounded,
          expanded: true,
          onPressed: _adicionarNota,
        ),
        const SizedBox(height: EspacamentosApp.md),
      ],
      Text('Atualizações do paciente', style: TipografiaApp.heading3),
      const SizedBox(height: EspacamentosApp.sm),
      if (prontuario.notasInternacao.isEmpty)
        CartaoClinica(
          child: Text(
            'Nenhuma atualização registrada',
            style: TipografiaApp.bodySmall,
          ),
        )
      else
        CartaoClinica(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < prontuario.notasInternacao.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: EspacamentosApp.xl,
                    color: CoresApp.divider,
                  ),
                Text(
                  'Registrado por ${prontuario.notasInternacao[i].autor}',
                  style: TipografiaApp.captionBold.copyWith(
                    color: CoresApp.primaryDark,
                  ),
                ),
                const SizedBox(height: EspacamentosApp.xs),
                Text(
                  prontuario.notasInternacao[i].texto,
                  style: TipografiaApp.bodyMedium,
                ),
              ],
            ],
          ),
        ),
    ],
  );

  Widget _secao({
    required String titulo,
    required IconData icone,
    required Widget child,
    Widget? acao,
  }) => SecaoClinica(titulo: titulo, icone: icone, acao: acao, child: child);

  Widget _cartaoItem({
    required String titulo,
    required IconData icone,
    required List<String> linhas,
    Widget? acao,
    Widget? conteudo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: CartaoClinica(
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
        SizedBox(width: 112, child: Text(rotulo, style: TipografiaApp.caption)),
        Expanded(child: Text(valor, style: TipografiaApp.captionBold)),
      ],
    ),
  );

  Widget _textoVazio(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: EspacamentosApp.xs),
    child: Text(texto, style: TipografiaApp.caption),
  );

  Widget _botaoAdicionar(VoidCallback aoTocar) =>
      botaoAdicionarClinica(aoTocar);

  Widget _barraAcao(ProntuarioCompartilhado prontuario) {
    return RodapeClinica(
      child: prontuario.internacaoAtiva
          ? BotaoClinica(
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

  Future<void> _concluirProcedimento(
    ProcedimentoInternacao procedimento,
  ) async {
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
      rotulos: const ['Nota (data e horário opcionais)'],
      maxLines: 4,
    );
    if (campos == null || campos[0].isEmpty || !mounted) return;
    _agenda.adicionarNotaInternacao(
      widget.consulta,
      NotaInternacao(texto: campos[0], autor: _responsavel),
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
  }) => showDialog<List<String>>(
    context: context,
    builder: (_) => DialogoCamposClinica(
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

String _dataHora(DateTime dataHora) {
  final dia = dataHora.day.toString().padLeft(2, '0');
  final mes = dataHora.month.toString().padLeft(2, '0');
  final hora = dataHora.hour.toString().padLeft(2, '0');
  final minuto = dataHora.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${dataHora.year} às $hora:$minuto';
}
