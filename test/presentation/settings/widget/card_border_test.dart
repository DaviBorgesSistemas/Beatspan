import 'package:beatspan/presentation/settings/widget/card_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza o child quando selected é true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardBorder(selected: true, child: Text('conteúdo')),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('renderiza o child quando selected é false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardBorder(selected: false, child: Text('conteúdo')),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('aceita borderRadius customizado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CardBorder(
          selected: false,
          borderRadius: BorderRadius.zero,
          child: Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
  });
}
