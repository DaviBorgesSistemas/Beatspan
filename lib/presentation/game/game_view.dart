// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_prefs.dart';
import '../../domain/model/musica_playback_result.dart';
import '../../domain/usecase/musica_playback_usecase.dart';
import '../../domain/usecase/preview_playback_usecase.dart';
import '../../domain/usecase/spotify_playback_usecase.dart';
import '../share/widgets/beatspan_loading_overlay.dart';
import 'game_error_view.dart';
import 'game_navigation_event.dart';
import 'game_viewmodel.dart';
import 'player_music/play_music_free_view.dart';
import 'player_music/player_music_premium_view.dart';
import 'turn_phone_ready_view.dart';
import 'widget/scanner_overlay.dart';

class GameView extends StatefulWidget {
  final AppPreferences appPreferences;
  final GameViewModel viewModel;
  final SpotifyPlaybackUseCase spotifyPlaybackUseCase;
  final MusicaPlaybackUseCase musicaPlaybackUseCase;
  final PreviewPlaybackUseCase Function() previewPlaybackUseCaseFactory;

  const GameView({
    super.key,
    required this.appPreferences,
    required this.viewModel,
    required this.spotifyPlaybackUseCase,
    required this.musicaPlaybackUseCase,
    required this.previewPlaybackUseCaseFactory,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final MobileScannerController qrController = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  late final GameViewModel _viewModel = widget.viewModel;
  late final AppPreferences _appPreferences = widget.appPreferences;

  bool _isHandlingCode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel.navigationEvent.addListener(_onNavigationEvent);
  }

  @override
  void dispose() {
    _viewModel.navigationEvent.removeListener(_onNavigationEvent);
    qrController.dispose();
    super.dispose();
  }

  void _onNavigationEvent() {
    final event = _viewModel.navigationEvent.value;
    if (event == null || !mounted) return;
    _viewModel.navigationEvent.value = null;

    switch (event) {
      case NavigateToError(:final title, :final message, :final icon):
        _goToError(title: title, message: message, icon: icon);
      case NavigateToPlayer(:final playback):
        _goToPlayer(playback);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isHandlingCode) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value == null) return;

    _isHandlingCode = true;

    await qrController.stop();
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _viewModel.handleDetectedCode(value);
    } finally {
      if (mounted) {
        _isHandlingCode = false;
        setState(() => _isLoading = false);
        await qrController.start();
      }
    }
  }

  Future<void> _goToError({String? title, String? message, IconData? icon}) {
    return _navigateTo(
      GameErrorView(
        title: title ?? 'OPS, CÓDIGO QR\nDESCONHECIDO!',
        message:
            message ??
            'Você escaneou um QR code que não pertence a uma carta Beatspan. Tente outra carta do jogo!',
        icon: icon ?? Icons.qr_code_scanner_rounded,
      ),
    );
  }

  Future<void> _goToPlayer(MusicaPlaybackResult playback) {
    return switch (playback) {
      FullTrackPlayback(:final spotifyUri) => _navigateToPlayer(
        PlayerMusicPremiumView(
          initialUri: spotifyUri,
          spotifyPlaybackUseCase: widget.spotifyPlaybackUseCase,
          musicaPlaybackUseCase: widget.musicaPlaybackUseCase,
          previewPlaybackUseCaseFactory: widget.previewPlaybackUseCaseFactory,
        ),
      ),
      PreviewPlayback() => _navigateToPlayer(
        PlayerMusicFreeView(
          trackId: playback.trackId,
          previewUrl: playback.previewUrl,
          trackName: playback.trackName,
          artistName: playback.artistName,
          albumArtUrl: playback.albumArtUrl,
          previewPlaybackUseCase: widget.previewPlaybackUseCaseFactory(),
          spotifyPlaybackUseCase: widget.spotifyPlaybackUseCase,
        ),
      ),
    };
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
