class NetworkTimeoutException implements Exception {
  final String endpoint;
  NetworkTimeoutException(this.endpoint);

  @override
  String toString() => 'Tempo esgotado ao chamar "$endpoint".';
}

class NetworkConnectionException implements Exception {
  final String endpoint;
  final Object? cause;
  NetworkConnectionException(this.endpoint, {this.cause});

  @override
  String toString() => 'Falha de conexão ao chamar "$endpoint": $cause';
}

class InvalidServerResponseException implements Exception {
  final String endpoint;
  final int? statusCode;
  final String message;
  InvalidServerResponseException(
    this.endpoint,
    this.message, {
    this.statusCode,
  });

  @override
  String toString() =>
      'Resposta inválida de "$endpoint" (status: $statusCode): $message';
}
