import 'dart:async';
import 'dart:io';

import 'package:beatspan/data/network/retry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('withRetry', () {
    test(
      'retorna o resultado da primeira tentativa quando ela têm sucesso',
      () async {
        var attempts = 0;

        final result = await withRetry(() async {
          attempts++;
          return 'ok';
        }, shouldRetry: (_) => true);

        expect(result, 'ok');
        expect(attempts, 1);
      },
    );

    test(
      'tenta de novo quando shouldRetry retorna true e depois têm sucesso',
      () async {
        var attempts = 0;

        final result = await withRetry(
          () async {
            attempts++;
            if (attempts == 1) throw Exception('transitório');
            return 'ok';
          },
          shouldRetry: (_) => true,
          backoff: (_) => Duration.zero,
        );

        expect(result, 'ok');
        expect(attempts, 2);
      },
    );

    test('propaga o erro sem retry quando shouldRetry retorna false', () async {
      var attempts = 0;

      await expectLater(
        () => withRetry(() async {
          attempts++;
          throw Exception('não transitório');
        }, shouldRetry: (_) => false),
        throwsA(isException),
      );
      expect(attempts, 1);
    });

    test(
      'propaga o erro após esgotar maxAttempts mesmo quando shouldRetry retorna true',
      () async {
        var attempts = 0;

        await expectLater(
          () => withRetry(
            () async {
              attempts++;
              throw Exception('sempre falha');
            },
            shouldRetry: (_) => true,
            backoff: (_) => Duration.zero,
          ),
          throwsA(isException),
        );
        expect(attempts, 2, reason: 'maxAttempts padrão é 2');
      },
    );

    test('respeita maxAttempts customizado', () async {
      var attempts = 0;

      await expectLater(
        () => withRetry(
          () async {
            attempts++;
            throw Exception('sempre falha');
          },
          maxAttempts: 4,
          shouldRetry: (_) => true,
          backoff: (_) => Duration.zero,
        ),
        throwsA(isException),
      );
      expect(attempts, 4);
    });

    test('aguarda o backoff informado entre tentativas', () async {
      final delays = <Duration>[];

      await expectLater(
        () => withRetry(
          () async {
            throw Exception('sempre falha');
          },
          maxAttempts: 3,
          shouldRetry: (_) => true,
          backoff: (attempt) {
            final d = Duration(milliseconds: attempt);
            delays.add(d);
            return d;
          },
        ),
        throwsA(isException),
      );

      expect(delays, [Duration(milliseconds: 1), Duration(milliseconds: 2)]);
    });
  });

  group('isTransientHttpError', () {
    test('considera TimeoutException transitório', () {
      expect(isTransientHttpError(TimeoutException('x')), isTrue);
    });

    test('considera SocketException transitório', () {
      expect(isTransientHttpError(const SocketException('x')), isTrue);
    });

    test('considera http.ClientException transitório', () {
      expect(isTransientHttpError(http.ClientException('x')), isTrue);
    });

    test('não considera erro genérico transitório', () {
      expect(isTransientHttpError(Exception('genérico')), isFalse);
    });
  });
}
