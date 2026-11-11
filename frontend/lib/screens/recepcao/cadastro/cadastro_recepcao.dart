import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
// fluxo de cadastro de tutor e pet pela recepção
import 'package:flutter/material.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/core/tema/tipografia_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/recepcao/cadastro/encaminhamento_cadastro.dart';
import 'package:pet_care/screens/recepcao/cadastro/etapas_identificacao_cadastro.dart';
import 'package:pet_care/screens/recepcao/cadastro/etapas_formulario_cadastro.dart';

// Etapas do fluxo de cadastro / admissão

enum _EtapaCadastro {
  inicio,
  cpf,
  pets,
  responsavel,
  pet,
  encaminhamento,
  sucesso,
}
// Tela de cadastro da recepção

/// Fluxo de admissão de paciente pela recepção.
///
/// **Tutor existente**: CPF → localizar → escolher pet → encaminhamento.
/// **Novo tutor**: dados do responsável → perfil do pet → encaminhamento.
///
/// Cada etapa avança ou volta na máquina de estados `_EtapaCadastro`.
class CadastroRecepcao extends StatefulWidget {
  const CadastroRecepcao({
    super.key,
    required this.onRegistrarConsulta,
    this.dataInicial,
    this.somenteCadastro = false,
    this.onCadastroConcluido,
    this.cadastrosService,
  });
  final CadastrosRecepcaoService? cadastrosService;
  final DateTime? dataInicial;
  final bool somenteCadastro;
  final ValueChanged<RegistroRecepcaoLocal>? onCadastroConcluido;

  final bool Function(ConsultaRecepcao consulta) onRegistrarConsulta;

  @override
  State<CadastroRecepcao> createState() => _CadastroRecepcaoState();
}

class _CadastroRecepcaoState extends State<CadastroRecepcao> {
  late final _cadastrosService =
      widget.cadastrosService ?? CadastrosRecepcaoService();
  String _solicitacaoId = CadastrosRecepcaoService.novaSolicitacao();
  bool _salvando = false;
  Map<String, dynamic>? _cadastroSalvo;
  final _cpfKey = GlobalKey<FormState>();
  final _responsavelKey = GlobalKey<FormState>();
  final _petKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomePetController = TextEditingController();
  final _racaController = TextEditingController();
  DateTime? _dataNascimentoPet;
  _EtapaCadastro _etapa = _EtapaCadastro.inicio;
  String _nomeResponsavel = '';
  String? _petSelecionado;
  String? _prontuarioSelecionado;
  RegistroRecepcaoLocal? _tutorLocal;
  Map<String, String> get _pets => {
    for (final registro in CadastrosRecepcaoLocal.instancia.petsPorCpf(
      _cpfController.text,
    ))
      registro.dados['pet']!: registro.dados['especie'] ?? 'Pet',
  };
  String _especie = 'Cachorro';
  String _sexo = 'Macho';
  String _encaminhamento = 'Triagem';
  late DateTime _dataConsulta;
  TimeOfDay _horarioConsulta = const TimeOfDay(hour: 9, minute: 0);
  String _profissionalConsulta = 'Dra. Beatriz';
  ConsultaRecepcao? _consultaCriada;
  bool _responsavelExistente = false;

