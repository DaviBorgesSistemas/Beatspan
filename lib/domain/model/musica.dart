// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class Musica {
  final String id;
  final String spotifyId;
  final String spotifyUri;

  Musica({required this.id, required this.spotifyId, required this.spotifyUri});

  factory Musica.fromMap(String id, Map<String, dynamic> map) {
    return Musica(
      id: id,
      spotifyId: map['spotify_id'] as String? ?? '',
      spotifyUri: map['spotify_uri'] as String? ?? '',
    );
  }
}
