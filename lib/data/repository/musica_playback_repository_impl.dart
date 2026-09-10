import 'package:flutter/services.dart';

import '../../domain/error_reporting.dart';
import '../../domain/exceptions/playback_exceptions.dart';
import '../../domain/exceptions/rate_limited_exception.dart';
import '../../domain/exceptions/spotify_consent_exception.dart';
import '../../domain/model/musica_playback_result.dart';
import '../../domain/repository/musica_playback_repository.dart';
import '../network/itunes_search_api.dart';
import '../network/network_exceptions.dart';
import '../network/spotify_service.dart';
import '../network/spotify_webapi.dart';

typedef SpotifyWebApiFactory = SpotifyWebApi Function(String accessToken);

class MusicaPlaybackRepositoryImpl implements MusicaPlaybackRepository {
  final SpotifyService _spotifyService;
  final ItunesSearchApi _itunesSearchApi;
  final SpotifyWebApiFactory _spotifyWebApiFactory;

  // Cache em memória por trackId: a mesma carta escaneada de novo na mesma
  // sessão do app reaproveita a resolução anterior em vez de rechamar
  // Spotify/iTunes. Sem TTL — o resultado não muda durante a sessão.
  final Map<String, PreviewPlayback?> _previewCache = {};

  MusicaPlaybackRepositoryImpl(
    this._spotifyService,
    this._itunesSearchApi, {
    SpotifyWebApiFactory spotifyWebApiFactory = SpotifyWebApi.new,
  }) : _spotifyWebApiFactory = spotifyWebApiFactory;

  @override
  Future<PreviewPlayback?> resolvePreview(String trackId) async {
    if (_previewCache.containsKey(trackId)) {
      return _previewCache[trackId];
    }

    final result = await _fetchPreview(trackId);
    _previewCache[trackId] = result;
    return result;
  }

  Future<PreviewPlayback?> _fetchPreview(String trackId) async {
    try {
      final token = await _spotifyService.getAccessToken();
      final api = _spotifyWebApiFactory(token);
      final track = await api.getTrack(trackId);

      String? previewUrl = track?.previewUrl;
      String? albumArtUrl = track?.albumArtUrl;
      final trackName = track?.name;
      final artistName = track?.artist;

      if (previewUrl == null && trackName != null) {
        final itunesTrack = await _itunesSearchApi.searchTrack(
          trackName: trackName,
          artist: artistName,
        );
        previewUrl = itunesTrack?.previewUrl;
        albumArtUrl ??= itunesTrack?.artworkUrl;
      }

      if (previewUrl == null) return null;

      return PreviewPlayback(
        trackId: trackId,
        previewUrl: previewUrl,
        trackName: trackName,
        artistName: artistName,
        albumArtUrl: albumArtUrl,
      );
    } on SpotifyConsentRequiredException {
      throw const PlaybackAuthException(
        'É necessário aceitar o consentimento do Spotify antes de tocar as faixas.',
      );
    } on MissingPluginException catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['MusicaPlaybackRepositoryImpl._fetchPreview'],
      );
      throw const PlaybackAuthException(
        'Plugin do Spotify não registrado neste build.',
      );
    } on PlatformException catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: [
          'MusicaPlaybackRepositoryImpl._fetchPreview',
          'PlatformException.code=${e.code}',
        ],
      );
      throw PlaybackAuthException(
        'Falha ao autorizar o acesso ao Spotify (${e.code}).',
      );
    } on RateLimitedException catch (e, s) {
      reportNonFatalError(e, s);
      throw PlaybackNetworkException(
        'Limite de requisições do Spotify atingido. Tente novamente em '
        '${e.retryAfter.inSeconds}s.',
      );
    } on NetworkTimeoutException catch (e, s) {
      reportNonFatalError(e, s);
      throw const PlaybackNetworkException('Tempo de conexão esgotado.');
    } on NetworkConnectionException catch (e, s) {
      reportNonFatalError(e, s);
      throw const PlaybackNetworkException('Falha de conexão com a internet.');
    } on InvalidServerResponseException catch (e, s) {
      reportNonFatalError(e, s);
      throw const PlaybackNetworkException(
        'Resposta inválida do servidor do Spotify.',
      );
    }
  }
}