  @override
  void initState() {
    super.initState();
    _dataConsulta = DateUtils.dateOnly(
      widget.dataInicial ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (widget.dataInicial != null) _encaminhamento = 'Agendar consulta';
    if (widget.somenteCadastro) _etapa = _EtapaCadastro.responsavel;
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _nomeResponsavelController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _nomePetController.dispose();
    _racaController.dispose();
    super.dispose();
  }
  // Navegação entre etapas

  void _voltar() {
    if (_salvando) return;
    setState(() {
      switch (_etapa) {
        case _EtapaCadastro.inicio:
          break;
        case _EtapaCadastro.cpf:
          _etapa = _EtapaCadastro.inicio;
          break;
        case _EtapaCadastro.pets:
          _etapa = _EtapaCadastro.cpf;
          break;
        case _EtapaCadastro.responsavel:
          _etapa = _EtapaCadastro.inicio;
          break;
        case _EtapaCadastro.pet:
          _etapa = _responsavelExistente
              ? _EtapaCadastro.pets
              : _EtapaCadastro.responsavel;
          break;
        case _EtapaCadastro.encaminhamento:
          _etapa = _responsavelExistente && _petSelecionado != null
              ? _EtapaCadastro.pets
              : _EtapaCadastro.pet;
          break;
        case _EtapaCadastro.sucesso:
          _etapa = _EtapaCadastro.inicio;
          break;
      }
    });
  }
  // Ações

  void _buscarResponsavel() {
    if (!_cpfKey.currentState!.validate()) return;
    final tutor = CadastrosRecepcaoLocal.instancia.tutorPorCpf(
      _cpfController.text,
    );
    if (tutor == null) {
      _mensagem(
        'CPF não encontrado nesta sessão. Cadastre o tutor como novo responsável.',
      );
      return;
    }
    setState(() {
      _responsavelExistente = true;
      _tutorLocal = tutor;
      _petSelecionado = null;
      _prontuarioSelecionado = null;
      _nomeResponsavel = tutor.nome;
      _nomeResponsavelController.text = _nomeResponsavel;
      _telefoneController.text = tutor.dados['telefone'] ?? '';
      _emailController.text = tutor.dados['email'] ?? '';
      _etapa = _EtapaCadastro.pets;
    });
  }

  void _continuarResponsavel() {
    if (!_responsavelKey.currentState!.validate()) return;
    if (widget.somenteCadastro &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
            .hasMatch(_emailController.text.trim())) {
      _mensagem('Informe um e-mail válido para o tutor acessar a conta.');
      return;
    }
    if (!widget.somenteCadastro &&
        !_responsavelExistente &&
        CadastrosRecepcaoLocal.instancia.tutorPorCpf(_cpfController.text) !=
            null) {
      _mensagem(
        'Este tutor já está cadastrado nesta prévia. Localize-o pelo CPF na agenda.',
      );
      return;
    }
    setState(() {
      _nomeResponsavel = _nomeResponsavelController.text.trim();
      _etapa = _EtapaCadastro.pet;
    });
  }

  void _abrirPetExistente() {
    if (_petSelecionado == null) {
      _mensagem('Escolha um pet para continuar');
      return;
    }
    setState(() {
      _nomePetController.text = _petSelecionado!;
      final registros = CadastrosRecepcaoLocal.instancia
          .petsPorCpf(_cpfController.text)
          .where((r) => r.dados['pet'] == _petSelecionado);
      _especie = registros.isNotEmpty
          ? registros.last.dados['especie'] ?? 'Cachorro'
          : (_petSelecionado == 'Luna' ? 'Gato' : 'Cachorro');
      _prontuarioSelecionado = null;
      _etapa = _EtapaCadastro.encaminhamento;
    });
  }

  Future<void> _continuarPet() async {
    if (_salvando || !_petKey.currentState!.validate()) return;
    if (widget.somenteCadastro) {
      if (_racaController.text.trim().isEmpty) {
        _mensagem(
          'Informe a raça do pet. Para raça desconhecida, informe SRD.',
        );
        return;
      }
      setState(() => _salvando = true);
      try {
        final dados = _registroTutorPet().dados;
        final resultado = await _cadastrosService.cadastrar({
          ...dados,
          'nome': _nomeResponsavel,
        }, _solicitacaoId);
        if (!mounted) return;
        _cadastroSalvo = resultado;
        _nomeResponsavel = resultado['nome']?.toString() ?? _nomeResponsavel;
        final registro = RegistroRecepcaoLocal(
          tipo: TipoCadastroRecepcao.tutorPet,
          nome: resultado['nome']?.toString() ?? _nomeResponsavel,
          dados: {
            ...dados,
            'tutorId': resultado['tutorId'] as String,
            'petId': resultado['petId'] as String,
          },
        );
        widget.onCadastroConcluido?.call(registro);
        setState(() => _etapa = _EtapaCadastro.sucesso);
      } catch (erro) {
        if (mounted) _mensagem(erro.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
      return;
    }
    setState(() {
      _prontuarioSelecionado = null;
      _etapa = _EtapaCadastro.encaminhamento;
    });
  }

  RegistroRecepcaoLocal _registroTutorPet() => RegistroRecepcaoLocal(
    tipo: TipoCadastroRecepcao.tutorPet,
    tutorDemonstracao:
        _responsavelExistente &&
        (_tutorLocal == null || _tutorLocal!.tutorDemonstracao),
    nome: _nomeResponsavel,
    dados: {
      'cpf': _cpfController.text,
      'telefone': _telefoneController.text,
      'email': _emailController.text,
      'pet': _nomePetController.text.trim(),
      'especie': _especie,
      'raca': _racaController.text,
      'dataNascimento': _dataNascimentoPet?.toIso8601String() ?? '',
      'sexo': _sexo,
    },
  );

  List<ConsultaRecepcao> get _indicacoes =>
      AgendaClinica.instancia.consultas.where((c) {
        final p = AgendaClinica.instancia.prontuarios[c.id];
        return c.pet == _nomePetController.text.trim() &&
            c.tutor == _nomeResponsavel &&
            p != null &&
            p.internacao.isNotEmpty &&
            !p.internacaoAtiva &&
            p.internacaoFinalizadaEm == null &&
            p.dataPrevistaInternacao != null &&
            !AgendaClinica.instancia.consultas.any(
              (a) => a.prontuarioOrigemId == c.id,
            );
      }).toList();

  void _confirmarEncaminhamento() {
    final agendar = _encaminhamento != 'Triagem';
    final internacao = _encaminhamento == 'Agendar internação';
    if (internacao && !_indicacoes.any((c) => c.id == _prontuarioSelecionado)) {
      _mensagem(
        'Selecione um prontuário com indicação de internação disponível para este pet',
      );
      return;
    }
    final origem = internacao
        ? AgendaClinica.instancia.prontuarios[_prontuarioSelecionado]
        : null;
    final agora = DateTime.now();
    final dataHora = DateTime(
      _dataConsulta.year,
      _dataConsulta.month,
      _dataConsulta.day,
      _horarioConsulta.hour,
      _horarioConsulta.minute,
    );

    if (agendar && dataHora.isBefore(agora)) {
      _mensagem('Escolha uma data e um horário futuros');
      return;
    }

    final consulta = ConsultaRecepcao(
      id: 'cadastro-${agora.microsecondsSinceEpoch}',
      data: agendar
          ? DateUtils.dateOnly(_dataConsulta)
          : DateUtils.dateOnly(agora),
      horario: agendar
          ? _formatarHorario(_horarioConsulta)
          : _formatarHorario(TimeOfDay.fromDateTime(agora)),
      duracaoMinutos: 30,
      pet: _nomePetController.text.trim(),
      especie: _especie,
      tutor: _nomeResponsavel,
      profissional: agendar ? _profissionalConsulta : 'A definir',
      motivo: internacao
          ? 'Internação · ${origem!.procedimentoIndicado}'
          : agendar
          ? 'Consulta inicial'
          : 'Avaliação inicial',
      internacaoAgendada: internacao,
      prontuarioOrigemId: internacao ? _prontuarioSelecionado : null,
      dataPrevistaInternacao: origem?.dataPrevistaInternacao,
      sala: agendar ? _salaDoProfissional(_profissionalConsulta) : 'Triagem',
      status: agendar
          ? StatusConsultaRecepcao.agendada
          : StatusConsultaRecepcao.aguardandoTriagem,
    );

    if (!widget.onRegistrarConsulta(consulta)) {
      _mensagem('Esse horário já está ocupado para o veterinário escolhido');
      return;
    }

    if (!_responsavelExistente || _petSelecionado == null) {
      CadastrosRecepcaoLocal.instancia.registros.add(_registroTutorPet());
    }
    setState(() {
      _consultaCriada = consulta;
      _etapa = _EtapaCadastro.sucesso;
    });
  }

  String _formatarHorario(TimeOfDay horario) =>
      '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _salaDoProfissional(String profissional) =>
      profissional == 'Dr. Silva' ? 'Sala 01' : 'Sala 02';

  Future<void> _selecionarDataConsulta() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final data = await showDatePicker(
      context: context,
      initialDate: _dataConsulta.isBefore(hoje) ? hoje : _dataConsulta,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
      helpText: 'Escolha a data da consulta',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (data != null) setState(() => _dataConsulta = DateUtils.dateOnly(data));
  }

  Future<void> _selecionarHorarioConsulta() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: _horarioConsulta,
      helpText: 'Escolha o horário da consulta',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (horario != null) setState(() => _horarioConsulta = horario);
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
      );
  }

  void _reiniciar() {
    setState(() {
      _solicitacaoId = CadastrosRecepcaoService.novaSolicitacao();
      _cadastroSalvo = null;
      _etapa = widget.somenteCadastro
          ? _EtapaCadastro.responsavel
          : _EtapaCadastro.inicio;
      _prontuarioSelecionado = null;
      _tutorLocal = null;
      _cpfController.clear();
      _nomeResponsavelController.clear();
      _telefoneController.clear();
      _emailController.clear();
      _nomePetController.clear();
      _racaController.clear();
      _dataNascimentoPet = null;
      _petSelecionado = null;
      _especie = 'Cachorro';
      _sexo = 'Macho';
      _encaminhamento = widget.dataInicial != null
          ? 'Agendar consulta'
          : 'Triagem';
      _dataConsulta = DateUtils.dateOnly(
        widget.dataInicial ?? DateTime.now().add(const Duration(days: 1)),
      );
      _horarioConsulta = const TimeOfDay(hour: 9, minute: 0);
      _profissionalConsulta = 'Dra. Beatriz';
      _consultaCriada = null;
      _responsavelExistente = false;
      _nomeResponsavel = '';
    });
  }
  // Build

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        EspacamentosApp.pagePadding,
        EspacamentosApp.sm,
        EspacamentosApp.pagePadding,
        EspacamentosApp.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalhoEtapa(),
              const SizedBox(height: EspacamentosApp.md),
              if (_salvando) const LinearProgressIndicator(),
              AbsorbPointer(absorbing: _salvando, child: _conteudoEtapa()),
            ],
          ),
        ),
      ),
    );
  }
  // Cabeçalho da etapa atual

  Widget _cabecalhoEtapa() {
    final titulo = switch (_etapa) {
      _EtapaCadastro.inicio =>
        widget.dataInicial != null ? 'Novo agendamento' : 'Cadastrar paciente',
      _EtapaCadastro.cpf => 'Localizar responsável',
      _EtapaCadastro.pets => 'Escolher paciente',
      _EtapaCadastro.responsavel => 'Dados do responsável',
      _EtapaCadastro.pet => 'Perfil do pet',
      _EtapaCadastro.encaminhamento => 'Encaminhamento',
      _EtapaCadastro.sucesso => 'Cadastro concluído',
    };

    return CabecalhoEtapaCadastro(
      titulo: titulo,
      mostrarVoltar:
          _etapa != _EtapaCadastro.inicio &&
          _etapa != _EtapaCadastro.sucesso &&
          !(widget.somenteCadastro && _etapa == _EtapaCadastro.responsavel),
      mostrarAjuda: _etapa == _EtapaCadastro.inicio,
      onVoltar: _voltar,
      onAjuda: () => _mensagem(
        'Localize um responsável pelo CPF ou inicie um novo cadastro',
      ),
    );
  }
  // Roteador de conteúdo

  Widget _conteudoEtapa() {
    return switch (_etapa) {
      _EtapaCadastro.inicio => _telaInicio(),
      _EtapaCadastro.cpf => _telaCpf(),
      _EtapaCadastro.pets => _telaPets(),
      _EtapaCadastro.responsavel => _telaResponsavel(),
      _EtapaCadastro.pet => _telaPet(),
      _EtapaCadastro.encaminhamento => _telaEncaminhamento(),
      _EtapaCadastro.sucesso => _telaSucesso(),
    };
  }
  // Etapa: Início

  Widget _telaInicio() => InicioCadastroRecepcao(
    onResponsavelExistente: () => setState(() => _etapa = _EtapaCadastro.cpf),
    onNovoResponsavel: () {
      setState(() {
        _responsavelExistente = false;
        _etapa = _EtapaCadastro.responsavel;
      });
    },
  );
  // Etapa: Busca por CPF

  Widget _telaCpf() => CpfResponsavelCadastro(
    formKey: _cpfKey,
    controller: _cpfController,
    onBuscar: _buscarResponsavel,
  );
  // Etapa: Pets do responsável encontrado

  Widget _telaPets() => PetsResponsavelCadastro(
    nomeResponsavel: _nomeResponsavel,
    pets: _pets,
    cpfMascarado: _mascaraCpf(_cpfController.text),
    petSelecionado: _petSelecionado,
    onPetSelecionado: (pet) => setState(() {
      _petSelecionado = pet;
      _prontuarioSelecionado = null;
    }),
    onContinuar: _abrirPetExistente,
    onCadastrarPet: () {
      setState(() {
        _nomePetController.clear();
        _petSelecionado = null;
        _prontuarioSelecionado = null;
        _etapa = _EtapaCadastro.pet;
      });
    },
  );
  // Etapa: Dados do responsável (novo tutor)

  Widget _telaResponsavel() => DadosResponsavelCadastro(
    formKey: _responsavelKey,
    nomeController: _nomeResponsavelController,
    cpfController: _cpfController,
    telefoneController: _telefoneController,
    emailController: _emailController,
    validarNome: _obrigatorio('Informe o nome completo'),
    validarTelefone: _obrigatorio('Informe o celular'),
    onContinuar: _continuarResponsavel,
  );

  // Etapa: Perfil clínico do pet

  Widget _telaPet() => PerfilPetCadastro(
    formKey: _petKey,
    nomeResponsavel: _nomeResponsavel,
    cpfResponsavel: _responsavelExistente
        ? _mascaraCpf(_cpfController.text)
        : _cpfController.text,
    telefoneResponsavel: _telefoneController.text,
    emailResponsavel: _emailController.text,
    nomePetController: _nomePetController,
    racaController: _racaController,
    dataNascimento: _dataNascimentoPet,
    especie: _especie,
    sexo: _sexo,
    validarNomePet: _obrigatorio('Informe o nome do pet'),
    onEditarResponsavel: _voltar,
    onEspecieChanged: (valor) => setState(() => _especie = valor),
    onSexoChanged: (valor) => setState(() => _sexo = valor),
    onDataNascimentoChanged: (data) =>
        setState(() => _dataNascimentoPet = data),
    onContinuar: _continuarPet,
    rotuloContinuar: widget.somenteCadastro
        ? 'Cadastrar tutor e pet'
        : 'Continuar',
  );

  // Etapa: triagem imediata ou agendamento de consulta

  Widget _telaEncaminhamento() => EncaminhamentoCadastro(
    campoIndicacao: _seletorIndicacao(),
    nomePet: _nomePetController.text,
    nomeResponsavel: _nomeResponsavel,
    encaminhamento: _encaminhamento,
    dataConsulta: _formatarData(_dataConsulta),
    horarioConsulta: _formatarHorario(_horarioConsulta),
    profissionalConsulta: _profissionalConsulta,
    profissionais: const ['Dra. Beatriz', 'Dra. Camila', 'Dr. Silva'],
    onEncaminhamentoChanged: (valor) => setState(() => _encaminhamento = valor),
    onSelecionarData: _selecionarDataConsulta,
    onSelecionarHorario: _selecionarHorarioConsulta,
    onProfissionalChanged: (nome) =>
        setState(() => _profissionalConsulta = nome),
    onConfirmar: _confirmarEncaminhamento,
  );

  // Etapa: Sucesso

  Widget _telaSucesso() => widget.somenteCadastro
      ? CartaoClinica(
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Tutor e pet cadastrados',
                style: TipografiaApp.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$_nomeResponsavel · ${_nomePetController.text}\nCadastro salvo.\n'
                '${_cadastroSalvo?['contaCriada'] == true ? 'Para criar a senha, o tutor deve usar “Esqueci a senha” com o e-mail cadastrado.' : 'O tutor pode usar sua senha ou selecionar “Esqueci a senha” com o e-mail cadastrado.'}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              BotaoClinica(
                label: 'Concluir',
                expanded: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        )
      : SucessoCadastroRecepcao(
          consulta: _consultaCriada,
          nomePet: _nomePetController.text,
          dataFormatada: _consultaCriada == null
              ? ''
              : _formatarData(_consultaCriada!.data),
          onNovoCadastro: _reiniciar,
        );

  Widget _seletorIndicacao() {
    final indicacoes = _indicacoes;
    final origem = AgendaClinica.instancia.prontuarios[_prontuarioSelecionado];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (indicacoes.isEmpty)
          const Text(
            'Este pet não tem indicação de internação disponível. A indicação deve ser registrada pelo veterinário no prontuário.',
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey(
              'indicacao-${_nomePetController.text}-$_prontuarioSelecionado',
            ),
            initialValue: indicacoes.any((c) => c.id == _prontuarioSelecionado)
                ? _prontuarioSelecionado
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Prontuário com indicação',
              border: OutlineInputBorder(),
            ),
            items: indicacoes
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${_formatarData(c.data)} · ${AgendaClinica.instancia.prontuarios[c.id]!.procedimentoIndicado}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() => _prontuarioSelecionado = id),
          ),
        if (origem?.dataPrevistaInternacao != null) ...[
          const SizedBox(height: 12),
          Text(
            'Data prevista: ${_formatarData(origem!.dataPrevistaInternacao!)}',
            style: TipografiaApp.bodyMedium,
          ),
          const Text(
            'A previsão é uma referência. Você pode escolher outra data para o agendamento.',
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  String? Function(String?) _obrigatorio(String mensagem) {
    return (value) => (value?.trim().isEmpty ?? true) ? mensagem : null;
  }

  /// Mascara um CPF para exibição parcial.
  String _mascaraCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return cpf;
    return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
  }
}
