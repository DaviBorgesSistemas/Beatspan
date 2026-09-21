// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../resource/color_manager.dart';
import 'card_border.dart';

class GradientSwitch extends StatelessWidget {
  const GradientSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _width = 52.0;
  static const _height = 32.0;
  static const _thumbSize = 24.0;
  static const _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          gradient: value ? kSelectedGradient : null,
          color: value ? null : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: _thumbSize,
            height: _thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : ColorManager.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
