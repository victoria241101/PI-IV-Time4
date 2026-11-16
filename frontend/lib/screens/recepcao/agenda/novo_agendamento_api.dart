import 'package:flutter/material.dart';
import 'package:pet_care/core/constantes/api_config.dart';
import 'package:pet_care/services/veterinarios_service.dart';
import 'package:pet_care/services/clinica/cadastros_recepcao_service.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/widgets/campo_formulario_app.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

/// Usa os mesmos serviços de veterinários e agendamentos usados pelo tutor.
class NovoAgendamentoApi extends StatefulWidget {
  const NovoAgendamentoApi({super.key, required this.dia});
  final DateTime dia;
  @override
  State<NovoAgendamentoApi> createState() => _NovoAgendamentoApiState();
}

class _NovoAgendamentoApiState extends State<NovoAgendamentoApi> {
  final _cpf = TextEditingController();
  final _cadastros = CadastrosRecepcaoService();
  List<Map<String, dynamic>> _pets = [], _veterinarios = [];
  List<String> _horarios = [];
  String? _pet, _vet, _horario;
  String _tutor = '';
  String _tipo = 'consulta_geral';
  int _duracao = 30;
  bool _ocupado = false;
  final _tipos = const {
    'consulta_geral': 'Consulta geral',
    'vacinacao': 'Vacinação',
    'dermatologia': 'Dermatologia',
    'odontologia': 'Odontologia',
    'retorno': 'Retorno',
    'exames_laboratoriais': 'Exames laboratoriais',
  };
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
    final vets = await VeterinariosService(baseUrl: ApiConfig.baseUrl)
        .listarVeterinarios();
    if (!mounted) return;
    setState(() {
      _tutor = dados['tutor']['nome'] as String;
      _pets = (dados['pets'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      _veterinarios = vets;
    });
  });

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
          duracaoMinutos: _duracao,
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
      tipo: _tipo,
      duracaoMinutos: _duracao,
    );
    if (mounted) Navigator.pop(context, true);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: cabecalhoClinica('Novo agendamento'),
    body: AbsorbPointer(
      absorbing: _ocupado,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Data: ${widget.dia.day}/${widget.dia.month}/${widget.dia.year}',
          ),
          if (_ocupado) const LinearProgressIndicator(),
          CampoFormularioApp(controller: _cpf, label: 'CPF do tutor'),
          TextButton(
            onPressed: _buscar,
            child: const Text('Buscar tutor e pets'),
          ),
          if (_tutor.isNotEmpty) Text(_tutor),
          if (_tutor.isNotEmpty && _pets.isEmpty)
            const Text('Este tutor não tem pets cadastrados.'),
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
            onChanged: (v) => setState(() => _pet = v),
          ),
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
          DropdownButtonFormField<int>(
            initialValue: _duracao,
            decoration: const InputDecoration(labelText: 'Duração'),
            items: [30, 60, 90, 120]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v min')))
                .toList(),
            onChanged: (v) {
              setState(() => _duracao = v!);
              _disponibilidade();
            },
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: _tipos.entries
                .map(
                  (v) => DropdownMenuItem(value: v.key, child: Text(v.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _horario,
            key: ValueKey('horario-$_horario-${_horarios.join()}'),
            decoration: const InputDecoration(labelText: 'Horário disponível'),
            items: _horarios
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _horario = v),
          ),
          if (_vet != null && !_ocupado && _horarios.isEmpty)
            const Text(
              'Nenhum horário disponível. Escolha outra data ou veterinário.',
            ),
          const SizedBox(height: 20),
          BotaoClinica(label: 'Confirmar agendamento', onPressed: _salvar),
        ],
      ),
    ),
  );
}
