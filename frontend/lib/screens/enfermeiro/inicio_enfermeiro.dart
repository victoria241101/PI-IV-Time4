// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Início da enfermagem, fila de triagens, indicadores e ações permitidas, reaproveitando a estrutura do veterinário.
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

  // Adapta a tela compartilhada ao perfil de enfermagem sem duplicar o layout clínico.
  @override
  Widget build(BuildContext context) => InicioVeterinario(
    perfilAcesso: 'ENFERMEIRO',
    profissional: SessaoUsuario.instancia.nomeUsuario ?? 'Enfermeiro',
    mostrarTodasConsultas: true,
    // A enfermeira vê apenas as etapas de triagem previstas no filtro abaixo.
    paginaConsultaBuilder: _paginaTriagem,
    resumoHojeBuilder: _resumoTriagens,
    // Estes estados representam a fila ainda pendente e a triagem em andamento.
    filtroConsultas: (consulta) => const {
      StatusConsultaRecepcao.aguardandoTriagem,
      StatusConsultaRecepcao.emTriagem,
    }.contains(consulta.status),
    // A terceira aba reutiliza a tela de clientes, mas fixa o foco em internações.
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
    ),
    // O rótulo da ação acompanha a etapa atual, evitando uma ação genérica.
    rotuloAcaoConsulta: (consulta) => switch (consulta.status) {
      StatusConsultaRecepcao.aguardandoTriagem => 'Iniciar triagem',
      StatusConsultaRecepcao.emTriagem => 'Continuar triagem',
      _ => null,
    },
  );

  // Resumo local: conta fila e consultas que já avançaram após a triagem.
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
