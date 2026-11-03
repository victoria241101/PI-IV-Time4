// fluxo de cadastro de tutor e pet pela recepção
import 'package:flutter/material.dart';

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
  const CadastroRecepcao({super.key, required this.onRegistrarConsulta});

  final bool Function(ConsultaRecepcao consulta) onRegistrarConsulta;

  @override
  State<CadastroRecepcao> createState() => _CadastroRecepcaoState();
}

class _CadastroRecepcaoState extends State<CadastroRecepcao> {
  final _cpfKey = GlobalKey<FormState>();
  final _responsavelKey = GlobalKey<FormState>();
  final _petKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _nomePetController = TextEditingController();
  final _racaController = TextEditingController();
  final _idadeController = TextEditingController();
  final _condicoesController = TextEditingController();
  _EtapaCadastro _etapa = _EtapaCadastro.inicio;
  String _nomeResponsavel = '';
  String? _petSelecionado;
  String _especie = 'Cachorro';
  String _sexo = 'Macho';
  String _encaminhamento = 'Triagem';
  late DateTime _dataConsulta;
  TimeOfDay _horarioConsulta = const TimeOfDay(hour: 9, minute: 0);
  String _profissionalConsulta = 'Dra. Beatriz';
  ConsultaRecepcao? _consultaCriada;
  bool _castrado = false;
  bool _possuiMicrochip = false;
  bool _fotoSelecionada = false;
  bool _responsavelExistente = false;

  @override
  void initState() {
    super.initState();
    _dataConsulta = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _nomeResponsavelController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _nomePetController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _condicoesController.dispose();
    super.dispose();
  }
  // Navegação entre etapas

  void _voltar() {
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
          _etapa = _EtapaCadastro.pet;
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
    // TODO(backend): Substituir por chamada real ao serviço de busca de tutor.
    setState(() {
      _responsavelExistente = true;
      _nomeResponsavel = 'Marina Costa';
      _nomeResponsavelController.text = _nomeResponsavel;
      _telefoneController.text = '(11) 98842-1092';
      _emailController.text = 'marina.costa@email.com';
      _enderecoController.text = 'Av. Paulista, 1200 · Bela Vista';
      _etapa = _EtapaCadastro.pets;
    });
  }

  void _continuarResponsavel() {
    if (!_responsavelKey.currentState!.validate()) return;
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
      _etapa = _EtapaCadastro.encaminhamento;
    });
  }

  void _continuarPet() {
    if (!_petKey.currentState!.validate()) return;
    setState(() => _etapa = _EtapaCadastro.encaminhamento);
  }

  void _confirmarEncaminhamento() {
    final agendar = _encaminhamento == 'Agendar consulta';
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
      motivo: agendar ? 'Consulta inicial' : 'Avaliação inicial',
      sala: agendar ? _salaDoProfissional(_profissionalConsulta) : 'Triagem',
      status: agendar
          ? StatusConsultaRecepcao.agendada
          : StatusConsultaRecepcao.aguardandoTriagem,
    );

    if (!widget.onRegistrarConsulta(consulta)) {
      _mensagem('Esse horário já está ocupado para o veterinário escolhido');
      return;
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
      _etapa = _EtapaCadastro.inicio;
      _cpfController.clear();
      _nomeResponsavelController.clear();
      _telefoneController.clear();
      _emailController.clear();
      _enderecoController.clear();
      _nomePetController.clear();
      _racaController.clear();
      _idadeController.clear();
      _condicoesController.clear();
      _petSelecionado = null;
      _especie = 'Cachorro';
      _sexo = 'Macho';
      _encaminhamento = 'Triagem';
      _dataConsulta = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );
      _horarioConsulta = const TimeOfDay(hour: 9, minute: 0);
      _profissionalConsulta = 'Dra. Beatriz';
      _consultaCriada = null;
      _castrado = false;
      _possuiMicrochip = false;
      _fotoSelecionada = false;
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
              _conteudoEtapa(),
            ],
          ),
        ),
      ),
    );
  }
  // Cabeçalho da etapa atual

  Widget _cabecalhoEtapa() {
    final titulo = switch (_etapa) {
      _EtapaCadastro.inicio => 'Cadastrar paciente',
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
          _etapa != _EtapaCadastro.inicio && _etapa != _EtapaCadastro.sucesso,
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
    cpfMascarado: _mascaraCpf(_cpfController.text),
    petSelecionado: _petSelecionado,
    onPetSelecionado: (pet) => setState(() => _petSelecionado = pet),
    onContinuar: _abrirPetExistente,
    onCadastrarPet: () {
      setState(() {
        _nomePetController.clear();
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
    enderecoController: _enderecoController,
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
    enderecoResponsavel: _enderecoController.text,
    nomePetController: _nomePetController,
    racaController: _racaController,
    idadeController: _idadeController,
    condicoesController: _condicoesController,
    especie: _especie,
    sexo: _sexo,
    castrado: _castrado,
    possuiMicrochip: _possuiMicrochip,
    fotoSelecionada: _fotoSelecionada,
    validarNomePet: _obrigatorio('Informe o nome do pet'),
    onEditarResponsavel: _voltar,
    onEspecieChanged: (valor) => setState(() => _especie = valor),
    onSexoChanged: (valor) => setState(() => _sexo = valor),
    onCastradoChanged: (valor) => setState(() => _castrado = valor),
    onMicrochipChanged: (valor) => setState(() => _possuiMicrochip = valor),
    onFotoTocada: () => setState(() => _fotoSelecionada = !_fotoSelecionada),
    onFotoSelecionada: () => setState(() => _fotoSelecionada = true),
    onContinuar: _continuarPet,
  );

  // Etapa: triagem imediata ou agendamento de consulta

  Widget _telaEncaminhamento() => EncaminhamentoCadastro(
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

  Widget _telaSucesso() => SucessoCadastroRecepcao(
    consulta: _consultaCriada,
    nomePet: _nomePetController.text,
    dataFormatada: _consultaCriada == null
        ? ''
        : _formatarData(_consultaCriada!.data),
    onNovoCadastro: _reiniciar,
  );

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
