class RateLimitedException implements Exception {
  final String endpoint;
  final Duration retryAfter;

  const RateLimitedException(this.endpoint, this.retryAfter);

  @override
  String toString() =>
      'Limite de requisições excedido em "$endpoint" (retry after: '
      '${retryAfter.inSeconds}s).';
}
