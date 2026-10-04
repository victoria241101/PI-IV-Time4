import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';
import 'package:pet_care/core/tema/espacamentos_app.dart';
import 'package:pet_care/modelos/resumo_consulta.dart';
import 'package:pet_care/modelos/resumo_pet.dart';
import 'package:pet_care/screens/tutor/inicio_tutor.dart';

class ConfirmacaoDoacao extends StatelessWidget {
  const ConfirmacaoDoacao({
    super.key,
    required this.nomeAnimal,
    required this.titulo,
    required this.valorDoacao,
  });

  final String nomeAnimal;
  final String titulo;
  final double valorDoacao;

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  void _voltarParaInicio(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => InicioTutor(
          saudacao: 'Olá,',
          nomeTutor: 'Victoria',
          pets: const [
            ResumoPet(
              id: 'pet-001',
              name: 'Mel',
              species: 'Cachorro',
              breed: 'Golden Retriever',
              age: '3 anos',
              weight: 25.5,
            ),
            ResumoPet(
              id: 'pet-002',
              name: 'Luna',
              species: 'Gato',
              breed: 'Siamês',
              age: '2 anos',
              weight: 4.2,
            ),
          ],
          proximaConsulta: const ResumoConsulta(
            id: 'consulta-001',
            type: 'Consulta veterinária',
            date: '15/10/2026',
            time: '14:00',
            vetName: 'Dra. Ana Oliveira',
            petName: 'Mel',
            status: 'Confirmada',
            instructions: 'Chegar com 10 minutos de antecedência.',
            clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
          ),
          banners: const [],
          onConfirmarConsulta: (consultaId) async {
            return const ResumoConsulta(
              id: 'consulta-001',
              type: 'Consulta veterinária',
              date: '15/10/2026',
              time: '14:00',
              vetName: 'Dra. Ana Oliveira',
              petName: 'Mel',
              status: 'Confirmada',
              instructions: 'Chegar com 10 minutos de antecedência.',
              clinicAddress: 'Rua das Flores, 120 - Campinas/SP',
            );
          },
          carregarDetalhesPet: (petId) async {
            throw UnimplementedError(
              'Detalhes do pet ainda não estão conectados ao backend.',
            );
          },
          onAgendarNovaConsulta: () {},
          onNotificacoes: () {},
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            EspacamentosApp.pagePadding,
          ),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: CoresApp.primary.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: CoresApp.primary,
                  size: 54,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              const Text(
                'Doação confirmada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: CoresApp.darkBlue,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.sm,
              ),

              Text(
                'Sua contribuição de ${_formatarValor(valorDoacao)} '
                    'foi registrada para ajudar $nomeAnimal.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: CoresApp.textSecondary,
                ),
              ),

              const SizedBox(
                height: EspacamentosApp.xl,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  EspacamentosApp.lg,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withAlpha(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      color: CoresApp.primary,
                      size: 32,
                    ),

                    const SizedBox(
                      height: EspacamentosApp.sm,
                    ),

                    Text(
                      nomeAnimal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CoresApp.darkBlue,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _voltarParaInicio(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresApp.darkBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Voltar para o início',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}