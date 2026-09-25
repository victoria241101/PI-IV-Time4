import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_care/main.dart';
import 'package:pet_care/widgets/cartao_base.dart';
import 'package:pet_care/widgets/cartao_pet.dart';

void main() {
  testWidgets('Pet da Home abre detalhes e a tela de vacinas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AplicativoVeterinaria(home: criarInicioTutorLocal()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CartaoPet).first);
    await tester.pumpAndSettle();

    expect(find.text('Informações do pet'), findsOneWidget);
    expect(find.text('Informações básicas'), findsOneWidget);
    expect(find.text('Vacinas'), findsOneWidget);
    expect(find.text('Medicamentos'), findsOneWidget);
    expect(find.text('Exames'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);

    await tester.tap(find.text('Vacinas'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vacinas de'), findsOneWidget);
    expect(find.byType(CartaoBase), findsWidgets);
    expect(find.byIcon(Icons.vaccines_outlined), findsWidgets);
  });
}
