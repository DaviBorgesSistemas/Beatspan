// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../resource/color_manager.dart';
import '../../routes_manager.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geral',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorManager.textMuted,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.rulesRoute);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: ColorManager.cardBackground,
              border: Border.all(
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Como Jogar',
                  style: TextStyle(fontSize: 18, color: ColorManager.textLight),
                ),
                Icon(Icons.link, color: ColorManager.textLight),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.faqRoute);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: ColorManager.cardBackground,
              border: Border.all(
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perguntas frequentes',
                  style: TextStyle(fontSize: 18, color: ColorManager.textLight),
                ),
                Icon(Icons.link, color: ColorManager.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
