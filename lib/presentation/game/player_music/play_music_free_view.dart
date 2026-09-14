import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/model/playback_state.dart';
import '../../../domain/usecase/preview_playback_usecase.dart';
import '../../../domain/usecase/spotify_playback_usecase.dart';
import '../../resource/color_manager.dart';
import '../../share/widgets/beatspan_loading_overlay.dart';
import '../../share/widgets/next_card_button.dart';

class PlayerMusicFreeView extends StatefulWidget {
  final String? trackId;
  final String previewUrl;
  final String? trackName;
  final String? artistName;
  final String? albumArtUrl;
  final PreviewPlaybackUseCase previewPlaybackUseCase;
  final SpotifyPlaybackUseCase spotifyPlaybackUseCase;

  const PlayerMusicFreeView({
    super.key,
    this.trackId,
    required this.previewUrl,
    this.trackName,
    this.artistName,
    this.albumArtUrl,
    required this.previewPlaybackUseCase,
    required this.spotifyPlaybackUseCase,
  });

  @override
  State<PlayerMusicFreeView> createState() => _PlayerMusicFreeViewState();
}

class _PlayerMusicFreeViewState extends State<PlayerMusicFreeView> {
  bool _isLoading = true;
  String? _error;

  bool _isSavingTrack = false;
  bool _isTrackSaved = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final result = await widget.previewPlaybackUseCase.load(widget.previewUrl);
    if (!mounted) return;
    result.fold((failure) {
      setState(() {
        _isLoading = false;
        _error = failure.message;
      });
    }, (_) => setState(() => _isLoading = false));
  }

  @override
  void dispose() {
    widget.previewPlaybackUseCase.dispose();
    super.dispose();
  }

  Future<void> _saveToSpotify() async {
    final trackId = widget.trackId;
    if (trackId == null || _isSavingTrack || _isTrackSaved) return;

    setState(() => _isSavingTrack = true);
    final result = await widget.spotifyPlaybackUseCase.saveTrack(trackId);
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (saved) {
        setState(() => _isTrackSaved = saved);
        if (!saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível salvar a faixa no Spotify.'),
            ),
          );
        }
      },
    );
    if (mounted) setState(() => _isSavingTrack = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const BeatspanLoadingOverlay(
                message: 'CARREGANDO PRÉVIA...',
                fillBackground: true,
              )
            : _error != null
            ? _buildError(_error!)
            : _buildPlayer(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Semantics(
              button: true,
              label: 'Fechar',
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorManager.cardBackground,
              border: Border.all(
                width: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _albumArt(),
                SizedBox(height: 24),
                Text(
                  widget.trackName ?? '',
                  style: TextStyle(fontSize: 16, color: ColorManager.textLight),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.artistName ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: ColorManager.textMuted,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.cyanAccent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: ColorManager.cyanAccent.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PRÉVIA',
                        style: TextStyle(
                          color: ColorManager.cyanAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                _playButton(),
              ],
            ),
          ),
          SizedBox(height: 32),
          const NextCardButton(),
        ],
      ),
    );
  }

  Widget _albumArt() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: widget.albumArtUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.albumArtUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _albumArtFallback(),
              errorWidget: (_, __, ___) => _albumArtFallback(),
            )
          : _albumArtFallback(),
    );
  }

  Widget _albumArtFallback() {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 72),
    );
  }

  Widget _playButton() {
    return StreamBuilder<PlaybackState>(
      stream: widget.previewPlaybackUseCase.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state != null && !state.isPaused;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: widget.trackId == null ? null : _saveToSpotify,
              child: Row(
                children: [
                  _isSavingTrack
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isTrackSaved
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    _isTrackSaved ? 'SALVO NO SPOTIFY' : 'SALVAR NO SPOTIFY',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => widget.previewPlaybackUseCase.togglePlayback(
                isPaused: !playing,
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: -3,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: ColorManager.cardBackground,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
