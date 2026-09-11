import 'package:flutter/material.dart';

class NextCardButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool expandWidth;
  final EdgeInsetsGeometry margin;
  final List<Color> gradientColors;
  final Color textColor;
  final List<BoxShadow>? boxShadow;

  const NextCardButton({
    super.key,
    this.onTap,
    this.expandWidth = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 24),
    this.gradientColors = const [Color(0xFF6C2BFF), Color(0xFFFF469E)],
    this.textColor = Colors.white,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onTap ?? () => Navigator.of(context).pop();

    return Semantics(
      button: true,
      label: 'Próxima carta',
      excludeSemantics: true,
      onTap: effectiveOnTap,
      child: Container(
        width: expandWidth ? double.infinity : null,
        margin: expandWidth ? EdgeInsets.zero : margin,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: boxShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: effectiveOnTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PRÓXIMA CARTA',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: textColor, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
