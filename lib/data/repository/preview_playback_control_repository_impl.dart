import 'package:just_audio/just_audio.dart';

import '../../domain/model/playback_state.dart';
import '../../domain/repository/preview_playback_control_repository.dart';

class PreviewPlaybackControlRepositoryImpl
    implements PreviewPlaybackControlRepository {
  final AudioPlayer _player;

  PreviewPlaybackControlRepositoryImpl({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  @override
  Future<void> load(String previewUrl) async {
    await _player.setUrl(previewUrl);
    await _player.play();
  }

  @override
  Stream<PlaybackState> get playerStateStream => _player.playerStateStream.map(
    (state) => PlaybackState(isPaused: !state.playing),
  );

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}
