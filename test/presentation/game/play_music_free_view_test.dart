import 'dart:async';

import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/playback_state.dart';
import 'package:beatspan/domain/usecase/preview_playback_usecase.dart';
import 'package:beatspan/domain/usecase/spotify_playback_usecase.dart';
import 'package:beatspan/presentation/game/player_music/play_music_free_view.dart';
import 'package:beatspan/presentation/share/widgets/next_card_button.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreviewPlaybackUseCase extends Mock
    implements PreviewPlaybackUseCase {}

class _MockSpotifyPlaybackUseCase extends Mock
    implements SpotifyPlaybackUseCase {}

void main() {
  late _MockPreviewPlaybackUseCase previewPlaybackUseCase;
  late _MockSpotifyPlaybackUseCase spotifyPlaybackUseCase;

  setUp(() {
    previewPlaybackUseCase = _MockPreviewPlaybackUseCase();
    spotifyPlaybackUseCase = _MockSpotifyPlaybackUseCase();
    when(() => previewPlaybackUseCase.dispose()).thenAnswer((_) async {});
  });

  Widget buildSubject({
    String? trackId = 'track123',
    String previewUrl = 'https://preview.example/track.mp3',
    String? trackName = 'Some Track',
    String? artistName = 'Some Artist',
    String? albumArtUrl,
  }) {
    return MaterialApp(
      home: PlayerMusicFreeView(
        trackId: trackId,
        previewUrl: previewUrl,
        trackName: trackName,
        artistName: artistName,
        albumArtUrl: albumArtUrl,
        previewPlaybackUseCase: previewPlaybackUseCase,
        spotifyPlaybackUseCase: spotifyPlaybackUseCase,
      ),
    );
  }

  group('carregamento inicial', () {
    testWidgets('mostra o overlay de loading enquanto load() não resolve', (
      tester,
    ) async {
      final completer = Completer<Either<PreviewPlaybackFailure, Unit>>();
      when(
        () => previewPlaybackUseCase.load(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('CARREGANDO PRÉVIA...'), findsOneWidget);
      expect(find.byType(NextCardButton), findsNothing);

      completer.complete(const Right(unit));
      when(
        () => previewPlaybackUseCase.playerStateStream,
      ).thenAnswer((_) => const Stream<PlaybackState>.empty());
      await tester.pump();
    });

    testWidgets('erro no load() mostra tela de erro com botão Voltar', (
      tester,
    ) async {
      when(() => previewPlaybackUseCase.load(any())).thenAnswer(
        (_) async => const Left(
          PreviewPlaybackErroInesperado('Não foi possível carregar a prévia.'),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('Não foi possível carregar a prévia.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Voltar'), findsOneWidget);
    });

    testWidgets('toca em Voltar na tela de erro e fecha a tela', (
      tester,
    ) async {
      when(() => previewPlaybackUseCase.load(any())).thenAnswer(
        (_) async =>
            const Left(PreviewPlaybackErroInesperado('Erro ao carregar.')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerMusicFreeView(
                        trackId: 'track123',
                        previewUrl: 'https://preview.example/track.mp3',
                        previewPlaybackUseCase: previewPlaybackUseCase,
                        spotifyPlaybackUseCase: spotifyPlaybackUseCase,
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

      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('sucesso ao carregar prévia', () {
    setUp(() {
      when(
        () => previewPlaybackUseCase.load(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    testWidgets('mostra nome da faixa, artista e o NextCardButton', (
      tester,
    ) async {
      when(
        () => previewPlaybackUseCase.playerStateStream,
      ).thenAnswer((_) => const Stream<PlaybackState>.empty());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Some Track'), findsOneWidget);
      expect(find.text('Some Artist'), findsOneWidget);
      expect(find.byType(NextCardButton), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets(
      'toggle de play/pause chama togglePlayback com o valor correto',
      (tester) async {
        final controller = StreamController<PlaybackState>.broadcast();
        addTearDown(controller.close);

        when(
          () => previewPlaybackUseCase.playerStateStream,
        ).thenAnswer((_) => controller.stream);
        when(
          () => previewPlaybackUseCase.togglePlayback(
            isPaused: any(named: 'isPaused'),
          ),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        verify(
          () => previewPlaybackUseCase.togglePlayback(isPaused: true),
        ).called(1);

        controller.add(const PlaybackState(isPaused: false));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.pause), findsOneWidget);

        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        verify(
          () => previewPlaybackUseCase.togglePlayback(isPaused: false),
        ).called(1);
      },
    );

    testWidgets(
      'botão salvar desabilitado (sem ação) quando trackId é null',
      (tester) async {
        when(
          () => previewPlaybackUseCase.playerStateStream,
        ).thenAnswer((_) => const Stream<PlaybackState>.empty());

        await tester.pumpWidget(buildSubject(trackId: null));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SALVAR NO SPOTIFY'));
        await tester.pump();

        verifyZeroInteractions(spotifyPlaybackUseCase);
      },
    );

    testWidgets('salvar no Spotify com sucesso atualiza para SALVO', (
      tester,
    ) async {
      when(
        () => previewPlaybackUseCase.playerStateStream,
      ).thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(
        () => spotifyPlaybackUseCase.saveTrack(any()),
      ).thenAnswer((_) async => const Right(true));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('SALVAR NO SPOTIFY'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      await tester.tap(find.text('SALVAR NO SPOTIFY'));
      await tester.pumpAndSettle();

      verify(() => spotifyPlaybackUseCase.saveTrack('track123')).called(1);
      expect(find.text('SALVO NO SPOTIFY'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
      'salvar no Spotify retornando false mostra snackbar de falha silenciosa',
      (tester) async {
        when(
          () => previewPlaybackUseCase.playerStateStream,
        ).thenAnswer((_) => const Stream<PlaybackState>.empty());
        when(
          () => spotifyPlaybackUseCase.saveTrack(any()),
        ).thenAnswer((_) async => const Right(false));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('SALVAR NO SPOTIFY'));
        await tester.pumpAndSettle();

        expect(
          find.text('Não foi possível salvar a faixa no Spotify.'),
          findsOneWidget,
        );
        expect(find.text('SALVAR NO SPOTIFY'), findsOneWidget);
      },
    );

    testWidgets(
      'falha de saveTrack (Failure) mostra a mensagem em um snackbar',
      (tester) async {
        when(
          () => previewPlaybackUseCase.playerStateStream,
        ).thenAnswer((_) => const Stream<PlaybackState>.empty());
        when(() => spotifyPlaybackUseCase.saveTrack(any())).thenAnswer(
          (_) async => const Left(
            SpotifyPlaybackNaoAutorizado('Sessão do Spotify expirada.'),
          ),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('SALVAR NO SPOTIFY'));
        await tester.pumpAndSettle();

        expect(find.text('Sessão do Spotify expirada.'), findsOneWidget);
        expect(find.text('SALVAR NO SPOTIFY'), findsOneWidget);
      },
    );

    testWidgets(
      'tocar salvar novamente enquanto já está salvo não chama saveTrack de novo',
      (tester) async {
        when(
          () => previewPlaybackUseCase.playerStateStream,
        ).thenAnswer((_) => const Stream<PlaybackState>.empty());
        when(
          () => spotifyPlaybackUseCase.saveTrack(any()),
        ).thenAnswer((_) async => const Right(true));

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('SALVAR NO SPOTIFY'));
        await tester.pumpAndSettle();

        expect(find.text('SALVO NO SPOTIFY'), findsOneWidget);

        await tester.tap(find.text('SALVO NO SPOTIFY'));
        await tester.pump();

        verify(() => spotifyPlaybackUseCase.saveTrack('track123')).called(1);
      },
    );
  });

  testWidgets('dispose() chama previewPlaybackUseCase.dispose()', (
    tester,
  ) async {
    when(
      () => previewPlaybackUseCase.load(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => previewPlaybackUseCase.playerStateStream,
    ).thenAnswer((_) => const Stream<PlaybackState>.empty());

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    verifyNever(() => previewPlaybackUseCase.dispose());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    verify(() => previewPlaybackUseCase.dispose()).called(1);
  });
}
