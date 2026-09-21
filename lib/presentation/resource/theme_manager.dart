// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import 'color_manager.dart';
import 'font_manager.dart';

ThemeData getApplicationTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
    primary: ColorManager.primary,
    secondary: ColorManager.secondary,
    error: ColorManager.warning,
    surface: ColorManager.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ColorManager.black,
    canvasColor: ColorManager.black,
    fontFamily: FontConstants.fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: ColorManager.black,
      foregroundColor: ColorManager.white,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: ColorManager.white),
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontWeight: FontWeightManager.semiBold,
        fontSize: FontSize.s32,
        color: ColorManager.white,
      ),
      titleLarge: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontWeight: FontWeightManager.bold,
        fontSize: FontSize.s24,
        color: ColorManager.white,
      ),
      titleMedium: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontWeight: FontWeightManager.semiBold,
        fontSize: FontSize.s20,
        color: ColorManager.white,
      ),
      bodyLarge: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontWeight: FontWeightManager.regular,
        fontSize: FontSize.s16,
        color: ColorManager.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: FontConstants.fontFamily,
        fontWeight: FontWeightManager.regular,
        fontSize: FontSize.s14,
        color: ColorManager.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorManager.primary,
        foregroundColor: ColorManager.black,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ColorManager.yellowLink),
    ),
  );
}
