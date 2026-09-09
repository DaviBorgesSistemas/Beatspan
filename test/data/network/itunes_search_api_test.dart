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
      final client = MockClient(
        (request) async => http.Response('erro', 500),
      );
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

    test('lança NetworkTimeoutException quando a chamada expira', () async {
      final client = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 11));
        return http.Response('', 200);
      });
      final api = ItunesSearchApi(client: client);

      expect(
        () => api.searchTrack(trackName: 'Nome'),
        throwsA(isA<NetworkTimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

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
