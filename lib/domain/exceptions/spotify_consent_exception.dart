class SpotifyConsentRequiredException implements Exception {
  const SpotifyConsentRequiredException();

  @override
  String toString() =>
      'Consentimento do Spotify ainda não foi aceito pelo usuário.';
}
