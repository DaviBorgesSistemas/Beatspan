import '../model/playback_state.dart';

abstract class SpotifyPlaybackControlRepository {
  Future<void> playFullTrack(String spotifyUri);

  Stream<PlaybackState> subscribePlayerState();

  Future<void> pause();

  Future<void> resume();

  Future<bool> saveTrack(String trackId);
}
