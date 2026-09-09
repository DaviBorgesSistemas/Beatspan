import 'package:beatspan/data/network/itunes_search_api.dart';
import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/data/network/spotify_webapi.dart';
import 'package:beatspan/data/repository/musica_playback_repository_impl.dart';
import 'package:beatspan/domain/model/musica_playback_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpotifyService extends Mock implements SpotifyService {}

class _MockItunesSearchApi extends Mock implements ItunesSearchApi {}

class _MockSpotifyWebApi extends Mock implements SpotifyWebApi {}

void main() {
  late _MockSpotifyService spotifyService;
  late _MockItunesSearchApi itunesSearchApi;
  late _MockSpotifyWebApi spotifyWebApi;
  late MusicaPlaybackRepositoryImpl repository;

  const trackId = 'abc123';
  const accessToken = 'token-123';

  setUp(() {
    spotifyService = _MockSpotifyService();
    itunesSearchApi = _MockItunesSearchApi();
    spotifyWebApi = _MockSpotifyWebApi();

    when(() => spotifyService.getAccessToken()).thenAnswer(
      (_) async => accessToken,
    );

    repository = MusicaPlaybackRepositoryImpl(
      spotifyService,
      itunesSearchApi,
      spotifyWebApiFactory: (_) => spotifyWebApi,
    );
  });

  test(
    'retorna PreviewPlayback usando os dados do Spotify quando já tem preview',
    () async {
      when(() => spotifyWebApi.getTrack(trackId)).thenAnswer(
        (_) async => const SpotifyTrackInfo(
          name: 'Nome',
          artist: 'Artista',
          previewUrl: 'https://spotify-preview',
          albumArtUrl: 'https://album-art',
        ),
      );

      final result = await repository.resolvePreview(trackId);

      expect(result, isA<PreviewPlayback>());
      expect(result!.previewUrl, 'https://spotify-preview');
      expect(result.trackName, 'Nome');
      expect(result.artistName, 'Artista');
      expect(result.albumArtUrl, 'https://album-art');
      verifyNever(() => itunesSearchApi.searchTrack(trackName: any(named: 'trackName')));
    },
  );

  test(
    'cai para o fallback do iTunes quando o Spotify não tem preview',
    () async {
      when(() => spotifyWebApi.getTrack(trackId)).thenAnswer(
        (_) async => const SpotifyTrackInfo(
          name: 'Nome',
          artist: 'Artista',
          previewUrl: null,
          albumArtUrl: null,
        ),
      );
      when(
        () => itunesSearchApi.searchTrack(
          trackName: 'Nome',
          artist: 'Artista',
        ),
      ).thenAnswer(
        (_) async => const ItunesTrackInfo(
          previewUrl: 'https://itunes-preview',
          artworkUrl: 'https://itunes-art',
        ),
      );

      final result = await repository.resolvePreview(trackId);

      expect(result, isA<PreviewPlayback>());
      expect(result!.previewUrl, 'https://itunes-preview');
      expect(result.albumArtUrl, 'https://itunes-art');
    },
  );

  test(
    'retorna null quando nem Spotify nem iTunes têm preview disponível',
    () async {
      when(() => spotifyWebApi.getTrack(trackId)).thenAnswer(
        (_) async => const SpotifyTrackInfo(
          name: 'Nome',
          artist: 'Artista',
          previewUrl: null,
          albumArtUrl: null,
        ),
      );
      when(
        () => itunesSearchApi.searchTrack(
          trackName: 'Nome',
          artist: 'Artista',
        ),
      ).thenAnswer((_) async => null);

      final result = await repository.resolvePreview(trackId);

      expect(result, isNull);
    },
  );

  test('retorna null quando o Spotify não encontra a faixa', () async {
    when(() => spotifyWebApi.getTrack(trackId)).thenAnswer((_) async => null);

    final result = await repository.resolvePreview(trackId);

    expect(result, isNull);
    verifyNever(() => itunesSearchApi.searchTrack(trackName: any(named: 'trackName')));
  });

  test(
    'reusa o resultado em cache na segunda chamada para o mesmo trackId, sem rechamar as APIs',
    () async {
      when(() => spotifyWebApi.getTrack(trackId)).thenAnswer(
        (_) async => const SpotifyTrackInfo(
          name: 'Nome',
          artist: 'Artista',
          previewUrl: 'https://spotify-preview',
          albumArtUrl: 'https://album-art',
        ),
      );

      final first = await repository.resolvePreview(trackId);
      final second = await repository.resolvePreview(trackId);

      expect(second, equals(first));
      verify(() => spotifyService.getAccessToken()).called(1);
      verify(() => spotifyWebApi.getTrack(trackId)).called(1);
    },
  );

  test(
    'também cacheia um resultado null (faixa sem preview disponível)',
    () async {
      when(() => spotifyWebApi.getTrack(trackId)).thenAnswer((_) async => null);

      final first = await repository.resolvePreview(trackId);
      final second = await repository.resolvePreview(trackId);

      expect(first, isNull);
      expect(second, isNull);
      verify(() => spotifyWebApi.getTrack(trackId)).called(1);
    },
  );
}
