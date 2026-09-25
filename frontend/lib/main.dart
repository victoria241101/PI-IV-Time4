import 'package:fonte_dados_tutor/fonte_dados_tutor.dart';
import 'package:flutter/material.dart';

import 'package:pet_care/core/comportamento_rolagem.dart';
import 'package:pet_care/core/tema_app.dart';
import 'package:pet_care/modelos/dados_banner.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/tutor/inicio_tutor.dart';

void main() {
  runApp(AplicativoVeterinaria(home: criarInicioTutorLocal()));
}

/// Ponto único de composição da fonte de dados local.
///
/// Quando o back-end real estiver disponível, somente esta composição e a
/// dependência correspondente precisam ser trocadas. As telas e widgets não
/// conhecem a implementação usada.
InicioTutor criarInicioTutorLocal() {
  final dados = criarFonteDadosTutor();

  return InicioTutor(
    saudacao: dados.saudacao,
    nomeTutor: dados.nomeTutor,
    pets: dados.pets.map(ResumoPet.fromMap).toList(growable: false),
    proximaConsulta: ResumoConsulta.fromMap(dados.proximaConsulta),
    banners: dados.banners.map(DadosBanner.deMapa).toList(growable: false),
    onConfirmarConsulta: (consultaId) async {
      final consultaAtualizada = await dados.confirmarConsulta(consultaId);
      return ResumoConsulta.fromMap(consultaAtualizada);
    },
  );
}

class AplicativoVeterinaria extends StatelessWidget {
  const AplicativoVeterinaria({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ComportamentoRolagemApp(),
      theme: TemaApp.light,
      home: home,
    );
  }
}
