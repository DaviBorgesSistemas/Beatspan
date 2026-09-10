import 'package:beatspan/domain/usecase/musica_playback_usecase.dart';
import 'package:beatspan/domain/usecase/preview_playback_usecase.dart';
import 'package:beatspan/domain/usecase/spotify_playback_usecase.dart';
import 'package:beatspan/presentation/game/player_music/player_music_premium_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotifyPlaybackUseCase extends Mock
    implements SpotifyPlaybackUseCase {}

class _MockMusicaPlaybackUseCase extends Mock
    implements MusicaPlaybackUseCase {}

class _MockPreviewPlaybackUseCase extends Mock
    implements PreviewPlaybackUseCase {}

void main() {
  // `flutter test` roda em VM (não Android/iOS/web), então
  // `_PlayerMusicPremiumViewState._initSpotify` sempre cai no branch de
  // "plataforma não suportada" antes de qualquer chamada ao use case —
  // é o único caminho de fato exercitável sem um device real, e é também
  // o comportamento real do widget nesse ambiente (proteção explícita no
  // código contra plataformas sem o plugin nativo).
  late _MockSpotifyPlaybackUseCase spotifyPlaybackUseCase;
  late _MockMusicaPlaybackUseCase musicaPlaybackUseCase;

  setUp(() {
    spotifyPlaybackUseCase = _MockSpotifyPlaybackUseCase();
    musicaPlaybackUseCase = _MockMusicaPlaybackUseCase();
    when(() => spotifyPlaybackUseCase.pause()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MaterialApp(
      home: PlayerMusicPremiumView(
        initialUri: 'spotify:track:abc123',
        spotifyPlaybackUseCase: spotifyPlaybackUseCase,
        musicaPlaybackUseCase: musicaPlaybackUseCase,
        previewPlaybackUseCaseFactory: () => _MockPreviewPlaybackUseCase(),
      ),
    );
  }

  testWidgets(
    'mostra erro de plataforma não suportada e botão Voltar, sem chamar o use case',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('Plataforma não suportada pelo spotify_sdk.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
      verifyNever(() => spotifyPlaybackUseCase.startPlayback(any()));
      verifyZeroInteractions(musicaPlaybackUseCase);
    },
  );

  testWidgets('toca em Voltar e fecha a tela (pop da navegação)', (
    tester,
  ) async {
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
                      spotifyPlaybackUseCase: spotifyPlaybackUseCase,
                      musicaPlaybackUseCase: musicaPlaybackUseCase,
                      previewPlaybackUseCaseFactory: () =>
                          _MockPreviewPlaybackUseCase(),
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
  });
}
