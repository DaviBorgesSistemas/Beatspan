// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import '../model/playback_state.dart';

abstract class PreviewPlaybackControlRepository {
  Future<void> load(String previewUrl);

  Stream<PlaybackState> get playerStateStream;

  Future<void> play();

  Future<void> pause();

  Future<void> dispose();
}
