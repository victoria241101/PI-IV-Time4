// busca de clientes e historico clinico compartilhado pela equipe
import 'package:flutter/material.dart';

import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/screens/gerais/prontuario_internacao.dart';
import 'package:pet_care/widgets/avatar_pet.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/indicador_status.dart';

class ClientesVeterinario extends StatefulWidget {
  const ClientesVeterinario({
    super.key,
    required this.consultas,
    required this.profissional,
    this.mostrarInternadosInicialmente = false,
    this.somenteInternados = false,
    this.descricao,
  });

  final List<ConsultaRecepcao> consultas;
  final String profissional;
  final bool mostrarInternadosInicialmente;
  final bool somenteInternados;
  final String? descricao;

  @override
  State<ClientesVeterinario> createState() => _ClientesVeterinarioState();
}

class _ClientesVeterinarioState extends State<ClientesVeterinario> {
  final _buscaController = TextEditingController();
  late bool _mostrarInternados;

  @override
  void initState() {
    super.initState();
    _mostrarInternados =
        widget.somenteInternados || widget.mostrarInternadosInicialmente;
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<_ClienteVeterinario> get _clientes {
    final grupos = <String, List<ConsultaRecepcao>>{};
    for (final consulta in widget.consultas) {
      final chave =
          '${consulta.pet.toLowerCase()}|${consulta.tutor.toLowerCase()}';
      grupos.putIfAbsent(chave, () => []).add(consulta);
    }

    final clientes =
        grupos.values.map((consultas) {
            consultas.sort((a, b) {
              final porData = b.data.compareTo(a.data);
              return porData != 0 ? porData : b.horario.compareTo(a.horario);
            });
            return _ClienteVeterinario(
              pet: consultas.first.pet,
              especie: consultas.first.especie,
              tutor: consultas.first.tutor,
              consultas: consultas,
              fotoUrl: consultas.first.fotoPet,
            );
          }).toList()
          ..sort((a, b) => a.pet.toLowerCase().compareTo(b.pet.toLowerCase()));
    return clientes;
  }

  List<_ClienteVeterinario> get _clientesVisiveis {
    final termo = _buscaController.text.trim().toLowerCase();
    return _clientes.where((cliente) {
      final internado = _consultasDoPet(cliente).any(_temInternacaoAtiva);
      final correspondeAoFiltro = !_mostrarInternados || internado;
      final correspondeABusca =
          termo.isEmpty ||
          cliente.pet.toLowerCase().contains(termo) ||
          cliente.tutor.toLowerCase().contains(termo);
      return correspondeAoFiltro && correspondeABusca;
    }).toList();
  }

  bool _temInternacaoAtiva(ConsultaRecepcao consulta) {
    final prontuario = AgendaClinica.instancia.prontuarios[consulta.id];
    return prontuario?.internacaoAtiva ?? false;
  }

  List<ConsultaRecepcao> _consultasDoPet(_ClienteVeterinario cliente) =>
      AgendaClinica.instancia.consultasDoPet(cliente.pet, cliente.tutor);

  @override
  Widget build(BuildContext context) {
    final clientes = _clientesVisiveis;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.somenteInternados ? 'Pacientes internados' : 'Clientes',
            style: TipografiaApp.heading2,
          ),
          const SizedBox(height: EspacamentosApp.xs),
          Text(
            widget.descricao ??
                'Consulte os pets atendidos por ${widget.profissional}',
            style: TipografiaApp.bodySmall,
          ),
          const SizedBox(height: EspacamentosApp.md),
          CampoFormularioApp(
            controller: _buscaController,
            label: 'Buscar pet ou tutor',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: EspacamentosApp.sm),
          if (!widget.somenteInternados) ...[
            Wrap(
              spacing: EspacamentosApp.sm,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: !_mostrarInternados,
                  onSelected: (_) => setState(() => _mostrarInternados = false),
                  selectedColor: CoresApp.primary.withAlpha(28),
                ),
                ChoiceChip(
                  label: const Text('Internados'),
                  selected: _mostrarInternados,
                  onSelected: (_) => setState(() => _mostrarInternados = true),
                  selectedColor: CoresApp.primary.withAlpha(28),
                ),
              ],
            ),
            const SizedBox(height: EspacamentosApp.sm),
          ],
          Expanded(
            child: clientes.isEmpty
                ? _vazio()
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: EspacamentosApp.md),
                    itemCount: clientes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: EspacamentosApp.sm),
                    itemBuilder: (context, index) =>
                        _cartaoCliente(clientes[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoCliente(_ClienteVeterinario cliente) {
    final historico = _consultasDoPet(cliente);
    final internado = historico.any(_temInternacaoAtiva);
    final ultimaConsulta = historico.first;
    return CartaoBase(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _HistoricoPetVeterinario(cliente: cliente),
        ),
      ),
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Row(
        children: [
          AvatarPet(fotoUrl: cliente.fotoUrl, nome: cliente.pet, tamanho: 52),
          const SizedBox(width: EspacamentosApp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cliente.pet, style: TipografiaApp.bodyMedium),
                Text(
                  '${cliente.especie} · Tutor: ${cliente.tutor}',
                  style: TipografiaApp.caption,
                ),
                Text(
                  'Última consulta: ${_dataFormatada(ultimaConsulta.data)}',
                  style: TipografiaApp.caption,
                ),
              ],
            ),
          ),
          if (internado) ...[
            const IndicadorStatus(label: 'Internado', color: CoresApp.primary),
            IconButton(
              tooltip: 'Abrir prontuário da internação',
              onPressed: () => _abrirInternacao(cliente),
              icon: const Icon(
                Icons.local_hospital_outlined,
                color: CoresApp.primary,
              ),
            ),
          ] else
            const Icon(
              Icons.chevron_right_rounded,
              color: CoresApp.iconDefault,
            ),
        ],
      ),
    );
  }

  void _abrirInternacao(_ClienteVeterinario cliente) {
    final consulta = _consultasDoPet(cliente).where(_temInternacaoAtiva).first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProntuarioInternacao(
          consulta: consulta,
          responsavel: widget.profissional,
        ),
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: CartaoBase(
        padding: const EdgeInsets.all(EspacamentosApp.lg),
        child: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: CoresApp.iconDefault),
            const SizedBox(width: EspacamentosApp.sm),
            Expanded(
              child: Text(
                _mostrarInternados
                    ? 'Nenhum paciente internado'
                    : 'Nenhum cliente encontrado',
                style: TipografiaApp.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricoPetVeterinario extends StatelessWidget {
  const _HistoricoPetVeterinario({required this.cliente});

  final _ClienteVeterinario cliente;

  List<ConsultaRecepcao> get _consultas =>
      AgendaClinica.instancia.consultasDoPet(cliente.pet, cliente.tutor);

  ConsultaRecepcao? get _internacaoDisponivel {
    for (final consulta in _consultas) {
      if (AgendaClinica.instancia.prontuarios[consulta.id]?.internacaoAtiva ??
          false) {
        return consulta;
      }
    }
    for (final consulta in _consultas) {
      final prontuario = AgendaClinica.instancia.prontuarios[consulta.id];
      if (prontuario != null &&
          (prontuario.internacao.isNotEmpty ||
              prontuario.internacaoFinalizadaEm != null)) {
        return consulta;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final internacao = _internacaoDisponivel;
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        elevation: 0,
        title: Text('Prontuário', style: TipografiaApp.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          EspacamentosApp.pagePadding,
          EspacamentosApp.sm,
          EspacamentosApp.pagePadding,
          EspacamentosApp.xl,
        ),
        children: [
          CartaoBase(
            padding: const EdgeInsets.all(EspacamentosApp.md),
            child: Row(
              children: [
                AvatarPet(
                  fotoUrl: cliente.fotoUrl,
                  nome: cliente.pet,
                  tamanho: 60,
                ),
                const SizedBox(width: EspacamentosApp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.pet, style: TipografiaApp.heading3),
                      Text(cliente.especie, style: TipografiaApp.bodySmall),
                      Text(
                        'Tutor: ${cliente.tutor}',
                        style: TipografiaApp.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (internacao != null) ...[
            const SizedBox(height: EspacamentosApp.md),
            CartaoBase(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProntuarioInternacao(
                    consulta: internacao,
                    responsavel: internacao.profissional,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(EspacamentosApp.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    color: CoresApp.primary,
                  ),
                  const SizedBox(width: EspacamentosApp.sm),
                  Expanded(
                    child: Text(
                      'Abrir prontuário da internação',
                      style: TipografiaApp.bodyMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
          const SizedBox(height: EspacamentosApp.lg),
          Text('Histórico clínico', style: TipografiaApp.heading3),
          const SizedBox(height: EspacamentosApp.sm),
          for (final consulta in _consultas) ...[
            _RegistroConsulta(consulta: consulta),
            const SizedBox(height: EspacamentosApp.sm),
          ],
        ],
      ),
    );
  }
}

class _RegistroConsulta extends StatelessWidget {
  const _RegistroConsulta({required this.consulta});

  final ConsultaRecepcao consulta;

  @override
  Widget build(BuildContext context) {
    final prontuario = AgendaClinica.instancia.prontuarios[consulta.id];
    return CartaoBase(
      padding: const EdgeInsets.all(EspacamentosApp.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_dataFormatada(consulta.data)} · ${consulta.horario}',
                  style: TipografiaApp.bodyMedium,
                ),
              ),
              IndicadorStatus(
                label: consulta.status.rotulo,
                color: consulta.status.cor,
              ),
            ],
          ),
          const SizedBox(height: EspacamentosApp.xs),
          if (prontuario == null || !_temConteudo(prontuario)) ...[
            const SizedBox(height: EspacamentosApp.sm),
            Text(
              'Sem anotações clínicas registradas',
              style: TipografiaApp.bodySmall.copyWith(
                color: CoresApp.textSecondary,
              ),
            ),
          ] else ...[
            const Divider(height: EspacamentosApp.lg),
            if (prontuario.observacoesTriagem.isNotEmpty)
              _linha('Triagem', prontuario.observacoesTriagem),
            if (prontuario.descricaoConsulta.isNotEmpty)
              _linha('Consulta', prontuario.descricaoConsulta),
            if (prontuario.medicamentos.isNotEmpty)
              _linha(
                'Medicações',
                prontuario.medicamentos
                    .map(
                      (item) =>
                          '${item.nome} · ${item.dosagem} · ${item.orientacao}',
                    )
                    .join('\n'),
              ),
            if (prontuario.exames.isNotEmpty)
              _linha('Exames', prontuario.exames.join('\n')),
            if (prontuario.internacao.isNotEmpty)
              _linha('Internação', prontuario.internacao),
            if (prontuario.retornoRecomendado.isNotEmpty)
              _linha('Retorno recomendado', prontuario.retornoRecomendado),
            if (prontuario.observacoes.isNotEmpty)
              _linha('Observações', prontuario.observacoes),
          ],
        ],
      ),
    );
  }

  bool _temConteudo(ProntuarioCompartilhado prontuario) =>
      prontuario.observacoesTriagem.isNotEmpty ||
      prontuario.descricaoConsulta.isNotEmpty ||
      prontuario.medicamentos.isNotEmpty ||
      prontuario.exames.isNotEmpty ||
      prontuario.internacao.isNotEmpty ||
      prontuario.internacaoAtiva ||
      prontuario.procedimentosInternacao.isNotEmpty ||
      prontuario.medicacoesInternacao.isNotEmpty ||
      prontuario.notasInternacao.isNotEmpty ||
      prontuario.retornoRecomendado.isNotEmpty ||
      prontuario.observacoes.isNotEmpty;

  Widget _linha(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacamentosApp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TipografiaApp.captionBold),
          const SizedBox(height: 2),
          Text(valor, style: TipografiaApp.bodySmall),
        ],
      ),
    );
  }
}

class _ClienteVeterinario {
  const _ClienteVeterinario({
    required this.pet,
    required this.especie,
    required this.tutor,
    required this.consultas,
    required this.fotoUrl,
  });

  final String pet;
  final String especie;
  final String tutor;
  final List<ConsultaRecepcao> consultas;
  final String? fotoUrl;
}

String _dataFormatada(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}
