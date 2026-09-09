enum QrValidationResult { invalid, beatspanCode }

class GameViewModel {
  static const List<String> _beatspanHosts = [
    'beatspangame.com',
    'beatspan.web.app',
    'beatspan.firebaseapp.com',
  ];

  QrValidationResult validate(String rawValue) {
    final isBeatspanLink = extractCodigo(rawValue) != null;
    if (!isBeatspanLink) {
      return QrValidationResult.invalid;
    }
    return QrValidationResult.beatspanCode;
  }

  String? extractCodigo(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
    if (!_beatspanHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final codigo = segments.last;
    return codigo.isEmpty ? null : codigo;
  }
}
