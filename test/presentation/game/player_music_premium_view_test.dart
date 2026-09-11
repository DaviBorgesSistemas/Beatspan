import 'dart:async';

import 'package:beatspan/domain/enum/settings_enum.dart';
import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/musica_playback_result.dart';
import 'package:beatspan/domain/model/playback_state.dart';
import 'package:beatspan/domain/usecase/musica_playback_usecase.dart';
import 'package:beatspan/domain/usecase/preview_playback_usecase.dart';
import 'package:beatspan/domain/usecase/spotify_playback_usecase.dart';
import 'package:beatspan/presentation/game/player_music/play_music_free_view.dart';
import 'package:beatspan/presentation/game/player_music/player_music_premium_view.dart';
import 'package:beatspan/presentation/share/widgets/next_card_button.dart';
import 'package:dartz/dartz.dart' hide State;
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
  // `_PlayerMusicPremiumViewState._initSpotify` sempre cairia no branch de
  // "plataforma não suportada" antes de qualquer chamada ao use case. Para
  // exercitar os demais branches (sucesso, falhas do Spotify, fallback para
  // prévia, StreamBuilder/_VisualGlyphsCard), o widget aceita o parâmetro
  // `isPlatformSupportedForTest` — um escape hatch só para teste que, quando
  // não-nulo, substitui a checagem de plataforma real sem alterar o
  // comportamento de produção (onde ele é sempre `null`).
  late _MockSpotifyPlaybackUseCase spotifyPlaybackUseCase;
  late _MockMusicaPlaybackUseCase musicaPlaybackUseCase;

  setUpAll(() {
    registerFallbackValue(
      const MusicaPlaybackInput(
        spotifyUri: 'spotify:track:fallback',
        plan: PlanType.free,
        gameMode: GameModeType.preview,
      ),
    );
  });

  setUp(() {
    spotifyPlaybackUseCase = _MockSpotifyPlaybackUseCase();
    musicaPlaybackUseCase = _MockMusicaPlaybackUseCase();
    when(() => spotifyPlaybackUseCase.pause()).thenAnswer((_) async {});
  });

  Widget buildSubject({
    bool? isPlatformSupportedForTest = true,
    PreviewPlaybackUseCase Function()? previewPlaybackUseCaseFactory,
  }) {
    return MaterialApp(
      home: PlayerMusicPremiumView(
        initialUri: 'spotify:track:abc123',
        spotifyPlaybackUseCase: spotifyPlaybackUseCase,
        musicaPlaybackUseCase: musicaPlaybackUseCase,
        previewPlaybackUseCaseFactory:
            previewPlaybackUseCaseFactory ?? () => _MockPreviewPlaybackUseCase(),
        isPlatformSupportedForTest: isPlatformSupportedForTest,
      ),
    );
  }

  group('plataforma não suportada (comportamento real em flutter test)', () {
    testWidgets(
      'mostra erro de plataforma não suportada e botão Voltar, sem chamar o use case',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(isPlatformSupportedForTest: null),
        );
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
  });

  group('sucesso ao iniciar playback', () {
    testWidgets(
      'mostra o _VisualGlyphsCard/NextCardButton (não o erro) e assina a stream de estado',
      (tester) async {
        final controller = StreamController<PlaybackState>.broadcast();
        addTearDown(controller.close);

        when(
          () => spotifyPlaybackUseCase.startPlayback(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => spotifyPlaybackUseCase.subscribePlayerState(),
        ).thenAnswer((_) => controller.stream);

        await tester.pumpWidget(buildSubject());
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.byType(NextCardButton), findsOneWidget);
        verify(() => spotifyPlaybackUseCase.subscribePlayerState()).called(1);
      },
    );
  });

  group('falha de autorização (SpotifyPlaybackNaoAutorizado)', () {
    testWidgets('sem fallback disponível mostra erro com a mensagem e botão Voltar', (
      tester,
    ) async {
      when(() => spotifyPlaybackUseCase.startPlayback(any())).thenAnswer(
        (_) async => const Left(
          SpotifyPlaybackNaoAutorizado('Sessão do Spotify expirada.'),
        ),
      );
      when(() => musicaPlaybackUseCase.execute(any())).thenAnswer(
        (_) async => const Left(MusicaPlaybackPreviaIndisponivel()),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Sessão do Spotify expirada.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
      verify(() => musicaPlaybackUseCase.execute(any())).called(1);
    });

    testWidgets(
      'com fallback disponível navega para PlayerMusicFreeView mostrando antes a mensagem de fallback',
      (tester) async {
        when(() => spotifyPlaybackUseCase.startPlayback(any())).thenAnswer(
          (_) async => const Left(
            SpotifyPlaybackNaoAutorizado('Sessão do Spotify expirada.'),
          ),
        );
        when(() => musicaPlaybackUseCase.execute(any())).thenAnswer(
          (_) async => const Right(
            PreviewPlayback(
              trackId: 'abc123',
              previewUrl: 'https://preview.example/track.mp3',
              trackName: 'Some Track',
              artistName: 'Some Artist',
              albumArtUrl: 'https://art.example/cover.jpg',
            ),
          ),
        );
        final previewUseCase = _MockPreviewPlaybackUseCase();
        when(
          () => previewUseCase.load(any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => previewUseCase.playerStateStream,
        ).thenAnswer((_) => const Stream<PlaybackState>.empty());
        when(() => previewUseCase.dispose()).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildSubject(previewPlaybackUseCaseFactory: () => previewUseCase),
        );
        await tester.pump();

        // Antes de navegar, mostra brevemente a mensagem de fallback.
        expect(
          find.text('SPOTIFY INDISPONÍVEL, TOCANDO PRÉVIA...'),
          findsOneWidget,
        );

        await tester.pumpAndSettle();

        expect(find.byType(PlayerMusicFreeView), findsOneWidget);
      },
    );
  });

  testWidgets(
    'SpotifyPlaybackPluginAusente mostra erro sem distinguir botão de tentar de novo (não há um na tela de erro)',
    (tester) async {
      when(() => spotifyPlaybackUseCase.startPlayback(any())).thenAnswer(
        (_) async => const Left(
          SpotifyPlaybackPluginAusente('Plugin spotify_sdk ausente.'),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Plugin spotify_sdk ausente.'), findsOneWidget);
      // A tela de erro sempre mostra só o botão "Voltar" — o código não
      // distingue _pluginAvailable com nenhum botão extra de "tentar de
      // novo"; esse flag só é lido aqui e não afeta a UI renderizada.
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      verifyZeroInteractions(musicaPlaybackUseCase);
    },
  );

  testWidgets(
    'falha genérica (SpotifyPlaybackErroInesperado) mostra erro com a mensagem',
    (tester) async {
      when(() => spotifyPlaybackUseCase.startPlayback(any())).thenAnswer(
        (_) async => const Left(
          SpotifyPlaybackErroInesperado('Erro inesperado: timeout'),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Erro inesperado: timeout'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
      verifyZeroInteractions(musicaPlaybackUseCase);
    },
  );

  testWidgets(
    'toggle de play/pause chama togglePlayback com o valor correto ao tocar no _VisualGlyphsCard',
    (tester) async {
      final controller = StreamController<PlaybackState>.broadcast();
      addTearDown(controller.close);

      when(
        () => spotifyPlaybackUseCase.startPlayback(any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => spotifyPlaybackUseCase.subscribePlayerState(),
      ).thenAnswer((_) => controller.stream);
      when(
        () => spotifyPlaybackUseCase.togglePlayback(isPaused: any(named: 'isPaused')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump();

      // Estado inicial: sem dado ainda na stream -> snap.data é null ->
      // playing = false (isPaused == false é falso quando data é null).
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      controller.add(const PlaybackState(isPaused: false));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);

      // playing == true agora; o onTap chama togglePlayback(isPaused: !playing),
      // ou seja isPaused: false — que o use case traduz para _repository.pause()
      // (ver SpotifyPlaybackUseCase.togglePlayback: isPaused ? resume() : pause()).
      // Toca no ícone de pause/play central, dentro do _VisualGlyphsCard —
      // mais robusto do que indexar GestureDetectors pela ordem na árvore.
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      verify(
        () => spotifyPlaybackUseCase.togglePlayback(isPaused: false),
      ).called(1);

      controller.add(const PlaybackState(isPaused: true));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // playing == false agora; onTap chama togglePlayback(isPaused: !playing),
      // ou seja isPaused: true — traduzido para _repository.resume().
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(
        () => spotifyPlaybackUseCase.togglePlayback(isPaused: true),
      ).called(1);
    },
  );

  testWidgets('dispose() chama spotifyPlaybackUseCase.pause()', (
    tester,
  ) async {
    when(
      () => spotifyPlaybackUseCase.startPlayback(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => spotifyPlaybackUseCase.subscribePlayerState(),
    ).thenAnswer((_) => const Stream<PlaybackState>.empty());

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump();

    verifyNever(() => spotifyPlaybackUseCase.pause());

    // Desmonta a árvore trocando por outro widget raiz.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    verify(() => spotifyPlaybackUseCase.pause()).called(1);
  });
}
