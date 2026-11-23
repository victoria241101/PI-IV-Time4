
import 'package:flutter/material.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/services/veterinarios_service.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/cartao_opcao_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/controle/cadastros_recepcao_local.dart';
import 'package:pet_care/screens/recepcao/cadastro/cadastro_recepcao.dart';

enum _ModoAgendamento { tutorExistente, novoTutor }

class NovoAgendamentoApi extends StatefulWidget {
  const NovoAgendamentoApi({
    super.key,
    required this.dia,
    this.cadastrosService,
  });
  final DateTime dia;
  final CadastrosRecepcaoService? cadastrosService;

  @override
  State<NovoAgendamentoApi> createState() => _NovoAgendamentoApiState();
}

class _NovoAgendamentoApiState extends State<NovoAgendamentoApi> {
  final _cpf = TextEditingController();
  late final _cadastros =
      widget.cadastrosService ?? CadastrosRecepcaoService();
  List<Map<String, dynamic>> _pets = [], _veterinarios = [];
  List<String> _horarios = [];
  String? _pet, _vet, _horario;
  String _nomePet = '';
  String _tutor = '';
  _ModoAgendamento? _modo;
  bool _ocupado = false;

  @override
  void dispose() {
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _buscar() => _executar(() async {
    setState(() {
      _pet = null;
      _nomePet = '';
      _pets = [];
      _tutor = '';
      _vet = null;
      _horario = null;
      _horarios = [];
    });

    final dados = await _cadastros.buscarTutor(_cpf.text);
    if (dados == null) {
      throw StateError(
        'Tutor não encontrado. Faça o cadastro de tutor e pet na aba Cadastro.',
      );
    }

    if (!mounted) return;
    setState(() {
      _tutor = dados['tutor']['nome'] as String;
      _pets = (dados['pets'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
    });
    await _carregarVeterinarios();
  });

  Future<void> _carregarVeterinarios() async {
    final vets = await VeterinariosService(baseUrl: ApiConfig.baseUrl)
        .listarVeterinarios();
    if (mounted) setState(() => _veterinarios = vets);
  }

  void _selecionarTutorExistente() {
    setState(() {
      _modo = _ModoAgendamento.tutorExistente;
      _pet = null;
      _nomePet = '';
      _tutor = '';
      _pets = [];
      _vet = null;
      _horario = null;
      _horarios = [];
    });
  }

  Future<void> _cadastrarPaciente({required bool tutorExistente}) async {
    await _executar(() async {
      RegistroRecepcaoLocal? cadastro;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: cabecalhoClinica(
              tutorExistente ? 'Cadastrar pet' : 'Cadastrar tutor e pet',
            ),
            body: CadastroRecepcao(
              somenteCadastro: !tutorExistente,
              somentePet: tutorExistente,
              onRegistrarConsulta: (_) => false,
              cadastrosService: _cadastros,
              onCadastroConcluido: (registro) => cadastro = registro,
            ),
          ),
        ),
      );
      if (!mounted || cadastro == null) {
        if (mounted) setState(() => _modo = null);
        return;
      }
      final petId = cadastro!.dados['petId'];
      if (petId == null || petId.isEmpty) {
        throw const FormatException('Resposta de cadastro sem identificador do pet.');
      }
      setState(() {
        _modo = tutorExistente
            ? _ModoAgendamento.tutorExistente
            : _ModoAgendamento.novoTutor;
        _pet = petId;
        _nomePet = cadastro!.dados['pet'] ?? '';
        _tutor = cadastro!.nome;
        _vet = null;
        _horario = null;
        _horarios = [];
      });
      await _carregarVeterinarios();
    });
  }

  Future<void> _cadastrarOutroPet() => _cadastrarPaciente(
    tutorExistente: true,
  );

  void _voltarOpcoes() {
    setState(() {
      _modo = null;
      _pet = null;
      _nomePet = '';
      _tutor = '';
      _pets = [];
      _vet = null;
      _horario = null;
      _horarios = [];
    });
  }

  Future<void> _disponibilidade() => _executar(() async {
    setState(() {
      _horario = null;
      _horarios = [];
    });

    if (_vet == null) return;

    final horarios = await AgendaClinica.instancia.servico.agendamentos
        .consultarDisponibilidade(
          veterinarioId: _vet!,
          data: widget.dia,
        );

    if (mounted) setState(() => _horarios = horarios);
  });

