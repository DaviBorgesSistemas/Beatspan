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
