import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/enum/settings_enum.dart';
import '../../../domain/model/musica_playback_result.dart';
import '../../../domain/model/playback_state.dart';
import '../../../domain/usecase/musica_playback_usecase.dart';
import '../../../domain/usecase/preview_playback_usecase.dart';
import '../../../domain/usecase/spotify_playback_usecase.dart';
import '../../share/widgets/beatspan_loading_overlay.dart';
import '../../share/widgets/next_card_button.dart';
import 'play_music_free_view.dart';

class PlayerMusicPremiumView extends StatefulWidget {
  final String initialUri;
  final SpotifyPlaybackUseCase spotifyPlaybackUseCase;
  final MusicaPlaybackUseCase musicaPlaybackUseCase;
  final PreviewPlaybackUseCase Function() previewPlaybackUseCaseFactory;

  const PlayerMusicPremiumView({
    super.key,
    required this.initialUri,
    required this.spotifyPlaybackUseCase,
    required this.musicaPlaybackUseCase,
    required this.previewPlaybackUseCaseFactory,
  });

  @override
  State<PlayerMusicPremiumView> createState() => _PlayerMusicPremiumViewState();
}

class _PlayerMusicPremiumViewState extends State<PlayerMusicPremiumView> {
  bool _loading = true;
  String? _error;
  bool _pluginAvailable = true;
  bool _fallingBackToPreview = false;

  Stream<PlaybackState>? _playerStateStream;

  static const _background = Color(0xFF08050D);
  static const _purple = Color(0xFF6C2BFF);
  static const _pink = Color(0xFFFF469E);

  @override
  void initState() {
    super.initState();
    _initSpotify();
  }

  @override
  void dispose() {
    widget.spotifyPlaybackUseCase.pause();
    super.dispose();
  }

  Future<void> _initSpotify() async {
    if (!(kIsWeb || Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _pluginAvailable = false;
        _loading = false;
        _error = 'Plataforma não suportada pelo spotify_sdk.';
      });
      return;
    }

    final result = await widget.spotifyPlaybackUseCase.startPlayback(
      widget.initialUri,
    );

    await result.fold(
      (failure) async {
        if (failure.code == spotifyPlaybackAuthErrorCode) {
          final fellBack = await _tryFallbackToPreview();
          if (fellBack) return;
        }
        if (!mounted) return;
        setState(() {
          _loading = false;
          _pluginAvailable =
              failure.code != spotifyPlaybackPluginMissingErrorCode;
          _error = failure.message;
        });
      },
      (_) async {
        _playerStateStream = widget.spotifyPlaybackUseCase
            .subscribePlayerState();
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      },
    );
  }

  /// Quando a conexão Premium falha por autorização (app não instalado,
  /// autorização negada, sessão expirada), tenta tocar a prévia de 30s em
  /// vez de travar o usuário na tela de erro — comum em uso de festa, onde
  /// parar o jogo por causa de uma falha pontual do Spotify frustra mais
  /// que degradar para a prévia. Não altera a preferência de plano salva.
  Future<bool> _tryFallbackToPreview() async {
    setState(() => _fallingBackToPreview = true);

    final result = await widget.musicaPlaybackUseCase.execute(
      MusicaPlaybackInput(
        spotifyUri: widget.initialUri,
        plan: PlanType.free,
        gameMode: GameModeType.preview,
      ),
    );

    final preview = result.fold((_) => null, (playback) => playback);
    if (preview is! PreviewPlayback || !mounted) {
      if (mounted) setState(() => _fallingBackToPreview = false);
      return false;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerMusicFreeView(
          trackId: preview.trackId,
          previewUrl: preview.previewUrl,
          trackName: preview.trackName,
          artistName: preview.artistName,
          albumArtUrl: preview.albumArtUrl,
          previewPlaybackUseCase: widget.previewPlaybackUseCaseFactory(),
          spotifyPlaybackUseCase: widget.spotifyPlaybackUseCase,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _purple.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 300,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _pink.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ),
            Center(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading || _fallingBackToPreview) {
      return BeatspanLoadingOverlay(
        message: _fallingBackToPreview
            ? 'SPOTIFY INDISPONÍVEL, TOCANDO PRÉVIA...'
            : 'CONECTANDO AO SPOTIFY...',
      );
    }

    if (_error != null || !_pluginAvailable || _playerStateStream == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ??
                  'Não foi possível inicializar o player do Spotify nesta plataforma.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<PlaybackState>(
      stream: _playerStateStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro na stream de estado do player:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          );
        }

        final playing = snap.data?.isPaused == false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VisualGlyphsCard(
              playing: playing,
              onTap: () => widget.spotifyPlaybackUseCase.togglePlayback(
                isPaused: !playing,
              ),
            ),
            const SizedBox(height: 40),
            const NextCardButton(),
          ],
        );
      },
    );
  }
}

