import 'dart:io';

import 'package:beatspan/data/network/network_exceptions.dart';
import 'package:beatspan/data/network/spotify_webapi.dart';
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

    test('lança NetworkTimeoutException quando a chamada expira', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 11));
        return http.Response('', 200);
      });
      final api = SpotifyWebApi('token', client: client);

      expect(
        () => api.getTrack('abc123'),
        throwsA(isA<NetworkTimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

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

    test('lança NetworkTimeoutException quando a chamada expira', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 11));
        return http.Response('', 200);
      });
      final api = SpotifyWebApi('token', client: client);

      expect(
        () => api.saveTrack('abc123'),
        throwsA(isA<NetworkTimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
