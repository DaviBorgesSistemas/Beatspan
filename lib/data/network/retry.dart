import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Reexecuta [action] até [maxAttempts] vezes (1 tentativa original + retries)
/// quando [shouldRetry] considera o erro transitório, aguardando um backoff
/// entre tentativas. Sem retry para erros não classificados como transitórios
/// (ex.: resposta de erro do servidor, dado malformado) — só timeout/conexão.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 2,
  required bool Function(Object error) shouldRetry,
  Duration Function(int attempt) backoff = defaultRetryBackoff,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts || !shouldRetry(e)) rethrow;
      await Future.delayed(backoff(attempt));
    }
  }
}

Duration defaultRetryBackoff(int attempt) {
  return Duration(milliseconds: 300 * attempt);
}

/// Timeout ou conexão caída — transitório, vale tentar de novo. Erros de
/// resposta (status HTTP, JSON malformado) não são cobertos: repeti-los não
/// muda o resultado.
bool isTransientHttpError(Object error) {
  return error is TimeoutException ||
      error is SocketException ||
      error is http.ClientException;
}
