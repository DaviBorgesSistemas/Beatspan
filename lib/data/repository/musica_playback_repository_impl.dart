import '../../domain/model/musica_playback_result.dart';
import '../../domain/repository/musica_playback_repository.dart';
import '../network/itunes_search_api.dart';
import '../network/spotify_service.dart';
import '../network/spotify_webapi.dart';

class MusicaPlaybackRepositoryImpl implements MusicaPlaybackRepository {
  final SpotifyService _spotifyService;
  final ItunesSearchApi _itunesSearchApi;

  MusicaPlaybackRepositoryImpl(this._spotifyService, this._itunesSearchApi);

  @override
  Future<PreviewPlayback?> resolvePreview(String trackId) async {
    final token = await _spotifyService.getAccessToken();
    final api = SpotifyWebApi(token);
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
