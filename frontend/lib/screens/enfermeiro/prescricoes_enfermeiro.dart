// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Consulta somente leitura de prescrições do pet.
import 'package:flutter/material.dart';
import 'package:pet_care/controle/agenda_clinica.dart';
import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/modelos/prontuario_compartilhado.dart';
import 'package:pet_care/widgets/clinica/acesso_clinico.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

/// Leitura das prescrições existentes; não cadastra nem administra medicamentos.
class PrescricoesEnfermeiro extends StatefulWidget {
  const PrescricoesEnfermeiro({super.key, required this.consultas});
  final List<ConsultaRecepcao> consultas;

  @override
  State<PrescricoesEnfermeiro> createState() => _PrescricoesEnfermeiroState();
}

class _PrescricoesEnfermeiroState extends State<PrescricoesEnfermeiro> {
  late final Map<String, ConsultaRecepcao> _pets;
  String? _petId;
  Future<List<MedicamentoPrescrito>>? _leitura;

  @override
  void initState() {
    super.initState();
// Remove pacientes repetidos da agenda usando o petId como chave única.
    _pets = {
      for (final c in widget.consultas)
        if (c.petId != null && c.petId!.isNotEmpty) c.petId!: c,
    };
    _petId = _pets.keys.firstOrNull;
    _carregar();
  }

// Centraliza a leitura usada pela seleção e pelo botão Atualizar.
  void _carregar() {
    if (_petId != null && AcessoClinico.permitido('ENFERMEIRO')) {
      _leitura = AgendaClinica.instancia.servico.listarPrescricoes(_petId!);
    }
  }

  @override
  Widget build(BuildContext context) => AcessoClinico(
    perfil: 'ENFERMEIRO',
    builder: (_) => Scaffold(
      backgroundColor: CoresApp.background,
      appBar: cabecalhoClinica('Prescrições dos pacientes'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Pacientes da agenda carregada. Para outros dias, selecione a data na Agenda.',
            ),
            const SizedBox(height: 12),
            if (_pets.isEmpty)
              const Text('Nenhum paciente disponível nessa agenda.')
            else ...[
// Trocar o paciente altera a chave da FutureBuilder e força nova leitura.
              DropdownButtonFormField<String>(
                initialValue: _petId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Paciente'),
                items: [
                  for (final item in _pets.entries)
                    DropdownMenuItem(
                      value: item.key,
                      child: Text(
                        '${item.value.pet} · ${item.value.tutor}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() {
                  _petId = id;
                  _carregar();
                }),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
// Recria a leitura sem alterar o paciente selecionado.
                  onPressed: () => setState(_carregar),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<MedicamentoPrescrito>>(
                  key: ValueKey(_petId),
                  future: _leitura,
                  builder: (context, snapshot) {
// Os estados de carregamento, erro e lista vazia são tratados separadamente.
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                      );
                    }
                    final lista = snapshot.data ?? [];
                    if (lista.isEmpty) {
                      return const Text(
                        'Nenhuma prescrição registrada para este paciente.',
                      );
                    }
                    return ListView(
                      children: [
                        for (final p in lista)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CartaoClinica(
                              child: ListTile(
                                leading: const Icon(Icons.medication_outlined),
                                title: Text(p.nome),
                                subtitle: Text(
                                  'Dose: ${p.dosagem}\nFrequência: ${p.frequencia}\nDuração: ${p.duracao}\n${p.orientacao}\nStatus: ${p.status}',
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
