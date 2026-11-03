// inicio do enfermeiro com agenda e triagem dos atendimentos
import 'package:flutter/material.dart';
import 'package:pet_care/widgets/clinica/componentes_clinica.dart';

import 'package:pet_care/controle/sessao_usuario.dart';
import 'package:pet_care/modelos/consulta_recepcao.dart';
import 'package:pet_care/screens/enfermeiro/triagem_enfermeiro.dart';
import 'package:pet_care/screens/veterinario/clientes_veterinario.dart';
import 'package:pet_care/screens/veterinario/inicio_veterinario.dart';

class InicioEnfermeiro extends StatelessWidget {
  const InicioEnfermeiro({super.key});

  @override
  Widget build(BuildContext context) => InicioVeterinario(
    profissional: SessaoUsuario.instancia.nomeUsuario ?? 'Enfermeiro',
    mostrarTodasConsultas: true,
    paginaConsultaBuilder: _paginaTriagem,
    resumoHojeBuilder: _resumoTriagens,
    filtroConsultas: (consulta) => const {
      StatusConsultaRecepcao.aguardandoTriagem,
      StatusConsultaRecepcao.emTriagem,
    }.contains(consulta.status),
    terceiraAbaItem: const BottomNavigationBarItem(
      icon: Icon(Icons.local_hospital_outlined),
      activeIcon: Icon(Icons.local_hospital_rounded),
      label: 'Internados',
    ),
    terceiraAbaBuilder: (consultas) => ClientesVeterinario(
      consultas: consultas,
      profissional: SessaoUsuario.instancia.nomeUsuario ?? 'Enfermeiro',
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

  Widget _resumoTriagens(List<ConsultaRecepcao> consultas) {
    final finalizadas = consultas
        .where(
          (c) => const {
            StatusConsultaRecepcao.aguardandoVeterinario,
            StatusConsultaRecepcao.emConsulta,
            StatusConsultaRecepcao.finalizado,
          }.contains(c.status),
        )
        .length;
    return ResumoClinica(
      titulo: 'Suas triagens',
      indicadores: [
        (
          consultas
              .where(
                (c) => c.status == StatusConsultaRecepcao.aguardandoTriagem,
              )
              .length,
          'Na fila',
        ),
        (
          finalizadas,
          finalizadas == 1 ? 'Triagem finalizada' : 'Triagens finalizadas',
        ),
      ],
    );
  }

  Widget _paginaTriagem(ConsultaRecepcao consulta) =>
      TriagemEnfermeiro(consulta: consulta);
}
