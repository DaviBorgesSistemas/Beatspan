const String jsonPath = 'assets/json';

/// Caminhos de arquivos JSON locais consumidos por data sources
/// (ex.: `FaqLocalDataSource`). Pertence à camada de dados — não deve
/// ser referenciado a partir de `presentation/`.
class JsonAssets {
  static const String faqs = '$jsonPath/faq.json';
}
