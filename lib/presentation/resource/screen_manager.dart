// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

extension SizeExtensions on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);
  EdgeInsets get _padding => MediaQuery.paddingOf(this);

  double get screenWidth => math.max(0.0, _size.width);
  double get screenHeight => math.max(0.0, _size.height);
  double get screenShortestSide => math.max(0.0, _size.shortestSide);
  double get screenLongestSide => math.max(0.0, _size.longestSide);
  double get appbarHeight => _padding.top + kToolbarHeight;

  double percentWidth(double p) => math.max(0.0, screenWidth * p);
  double percentHeight(double p) => math.max(0.0, screenHeight * p);

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
