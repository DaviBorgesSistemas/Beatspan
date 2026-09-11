import 'package:flutter/material.dart';

import '../../app/app_prefs.dart';
import '../../domain/failure.dart';
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

  void dispose() {
    navigationEvent.dispose();
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
    return codigo.isEmpty ? null : codigo;
  }

  Future<void> handleDetectedCode(String rawValue) async {
    final result = validate(rawValue);

    if (result == QrValidationResult.invalid) {
      navigationEvent.value = const NavigateToError();
      return;
    }

    final codigo = extractCodigo(rawValue);
    if (codigo == null) {
      navigationEvent.value = const NavigateToError();
      return;
    }

    await _handleBeatspanCode(codigo);
  }

  Future<void> _handleBeatspanCode(String codigo) async {
    final result = await _getMusicaUseCase.execute(codigo);

    final spotifyUri = result.fold(
      (failure) => null,
      (musica) => musica.spotifyUri,
    );

    if (spotifyUri == null) {
      final failure = result.fold((failure) => failure, (_) => null);
      navigationEvent.value = switch (failure) {
        MusicaNaoEncontrada() => const NavigateToError(
          title: 'MÚSICA NÃO ENCONTRADA',
          message:
              'Não encontramos essa carta no nosso catálogo. Tente escanear novamente.',
        ),
        MusicaConsultaErro() || null => _connectionErrorEvent,
      };
      return;
    }

    await _handleSpotifyTrack(spotifyUri);
  }

  Future<void> _handleSpotifyTrack(String spotifyUri) async {
    final plan = await _appPreferences.getAppPlanType();
    if (plan == null) return;
    final gameMode = _appPreferences.getGameMode();

    final result = await _musicaPlaybackUseCase.execute(
      MusicaPlaybackInput(
        spotifyUri: spotifyUri,
        plan: plan,
        gameMode: gameMode,
      ),
    );

    navigationEvent.value = result.fold((failure) {
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
    }, (playback) => NavigateToPlayer(playback));
  }

  static const _connectionErrorEvent = NavigateToError(
    title: 'ERRO DE CONEXÃO',
    message:
        'Não foi possível conectar à internet. Verifique sua conexão e tente escanear a carta novamente.',
    icon: Icons.wifi_off_rounded,
  );
}
