import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/data/network/spotify_webapi.dart';
import 'package:beatspan/data/repository/spotify_playback_control_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotifyService extends Mock implements SpotifyService {}

class _MockSpotifyWebApi extends Mock implements SpotifyWebApi {}

void main() {
  late _MockSpotifyService spotifyService;
  late _MockSpotifyWebApi spotifyWebApi;
  late SpotifyPlaybackControlRepositoryImpl repository;

  const trackId = 'abc123';
  const accessToken = 'token-123';

  setUp(() {
    spotifyService = _MockSpotifyService();
    spotifyWebApi = _MockSpotifyWebApi();

    when(
      () => spotifyService.getAccessToken(),
    ).thenAnswer((_) async => accessToken);

    repository = SpotifyPlaybackControlRepositoryImpl(
      spotifyService,
      spotifyWebApiFactory: (_) => spotifyWebApi,
    );
  });

  group('saveTrack', () {
    test('obtém o token e delega ao SpotifyWebApi', () async {
      when(
        () => spotifyWebApi.saveTrack(trackId),
      ).thenAnswer((_) async => true);

      final result = await repository.saveTrack(trackId);

      expect(result, isTrue);
      verify(() => spotifyService.getAccessToken()).called(1);
      verify(() => spotifyWebApi.saveTrack(trackId)).called(1);
    });

    test('propaga false quando o SpotifyWebApi não conseguiu salvar', () async {
      when(
        () => spotifyWebApi.saveTrack(trackId),
      ).thenAnswer((_) async => false);

      final result = await repository.saveTrack(trackId);

      expect(result, isFalse);
    });

    test('propaga exceção de getAccessToken sem chamar a Web API', () async {
      when(
        () => spotifyService.getAccessToken(),
      ).thenThrow(Exception('sem consentimento'));

      await expectLater(
        () => repository.saveTrack(trackId),
        throwsA(isException),
      );
      verifyNever(() => spotifyWebApi.saveTrack(any()));
    });
  });
}
