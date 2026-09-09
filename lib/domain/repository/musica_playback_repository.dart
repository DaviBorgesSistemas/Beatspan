import '../model/musica_playback_result.dart';

abstract class MusicaPlaybackRepository {
  Future<PreviewPlayback?> resolvePreview(String trackId);
}
