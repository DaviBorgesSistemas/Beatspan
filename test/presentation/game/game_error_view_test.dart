import 'package:beatspan/presentation/game/game_error_view.dart';
import 'package:beatspan/presentation/share/widgets/next_card_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({String? title, String? message, IconData? icon}) {
    return MaterialApp(
      home: GameErrorView(
        title: title ?? 'OPS, CÓDIGO QR\nDESCONHECIDO!',
        message: message ??
            'Você escaneou um QR code que não pertence a uma carta Beatspan. Tente outra carta do jogo!',
        icon: icon ?? Icons.qr_code_scanner_rounded,
      ),
    );
  }

  testWidgets('mostra título, mensagem, ícone e o NextCardButton padrão', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('OPS, CÓDIGO QR\nDESCONHECIDO!'), findsOneWidget);
    expect(
      find.text(
        'Você escaneou um QR code que não pertence a uma carta Beatspan. Tente outra carta do jogo!',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byType(NextCardButton), findsOneWidget);
  });

  testWidgets('aceita título, mensagem e ícone customizados', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        title: 'Outro título',
        message: 'Outra mensagem',
        icon: Icons.error,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outro título'), findsOneWidget);
    expect(find.text('Outra mensagem'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });

  testWidgets('toca no botão de fechar e fecha a tela (pop da navegação)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GameErrorView()),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(GameErrorView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(GameErrorView), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });
}
