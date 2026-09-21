// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class SpotifyConsentRequiredException implements Exception {
  const SpotifyConsentRequiredException();

  @override
  String toString() =>
      'Consentimento do Spotify ainda não foi aceito pelo usuário.';
}
