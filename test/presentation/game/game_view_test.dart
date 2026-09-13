import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/domain/model/musica_playback_result.dart';
import 'package:beatspan/domain/model/playback_state.dart';
import 'package:beatspan/domain/usecase/get_musica_usecase.dart';
import 'package:beatspan/domain/usecase/musica_playback_usecase.dart';
import 'package:beatspan/domain/usecase/preview_playback_usecase.dart';
import 'package:beatspan/domain/usecase/spotify_playback_usecase.dart';
import 'package:beatspan/presentation/game/game_error_view.dart';
import 'package:beatspan/presentation/game/game_navigation_event.dart';
import 'package:beatspan/presentation/game/game_view.dart';
import 'package:beatspan/presentation/game/game_viewmodel.dart';
import 'package:beatspan/presentation/game/player_music/play_music_free_view.dart';
import 'package:beatspan/presentation/game/player_music/player_music_premium_view.dart';
import 'package:beatspan/presentation/game/turn_phone_ready_view.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGetMusicaUseCase extends Mock implements GetMusicaUseCase {}

class _MockMusicaPlaybackUseCase extends Mock
    implements MusicaPlaybackUseCase {}

class _MockSpotifyPlaybackUseCase extends Mock
    implements SpotifyPlaybackUseCase {}

class _MockPreviewPlaybackUseCase extends Mock
    implements PreviewPlaybackUseCase {}

void main() {
  late AppPreferences appPreferences;
  late GameViewModel viewModel;
  late _MockSpotifyPlaybackUseCase spotifyPlaybackUseCase;
  late _MockMusicaPlaybackUseCase musicaPlaybackUseCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());
    musicaPlaybackUseCase = _MockMusicaPlaybackUseCase();
    viewModel = GameViewModel(
      appPreferences: appPreferences,
      getMusicaUseCase: _MockGetMusicaUseCase(),
      musicaPlaybackUseCase: musicaPlaybackUseCase,
    );
    spotifyPlaybackUseCase = _MockSpotifyPlaybackUseCase();
    when(() => spotifyPlaybackUseCase.pause()).thenAnswer((_) async {});
  });

  PreviewPlaybackUseCase buildPreviewPlaybackUseCase() {
    final mock = _MockPreviewPlaybackUseCase();
    when(() => mock.load(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => mock.playerStateStream,
    ).thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => mock.dispose()).thenAnswer((_) async {});
    return mock;
  }

  Widget buildSubject() {
    return MaterialApp(
      home: GameView(
        appPreferences: appPreferences,
        viewModel: viewModel,
        spotifyPlaybackUseCase: spotifyPlaybackUseCase,
        musicaPlaybackUseCase: musicaPlaybackUseCase,
        previewPlaybackUseCaseFactory: buildPreviewPlaybackUseCase,
      ),
    );
  }

  testWidgets('monta sem lançar exceção', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(GameView), findsOneWidget);
  });

  testWidgets(
    'ignora BarcodeCapture sem barcodes detectados sem lançar exceção '
    '(ARQ-003)',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect!(const BarcodeCapture());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(GameView), findsOneWidget);
    },
  );

  testWidgets(
    'navega para GameErrorView quando o ViewModel emite NavigateToError',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      viewModel.navigationEvent.value = const NavigateToError(
        title: 'ERRO DE CONEXÃO',
        message: 'sem internet',
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('ERRO DE CONEXÃO'), findsOneWidget);
      expect(find.text('sem internet'), findsOneWidget);
    },
  );

  testWidgets(
    'reseta o navigationEvent do ViewModel para null depois de consumir',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      viewModel.navigationEvent.value = const NavigateToError();
      await tester.pumpAndSettle();

      expect(viewModel.navigationEvent.value, isNull);
    },
  );

  testWidgets(
    'navega para PlayerMusicPremiumView quando o evento é FullTrackPlayback e vira o telefone está desativado',
    (tester) async {
      await appPreferences.setTurnPhoneEnabled(false);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      viewModel.navigationEvent.value = const NavigateToPlayer(
        FullTrackPlayback('spotify:track:abc123'),
      );
      // Não usa pumpAndSettle: PlayerMusicPremiumView tem animações em loop
      // (AnimationController.repeat()) que nunca "assentam" sozinhas.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlayerMusicPremiumView), findsOneWidget);
    },
  );

  testWidgets(
    'navega para PlayerMusicFreeView quando o evento é PreviewPlayback',
    (tester) async {
      await appPreferences.setTurnPhoneEnabled(false);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      viewModel.navigationEvent.value = const NavigateToPlayer(
        PreviewPlayback(
          trackId: 'abc123',
          previewUrl: 'https://preview.example/track.mp3',
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlayerMusicFreeView), findsOneWidget);
    },
  );

  testWidgets(
    'interpõe TurnPhoneReadyView quando vira o telefone está ativado',
    (tester) async {
      await appPreferences.setTurnPhoneEnabled(true);
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      viewModel.navigationEvent.value = const NavigateToPlayer(
        FullTrackPlayback('spotify:track:abc123'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TurnPhoneReadyView), findsOneWidget);
      expect(find.byType(PlayerMusicPremiumView), findsNothing);
    },
  );
}
