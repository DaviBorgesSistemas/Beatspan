import 'dart:io';

import 'package:beatspan/data/network/network_exceptions.dart';
import 'package:beatspan/data/network/spotify_webapi.dart';
import 'package:beatspan/domain/exceptions/rate_limited_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('getTrack', () {
    test('retorna SpotifyTrackInfo para resposta 200 válida', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"name":"Nome","artists":[{"name":"Artista"}],'
          '"preview_url":"https://preview","album":{"images":[{"url":"https://art"}]}}',
          200,
        );
      });
      final api = SpotifyWebApi('token', client: client);

      final track = await api.getTrack('abc123');

      expect(track?.name, 'Nome');
      expect(track?.artist, 'Artista');
      expect(track?.previewUrl, 'https://preview');
      expect(track?.albumArtUrl, 'https://art');
    });

    test('retorna null para status 404', () async {
      final client = MockClient((request) async => http.Response('', 404));
      final api = SpotifyWebApi('token', client: client);

      final track = await api.getTrack('abc123');

      expect(track, isNull);
    });

    test('lança InvalidServerResponseException para status de erro', () async {
      final client = MockClient(
        (request) async => http.Response('erro interno', 500),
      );
      final api = SpotifyWebApi('token', client: client);

      expect(
        () => api.getTrack('abc123'),
        throwsA(isA<InvalidServerResponseException>()),
      );
    });

    test('lança InvalidServerResponseException para JSON malformado', () async {
      final client = MockClient(
        (request) async => http.Response('não é json', 200),
      );
      final api = SpotifyWebApi('token', client: client);

      expect(
        () => api.getTrack('abc123'),
        throwsA(isA<InvalidServerResponseException>()),
      );
    });

    test(
      'lança NetworkTimeoutException após esgotar as tentativas de retry',
      () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('', 200);
        });
        final api = SpotifyWebApi(
          'token',
          client: client,
          timeout: const Duration(milliseconds: 20),
          retryBackoff: (_) => Duration.zero,
        );

        await expectLater(
          () => api.getTrack('abc123'),
          throwsA(isA<NetworkTimeoutException>()),
        );
        expect(attempts, 2, reason: 'deve tentar 1 vez + 1 retry');
      },
    );

    test('lança NetworkConnectionException para falha de socket', () async {
      final client = MockClient((request) async {
        throw const SocketException('sem rede');
      });
      final api = SpotifyWebApi('token', client: client);

      expect(
        () => api.getTrack('abc123'),
        throwsA(isA<NetworkConnectionException>()),
      );
    });
  });

  group('saveTrack', () {
    test('retorna true para status 200/204', () async {
      final client = MockClient((request) async => http.Response('', 204));
      final api = SpotifyWebApi('token', client: client);

      expect(await api.saveTrack('abc123'), isTrue);
    });

    test('retorna false para status de erro', () async {
      final client = MockClient((request) async => http.Response('', 403));
      final api = SpotifyWebApi('token', client: client);

      expect(await api.saveTrack('abc123'), isFalse);
    });

    test(
      'lança NetworkTimeoutException após esgotar as tentativas de retry',
      () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('', 200);
        });
        final api = SpotifyWebApi(
          'token',
          client: client,
          timeout: const Duration(milliseconds: 20),
          retryBackoff: (_) => Duration.zero,
        );

        await expectLater(
          () => api.saveTrack('abc123'),
          throwsA(isA<NetworkTimeoutException>()),
        );
        expect(attempts, 2, reason: 'deve tentar 1 vez + 1 retry');
      },
    );
  });

  group('rate limiting (429)', () {
    test(
      'tenta de novo respeitando Retry-After e recupera na 2ª tentativa',
      () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            return http.Response('', 429, headers: {'retry-after': '0'});
          }
          return http.Response('', 204);
        });
        final api = SpotifyWebApi('token', client: client);

        final saved = await api.saveTrack('abc123');

        expect(saved, isTrue);
        expect(attempts, 2);
      },
    );

    test(
      'lança RateLimitedException com o retryAfter do header após esgotar as tentativas',
      () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          return http.Response('', 429, headers: {'retry-after': '0'});
        });
        final api = SpotifyWebApi('token', client: client);

        await expectLater(
          () => api.saveTrack('abc123'),
          throwsA(
            isA<RateLimitedException>().having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 0),
            ),
          ),
        );
        expect(attempts, 2, reason: 'tenta 1 vez + 1 retry antes de desistir');
      },
    );

    test(
      'usa um retryAfter padrão quando o header Retry-After está ausente',
      () async {
        final client = MockClient((request) async => http.Response('', 429));
        final api = SpotifyWebApi('token', client: client);

        await expectLater(
          () => api.saveTrack('abc123'),
          throwsA(
            isA<RateLimitedException>().having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 1),
            ),
          ),
        );
      },
    );

    test(
      'não espera mais que o teto configurado mesmo com Retry-After alto',
      () async {
        var attempts = 0;
        final stopwatch = Stopwatch()..start();
        final client = MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            return http.Response('', 429, headers: {'retry-after': '999'});
          }
          return http.Response('', 204);
        });
        final api = SpotifyWebApi(
          'token',
          client: client,
          maxRateLimitWait: const Duration(milliseconds: 50),
        );

        final saved = await api.saveTrack('abc123');
        stopwatch.stop();

        expect(saved, isTrue);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      },
    );
  });
}
