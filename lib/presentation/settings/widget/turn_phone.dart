// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../../app/app_prefs.dart';
import '../../../domain/enum/settings_enum.dart';
import '../../resource/color_manager.dart';
import 'card_border.dart';
import 'gradient_switch.dart';

class TurnPhone extends StatefulWidget {
  const TurnPhone({
    super.key,
    required this.appPreferences,
    this.isTurnPhoneEnabled,
  });

  final AppPreferences appPreferences;
  final ValueNotifier<bool>? isTurnPhoneEnabled;

  @override
  State<TurnPhone> createState() => _TurnPhoneState();
}

class _TurnPhoneState extends State<TurnPhone> {
  late final AppPreferences _appPreferences = widget.appPreferences;

  late final ValueNotifier<bool> isTurnPhoneEnabled =
      widget.isTurnPhoneEnabled ??
      ValueNotifier<bool>(_appPreferences.getTurnPhoneEnabled());
  late final ValueNotifier<int> turnPhoneMode = ValueNotifier<int>(
    _appPreferences.getTurnPhoneMode() == TurnPhoneMode.gyroscope ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    isTurnPhoneEnabled.addListener(_onEnabledChanged);
    turnPhoneMode.addListener(_persistMode);
  }

  void _onEnabledChanged() {
    _persistEnabled();
    if (isTurnPhoneEnabled.value) {
      turnPhoneMode.value = 0;
    }
  }

  @override
  void dispose() {
    isTurnPhoneEnabled.removeListener(_onEnabledChanged);
    turnPhoneMode.removeListener(_persistMode);
    super.dispose();
  }

  void _persistEnabled() {
    _appPreferences.setTurnPhoneEnabled(isTurnPhoneEnabled.value);
  }

  void _persistMode() {
    _appPreferences.setTurnPhoneMode(
      turnPhoneMode.value == 0
          ? TurnPhoneMode.gyroscope
          : TurnPhoneMode.countdown,
    );
  }

  Widget buttonRadio(bool selected) {
    return Container(
      width: 24,
      height: 24,

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: ColorManager.lavender.withValues(alpha: 0.50),
        ),
      ),
      child: selected
          ? Container(
              margin: EdgeInsets.all(4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: kSelectedGradient,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([isTurnPhoneEnabled, turnPhoneMode]),
      builder: (_, __) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorManager.cardBackground,
                border: Border.all(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                borderRadius: isTurnPhoneEnabled.value
                    ? BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      )
                    : BorderRadius.all(Radius.circular(12.0)),
              ),
              child: Row(
                children: [
                  GradientSwitch(
                    value: isTurnPhoneEnabled.value,
                    onChanged: (value) {
                      isTurnPhoneEnabled.value = value;
                    },
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usar Vire o Telefone',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: ColorManager.textLight,
                          ),
                        ),
                        Text(
                          'Após escanear uma carta, coloque o dispositivo virado para baixo. Isso oculta detalhes da faixa e mantém o jogo justo.',
                          style: TextStyle(color: ColorManager.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isTurnPhoneEnabled.value,
              child: Column(
                children: [
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      turnPhoneMode.value = 0;
                    },
                    child: CardBorder(
                      selected: turnPhoneMode.value == 0,
                      borderRadius: BorderRadius.all(Radius.zero),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            buttonRadio(turnPhoneMode.value == 0),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usar Giroscópio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: ColorManager.textLight,
                                    ),
                                  ),
                                  Text(
                                    'A faixa começa a tocar quando você vira o telefone.',
                                    style: TextStyle(
                                      color: ColorManager.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      turnPhoneMode.value = 1;
                    },
                    child: CardBorder(
                      selected: turnPhoneMode.value == 1,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.0),
                        bottomRight: Radius.circular(12.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            buttonRadio(turnPhoneMode.value == 1),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usar Contagem Regressiva',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: ColorManager.textLight,
                                    ),
                                  ),
                                  Text(
                                    'A faixa começa a tocar quando você vira o telefone.',
                                    style: TextStyle(
                                      color: ColorManager.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
