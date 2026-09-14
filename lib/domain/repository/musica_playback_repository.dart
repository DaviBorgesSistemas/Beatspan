// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import '../model/musica_playback_result.dart';

abstract class MusicaPlaybackRepository {
  Future<PreviewPlayback?> resolvePreview(String trackId);
}
