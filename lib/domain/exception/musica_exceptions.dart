class MusicaNaoEncontradaException implements Exception {
  final String codigo;
  MusicaNaoEncontradaException(this.codigo);

  @override
  String toString() => 'Música não encontrada para o código "$codigo".';
}

class MusicaConsultaException implements Exception {
  final String message;
  final Object? cause;
  MusicaConsultaException(this.message, {this.cause});

  @override
  String toString() => 'Erro ao consultar música: $message';
}
