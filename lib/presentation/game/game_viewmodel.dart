enum QrValidationResult { invalid, beatspanCode }

class GameViewModel {
  static const String _beatspanHost = 'beatspangame.com';

  QrValidationResult validate(String rawValue) {
    final isBeatspanLink = extractCodigo(rawValue) != null;
    if (!isBeatspanLink) {
      return QrValidationResult.invalid;
    }
    return QrValidationResult.beatspanCode;
  }

  /// Aceita links do domínio próprio, com ou sem "www.", ex:
  /// `https://www.beatspangame.com/0006`
  /// `https://beatspangame.com/0006`
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
    if (host != _beatspanHost) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final codigo = segments.last;
    return codigo.isEmpty ? null : codigo;
  }
}