class _VisualGlyphsCard extends StatefulWidget {
  final bool playing;
  final VoidCallback onTap;

  const _VisualGlyphsCard({required this.playing, required this.onTap});

  @override
  State<_VisualGlyphsCard> createState() => _VisualGlyphsCardState();
}

class _VisualGlyphsCardState extends State<_VisualGlyphsCard>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  static const _ringDurationsMs = [8000, 6000, 4000, 5000];
  static const _ringReversed = [false, true, false, true];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _ringDurationsMs.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _ringDurationsMs[i]),
      ),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _VisualGlyphsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    for (final c in _controllers) {
      if (widget.playing) {
        c.repeat(reverse: false);
      } else {
        c.stop();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: const Color(0xFF6C2BFF).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C2BFF).withValues(alpha: 0.15),
              blurRadius: 40,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge(_controllers),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(320, 320),
                  painter: _GlyphRingsPainter(
                    turns: _controllers
                        .asMap()
                        .entries
                        .map(
                          (e) => _ringReversed[e.key]
                              ? -e.value.value
                              : e.value.value,
                        )
                        .toList(),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF08050D).withValues(alpha: 0.3),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F7FC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Icon(
                widget.playing ? Icons.pause : Icons.play_arrow,
                color: const Color(0xFF08050D),
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlyphRingsPainter extends CustomPainter {
  final List<double> turns;

  _GlyphRingsPainter({required this.turns});

  static const _rings = [
    _RingSpec(
      radius: 110,
      strokeWidth: 6,
      dashes: [140, 50, 60, 40],
      opacity: 0.8,
    ),
    _RingSpec(
      radius: 90,
      strokeWidth: 6,
      dashes: [100, 40, 70, 30],
      opacity: 0.9,
    ),
    _RingSpec(
      radius: 70,
      strokeWidth: 5,
      dashes: [80, 30, 50, 40],
      opacity: 0.85,
    ),
    _RingSpec(
      radius: 50,
      strokeWidth: 4,
      dashes: [60, 25, 30, 20],
      opacity: 0.75,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200;

    for (var i = 0; i < _rings.length; i++) {
      final ring = _rings[i];
      final gradientColors = [
        const Color(0xFF6C2BFF).withValues(alpha: ring.opacity),
        const Color(0xFFFF469E).withValues(alpha: ring.opacity),
      ];
      final paint = Paint()
        ..shader =
            LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromCircle(center: center, radius: ring.radius * scale),
            )
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth * scale
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(turns[i] * 2 * math.pi);
      canvas.translate(-center.dx, -center.dy);

      final path = _dashedCirclePath(
        center: center,
        radius: ring.radius * scale,
        dashes: ring.dashes.map((d) => d * scale).toList(),
      );
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  Path _dashedCirclePath({
    required Offset center,
    required double radius,
    required List<double> dashes,
  }) {
    final circumference = 2 * math.pi * radius;
    final path = Path();
    double distance = 0;
    var dashIndex = 0;
    var draw = true;

    while (distance < circumference) {
      final dashLength = dashes[dashIndex % dashes.length];
      final startAngle = (distance / circumference) * 2 * math.pi - math.pi / 2;
      final endAngle =
          ((distance + dashLength).clamp(0, circumference) / circumference) *
              2 *
              math.pi -
          math.pi / 2;

      if (draw) {
        path.addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          endAngle - startAngle,
        );
      }

      distance += dashLength;
      dashIndex++;
      draw = !draw;
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _GlyphRingsPainter oldDelegate) => true;
}

class _RingSpec {
  final double radius;
  final double strokeWidth;
  final List<double> dashes;
  final double opacity;

  const _RingSpec({
    required this.radius,
    required this.strokeWidth,
    required this.dashes,
    required this.opacity,
  });
}
