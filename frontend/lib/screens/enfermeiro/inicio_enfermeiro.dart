// inicio da equipe de enfermagem com agenda e triagem dos atendimentos
import 'package:flutter/material.dart';

import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/triagem_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/clientes_veterinario.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

class InicioEnfermeiro extends StatelessWidget {
  const InicioEnfermeiro({super.key});

  @override
  Widget build(BuildContext context) => InicioVeterinario(
    profissional: 'Equipe de enfermagem',
    mostrarTodasConsultas: true,
    paginaConsultaBuilder: _paginaTriagem,
    cartoesCompactos: true,
    filtroConsultas: (consulta) => const {
      StatusConsultaRecepcao.aguardandoTriagem,
      StatusConsultaRecepcao.emTriagem,
      StatusConsultaRecepcao.aguardandoVeterinario,
    }.contains(consulta.status),
    terceiraAbaItem: const BottomNavigationBarItem(
      icon: Icon(Icons.local_hospital_outlined),
      activeIcon: Icon(Icons.local_hospital_rounded),
      label: 'Internados',
    ),
    terceiraAbaBuilder: (consultas) => ClientesVeterinario(
      consultas: consultas,
      profissional: 'Equipe de enfermagem',
      mostrarInternadosInicialmente: true,
      somenteInternados: true,
      descricao: 'Prontuários compartilhados dos pacientes internados',
    ),
    rotuloAcaoConsulta: (consulta) => switch (consulta.status) {
      StatusConsultaRecepcao.aguardandoTriagem => 'Iniciar triagem',
      StatusConsultaRecepcao.emTriagem => 'Continuar triagem',
      _ => null,
    },
  );

  Widget _paginaTriagem(ConsultaRecepcao consulta) =>
      TriagemEnfermeiro(consulta: consulta);
}
