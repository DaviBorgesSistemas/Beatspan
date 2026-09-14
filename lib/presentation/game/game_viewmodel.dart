import 'package:flutter/material.dart';

import '../../app/app_prefs.dart';
import '../../domain/analytics_reporting.dart';
import '../../domain/failure.dart';
import '../../domain/model/musica_playback_result.dart';
import '../../domain/usecase/get_musica_usecase.dart';
import '../../domain/usecase/musica_playback_usecase.dart';
import 'game_navigation_event.dart';

enum QrValidationResult { invalid, beatspanCode }

class GameViewModel {
  static const List<String> _beatspanHosts = [
    'beatspangame.com',
    'beatspan.web.app',
    'beatspan.firebaseapp.com',
  ];

  static const int _codigoMaxLength = 100;
  static final RegExp _codigoFormat = RegExp(r'^[a-zA-Z0-9]+$');

  final AppPreferences _appPreferences;
  final GetMusicaUseCase _getMusicaUseCase;
  final MusicaPlaybackUseCase _musicaPlaybackUseCase;

  GameViewModel({
    required AppPreferences appPreferences,
    required GetMusicaUseCase getMusicaUseCase,
    required MusicaPlaybackUseCase musicaPlaybackUseCase,
  }) : _appPreferences = appPreferences,
       _getMusicaUseCase = getMusicaUseCase,
       _musicaPlaybackUseCase = musicaPlaybackUseCase;

  final ValueNotifier<GameNavigationEvent?> navigationEvent = ValueNotifier(
    null,
  );

  bool _disposed = false;

  void dispose() {
    _disposed = true;
    navigationEvent.dispose();
  }

  void _emitNavigation(GameNavigationEvent event) {
    if (_disposed) return;
    navigationEvent.value = event;
  }

  QrValidationResult validate(String rawValue) {
    final isBeatspanLink = extractCodigo(rawValue) != null;
    if (!isBeatspanLink) {
      return QrValidationResult.invalid;
    }
    return QrValidationResult.beatspanCode;
  }

  String? extractCodigo(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
    if (!_beatspanHosts.contains(host)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final codigo = segments.last;
    if (codigo.isEmpty || codigo.length > _codigoMaxLength) return null;
    if (!_codigoFormat.hasMatch(codigo)) return null;

    return codigo;
  }

  Future<void> handleDetectedCode(String rawValue) async {
    reportAnalyticsEvent(AnalyticsEvent.qrScanned);
    final result = validate(rawValue);

    if (result == QrValidationResult.invalid) {
      reportAnalyticsEvent(AnalyticsEvent.qrInvalid);
      _emitNavigation(const NavigateToError());
      return;
    }

    final codigo = extractCodigo(rawValue);
    if (codigo == null) {
      reportAnalyticsEvent(AnalyticsEvent.qrInvalid);
      _emitNavigation(const NavigateToError());
      return;
    }

    await _handleBeatspanCode(codigo);
  }

  Future<void> _handleBeatspanCode(String codigo) async {
    final result = await _getMusicaUseCase.execute(codigo);
    if (_disposed) return;

    final spotifyUri = result.fold(
      (failure) => null,
      (musica) => musica.spotifyUri,
    );

    if (spotifyUri == null) {
      final failure = result.fold((failure) => failure, (_) => null);
      reportAnalyticsEvent(AnalyticsEvent.musicaLookupFailed, {
        'reason': failure.runtimeType.toString(),
      });
      _emitNavigation(switch (failure) {
        MusicaNaoEncontrada() => const NavigateToError(
          title: 'MÚSICA NÃO ENCONTRADA',
          message:
              'Não encontramos essa carta no nosso catálogo. Tente escanear novamente.',
        ),
        MusicaConsultaErro() || null => _connectionErrorEvent,
      });
      return;
    }

    await _handleSpotifyTrack(spotifyUri);
  }

  Future<void> _handleSpotifyTrack(String spotifyUri) async {
    final plan = await _appPreferences.getAppPlanType();
    if (_disposed) return;
    if (plan == null) return;
    final gameMode = _appPreferences.getGameMode();

    final result = await _musicaPlaybackUseCase.execute(
      MusicaPlaybackInput(
        spotifyUri: spotifyUri,
        plan: plan,
        gameMode: gameMode,
      ),
    );
    if (_disposed) return;

    _emitNavigation(
      result.fold(
        (failure) {
          reportAnalyticsEvent(AnalyticsEvent.playbackFailed, {
            'reason': failure.runtimeType.toString(),
          });
          return switch (failure) {
            MusicaPlaybackPreviaIndisponivel() => const NavigateToError(
              title: 'PRÉVIA INDISPONÍVEL',
              message:
                  'Essa faixa não tem uma prévia de 30 segundos disponível no plano Free. Tente outra carta ou use o Spotify Premium.',
            ),
            MusicaPlaybackErroConexao() => _connectionErrorEvent,
            MusicaPlaybackSpotifyNaoAutorizado() => const NavigateToError(
              title: 'SPOTIFY NÃO AUTORIZADO',
              message:
                  'Não foi possível autorizar o acesso ao Spotify. Verifique se o app do Spotify está instalado, atualizado e conectado à sua conta, então tente novamente.',
              icon: Icons.lock_outline_rounded,
            ),
            MusicaPlaybackErroInesperado() => const NavigateToError(
              title: 'ALGO DEU ERRADO',
              message:
                  'Ocorreu um erro inesperado ao preparar a música. Tente escanear a carta novamente.',
              icon: Icons.error_outline_rounded,
            ),
            MusicaPlaybackUriInvalida() => const NavigateToError(),
          };
        },
        (playback) {
          // A fonte exata da prévia (Spotify vs. fallback iTunes) é reportada
          // separadamente em `AnalyticsEvent.itunesFallbackUsed`, no ponto em
          // que essa decisão realmente acontece
          // (`MusicaPlaybackRepositoryImpl._fetchPreview`) — aqui só distinguimos
          // faixa completa (Premium) de prévia de 30s (Free/preview).
          reportAnalyticsEvent(AnalyticsEvent.playbackStarted, {
            'source': switch (playback) {
              FullTrackPlayback() => PlaybackSource.spotifyFull,
              PreviewPlayback() => PlaybackSource.spotifyPreview,
            },
          });
          return NavigateToPlayer(playback);
        },
      ),
    );
  }

  static const _connectionErrorEvent = NavigateToError(
    title: 'ERRO DE CONEXÃO',
    message:
        'Não foi possível conectar à internet. Verifique sua conexão e tente escanear a carta novamente.',
    icon: Icons.wifi_off_rounded,
  );
}
