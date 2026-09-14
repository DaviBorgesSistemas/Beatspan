// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:ui';

import 'package:flutter/material.dart';

class BubbleBlur extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const BubbleBlur({
    super.key,
    required this.size,
    required this.color,
    this.blur = 70,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
            stops: const [0.75, 1.0],
          ),
        ),
      ),
    );
  }
}
