// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class PlaybackNetworkException implements Exception {
  final String message;
  const PlaybackNetworkException(this.message);

  @override
  String toString() => message;
}

class PlaybackAuthException implements Exception {
  final String message;
  const PlaybackAuthException(this.message);

  @override
  String toString() => message;
}
