import 'dart:async';

import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/domain/enum/settings_enum.dart';
import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/musica.dart';
import 'package:beatspan/domain/model/musica_playback_result.dart';
import 'package:beatspan/domain/usecase/get_musica_usecase.dart';
import 'package:beatspan/domain/usecase/musica_playback_usecase.dart';
import 'package:beatspan/presentation/game/game_navigation_event.dart';
import 'package:beatspan/presentation/game/game_viewmodel.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGetMusicaUseCase extends Mock implements GetMusicaUseCase {}

class _MockMusicaPlaybackUseCase extends Mock
    implements MusicaPlaybackUseCase {}

void main() {
  late _MockGetMusicaUseCase getMusicaUseCase;
  late _MockMusicaPlaybackUseCase musicaPlaybackUseCase;
  late AppPreferences appPreferences;
  late GameViewModel viewModel;

  const codigo = '0006';
  const spotifyUri = 'spotify:track:abc123';
  final musica = Musica(id: '1', spotifyId: 'abc123', spotifyUri: spotifyUri);

  setUpAll(() {
    registerFallbackValue(
      const MusicaPlaybackInput(
        spotifyUri: spotifyUri,
        plan: PlanType.free,
        gameMode: GameModeType.preview,
      ),
    );
  });

  setUp(() async {
    getMusicaUseCase = _MockGetMusicaUseCase();
    musicaPlaybackUseCase = _MockMusicaPlaybackUseCase();
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());

    viewModel = GameViewModel(
      appPreferences: appPreferences,
      getMusicaUseCase: getMusicaUseCase,
      musicaPlaybackUseCase: musicaPlaybackUseCase,
    );
  });

  group('extractCodigo', () {
    test('extrai o código de uma URL do domínio principal', () {
      expect(viewModel.extractCodigo('https://beatspangame.com/0006'), '0006');
    });

    test('extrai o código com prefixo www.', () {
      expect(
        viewModel.extractCodigo('https://www.beatspangame.com/0006'),
        '0006',
      );
    });

    test('extrai o código de beatspan.web.app', () {
      expect(viewModel.extractCodigo('https://beatspan.web.app/0006'), '0006');
    });

    test('extrai o código de beatspan.firebaseapp.com', () {
      expect(
        viewModel.extractCodigo('https://beatspan.firebaseapp.com/0006'),
        '0006',
      );
    });

    test('extrai apenas o último segmento de path quando há mais de um', () {
      expect(
        viewModel.extractCodigo('https://beatspangame.com/br/aaaq0001/00006'),
        '00006',
      );
    });

    test('retorna null para host não reconhecido', () {
      expect(viewModel.extractCodigo('https://hitstergame.com/0006'), isNull);
    });

    test('retorna null para scheme não http/https', () {
      expect(viewModel.extractCodigo('spotify:track:0006'), isNull);
    });

    test('retorna null para URL sem path', () {
      expect(viewModel.extractCodigo('https://beatspangame.com'), isNull);
    });

    test('retorna null para URL sem path (apenas barra)', () {
      expect(viewModel.extractCodigo('https://beatspangame.com/'), isNull);
    });

    test('retorna null para string que não é uma URL válida', () {
      expect(viewModel.extractCodigo('não é uma url'), isNull);
    });
  });

  group('validate', () {
    test('retorna beatspanCode para URL válida do domínio', () {
      expect(
        viewModel.validate('https://beatspangame.com/0006'),
        QrValidationResult.beatspanCode,
      );
    });

    test('retorna invalid para URL de outro domínio', () {
      expect(
        viewModel.validate('https://open.spotify.com/track/abc123'),
        QrValidationResult.invalid,
      );
    });

    test('retorna invalid para conteúdo de QR code arbitrário', () {
      expect(
        viewModel.validate('qualquer texto escaneado'),
        QrValidationResult.invalid,
      );
    });
  });

  group('handleDetectedCode', () {
    test('emite NavigateToError genérico para QR fora do domínio', () async {
      await viewModel.handleDetectedCode('https://outro-dominio.com/x');

      expect(viewModel.navigationEvent.value, isA<NavigateToError>());
      final event = viewModel.navigationEvent.value as NavigateToError;
      expect(event.title, isNull);
      verifyZeroInteractions(getMusicaUseCase);
    });

    test(
      'emite NavigateToError "música não encontrada" para failure 404',
      () async {
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => const Left(MusicaNaoEncontrada()));

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        final event = viewModel.navigationEvent.value as NavigateToError;
        expect(event.title, 'MÚSICA NÃO ENCONTRADA');
      },
    );

    test(
      'emite NavigateToError de conexão para outra falha do GetMusicaUseCase',
      () async {
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => Left(MusicaConsultaErro('erro de rede')));

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        final event = viewModel.navigationEvent.value as NavigateToError;
        expect(event.title, 'ERRO DE CONEXÃO');
      },
    );

    test(
      'retorna sem emitir evento quando plano ainda não foi definido',
      () async {
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => Right(musica));

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        expect(viewModel.navigationEvent.value, isNull);
        verifyZeroInteractions(musicaPlaybackUseCase);
      },
    );

    test(
      'emite NavigateToPlayer quando o playback resolve com sucesso',
      () async {
        await appPreferences.setAppPlanType(PlanType.premium);
        await appPreferences.setGameMode(GameModeType.fullTrack);
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => Right(musica));
        const playback = FullTrackPlayback(spotifyUri);
        when(
          () => musicaPlaybackUseCase.execute(any()),
        ).thenAnswer((_) async => const Right(playback));

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        expect(
          viewModel.navigationEvent.value,
          isA<NavigateToPlayer>().having(
            (e) => e.playback,
            'playback',
            playback,
          ),
        );
      },
    );

    test(
      'emite NavigateToError "prévia indisponível" para o código correspondente',
      () async {
        await appPreferences.setAppPlanType(PlanType.free);
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => Right(musica));
        when(() => musicaPlaybackUseCase.execute(any())).thenAnswer(
          (_) async => const Left(MusicaPlaybackPreviaIndisponivel()),
        );

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        final event = viewModel.navigationEvent.value as NavigateToError;
        expect(event.title, 'PRÉVIA INDISPONÍVEL');
      },
    );

    test(
      'emite NavigateToError "Spotify não autorizado" para o código correspondente',
      () async {
        await appPreferences.setAppPlanType(PlanType.premium);
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) async => Right(musica));
        when(() => musicaPlaybackUseCase.execute(any())).thenAnswer(
          (_) async =>
              Left(MusicaPlaybackSpotifyNaoAutorizado('sem autorização')),
        );

        await viewModel.handleDetectedCode('https://beatspangame.com/$codigo');

        final event = viewModel.navigationEvent.value as NavigateToError;
        expect(event.title, 'SPOTIFY NÃO AUTORIZADO');
      },
    );
  });

  group('dispose', () {
    test(
      'não lança FlutterError ao emitir navegação após dispose durante busca ativa',
      () async {
        final completer = Completer<Either<MusicaFailure, Musica>>();
        when(
          () => getMusicaUseCase.execute(codigo),
        ).thenAnswer((_) => completer.future);

        final future = viewModel.handleDetectedCode(
          'https://beatspangame.com/$codigo',
        );

        viewModel.dispose();
        completer.complete(Right(musica));

        await expectLater(future, completes);
      },
    );
  });
}