  Future<void> _salvar() => _executar(() async {
    if (_pet == null || _vet == null || _horario == null) {
      throw StateError('Selecione pet, veterinário e horário.');
    }

    await AgendaClinica.instancia.servico.agendamentos.criarAgendamento(
      petId: _pet!,
      veterinarioId: _vet!,
      data: widget.dia,
      horario: _horario!,
    );

    if (mounted) Navigator.pop(context, true);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: cabecalhoClinica('Novo agendamento'),
    body: AbsorbPointer(
      absorbing: _ocupado,
      child: ListView(
        padding: const EdgeInsets.all(EspacamentosApp.md),
        children: [
          CartaoClinica(
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: EspacamentosApp.sm),
                Expanded(
                  child: Text(
                    'Data selecionada · ${widget.dia.day}/${widget.dia.month}/${widget.dia.year}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EspacamentosApp.md),
          if (_ocupado) const LinearProgressIndicator(),
          if (_modo == null) ...[
            Text('Como deseja identificar o paciente?'),
            const SizedBox(height: EspacamentosApp.sm),
            CartaoOpcaoApp(
              icon: Icons.person_add_alt_1_outlined,
              titulo: 'Novo tutor',
              descricao: 'Cadastre o responsável e o pet',
              onTap: () => _cadastrarPaciente(tutorExistente: false),
            ),
            const SizedBox(height: EspacamentosApp.sm),
            CartaoOpcaoApp(
              icon: Icons.pets_outlined,
              titulo: 'Tutor existente',
              descricao: 'Busque pelo CPF, selecione um pet ou cadastre outro',
              onTap: _selecionarTutorExistente,
            ),
          ] else ...[
            TextButton.icon(
              onPressed: _voltarOpcoes,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Alterar opção de paciente'),
            ),
            if (_modo == _ModoAgendamento.tutorExistente &&
                _pet == null) ...[
              CampoFormularioApp(controller: _cpf, label: 'CPF do tutor'),
              const SizedBox(height: EspacamentosApp.sm),
              BotaoClinica(
                label: 'Buscar tutor e pets',
                icon: Icons.search_rounded,
                expanded: true,
                onPressed: _buscar,
              ),
              if (_tutor.isNotEmpty) ...[
                const SizedBox(height: EspacamentosApp.md),
                Text('Tutor: $_tutor'),
                if (_pets.isEmpty)
                  const Text('Este tutor não tem pets cadastrados.'),
                if (_pets.isNotEmpty) ...[
                  const SizedBox(height: EspacamentosApp.sm),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _pet,
                    key: ValueKey('pet-$_pet-${_pets.length}'),
                    decoration: const InputDecoration(labelText: 'Pet'),
                    items: _pets
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['nome'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _pet = v;
                      _nomePet = _pets.firstWhere((p) => p['id'] == v)['nome']
                          as String;
                    }),
                  ),
                ],
                const SizedBox(height: EspacamentosApp.sm),
                OutlinedButton.icon(
                  onPressed: _cadastrarOutroPet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Cadastrar outro pet'),
                ),
              ],
            ],
            if (_pet != null) ...[
              const SizedBox(height: EspacamentosApp.md),
              CartaoClinica(
                child: Text('Paciente: $_nomePet · Tutor: $_tutor'),
              ),
            ],
            if (_pet != null) ...[
              const SizedBox(height: EspacamentosApp.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _vet,
                key: ValueKey('vet-$_vet'),
                decoration: const InputDecoration(labelText: 'Veterinário'),
                items: _veterinarios
                    .map(
                      (v) => DropdownMenuItem(
                        value: v['_id'].toString(),
                        child: Text(v['nome'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _vet = v);
                  _disponibilidade();
                },
              ),
              const SizedBox(height: EspacamentosApp.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _horario,
                key: ValueKey('horario-$_horario-${_horarios.join()}'),
                decoration: const InputDecoration(
                  labelText: 'Horário disponível',
                ),
                items: _horarios
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => setState(() => _horario = v),
              ),
              if (_vet != null && !_ocupado && _horarios.isEmpty)
                const Text(
                  'Nenhum horário disponível para esta data e veterinário.',
                ),
              const SizedBox(height: EspacamentosApp.lg),
              BotaoClinica(
                label: 'Confirmar agendamento',
                onPressed: _salvar,
                expanded: true,
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
