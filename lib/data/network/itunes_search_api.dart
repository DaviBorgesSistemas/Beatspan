import 'dart:convert';

import 'package:http/http.dart' as http;

class ItunesSearchApi {
  static const _timeout = Duration(seconds: 10);

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

    final r = await http.get(url).timeout(_timeout);
    if (r.statusCode != 200) return null;

    final j = json.decode(r.body) as Map<String, dynamic>;
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
