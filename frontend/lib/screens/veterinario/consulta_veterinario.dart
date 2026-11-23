
 // prontuario e atendimento veterinario da consulta
import 'package:flutter/material.dart';
import 'package:pet_care/widgets/clinica/dialogo_campos_clinica.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class ConsultaVeterinario extends StatefulWidget {
  const ConsultaVeterinario({super.key, required this.consulta});

  final ConsultaRecepcao consulta;

  @override
  State<ConsultaVeterinario> createState() => _ConsultaVeterinarioState();
}

class _ConsultaVeterinarioState extends State<ConsultaVeterinario> {
  late final ProntuarioCompartilhado _prontuario;
  final _camposAtendimento = <String, TextEditingController>{
    for (final nome in [
      'Anamnese',
      'Exame físico',
      'Diagnóstico',
      'Prognóstico',
      'Tratamento',
    ])
      nome: TextEditingController(),
  };
  bool _salvando = false;
  bool get _atendimentoSalvo => _prontuario.atendimentoId != null;
  bool _dadosCarregados = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _carregarProntuario();
      } catch (erro) {
        if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
      }
    });
  }

  Future<void> _carregarProntuario() async {
    final dados = await AgendaClinica.instancia.servico.lerProntuario(
      widget.consulta.id,
    );
    if (!mounted) return;
    final triagem = dados['triagem'];
    if (triagem is Map) {
      _prontuario.observacoesTriagem =
          'Peso: ${triagem['peso']} kg\nTemperatura: ${triagem['temperatura']} °C\nSintomas: ${triagem['sintomas']}\n${triagem['observacoes'] ?? ''}';
    }
    final atendimento = dados['atendimento'];
    _prontuario.atendimentoId = atendimento is Map
        ? atendimento['_id'] as String
        : null;
    if (atendimento is Map) {
      const chaves = {
        'Anamnese': 'anamnese',
        'Exame físico': 'exameFisico',
        'Diagnóstico': 'diagnostico',
        'Prognóstico': 'prognostico',
        'Tratamento': 'tratamento',
      };
      for (final campo in chaves.entries) {
        _camposAtendimento[campo.key]!.text =
            '${atendimento[campo.value] ?? ''}';
      }
      _descricaoController.text = '${atendimento['anamnese'] ?? ''}';
      _observacoesController.text = '${atendimento['observacoes'] ?? ''}';
    }
    if (_prontuario.atendimentoId != null && widget.consulta.petId != null) {
      final prescricoes = await AgendaClinica.instancia.servico
          .listarPrescricoes(
            widget.consulta.petId!,
            atendimentoId: _prontuario.atendimentoId,
          );
      if (!mounted) return;
      _prontuario.medicamentos
        ..clear()
        ..addAll(prescricoes);
      final exames = await AgendaClinica.instancia.servico
          .listarExames(widget.consulta.petId!);
      if (!mounted) return;
      _prontuario.exames
        ..clear()
        ..addAll(
          exames.where(
            (e) =>
                _prontuario.atendimentoId == null ||
                e.atendimentoId == _prontuario.atendimentoId,
          ),
        );
    } else {
      _prontuario.medicamentos.clear();
      _prontuario.exames.clear();
    }
    setState(() => _dadosCarregados = true);
  }

  @override
  void dispose() {
    for (final campo in _camposAtendimento.values) {
      campo.dispose();
    }
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
      appBar: cabecalhoClinica('Consulta'),
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
            const SizedBox(height: EspacamentosApp.sm),
            _secaoTriagem(),
            if (_emConsulta || _finalizada)
              for (final campo in _camposAtendimento.entries)
                CampoFormularioApp(
                  controller: campo.value,
                  label: campo.key,
                  enabled:
                      _dadosCarregados &&
                      !_finalizada &&
                      !_salvando &&
                      !_atendimentoSalvo,
                  maxLines: 3,
                ),
            if (_aguardandoVeterinario) ...[
              const SizedBox(height: EspacamentosApp.sm),
              _aviso(
                Icons.medical_services_outlined,
                'Triagem concluída',
                'Inicie a consulta para registrar a avaliação e as condutas',
                CoresApp.primary,
              ),
            ] else if (!_finalizada && !_emConsulta) ...[
              const SizedBox(height: EspacamentosApp.sm),
              _aviso(
                Icons.hourglass_top_rounded,
                'Aguardando triagem',
                'O prontuário será liberado para o veterinário quando a enfermagem concluir a triagem',
                CoresApp.accentOrangeDark,
              ),
            ],
            if (_emConsulta || _finalizada) ...[
              const SizedBox(height: EspacamentosApp.sm),
              _secaoDescricao(),
              const SizedBox(height: EspacamentosApp.sm),
              _secaoMedicamentos(),
              const SizedBox(height: EspacamentosApp.sm),
              _secaoExames(),
              const SizedBox(height: EspacamentosApp.sm),
              if (!_finalizada)
                Padding(
                  padding: const EdgeInsets.only(bottom: EspacamentosApp.xs),
                  child: Text(
                    'Internação ainda é gerenciada localmente.',
                    style: TipografiaApp.caption,
                  ),
                ),
              _secaoInternacao(),
              const SizedBox(height: EspacamentosApp.sm),
              _secaoRetorno(),
              const SizedBox(height: EspacamentosApp.sm),
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
    return CartaoClinica(
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
          const SizedBox(height: EspacamentosApp.sm),
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
      trailing: _emConsulta && _dadosCarregados && !_salvando
          ? _adicionarBotao(_adicionarMedicamento)
          : null,
      child: _prontuario.medicamentos.isEmpty
          ? Text('Nenhuma medicação registrada', style: TipografiaApp.bodySmall)
          : Column(
              children: [
                for (final medicamento in _prontuario.medicamentos)
                  _itemPlano(
                    medicamento.nome,
                    '${medicamento.dosagem} · ${medicamento.frequencia} · ${medicamento.duracao}\n${medicamento.orientacao} · ${medicamento.status}',
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
      trailing: _emConsulta && _dadosCarregados && !_salvando
          ? _adicionarBotao(_adicionarExame)
          : null,
      child: _prontuario.exames.isEmpty
          ? Text('Nenhum exame solicitado', style: TipografiaApp.bodySmall)
          : Column(
              children: [
                for (final exame in _prontuario.exames)
                  _itemExame(exame),
              ],
            ),
    );
  }

  Widget _itemExame(ExameVeterinario exame) {
    final concluido = exame.concluido;
    final descricao = concluido
        ? 'Resultado: ${exame.resultado ?? ''}'
        : 'Aguardando resultado · ${exame.tipo}';
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            concluido ? Icons.check_circle_outline : Icons.biotech_outlined,
            color: concluido ? CoresApp.primary : CoresApp.darkBlue,
            size: 18,
          ),
          const SizedBox(width: EspacamentosApp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exame.nome, style: TipografiaApp.bodyMedium),
                Text(descricao, style: TipografiaApp.caption),
                if (exame.justificativa.isNotEmpty)
                  Text(
                    exame.justificativa,
                    style: TipografiaApp.caption.copyWith(
                      color: CoresApp.textSecondary,
                    ),
                  ),
              ],
            ),
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
              isExpanded: true,
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
  }) =>
      SecaoClinica(titulo: titulo, icone: icone, acao: trailing, child: child);

  Widget _campo(
    TextEditingController controller, {
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return IgnorePointer(
      ignoring: _finalizada || _salvando || _atendimentoSalvo,
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
    return CartaoClinica(
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

  Widget _adicionarBotao(VoidCallback aoTocar) =>
      botaoAdicionarClinica(aoTocar);

  Widget _barraAcoes() {
    return RodapeClinica(
      child: _aguardandoVeterinario
          ? BotaoClinica(
              label: 'Iniciar consulta',
              icon: Icons.medical_services_outlined,
              expanded: true,
              onPressed: _iniciarConsulta,
            )
          : _emConsulta
          ? BotaoClinica(
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
    );
  }

  Future<void> _iniciarConsulta() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      if (!_dadosCarregados) await _carregarProntuario();
      if (!mounted) return;
      await AgendaClinica.instancia.servico.iniciarAtendimento(
        widget.consulta.id,
      );
      if (!mounted) return;
      AgendaClinica.instancia.atualizarStatus(
        widget.consulta,
        StatusConsultaRecepcao.emConsulta,
      );
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _finalizarConsulta() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await _garantirAtendimentoSalvo();
      if (!mounted) return;
      await AgendaClinica.instancia.servico.finalizarAtendimento(
        widget.consulta.id,
      );
      if (!mounted) return;
      _atualizarProntuario();
      AgendaClinica.instancia.finalizarConsulta(widget.consulta, _prontuario);
      _mensagem('Atendimento clínico salvo e consulta finalizada na API');
      Navigator.of(context).pop();
    } catch (erro) {
      if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _garantirAtendimentoSalvo() async {
    // Recupera um possível salvamento cuja resposta não chegou ao aplicativo.
    if (!_dadosCarregados || !_atendimentoSalvo) await _carregarProntuario();
    if (!mounted) return;
    final servico = AgendaClinica.instancia.servico;
    {
      if (!_atendimentoSalvo) {
        String valor(String nome) => _camposAtendimento[nome]!.text.trim();
        _prontuario.atendimentoId = await servico.salvarAtendimento(
          widget.consulta.id,
          anamnese: valor('Anamnese'),
          exameFisico: valor('Exame físico'),
          diagnostico: valor('Diagnóstico'),
          prognostico: valor('Prognóstico'),
          tratamento: valor('Tratamento'),
          observacoes: [
            if (_descricaoController.text.trim().isNotEmpty)
              'Descrição: ${_descricaoController.text.trim()}',
            if (_retornoController.text.trim().isNotEmpty)
              'Retorno: ${_retornoController.text.trim()}',
            _observacoesController.text.trim(),
          ].where((texto) => texto.isNotEmpty).join('\n'),
        );
      }
    }
  }

  void _atualizarProntuario() {
    _prontuario
      ..descricaoConsulta = _descricaoController.text.trim()
      ..retornoRecomendado = _retornoController.text.trim()
      ..observacoes = _observacoesController.text.trim();
  }

  Future<void> _adicionarMedicamento() async {
    if (_salvando || !_emConsulta || !_dadosCarregados) return;
    final petId = widget.consulta.petId;
    if (petId == null || petId.isEmpty) {
      _mensagem('Pet não identificado. Atualize a agenda.');
      return;
    }
    final solicitacaoId = CadastrosRecepcaoService.novaSolicitacao();
    MedicamentoPrescrito? salva;
    setState(() => _salvando = true);
    try {
      await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DialogoCamposClinica(
          titulo: 'Adicionar medicação',
          rotulos: const [
            'Medicamento',
            'Dose',
            'Frequência',
            'Duração',
            'Orientações',
          ],
          camposObrigatorios: const [0, 1, 2, 3],
          labelAcao: 'Salvar prescrição',
          aviso: 'Medicamento, dose, frequência e duração são obrigatórios. A avaliação será salva junto da primeira prescrição e não poderá ser editada depois.',
          bloquearEdicaoAposEnvio: true,
          onSalvar: (campos) async {
            await _garantirAtendimentoSalvo();
            if (!mounted) return;
            final atendimentoId = _prontuario.atendimentoId;
            if (atendimentoId == null) {
              throw StateError('Atendimento não identificado.');
            }
            final id = await AgendaClinica.instancia.servico.salvarPrescricao(
              petId: petId,
              atendimentoId: atendimentoId,
              solicitacaoId: solicitacaoId,
              medicamento: campos[0],
              dose: campos[1],
              frequencia: campos[2],
              duracao: campos[3],
              orientacoes: campos[4],
            );
            salva = MedicamentoPrescrito(
              id: id,
              petId: petId,
              atendimentoId: atendimentoId,
              nome: campos[0],
              dosagem: campos[1],
              frequencia: campos[2],
              duracao: campos[3],
              orientacao: campos[4],
            );
          },
        ),
      );
      if (!mounted || salva == null) return;
      setState(() {
        _prontuario.medicamentos.removeWhere((p) => p.id == salva!.id);
        _prontuario.medicamentos.add(salva!);
      });
      _mensagem('Prescrição salva no sistema.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _adicionarExame() async {
    if (_salvando || !_emConsulta || !_dadosCarregados) return;
    final petId = widget.consulta.petId;
    if (petId == null || petId.isEmpty) {
      _mensagem('Pet não identificado. Atualize a agenda.');
      return;
    }
    // Garante que o atendimento esteja salvo antes de solicitar o exame,
    // exatamente como nas prescrições. Se já foi salvo, não reenvia.
    ExameVeterinario? salvo;
    // Rastreia se o POST chegou ao servidor para tratar resultado incerto.
    // A rota atual não usa chave de idempotência: um novo POST sempre cria
    // outro registro. Por isso não reenviamos automaticamente em caso de
    // timeout — mantemos o diálogo aberto para o veterinário decidir.
    bool enviado = false;
    setState(() => _salvando = true);
    try {
      await _garantirAtendimentoSalvo();
      if (!mounted) return;
      final atendimentoId = _prontuario.atendimentoId;
      if (atendimentoId == null) throw StateError('Atendimento não identificado.');
      await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DialogoCamposClinica(
          titulo: 'Solicitar exame',
          rotulos: const ['Tipo do exame', 'Nome do exame', 'Justificativa'],
          camposObrigatorios: const [0, 1],
          labelAcao: 'Solicitar exame',
          aviso: 'Tipo e nome são obrigatórios. '
              'Em caso de falha sem confirmação, verifique a lista antes de reenviar '
              '— um novo envio cria outro registro.',
          bloquearEdicaoAposEnvio: true,
          onSalvar: (campos) async {
            enviado = true;
            salvo = await AgendaClinica.instancia.servico.solicitarExame(
              petId: petId,
              atendimentoId: atendimentoId,
              tipo: campos[0],
              nome: campos[1],
              justificativa: campos[2],
            );
          },
        ),
      );
      if (!mounted) return;
      if (salvo != null) {
        setState(() {
          _prontuario.exames.removeWhere((e) => e.id == salvo!.id);
          _prontuario.exames.add(salvo!);
        });
        _mensagem('Exame solicitado no sistema.');
      } else if (enviado) {
        // POST chegou ao servidor mas a resposta foi perdida antes de confirmar.
        // Recarrega a lista para evitar mostrar duplicata ou exame fantasma.
        try {
          final atualizados = await AgendaClinica.instancia.servico
              .listarExames(petId);
          if (!mounted) return;
          setState(() {
            _prontuario.exames
              ..clear()
              ..addAll(
                atualizados.where(
                  (e) => e.atendimentoId == atendimentoId,
                ),
              );
          });
          _mensagem('Exame enviado — lista atualizada da API.');
        } catch (_) {
          if (mounted) {
            _mensagem(
              'Envio incerto. Verifique a lista antes de reenviar.',
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }
}
