// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../resource/color_manager.dart';

class CenterGraphic extends StatelessWidget {
  const CenterGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: 256,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.002),
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: ColorManager.centerGraphicPurple),
        boxShadow: [
          BoxShadow(
            color: ColorManager.centerGraphicPurple,
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.cardBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.graphic_eq, size: 70),
      ),
    );
  }
}
