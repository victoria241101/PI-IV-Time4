import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/cartao_campanha.dart';
import 'package:pet_care/widgets/publicos/cabecalho_publico.dart';

import '../doacao/detalhes_doacao.dart';

class InicioPublico extends StatelessWidget {
  const InicioPublico({
    super.key,
  });

  void _abrirCampanha(
      BuildContext context, {
        required String nomeAnimal,
        required String titulo,
        required double valorArrecadado,
        required double meta,
        bool urgente = false,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesDoacao(
          nomeAnimal: nomeAnimal,
          titulo: titulo,
          valorArrecadado: valorArrecadado,
          meta: meta,
          urgente: urgente,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: EspacamentosApp.lg,
            bottom: EspacamentosApp.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoPublico(),

              const SizedBox(
                height: EspacamentosApp.xxl,
              ),

              // ==========================
              // APRESENTAÇÃO
              // ==========================

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuide. Ajude. Transforme.',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(
                      height: EspacamentosApp.sm,
                    ),
                    Text(
                      'Ajude animais que precisam de cuidados veterinários.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xxl,
              ),

              // ==========================
              // CAMPANHAS
              // ==========================

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Text(
                  'Campanhas em destaque',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.darkBlue,
                  ),
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.md,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  children: [
                    CartaoCampanha(
                      nomeAnimal: 'Bobby',
                      titulo: 'Cirurgia ortopédica de emergência',
                      valorArrecadado: 1250,
                      meta: 2000,
                      urgente: true,
                      onTap: () => _abrirCampanha(
                        context,
                        nomeAnimal: 'Bobby',
                        titulo: 'Cirurgia ortopédica de emergência',
                        valorArrecadado: 1250,
                        meta: 2000,
                        urgente: true,
                      ),
                    ),

                    const SizedBox(
                      height: EspacamentosApp.lg,
                    ),

                    CartaoCampanha(
                      nomeAnimal: 'Luna',
                      titulo: 'Tratamento veterinário',
                      valorArrecadado: 400,
                      meta: 850,
                      onTap: () => _abrirCampanha(
                        context,
                        nomeAnimal: 'Luna',
                        titulo: 'Tratamento veterinário',
                        valorArrecadado: 400,
                        meta: 850,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}