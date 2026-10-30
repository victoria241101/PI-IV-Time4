
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/widgets/cabecalho_app.dart';

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
                            child: Icon(
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
                    Row(
                      children: [
                        Text(
                          'Suas conversas',
                          style: TextStyle(
                            color: CoresApp.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: CoresApp.surfaceSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '0 conversas',
                            style: TextStyle(
                              color: CoresApp.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EspacamentosApp.md),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: EspacamentosApp.lg,
                              vertical: EspacamentosApp.xl,
                            ),
                            decoration: BoxDecoration(
                              color: CoresApp.surface,
                              borderRadius: BorderRadius.circular(
                                EspacamentosApp.radiusLg,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: CoresApp.surfaceSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.forum_outlined,
                                    size: 40,
                                    color: CoresApp.primary,
                                  ),
                                ),
                                const SizedBox(
                                  height: EspacamentosApp.lg,
                                ),
                                Text(
                                  'Nenhuma conversa ainda',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CoresApp.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: EspacamentosApp.sm,
                                ),
                                Text(
                                  'Quando houver conversas vinculadas '
                                      'ao seu atendimento, elas aparecerão aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CoresApp.textSecondary,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
