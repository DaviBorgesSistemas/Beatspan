import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_prefs.dart';
import '../../data/network/spotify_service.dart';
import '../../domain/model/musica_playback_result.dart';
import '../../domain/usecase/get_musica_usecase.dart';
import '../../domain/usecase/musica_playback_usecase.dart';
import '../share/widgets/beatspan_loading_overlay.dart';
import 'game_viewmodel.dart';
import 'game_error_view.dart';
import 'player_music/play_music_free_view.dart';
import 'player_music/player_music_premium_view.dart';
import 'turn_phone_ready_view.dart';
import 'widget/scanner_overlay.dart';

class GameView extends StatefulWidget {
  final AppPreferences appPreferences;
  final GetMusicaUseCase getMusicaUseCase;
  final MusicaPlaybackUseCase musicaPlaybackUseCase;
  final SpotifyService spotifyService;

  const GameView({
    super.key,
    required this.appPreferences,
    required this.getMusicaUseCase,
    required this.musicaPlaybackUseCase,
    required this.spotifyService,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final MobileScannerController qrController = MobileScannerController();
  final GameViewModel controller = GameViewModel();
  late final AppPreferences _appPreferences = widget.appPreferences;
  late final GetMusicaUseCase _getMusicaUseCase = widget.getMusicaUseCase;
  late final MusicaPlaybackUseCase _musicaPlaybackUseCase =
      widget.musicaPlaybackUseCase;

  bool _isHandlingCode = false;
  bool _isLoading = false;

  @override
  void dispose() {
    qrController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isHandlingCode) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value == null) return;

    _isHandlingCode = true;

    await qrController.stop();
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final result = controller.validate(value);

      if (result == QrValidationResult.invalid) {
        await _goToError();
        return;
      }

      final codigo = controller.extractCodigo(value);
      if (codigo == null) {
        await _goToError();
        return;
      }

      await _handleBeatspanCode(codigo);
    } finally {
      if (mounted) {
        _isHandlingCode = false;
        setState(() => _isLoading = false);
        await qrController.start();
      }
    }
  }

  Future<void> _handleBeatspanCode(String codigo) async {
    final result = await _getMusicaUseCase.execute(codigo);

    final spotifyUri = result.fold(
      (failure) => null,
      (musica) => musica.spotifyUri,
    );

    if (spotifyUri == null) {
      final failureCode = result.fold((failure) => failure.code, (_) => 0);
      if (failureCode == 404) {
        await _goToMusicaNaoEncontrada();
      } else {
        await _goToConnectionError();
      }
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

    await result.fold(
      (failure) async {
        switch (failure.code) {
          case musicaPlaybackPreviewUnavailableCode:
            await _goToPreviewUnavailable();
          case musicaPlaybackConnectionErrorCode:
            await _goToConnectionError();
          default:
            await _goToError();
        }
      },
      (playback) async {
        if (!mounted) return;
        switch (playback) {
          case FullTrackPlayback(:final spotifyUri):
            await _navigateToPlayer(
              PlayerMusicPremiumView(
                initialUri: spotifyUri,
                spotifyService: widget.spotifyService,
              ),
            );
          case PreviewPlayback():
            await _navigateToPlayer(
              PlayerMusicFreeView(
                trackId: playback.trackId,
                previewUrl: playback.previewUrl,
                trackName: playback.trackName,
                artistName: playback.artistName,
                albumArtUrl: playback.albumArtUrl,
                spotifyService: widget.spotifyService,
              ),
            );
        }
      },
    );
  }

  Future<void> _goToError() async {
    if (!mounted) return;
    await _navigateTo(const GameErrorView());
  }

  Future<void> _goToMusicaNaoEncontrada() async {
    if (!mounted) return;
    await _navigateTo(
      const GameErrorView(
        title: 'MÚSICA NÃO ENCONTRADA',
        message:
            'Não encontramos essa carta no nosso catálogo. Tente escanear novamente.',
      ),
    );
  }

  Future<void> _goToPreviewUnavailable() async {
    if (!mounted) return;
    await _navigateTo(
      const GameErrorView(
        title: 'PRÉVIA INDISPONÍVEL',
        message:
            'Essa faixa não tem uma prévia de 30 segundos disponível no plano Free. Tente outra carta ou use o Spotify Premium.',
      ),
    );
  }

  Future<void> _goToConnectionError() async {
    if (!mounted) return;
    await _navigateTo(
      const GameErrorView(
        title: 'ERRO DE CONEXÃO',
        message:
            'Não foi possível conectar ao Spotify. Verifique sua internet e tente escanear a carta novamente.',
        icon: Icons.wifi_off_rounded,
      ),
    );
  }

  Future<void> _navigateToPlayer(Widget player) async {
    final turnPhoneEnabled = _appPreferences.getTurnPhoneEnabled();
    if (!turnPhoneEnabled) {
      await _navigateTo(player);
      return;
    }

    final mode = _appPreferences.getTurnPhoneMode();
    await _navigateTo(
      TurnPhoneReadyView(
        mode: mode,
        onReady: () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => player,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateTo(Widget page) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 260,
      height: 260,
    );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: qrController,
              fit: BoxFit.cover,
              scanWindow: scanWindow,
              onDetect: _onDetect,
            ),
          ),
          ScannerOverlay(),
          if (_isLoading)
            const Positioned.fill(child: BeatspanLoadingOverlay()),
        ],
      ),
    );
  }
}
