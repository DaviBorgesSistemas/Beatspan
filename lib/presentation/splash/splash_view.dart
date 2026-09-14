// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import '../../app/app_prefs.dart';
import '../resource/assets_manager.dart';
import '../resource/color_manager.dart';
import '../resource/screen_manager.dart';
import '../routes_manager.dart';
import 'widgets/loading_dots.dart';

class SplashView extends StatefulWidget {
  final AppPreferences appPreferences;

  const SplashView({super.key, required this.appPreferences});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AppPreferences _appPreferences = widget.appPreferences;
  late final AnimationController _c;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _nameOffset;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _taglineOffset;
  late final Animation<double> _taglineOpacity;

  late final Animation<double> _dotsExitOpacity;
  late final Animation<double> _taglineExitOpacity;
  late final Animation<double> _nameExitOpacity;
  late final Animation<double> _logoExitScale;
  late final Animation<Offset> _logoExitOffset;
  late final Animation<double> _logoExitOpacity;

  static const totalMs = 3700;

  bool _didNavigate = false;

  void _goNext() async {
    final NavigatorState navigator = Navigator.of(context);

    if (_didNavigate || !mounted) return;
    _didNavigate = true;
    if (!_appPreferences.hasAcceptedPrivacyConsent()) {
      navigator.pushReplacementNamed(Routes.privacyConsentRoute);
      return;
    }
    _appPreferences.getAppPlanType().then((plan) {
      if (plan != null) {
        navigator.pushReplacementNamed(Routes.homeRoute);
      } else {
        navigator.pushReplacementNamed(Routes.firstTimeRoute);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: totalMs),
    );

    _logoScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.19, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.10)));

    _nameOffset = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.135, 0.30, curve: Curves.easeOut),
      ),
    );
    _nameOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.135, 0.30)));

    _taglineOffset = Tween(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _c,
            curve: const Interval(0.216, 0.38, curve: Curves.easeOut),
          ),
        );
    _taglineOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.216, 0.38)));

    _dotsExitOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.54, 0.635, curve: Curves.easeIn),
      ),
    );
    _taglineExitOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.594, 0.689, curve: Curves.easeIn),
      ),
    );
    _nameExitOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.676, 0.770, curve: Curves.easeIn),
      ),
    );
    _logoExitScale = Tween(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.865, 1.0, curve: Curves.easeIn),
      ),
    );
    _logoExitOffset = Tween(begin: Offset.zero, end: const Offset(0, -0.4))
        .animate(
          CurvedAnimation(
            parent: _c,
            curve: const Interval(0.865, 1.0, curve: Curves.easeIn),
          ),
        );
    _logoExitOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    _c.forward().whenComplete(_goNext);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: _logoExitOffset.value * 100,
                      child: Transform.scale(
                        scale: _logoScale.value * _logoExitScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value * _logoExitOpacity.value,
                          child: SizedBox(
                            width: context.screenShortestSide * 0.476,
                            child: Image.asset(ImageAssets.splashLogo),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: _nameOpacity.value * _nameExitOpacity.value,
                      child: Transform.translate(
                        offset: _nameOffset.value * 40,
                        child: SizedBox(
                          width: context.screenShortestSide * 0.78,
                          child: Image.asset(ImageAssets.splashWordmark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity:
                          _taglineOpacity.value * _taglineExitOpacity.value,
                      child: Transform.translate(
                        offset: _taglineOffset.value * 40,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              ColorManager.splashPurple,
                              ColorManager.gradientMagenta,
                              ColorManager.gradientOrange,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'MUSIC. FAITH. CONNECT.',
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 3.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 120,
                child: Column(
                  children: [
                    Opacity(
                      opacity: _dotsExitOpacity.value,
                      child: LoadingDots(controller: _c),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'CARREGANDO...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4.0,
                        color: ColorManager.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
