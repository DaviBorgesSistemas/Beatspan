import 'package:beatspan/domain/exceptions/rate_limited_exception.dart';
import 'package:beatspan/domain/exceptions/spotify_consent_exception.dart';
import 'package:beatspan/domain/model/playback_state.dart';
import 'package:beatspan/domain/repository/spotify_playback_control_repository.dart';
import 'package:beatspan/domain/usecase/spotify_playback_usecase.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotifyPlaybackControlRepository extends Mock
    implements SpotifyPlaybackControlRepository {}

void main() {
  late _MockSpotifyPlaybackControlRepository repository;
  late SpotifyPlaybackUseCase useCase;

  const spotifyUri = 'spotify:track:abc123';
  const trackId = 'abc123';

  setUp(() {
    repository = _MockSpotifyPlaybackControlRepository();
    useCase = SpotifyPlaybackUseCase(repository);
  });

  group('startPlayback', () {
    test('retorna sucesso quando o repository toca a faixa', () async {
      when(() => repository.playFullTrack(spotifyUri)).thenAnswer((_) async {});

      final result = await useCase.startPlayback(spotifyUri);

      expect(result, const Right(unit));
    });

    test(
      'converte SpotifyConsentRequiredException em falha de autorização',
      () async {
        when(
          () => repository.playFullTrack(spotifyUri),
        ).thenThrow(const SpotifyConsentRequiredException());

        final result = await useCase.startPlayback(spotifyUri);

        expect(
          result,
          isA<Left>().having(
            (l) => l.value.code,
            'code',
            spotifyPlaybackAuthErrorCode,
          ),
        );
      },
    );

    test(
      'converte MissingPluginException em falha de plugin ausente',
      () async {
        when(
          () => repository.playFullTrack(spotifyUri),
        ).thenThrow(MissingPluginException());

        final result = await useCase.startPlayback(spotifyUri);

        expect(
          result,
          isA<Left>().having(
            (l) => l.value.code,
            'code',
            spotifyPlaybackPluginMissingErrorCode,
          ),
        );
      },
    );

    test('converte PlatformException em falha de autorização', () async {
      when(
        () => repository.playFullTrack(spotifyUri),
      ).thenThrow(PlatformException(code: 'UserNotAuthorizedException'));

      final result = await useCase.startPlayback(spotifyUri);

      expect(
        result,
        isA<Left>().having(
          (l) => l.value.code,
          'code',
          spotifyPlaybackAuthErrorCode,
        ),
      );
    });

    test('converte erro não classificado em falha inesperada', () async {
      when(
        () => repository.playFullTrack(spotifyUri),
      ).thenThrow(Exception('boom'));

      final result = await useCase.startPlayback(spotifyUri);

      expect(
        result,
        isA<Left>().having(
          (l) => l.value.code,
          'code',
          spotifyPlaybackUnexpectedErrorCode,
        ),
      );
    });
  });

  group('togglePlayback', () {
    test('chama resume quando estava pausado', () async {
      when(() => repository.resume()).thenAnswer((_) async {});

      await useCase.togglePlayback(isPaused: true);

      verify(() => repository.resume()).called(1);
      verifyNever(() => repository.pause());
    });

    test('chama pause quando estava tocando', () async {
      when(() => repository.pause()).thenAnswer((_) async {});

      await useCase.togglePlayback(isPaused: false);

      verify(() => repository.pause()).called(1);
      verifyNever(() => repository.resume());
    });
  });

  test('pause() nunca propaga exceção do repository', () async {
    when(() => repository.pause()).thenThrow(Exception('falha ao pausar'));

    await expectLater(useCase.pause(), completes);
  });

  test('subscribePlayerState delega ao repository', () {
    final stream = Stream<PlaybackState>.fromIterable([
      const PlaybackState(isPaused: false),
    ]);
    when(() => repository.subscribePlayerState()).thenAnswer((_) => stream);

    expect(useCase.subscribePlayerState(), same(stream));
  });

  group('saveTrack', () {
    test('retorna o resultado do repository em caso de sucesso', () async {
      when(() => repository.saveTrack(trackId)).thenAnswer((_) async => true);

      final result = await useCase.saveTrack(trackId);

      expect(result, const Right(true));
    });

    test(
      'converte SpotifyConsentRequiredException em falha de autorização',
      () async {
        when(
          () => repository.saveTrack(trackId),
        ).thenThrow(const SpotifyConsentRequiredException());

        final result = await useCase.saveTrack(trackId);

        expect(
          result,
          isA<Left>().having(
            (l) => l.value.code,
            'code',
            spotifyPlaybackAuthErrorCode,
          ),
        );
      },
    );

    test('converte erro não classificado em falha inesperada', () async {
      when(() => repository.saveTrack(trackId)).thenThrow(Exception('boom'));

      final result = await useCase.saveTrack(trackId);

      expect(
        result,
        isA<Left>().having(
          (l) => l.value.code,
          'code',
          spotifyPlaybackUnexpectedErrorCode,
        ),
      );
    });

    test(
      'converte RateLimitedException em falha de rate limit com o retryAfter na mensagem',
      () async {
        when(() => repository.saveTrack(trackId)).thenThrow(
          const RateLimitedException('PUT /v1/me/tracks', Duration(seconds: 3)),
        );

        final result = await useCase.saveTrack(trackId);

        expect(
          result,
          isA<Left>()
              .having(
                (l) => l.value.code,
                'code',
                spotifyPlaybackRateLimitedErrorCode,
              )
              .having((l) => l.value.message, 'message', contains('3s')),
        );
      },
    );
  });
}
