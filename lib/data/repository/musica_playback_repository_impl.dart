import '../../domain/model/musica_playback_result.dart';
import '../../domain/repository/musica_playback_repository.dart';
import '../network/itunes_search_api.dart';
import '../network/spotify_service.dart';
import '../network/spotify_webapi.dart';

typedef SpotifyWebApiFactory = SpotifyWebApi Function(String accessToken);

class MusicaPlaybackRepositoryImpl implements MusicaPlaybackRepository {
  final SpotifyService _spotifyService;
  final ItunesSearchApi _itunesSearchApi;
  final SpotifyWebApiFactory _spotifyWebApiFactory;

  // Cache em memória por trackId: a mesma carta escaneada de novo na mesma
  // sessão do app reaproveita a resolução anterior em vez de rechamar
  // Spotify/iTunes. Sem TTL — o resultado não muda durante a sessão.
  final Map<String, PreviewPlayback?> _previewCache = {};

  MusicaPlaybackRepositoryImpl(
    this._spotifyService,
    this._itunesSearchApi, {
    SpotifyWebApiFactory spotifyWebApiFactory = SpotifyWebApi.new,
  }) : _spotifyWebApiFactory = spotifyWebApiFactory;

  @override
  Future<PreviewPlayback?> resolvePreview(String trackId) async {
    if (_previewCache.containsKey(trackId)) {
      return _previewCache[trackId];
    }

    final result = await _fetchPreview(trackId);
    _previewCache[trackId] = result;
    return result;
  }

  Future<PreviewPlayback?> _fetchPreview(String trackId) async {
    final token = await _spotifyService.getAccessToken();
    final api = _spotifyWebApiFactory(token);
    final track = await api.getTrack(trackId);

    String? previewUrl = track?.previewUrl;
    String? albumArtUrl = track?.albumArtUrl;
    final trackName = track?.name;
    final artistName = track?.artist;

    if (previewUrl == null && trackName != null) {
      final itunesTrack = await _itunesSearchApi.searchTrack(
        trackName: trackName,
        artist: artistName,
      );
      previewUrl = itunesTrack?.previewUrl;
      albumArtUrl ??= itunesTrack?.artworkUrl;
    }

    if (previewUrl == null) return null;

    return PreviewPlayback(
      trackId: trackId,
      previewUrl: previewUrl,
      trackName: trackName,
      artistName: artistName,
      albumArtUrl: albumArtUrl,
    );
  }
}
