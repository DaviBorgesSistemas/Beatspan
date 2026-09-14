// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/exceptions/rate_limited_exception.dart';
import 'network_exceptions.dart';
import 'retry.dart';

class SpotifyWebApi {
  final String accessToken;
  final http.Client _client;
  final Duration _timeout;
  final Duration Function(int attempt) _retryBackoff;
  final Duration _maxRateLimitWait;

  static const _defaultTimeout = Duration(seconds: 10);
  static const _defaultMaxRateLimitWait = Duration(seconds: 10);
  static const _defaultRetryAfter = Duration(seconds: 1);
  static const _maxRateLimitAttempts = 2;

  SpotifyWebApi(
    this.accessToken, {
    http.Client? client,
    Duration timeout = _defaultTimeout,
    Duration Function(int attempt)? retryBackoff,
    Duration maxRateLimitWait = _defaultMaxRateLimitWait,
  }) : _client = client ?? http.Client(),
       _timeout = timeout,
       _retryBackoff = retryBackoff ?? defaultRetryBackoff,
       _maxRateLimitWait = maxRateLimitWait;

  Map<String, String> get _h => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  Future<String?> getTrackPreviewUrl(String trackId) async {
    final track = await getTrack(trackId);
    return track?.previewUrl;
  }

  Future<SpotifyTrackInfo?> getTrack(String trackId) async {
    final endpoint = 'GET /v1/tracks/$trackId';
    final url = Uri.parse('https://api.spotify.com/v1/tracks/$trackId');
    final r = await _get(url, endpoint);

    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) {
      throw InvalidServerResponseException(
        endpoint,
        r.body,
        statusCode: r.statusCode,
      );
    }

    final Map<String, dynamic> j;
    try {
      j = json.decode(r.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw InvalidServerResponseException(endpoint, e.message);
    }

    final artists = (j['artists'] as List<dynamic>?)
        ?.map((a) => (a as Map<String, dynamic>)['name'] as String?)
        .whereType<String>()
        .toList();

    final images =
        (j['album'] as Map<String, dynamic>?)?['images'] as List<dynamic>?;
    final albumArtUrl = images?.isNotEmpty == true
        ? (images!.first as Map<String, dynamic>)['url'] as String?
        : null;

    return SpotifyTrackInfo(
      name: j['name'] as String?,
      artist: artists?.isNotEmpty == true ? artists!.first : null,
      previewUrl: j['preview_url'] as String?,
      albumArtUrl: albumArtUrl,
    );
  }

  Future<bool> saveTrack(String trackId) async {
    final endpoint = 'PUT /v1/me/tracks';
    final url = Uri.parse('https://api.spotify.com/v1/me/tracks?ids=$trackId');
    final r = await _put(url, endpoint);
    return r.statusCode == 200 || r.statusCode == 204;
  }

  Future<bool> isTrackSaved(String trackId) async {
    final endpoint = 'GET /v1/me/tracks/contains';
    final url = Uri.parse(
      'https://api.spotify.com/v1/me/tracks/contains?ids=$trackId',
    );
    final r = await _get(url, endpoint);
    if (r.statusCode != 200) return false;

    final List<dynamic> list;
    try {
      list = json.decode(r.body) as List<dynamic>;
    } on FormatException catch (e) {
      throw InvalidServerResponseException(endpoint, e.message);
    }
    return list.isNotEmpty && list.first == true;
  }

  Future<http.Response> _get(Uri url, String endpoint) {
    return _send(() => _client.get(url, headers: _h), endpoint);
  }

  Future<http.Response> _put(Uri url, String endpoint) {
    return _send(() => _client.put(url, headers: _h), endpoint);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    String endpoint,
  ) async {
    for (var rateLimitAttempt = 1; ; rateLimitAttempt++) {
      final http.Response response;
      try {
        response = await withRetry(
          () => request().timeout(_timeout),
          shouldRetry: isTransientHttpError,
          backoff: _retryBackoff,
        );
      } on TimeoutException {
        throw NetworkTimeoutException(endpoint);
      } on SocketException catch (e) {
        throw NetworkConnectionException(endpoint, cause: e);
      } on http.ClientException catch (e) {
        throw NetworkConnectionException(endpoint, cause: e);
      }

      if (response.statusCode != 429) return response;

      final retryAfter = _parseRetryAfter(response.headers['retry-after']);
      if (rateLimitAttempt >= _maxRateLimitAttempts) {
        throw RateLimitedException(endpoint, retryAfter);
      }
      await Future.delayed(
        retryAfter > _maxRateLimitWait ? _maxRateLimitWait : retryAfter,
      );
    }
  }

  Duration _parseRetryAfter(String? header) {
    final seconds = header != null ? int.tryParse(header) : null;
    if (seconds == null) return _defaultRetryAfter;
    return Duration(seconds: seconds);
  }
}

class SpotifyTrackInfo {
  final String? name;
  final String? artist;
  final String? previewUrl;
  final String? albumArtUrl;

  const SpotifyTrackInfo({
    this.name,
    this.artist,
    this.previewUrl,
    this.albumArtUrl,
  });
}
