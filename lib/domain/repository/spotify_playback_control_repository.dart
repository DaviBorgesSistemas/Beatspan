// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import '../model/playback_state.dart';

abstract class SpotifyPlaybackControlRepository {
  Future<void> playFullTrack(String spotifyUri);

  Stream<PlaybackState> subscribePlayerState();

  Future<void> pause();

  Future<void> resume();

  Future<bool> saveTrack(String trackId);
}
