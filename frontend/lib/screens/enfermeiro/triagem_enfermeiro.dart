// registro das observacoes e mudanca de etapa da triagem
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/gerais/prontuario_internacao.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/botao_principal.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
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

  @override
  void initState() {
    super.initState();
    _observacoesController = TextEditingController(
      text: _agenda.prontuarioDa(widget.consulta).observacoesTriagem,
    );
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  bool get _podeEditar =>
      widget.consulta.status == StatusConsultaRecepcao.emTriagem;

  String get _responsavel =>
      SessaoUsuario.instancia.nomeUsuario ?? 'Equipe de enfermagem';

  void _salvarObservacoes({StatusConsultaRecepcao? novoStatus}) {
    _agenda.prontuarioDa(widget.consulta).observacoesTriagem =
        _observacoesController.text.trim();
    if (novoStatus == null) {
      _agenda.notificarAlteracao();
    } else {
      _agenda.atualizarStatus(widget.consulta, novoStatus);
    }
  }

  void _avancarEtapa() {
    if (widget.consulta.status == StatusConsultaRecepcao.aguardandoTriagem) {
      _salvarObservacoes(novoStatus: StatusConsultaRecepcao.emTriagem);
    } else if (widget.consulta.status == StatusConsultaRecepcao.emTriagem) {
      _salvarObservacoes(
        novoStatus: StatusConsultaRecepcao.aguardandoVeterinario,
      );
    }
  }

  String get _rotuloAcao => switch (widget.consulta.status) {
    StatusConsultaRecepcao.aguardandoTriagem => 'Iniciar triagem',
    StatusConsultaRecepcao.emTriagem => 'Concluir triagem e encaminhar',
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
          appBar: AppBar(
            backgroundColor: CoresApp.background,
            elevation: 0,
            title: Text('Triagem', style: TipografiaApp.heading3),
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
              const SizedBox(height: EspacamentosApp.lg),
              Text('Observações da triagem', style: TipografiaApp.heading3),
              const SizedBox(height: EspacamentosApp.sm),
              CampoFormularioApp(
                controller: _observacoesController,
                label: 'Observações clínicas',
                hint: 'Registre as informações iniciais do paciente',
                prefixIcon: Icons.notes_rounded,
                maxLines: 5,
                enabled: _podeEditar,
                onChanged: (_) => _salvarObservacoes(),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (status == StatusConsultaRecepcao.agendada)
                _aviso(
                  'A triagem ficará disponível depois que a recepção confirmar a chegada do tutor',
                ),
              if (status == StatusConsultaRecepcao.aguardandoVeterinario)
                _aviso('Triagem concluída · paciente aguardando veterinário'),
            ],
          ),
          bottomNavigationBar: _barraAcao(status),
        );
      },
    );
  }

  Widget _cabecalho() => CartaoBase(
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
          label: widget.consulta.status.rotulo,
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
    child: CartaoBase(
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
      StatusConsultaRecepcao.aguardandoVeterinario =>
        'Triagem concluída · aguardando veterinário',
      StatusConsultaRecepcao.emConsulta => 'Atendimento veterinário iniciado',
      StatusConsultaRecepcao.finalizado => 'Atendimento finalizado',
      _ => '',
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EspacamentosApp.pagePadding,
          EspacamentosApp.sm,
          EspacamentosApp.pagePadding,
          EspacamentosApp.md,
        ),
        child: podeAvancar
            ? BotaoPrincipal(
                label: _rotuloAcao,
                icon: _iconeAcao,
                expanded: true,
                onPressed: _avancarEtapa,
              )
            : Text(
                textoInformativo,
                textAlign: TextAlign.center,
                style: TipografiaApp.bodySmall,
              ),
      ),
    );
  }
}
