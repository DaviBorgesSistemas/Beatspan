// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../resource/color_manager.dart';
import '../share/widgets/next_card_button.dart';

class GameErrorView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GameErrorView({
    super.key,
    this.title = 'OPS, CÓDIGO QR\nDESCONHECIDO!',
    this.message =
        'Você escaneou um QR code que não pertence a uma carta Beatspan. Tente outra carta do jogo!',
    this.icon = Icons.qr_code_scanner_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: Colors.white, size: 48),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              NextCardButton(
                expandWidth: true,
                gradientColors: [
                  ColorManager.accentPink,
                  ColorManager.errorOrange,
                ],
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.accentPink.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
