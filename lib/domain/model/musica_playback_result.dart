// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

sealed class MusicaPlaybackResult {
  const MusicaPlaybackResult();
}

class FullTrackPlayback extends MusicaPlaybackResult {
  final String spotifyUri;
  const FullTrackPlayback(this.spotifyUri);

  @override
  bool operator ==(Object other) =>
      other is FullTrackPlayback && other.spotifyUri == spotifyUri;

  @override
  int get hashCode => spotifyUri.hashCode;
}

class PreviewPlayback extends MusicaPlaybackResult {
  final String trackId;
  final String previewUrl;
  final String? trackName;
  final String? artistName;
  final String? albumArtUrl;

  const PreviewPlayback({
    required this.trackId,
    required this.previewUrl,
    this.trackName,
    this.artistName,
    this.albumArtUrl,
  });

  @override
  bool operator ==(Object other) =>
      other is PreviewPlayback &&
      other.trackId == trackId &&
      other.previewUrl == previewUrl &&
      other.trackName == trackName &&
      other.artistName == artistName &&
      other.albumArtUrl == albumArtUrl;

  @override
  int get hashCode =>
      Object.hash(trackId, previewUrl, trackName, artistName, albumArtUrl);
}
