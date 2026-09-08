enum QrValidationResult { invalid, beatspanCode }

class GameViewModel {
  /// Domínios aceitos como links de carta do BEATSPAN. `beatspangame.com`
  /// é o domínio definitivo (impresso nas cartas); `beatspan.web.app` é
  /// a URL padrão do Firebase Hosting, usada enquanto o domínio próprio
  /// não está configurado.
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

  /// Aceita links de qualquer domínio reconhecido do BEATSPAN, com ou
  /// sem "www.", ex:
  /// `https://www.beatspangame.com/0006`
  /// `https://beatspangame.com/0006`
  /// `https://beatspan.web.app/0006`
  ///
  /// Retorna o código curto (ex: "0006") ou `null` se a URL não for
  /// reconhecida como um link válido do BEATSPAN.
  String? extractCodigo(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.startsWith('www.')
        ? uri.host.substring(4)
        : uri.host;
    if (!_beatspanHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final codigo = segments.last;
    return codigo.isEmpty ? null : codigo;
  }
}
