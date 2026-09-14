import 'package:flutter/material.dart';

class ColorManager {
  static Color primary = HexColor.fromHex('#2CCBF5');
  static Color secondary = HexColor.fromHex('#624595');
  static Color ternary = HexColor.fromHex('#29107D');
  static Color ternaryLight = HexColor.fromHex('#5E1B88');
  static Color quaternary = HexColor.fromHex('#DE436B');
  static Color quaternaryLight = HexColor.fromHex('#ED8E4C');

  static Color black = HexColor.fromHex('#000000');
  static Color white = HexColor.fromHex('#FFFFFF');
  static Color backgroundColor = HexColor.fromHex('#08050D');

  static Color yellowLink = HexColor.fromHex('#FFC850');
  static Color warning = HexColor.fromHex('#E32636');

  static Color gradientPurple = HexColor.fromHex('#6C2BFF');
  static Color gradientPink = HexColor.fromHex('#FF469E');
  static Color accentPink = HexColor.fromHex('#FF1B8D');
  static Color textLight = HexColor.fromHex('#F8F7FC');
  static Color textMuted = HexColor.fromHex('#A9A2B5');
  static Color gradientMagenta = HexColor.fromHex('#E84BC7');
  static Color gradientOrange = HexColor.fromHex('#FF8A3D');
  static Color splashPurple = HexColor.fromHex('#6C5CE7');
  static Color splashViolet = HexColor.fromHex('#9C4FE0');
  static Color splashCoral = HexColor.fromHex('#FF6F5C');
  static Color homeOrange = HexColor.fromHex('#FF7A1A');
  static Color errorOrange = HexColor.fromHex('#FF5A1B');
  static Color scannerPinkLight = HexColor.fromHex('#FFB0CB');
  static Color centerGraphicPurple = HexColor.fromHex('#6824FC');
  static Color noInternetOrange = HexColor.fromHex('#FF8A00');
  static Color cardBackground = HexColor.fromHex('#110B1A');
  static Color lavender = HexColor.fromHex('#CDBDFF');
  static Color spotifyGreen = HexColor.fromHex('#1DB954');
  static Color cyanAccent = HexColor.fromHex('#06B6D4');
  static Color overlayScrim = black.withValues(alpha: 0.5);
}

extension HexColor on Color {
  static Color fromHex(String hexColorString) {
    hexColorString = hexColorString.replaceAll('#', '');
    if (hexColorString.length == 6) {
      hexColorString = 'FF$hexColorString';
    }
    return Color(int.parse(hexColorString, radix: 16));
  }
}
