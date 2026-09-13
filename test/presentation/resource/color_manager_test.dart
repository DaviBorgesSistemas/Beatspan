import 'package:beatspan/presentation/resource/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todas as cores nomeadas resolvem para um Color válido', () {
    final colors = <Color>[
      ColorManager.primary,
      ColorManager.secondary,
      ColorManager.ternary,
      ColorManager.ternaryLight,
      ColorManager.quaternary,
      ColorManager.quaternaryLight,
      ColorManager.black,
      ColorManager.white,
      ColorManager.bagroundColor,
      ColorManager.yellowLink,
      ColorManager.warning,
      ColorManager.gradientPurple,
      ColorManager.gradientPink,
      ColorManager.accentPink,
      ColorManager.textLight,
      ColorManager.textMuted,
      ColorManager.gradientMagenta,
      ColorManager.gradientOrange,
      ColorManager.splashPurple,
      ColorManager.splashViolet,
      ColorManager.splashCoral,
      ColorManager.homeOrange,
      ColorManager.errorOrange,
      ColorManager.scannerPinkLight,
      ColorManager.centerGraphicPurple,
      ColorManager.noInternetOrange,
      ColorManager.cardBackground,
      ColorManager.lavender,
      ColorManager.spotifyGreen,
      ColorManager.cyanAccent,
      ColorManager.overlayScrim,
    ];

    expect(colors, everyElement(isA<Color>()));
  });

  test('primary converte hex de 6 dígitos para opacidade total', () {
    expect(ColorManager.primary, const Color(0xFF2CCBF5));
  });

  test('overlayScrim aplica alpha 0.5 sobre o preto', () {
    expect(ColorManager.overlayScrim.a, closeTo(0.5, 0.01));
  });

  test('HexColor.fromHex aceita hex com 8 dígitos (com alpha explícito)', () {
    final color = HexColor.fromHex('#802CCBF5');

    expect(color, const Color(0x802CCBF5));
  });
}
