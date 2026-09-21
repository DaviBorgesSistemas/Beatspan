// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../resource/color_manager.dart';

class BeatspanLoadingOverlay extends StatefulWidget {
  final String message;
  final bool fillBackground;

  const BeatspanLoadingOverlay({
    super.key,
    this.message = 'BUSCANDO MÚSICA...',
    this.fillBackground = false,
  });

  @override
  State<BeatspanLoadingOverlay> createState() => _BeatspanLoadingOverlayState();
}

class _BeatspanLoadingOverlayState extends State<BeatspanLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _spinController,
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    ColorManager.gradientPurple,
                    ColorManager.gradientMagenta,
                    ColorManager.gradientOrange,
                    ColorManager.gradientPurple,
                  ],
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      label: widget.message,
      excludeSemantics: true,
      child: widget.fillBackground
          ? ColoredBox(color: ColorManager.backgroundColor, child: content)
          : ColoredBox(
              color: Colors.black.withValues(alpha: 0.75),
              child: content,
            ),
    );
  }
}
