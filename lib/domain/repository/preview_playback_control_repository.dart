import '../model/playback_state.dart';

abstract class PreviewPlaybackControlRepository {
  Future<void> load(String previewUrl);

  Stream<PlaybackState> get playerStateStream;

  Future<void> play();

  Future<void> pause();

  Future<void> dispose();
}
