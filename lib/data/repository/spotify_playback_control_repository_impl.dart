import 'package:spotify_sdk/spotify_sdk.dart';

import '../../domain/model/playback_state.dart';
import '../../domain/repository/spotify_playback_control_repository.dart';
import '../network/spotify_service.dart';
import '../network/spotify_webapi.dart';

typedef SpotifyWebApiFactory = SpotifyWebApi Function(String accessToken);

class SpotifyPlaybackControlRepositoryImpl
    implements SpotifyPlaybackControlRepository {
  final SpotifyService _spotifyService;
  final SpotifyWebApiFactory _spotifyWebApiFactory;

  SpotifyPlaybackControlRepositoryImpl(
    this._spotifyService, {
    SpotifyWebApiFactory spotifyWebApiFactory = SpotifyWebApi.new,
  }) : _spotifyWebApiFactory = spotifyWebApiFactory;

  @override
  Future<void> playFullTrack(String spotifyUri) async {
    await _spotifyService.authorizeAndConnect();
    await SpotifySdk.play(spotifyUri: spotifyUri);
  }

  @override
  Stream<PlaybackState> subscribePlayerState() {
    return SpotifySdk.subscribePlayerState().map(
      (state) => PlaybackState(isPaused: state.isPaused),
    );
  }

  @override
  Future<void> pause() => SpotifySdk.pause();

  @override
  Future<void> resume() => SpotifySdk.resume();

  @override
  Future<bool> saveTrack(String trackId) async {
    final token = await _spotifyService.getAccessToken();
    final api = _spotifyWebApiFactory(token);
    return api.saveTrack(trackId);
  }
}
