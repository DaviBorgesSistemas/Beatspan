import 'package:beatspan/domain/model/faqs.dart';
import 'package:beatspan/presentation/faqs/widgets/faq_tile.dart';
import 'package:beatspan/presentation/faqs/widgets/session_tile.dart';
import 'package:beatspan/presentation/share/widgets/empty_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra EmptyContainer quando faq é nulo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FaqTile(faq: null)));

    expect(find.byType(EmptyContainer), findsOneWidget);
    expect(find.byType(SessionTile), findsNothing);
  });

  testWidgets(
    'mostra título e uma SessionTile por sessão quando faq não é nulo',
    (tester) async {
      final faq = Faq(
        title: 'Categoria',
        session: [
          Session(title: 'P1', content: 'Resposta simples'),
          Session(title: 'P2', content: 'Outra resposta'),
        ],
      );

      await tester.pumpWidget(MaterialApp(home: FaqTile(faq: faq)));

      expect(find.text('Categoria'), findsOneWidget);
      expect(find.byType(SessionTile), findsNWidgets(2));
    },
  );

  testWidgets('expandir a sessão mostra o conteúdo com link externo, interno e '
      'texto puro', (tester) async {
    final faq = Faq(
      title: 'Categoria',
      session: [
        Session(
          title: 'Pergunta',
          content:
              'Veja [aqui](https://exemplo.com) ou [Regras](@rules) ou'
              ' [ruim](xyz) — texto final.',
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: FaqTile(faq: faq)));

    await tester.tap(find.text('Pergunta'));
    await tester.pumpAndSettle();

    final richText = tester.widget<RichText>(find.byType(RichText).last);
    final fullText = richText.text.toPlainText();

    expect(fullText, contains('aqui'));
    expect(fullText, contains('Regras'));
    expect(fullText, contains('ruim'));
    expect(fullText, contains('texto final'));

    final rootSpan = richText.text as TextSpan;
    final linkSpan =
        rootSpan.children!.firstWhere((s) => (s as TextSpan).text == 'aqui')
            as TextSpan;
    expect(linkSpan.recognizer, isA<TapGestureRecognizer>());
  });
}
