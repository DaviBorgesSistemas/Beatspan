import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'network_exceptions.dart';
import 'retry.dart';

class ItunesSearchApi {
  final http.Client _client;
  final Duration _timeout;
  final Duration Function(int attempt) _retryBackoff;

  static const _defaultTimeout = Duration(seconds: 10);
  static const _endpoint = 'GET /search';

  ItunesSearchApi({
    http.Client? client,
    Duration timeout = _defaultTimeout,
    Duration Function(int attempt)? retryBackoff,
  }) : _client = client ?? http.Client(),
       _timeout = timeout,
       _retryBackoff = retryBackoff ?? defaultRetryBackoff;

  Future<ItunesTrackInfo?> searchTrack({
    required String trackName,
    String? artist,
  }) async {
    final term = artist == null ? trackName : '$trackName $artist';
    final url = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'media': 'music',
      'entity': 'song',
      'limit': '1',
      'country': 'BR',
    });

    final http.Response r;
    try {
      r = await withRetry(
        () => _client.get(url).timeout(_timeout),
        shouldRetry: isTransientHttpError,
        backoff: _retryBackoff,
      );
    } on TimeoutException {
      throw NetworkTimeoutException(_endpoint);
    } on SocketException catch (e) {
      throw NetworkConnectionException(_endpoint, cause: e);
    } on http.ClientException catch (e) {
      throw NetworkConnectionException(_endpoint, cause: e);
    }

    if (r.statusCode != 200) {
      throw InvalidServerResponseException(
        _endpoint,
        r.body,
        statusCode: r.statusCode,
      );
    }

    final Map<String, dynamic> j;
    try {
      j = json.decode(r.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw InvalidServerResponseException(_endpoint, e.message);
    }

    final results = j['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final track = results.first as Map<String, dynamic>;
    final artworkUrl100 = track['artworkUrl100'] as String?;

    return ItunesTrackInfo(
      trackName: track['trackName'] as String?,
      artistName: track['artistName'] as String?,
      previewUrl: track['previewUrl'] as String?,
      artworkUrl: artworkUrl100?.replaceFirst('100x100', '512x512'),
    );
  }
}

class ItunesTrackInfo {
  final String? trackName;
  final String? artistName;
  final String? previewUrl;
  final String? artworkUrl;

  const ItunesTrackInfo({
    this.trackName,
    this.artistName,
    this.previewUrl,
    this.artworkUrl,
  });
}
