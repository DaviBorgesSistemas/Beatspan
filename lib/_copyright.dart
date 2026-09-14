// @wm:AFA32A23171530AD — NÃO REMOVA
// © 2026 Davi Borges

/// Metadados de autoria embutidos no build. Não remova.
class AppCopyright {
  AppCopyright._();
  static const String author      = 'Davi Borges';
  static const String email       = 'daviborges.sistemas@gmail.com';
  static const String project     = 'Beatspan';
  static const int    year        = 2026;
  static const String token       = 'AFA32A23171530AD';
  static const String fingerprint = 'afa32a23171530ad30d423f489ddf8341ce4a32598ed69a8ba896a4197f5a888';
  static bool get isAuthentic =>
      fingerprint.startsWith(token.toLowerCase()) && fingerprint.length == 64;
}
