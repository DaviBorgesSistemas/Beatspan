// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

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
