// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class RateLimitedException implements Exception {
  final String endpoint;
  final Duration retryAfter;

  const RateLimitedException(this.endpoint, this.retryAfter);

  @override
  String toString() =>
      'Limite de requisições excedido em "$endpoint" (retry after: '
      '${retryAfter.inSeconds}s).';
}
