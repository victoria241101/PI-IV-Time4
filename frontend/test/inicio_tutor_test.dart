import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_care/main.dart';

Widget _aplicativoParaTeste() {
  return AplicativoVeterinaria(home: criarInicioTutorLocal());
}

void main() {
  testWidgets('Home do cliente renderiza seções principais', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_aplicativoParaTeste());
    await tester.pumpAndSettle();

    // Verifica saudação
    expect(find.text('Maria'), findsOneWidget);

    // Verifica seção "Meus pets"
    expect(find.text('Meus pets'), findsOneWidget);

    // Verifica seção "Próxima consulta"
    expect(find.text('Próxima consulta'), findsWidgets);

    // Verifica que não há texto "Community Care"
    expect(find.text('Community Care'), findsNothing);

    // Verifica navegação inferior com "Doações"
    expect(find.text('Doações'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('Ver detalhes abre modal inferior', (WidgetTester tester) async {
    await tester.pumpWidget(_aplicativoParaTeste());
    await tester.pumpAndSettle();

    // Usa drag para rolar o conteúdo principal
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver detalhes'), findsOneWidget);

    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da consulta'), findsOneWidget);
    expect(find.text('Rua das Acácias, 245 — Centro'), findsOneWidget);
    expect(find.text('Reagendar consulta'), findsOneWidget);
    expect(find.text('Cancelar consulta'), findsOneWidget);
  });

  testWidgets('Consulta pendente pode ser confirmada no cartão', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_aplicativoParaTeste());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aguardando confirmação'), findsOneWidget);
    expect(find.text('Confirmar consulta'), findsOneWidget);

    await tester.tap(find.text('Confirmar consulta'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Consulta confirmada'), findsOneWidget);
    expect(find.text('Confirmar consulta'), findsNothing);
    expect(find.text('Consulta confirmada!'), findsOneWidget);
    expect(
      find.text('Nos vemos em 28 de setembro, 2026 às 14:30.'),
      findsOneWidget,
    );
  });

  testWidgets('Agendar nova consulta está visível ao rolar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_aplicativoParaTeste());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agendar nova consulta'), findsOneWidget);
  });

  testWidgets('Seção de banners mostra mensagem quando não há imagens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_aplicativoParaTeste());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Novidades'), findsOneWidget);
    expect(find.text('Nenhuma novidade no momento.'), findsOneWidget);
  });
}
