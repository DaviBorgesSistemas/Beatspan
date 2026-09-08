/// Erro de domínio lançado quando o código lido no QR não existe
/// na coleção `musicas` do Firestore.
class MusicaNaoEncontradaException implements Exception {
  final String codigo;
  MusicaNaoEncontradaException(this.codigo);

  @override
  String toString() => 'Música não encontrada para o código "$codigo".';
}

/// Erro de domínio lançado quando não foi possível consultar o Firestore
/// (sem internet, serviço indisponível, timeout, etc).
class MusicaConsultaException implements Exception {
  final String message;
  final Object? cause;
  MusicaConsultaException(this.message, {this.cause});

  @override
  String toString() => 'Erro ao consultar música: $message';
}
