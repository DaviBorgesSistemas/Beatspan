import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/presentation/game/player_music/player_music_premium_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotifyService extends Mock implements SpotifyService {}

void main() {
  // `flutter test` roda em VM (não Android/iOS/web), então
  // `_PlayerMusicPremiumViewState._initSpotify` sempre cai no branch de
  // "plataforma não suportada" antes de qualquer chamada ao spotify_sdk —
  // é o único caminho de fato exercitável sem um device real, e é também
  // o comportamento real do widget nesse ambiente (proteção explícita no
  // código contra plataformas sem o plugin nativo).
  late _MockSpotifyService spotifyService;

  setUp(() {
    spotifyService = _MockSpotifyService();
  });

  Widget buildSubject() {
    return MaterialApp(
      home: PlayerMusicPremiumView(
        initialUri: 'spotify:track:abc123',
        spotifyService: spotifyService,
      ),
    );
  }

  testWidgets(
    'mostra erro de plataforma não suportada e botão Voltar, sem chamar o SpotifyService',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('Plataforma não suportada pelo spotify_sdk.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
      verifyNever(() => spotifyService.authorizeAndConnect());
    },
  );

  testWidgets(
    'toca em Voltar e fecha a tela (pop da navegação)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerMusicPremiumView(
                        initialUri: 'spotify:track:abc123',
                        spotifyService: spotifyService,
                      ),
                    ),
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

      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Voltar'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    },
  );
}
