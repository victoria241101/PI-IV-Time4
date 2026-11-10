import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';
import 'package:pet_care/widgets/chat/lista_conversas.dart';

class ConversasTutor extends StatelessWidget {
  const ConversasTutor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: EspacamentosApp.lg),
            const CabecalhoApp(
              greeting: 'Chat',
              name: '',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacamentosApp.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: EspacamentosApp.lg),
                    Text(
                      'Converse com a clínica',
                      style: TextStyle(
                        color: CoresApp.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xs),
                    Text(
                      'Um espaço para acompanhar suas conversas '
                          'sobre o cuidado do seu pet.',
                      style: TextStyle(
                        color: CoresApp.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        EspacamentosApp.md,
                      ),
                      decoration: BoxDecoration(
                        color: CoresApp.surface,
                        borderRadius: BorderRadius.circular(
                          EspacamentosApp.radiusLg,
                        ),
                        border: Border.all(
                          color: CoresApp.primary.withAlpha(35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: CoresApp.surfaceSoft,
                              borderRadius: BorderRadius.circular(
                                EspacamentosApp.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: CoresApp.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: EspacamentosApp.md,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estamos aqui para ajudar',
                                  style: TextStyle(
                                    color: CoresApp.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: EspacamentosApp.xs,
                                ),
                                Text(
                                  'Consulte as conversas disponíveis '
                                      'com a equipe responsável pelo atendimento.',
                                  style: TextStyle(
                                    color: CoresApp.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.xl),
                    Expanded(
                      child: ListaConversas(
                        titulo: 'Suas conversas',
                        onAbrirConversa: (conversa) {
                          // provisório até a Parte 5
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A tela de mensagens chega na próxima etapa.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: EspacamentosApp.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
