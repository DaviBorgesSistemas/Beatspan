import 'package:flutter/material.dart';

import '../../domain/enum/flow_state.dart';
import '../../domain/exceptions/spotify_consent_exception.dart';
import '../../app/app_prefs.dart';
import '../resource/color_manager.dart';
import '../resource/font_manager.dart';
import '../resource/style_manager.dart';
import '../routes_manager.dart';
import 'connect_spotify_premium_view_model.dart';
import 'widgets/spotify_connect_graphic.dart';
import 'widgets/spotify_consent_dialog.dart';

class ChangeSpotifyView extends StatefulWidget {
  final AppPreferences appPreferences;
  final ConnectSpotifyPremiumViewModel viewModel;

  const ChangeSpotifyView({
    super.key,
    required this.appPreferences,
    required this.viewModel,
  });

  @override
  State<ChangeSpotifyView> createState() => _ChangeSpotifyViewState();
}

class _ChangeSpotifyViewState extends State<ChangeSpotifyView> {
  late final ConnectSpotifyPremiumViewModel _viewModel = widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.state.addListener(() {
      if (mounted) {
        if (_viewModel.state.value == FlowState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _viewModel.errorMessage.value ?? 'Erro desconhecido',
                style: getMediumStyle(
                  color: ColorManager.white,
                  fontSize: FontSize.s14,
                ),
              ),
              backgroundColor: ColorManager.warning,
            ),
          );
        } else if (_viewModel.state.value == FlowState.success) {
          Navigator.of(context).pushReplacementNamed(Routes.homeRoute);
        }
      }
    });
  }

  Future<void> _connectSpotify(BuildContext context) async {
    try {
      await _viewModel.connect();
    } on SpotifyConsentRequiredException {
      if (!context.mounted) return;
      final appPreferences = widget.appPreferences;
      final accepted = await SpotifyConsentDialog.show(context);
      if (!accepted) return;
      await appPreferences.setSpotifyConsentAccepted(true);
      if (!context.mounted) return;
      await _viewModel.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorManager.bagroundColor,
          leading: Semantics(
            button: true,
            label: 'Voltar',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).pop(),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1,
                      color: ColorManager.lavender.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 8),
                  Text(
                    'CONEXÃO SPOTIFY PREMIUM',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorManager.textLight,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Se você tem uma conta Spotify Premium, conecte o app ao Beatspan. Certifique-se de que o app está instalado no dispositivo.',
                    style: TextStyle(
                      color: ColorManager.textLight.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: ExcludeSemantics(child: SpotifyConnectGraphic()),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Ligar com Spotify',
                      excludeSemantics: true,
                      onTap: () => _connectSpotify(context),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              ColorManager.gradientPurple,
                              ColorManager.gradientPink,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () => _connectSpotify(context),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.graphic_eq),
                                  SizedBox(width: 8),
                                  Text(
                                    'LIGAR COM SPOTIFY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Não tenho Spotify Premium',
                      excludeSemantics: true,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(Routes.changeSpotifyFreeRoute),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            width: 2,
                            color: ColorManager.centerGraphicPurple,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(Routes.changeSpotifyFreeRoute);
                            },
                            child: Center(
                              child: Text(
                                'NÃO TENHO SPOTIFY PREMIUM',
                                style: TextStyle(
                                  color: ColorManager.centerGraphicPurple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
