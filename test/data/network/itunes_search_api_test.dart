import 'dart:io';

import 'package:beatspan/data/network/itunes_search_api.dart';
import 'package:beatspan/data/network/network_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('searchTrack', () {
    test('retorna ItunesTrackInfo para resposta 200 válida', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"results":[{"trackName":"Nome","artistName":"Artista",'
          '"previewUrl":"https://preview","artworkUrl100":"https://art/100x100bb.jpg"}]}',
          200,
        );
      });
      final api = ItunesSearchApi(client: client);

      final track = await api.searchTrack(trackName: 'Nome', artist: 'Artista');

      expect(track?.trackName, 'Nome');
      expect(track?.artistName, 'Artista');
      expect(track?.previewUrl, 'https://preview');
      expect(track?.artworkUrl, 'https://art/512x512bb.jpg');
    });

    test('retorna null quando não há resultados', () async {
      final client = MockClient(
        (request) async => http.Response('{"results":[]}', 200),
      );
      final api = ItunesSearchApi(client: client);

      final track = await api.searchTrack(trackName: 'Inexistente');

      expect(track, isNull);
    });

    test('lança InvalidServerResponseException para status de erro', () async {
      final client = MockClient((request) async => http.Response('erro', 500));
      final api = ItunesSearchApi(client: client);

      expect(
        () => api.searchTrack(trackName: 'Nome'),
        throwsA(isA<InvalidServerResponseException>()),
      );
    });

    test('lança InvalidServerResponseException para JSON malformado', () async {
      final client = MockClient(
        (request) async => http.Response('não é json', 200),
      );
      final api = ItunesSearchApi(client: client);

      expect(
        () => api.searchTrack(trackName: 'Nome'),
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
        final api = ItunesSearchApi(
          client: client,
          timeout: const Duration(milliseconds: 20),
          retryBackoff: (_) => Duration.zero,
        );

        await expectLater(
          () => api.searchTrack(trackName: 'Nome'),
          throwsA(isA<NetworkTimeoutException>()),
        );
        expect(attempts, 2, reason: 'deve tentar 1 vez + 1 retry');
      },
    );

    test(
      'recupera no retry quando a 1ª tentativa expira e a 2ª responde a tempo',
      () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          return http.Response(
            '{"results":[{"trackName":"Nome","artistName":"Artista",'
            '"previewUrl":"https://preview"}]}',
            200,
          );
        });
        final api = ItunesSearchApi(
          client: client,
          timeout: const Duration(milliseconds: 20),
          retryBackoff: (_) => Duration.zero,
        );

        final track = await api.searchTrack(trackName: 'Nome');

        expect(track?.trackName, 'Nome');
        expect(attempts, 2);
      },
    );

    test('lança NetworkConnectionException para falha de socket', () async {
      final client = MockClient((request) async {
        throw const SocketException('sem rede');
      });
      final api = ItunesSearchApi(client: client);

      expect(
        () => api.searchTrack(trackName: 'Nome'),
        throwsA(isA<NetworkConnectionException>()),
      );
    });
  });
}
