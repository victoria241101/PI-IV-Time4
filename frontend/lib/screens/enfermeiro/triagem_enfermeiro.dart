// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Início de triagem, sinais/sintomas/observações e encaminhamento ao veterinário.
// registro das observacoes e mudanca de etapa da triagem
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/veterinario/prontuario_internacao.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class TriagemEnfermeiro extends StatefulWidget {
  const TriagemEnfermeiro({super.key, required this.consulta});

  final ConsultaRecepcao consulta;

  @override
  State<TriagemEnfermeiro> createState() => _TriagemEnfermeiroState();
}

class _TriagemEnfermeiroState extends State<TriagemEnfermeiro> {
  final _agenda = AgendaClinica.instancia;
  late final TextEditingController _observacoesController;
  final _peso = TextEditingController();
  final _temperatura = TextEditingController();
  final _sintomas = TextEditingController();
  bool _salvando = false;
  bool _triagemSalva = false;
  bool _dadosCarregados = false;

  @override
  void initState() {
    super.initState();
    _observacoesController = TextEditingController(
      text: _agenda.prontuarioDa(widget.consulta).observacoesTriagem,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _carregarProntuario();
      } catch (erro) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erro.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    });
  }

  Future<void> _carregarProntuario() async {
    final dados = await _agenda.servico.lerProntuario(widget.consulta.id);
    if (!mounted) return;
    final triagem = dados['triagem'];
    if (triagem is Map) {
      _peso.text = '${triagem['peso'] ?? ''}';
      _temperatura.text = '${triagem['temperatura'] ?? ''}';
      _sintomas.text = '${triagem['sintomas'] ?? ''}';
      _observacoesController.text = '${triagem['observacoes'] ?? ''}';
      _triagemSalva = true;
    }
    setState(() => _dadosCarregados = true);
  }

  @override
  void dispose() {
    _peso.dispose();
    _temperatura.dispose();
    _sintomas.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  bool get _podeEditar =>
      widget.consulta.status == StatusConsultaRecepcao.emTriagem &&
      _dadosCarregados;

  String get _responsavel =>
      SessaoUsuario.instancia.nomeUsuario ?? 'Enfermeiro';

  void _salvarObservacoes({StatusConsultaRecepcao? novoStatus}) {
    _agenda.prontuarioDa(widget.consulta).observacoesTriagem =
        _observacoesController.text.trim();
    if (novoStatus == null) {
      _agenda.notificarAlteracao();
    } else {
      _agenda.atualizarStatus(widget.consulta, novoStatus);
    }
  }

  Future<void> _avancarEtapa() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      if (!_dadosCarregados) await _carregarProntuario();
      if (!mounted) return;
      if (widget.consulta.status == StatusConsultaRecepcao.aguardandoTriagem) {
        await _agenda.servico.iniciarTriagem(widget.consulta.id);
        if (!mounted) return;
        _salvarObservacoes(novoStatus: StatusConsultaRecepcao.emTriagem);
      } else if (widget.consulta.status == StatusConsultaRecepcao.emTriagem) {
        {
          if (!_triagemSalva) {
            final peso = double.tryParse(_peso.text.replaceAll(',', '.'));
            final temperatura = double.tryParse(
              _temperatura.text.replaceAll(',', '.'),
            );
            if (peso == null ||
                !peso.isFinite ||
                peso <= 0 ||
                temperatura == null ||
                !temperatura.isFinite ||
                _sintomas.text.trim().isEmpty) {
              throw const FormatException(
                'Preencha peso, temperatura e sintomas válidos.',
              );
            }
            await _agenda.servico.salvarTriagem(
              widget.consulta.id,
              peso: peso,
              temperatura: temperatura,
              sintomas: _sintomas.text.trim(),
              observacoes: _observacoesController.text.trim(),
            );
            _triagemSalva = true;
          }
          await _agenda.servico.finalizarTriagem(widget.consulta.id);
        }
        if (!mounted) return;
        _salvarObservacoes(
          novoStatus: StatusConsultaRecepcao.aguardandoVeterinario,
        );
        Navigator.of(context).pop();
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String get _rotuloAcao => switch (widget.consulta.status) {
    StatusConsultaRecepcao.aguardandoTriagem => 'Iniciar triagem',
    StatusConsultaRecepcao.emTriagem => 'Concluir triagem',
    _ => '',
  };

  IconData get _iconeAcao =>
      widget.consulta.status == StatusConsultaRecepcao.aguardandoTriagem
      ? Icons.play_arrow_rounded
      : Icons.check_circle_outline_rounded;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _agenda,
      builder: (context, _) {
        final status = widget.consulta.status;
        final prontuario = _agenda.prontuarioDa(widget.consulta);
        return Scaffold(
          backgroundColor: CoresApp.background,
          appBar: cabecalhoClinica(
            'Triagem',
            actions: [
              if (prontuario.internacaoAtiva)
                IconButton(
                  tooltip: 'Abrir prontuário da internação',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProntuarioInternacao(
                        consulta: widget.consulta,
                        responsavel: _responsavel,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.local_hospital_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              EspacamentosApp.pagePadding,
              EspacamentosApp.sm,
              EspacamentosApp.pagePadding,
              EspacamentosApp.xl,
            ),
            children: [
              _cabecalho(),
              const SizedBox(height: EspacamentosApp.sm),
              CartaoClinica(
                color: CoresApp.primary.withAlpha(24),
                padding: const EdgeInsets.all(EspacamentosApp.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: CoresApp.primaryDark,
                    ),
                    const SizedBox(width: EspacamentosApp.sm),
                    Expanded(
                      child: Text(
                        'Observações da triagem',
                        style: TipografiaApp.heading3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EspacamentosApp.sm),
              ...[
                CampoFormularioApp(
                  controller: _peso,
                  label: 'Peso (kg)',
                  enabled: _podeEditar && !_salvando && !_triagemSalva,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: _temperatura,
                  label: 'Temperatura (°C)',
                  enabled: _podeEditar && !_salvando && !_triagemSalva,
                ),
                const SizedBox(height: EspacamentosApp.md),
                CampoFormularioApp(
                  controller: _sintomas,
                  label: 'Sintomas',
                  enabled: _podeEditar && !_salvando && !_triagemSalva,
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: EspacamentosApp.md),
              CampoFormularioApp(
                controller: _observacoesController,
                label: 'Observações clínicas',
                hint: 'Registre as informações iniciais do paciente',
                prefixIcon: Icons.notes_rounded,
                maxLines: 7,
                enabled: _podeEditar && !_salvando && !_triagemSalva,
                onChanged: (_) => _salvarObservacoes(),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (status == StatusConsultaRecepcao.agendada)
                _aviso(
                  'A triagem ficará disponível depois que a recepção confirmar a chegada do tutor',
                ),
              if (status == StatusConsultaRecepcao.aguardandoVeterinario)
                _aviso('Triagem concluída'),
            ],
          ),
          bottomNavigationBar: _barraAcao(status),
        );
      },
    );
  }

  Widget _cabecalho() => CartaoClinica(
    color: CoresApp.surfaceSoft,
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
                    style: TipografiaApp.heading3,
                  ),
                  Text(
                    'Tutor: ${widget.consulta.tutor}',
                    style: TipografiaApp.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspacamentosApp.md),
        IndicadorStatus(
          label:
              widget.consulta.status ==
                  StatusConsultaRecepcao.aguardandoVeterinario
              ? 'Triagem concluída'
              : widget.consulta.status.rotulo,
          color: widget.consulta.status.cor,
        ),
        const SizedBox(height: EspacamentosApp.sm),
        Text(
          'Veterinário: ${widget.consulta.profissional}',
          style: TipografiaApp.caption,
        ),
      ],
    ),
  );

  Widget _aviso(String texto) => Padding(
    padding: const EdgeInsets.only(top: EspacamentosApp.md),
    child: CartaoClinica(
      color: CoresApp.primary.withAlpha(20),
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Text(texto, style: TipografiaApp.bodySmall),
    ),
  );

  Widget _barraAcao(StatusConsultaRecepcao status) {
    final podeAvancar =
        status == StatusConsultaRecepcao.aguardandoTriagem ||
        status == StatusConsultaRecepcao.emTriagem;
    final textoInformativo = switch (status) {
      StatusConsultaRecepcao.agendada =>
        'Aguardando confirmação de chegada pela recepção',
      StatusConsultaRecepcao.aguardandoVeterinario => 'Triagem concluída',
      StatusConsultaRecepcao.emConsulta => 'Atendimento veterinário iniciado',
      StatusConsultaRecepcao.finalizado => 'Atendimento finalizado',
      _ => '',
    };
    return RodapeClinica(
      child: podeAvancar
          ? BotaoClinica(
              label: _rotuloAcao,
              backgroundColor: CoresApp.primaryDark,
              icon: _iconeAcao,
              expanded: true,
              onPressed: _avancarEtapa,
            )
          : Text(
              textoInformativo,
              textAlign: TextAlign.center,
              style: TipografiaApp.bodySmall,
            ),
    );
  }
}
