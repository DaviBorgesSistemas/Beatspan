import 'dart:async';

import 'package:flutter/material.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/enum/settings_enum.dart';
import '../resource/color_manager.dart';
import '../resource/screen_manager.dart';
import '../routes_manager.dart';

class TurnPhoneReadyView extends StatefulWidget {
  const TurnPhoneReadyView({
    super.key,
    required this.mode,
    required this.onReady,
  });

  final TurnPhoneMode mode;
  final VoidCallback onReady;

  static final _background = ColorManager.backgroundColor;

  @override
  State<TurnPhoneReadyView> createState() => _TurnPhoneReadyViewState();
}

class _TurnPhoneReadyViewState extends State<TurnPhoneReadyView>
    with WidgetsBindingObserver {
  static const _faceDownThreshold = -8.5;
  static const _proximityFallbackDelay = Duration(milliseconds: 1500);

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<int>? _proximitySubscription;
  Timer? _countdownTimer;
  Timer? _proximityFallbackTimer;
  int _secondsLeft = 3;
  bool _completed = false;
  bool _isFaceDown = false;
  bool _isNear = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    switch (widget.mode) {
      case TurnPhoneMode.gyroscope:
        _listenForFaceDown();
        _listenForProximity();
        break;
      case TurnPhoneMode.countdown:
        _startCountdown();
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_completed || widget.mode != TurnPhoneMode.gyroscope) return;
    if (state == AppLifecycleState.resumed) {
      _accelerometerSubscription?.cancel();
      _proximitySubscription?.cancel();
      _proximityFallbackTimer?.cancel();
      _isFaceDown = false;
      _isNear = false;
      _listenForFaceDown();
      _listenForProximity();
    }
  }

  void _listenForFaceDown() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final wasFaceDown = _isFaceDown;
      _isFaceDown = event.z < _faceDownThreshold;
      if (_isFaceDown && !wasFaceDown) {
        _scheduleProximityFallback();
      } else if (!_isFaceDown) {
        _proximityFallbackTimer?.cancel();
      }
      _checkGyroscopeReady();
    });
  }

  void _listenForProximity() {
    _proximitySubscription = ProximitySensor.events.listen((event) {
      _isNear = event > 0;
      _checkGyroscopeReady();
    });
  }

  void _scheduleProximityFallback() {
    _proximityFallbackTimer?.cancel();
    _proximityFallbackTimer = Timer(_proximityFallbackDelay, () {
      if (!_isFaceDown || _isNear) return;
      _isNear = true;
      _checkGyroscopeReady();
    });
  }

  void _checkGyroscopeReady() {
    if (_isFaceDown && _isNear) {
      _complete();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        _complete();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    _accelerometerSubscription?.cancel();
    _proximitySubscription?.cancel();
    _countdownTimer?.cancel();
    _proximityFallbackTimer?.cancel();
    widget.onReady();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSubscription?.cancel();
    _proximitySubscription?.cancel();
    _countdownTimer?.cancel();
    _proximityFallbackTimer?.cancel();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(Routes.homeRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToHome();
      },
      child: Scaffold(
        backgroundColor: TurnPhoneReadyView._background,
        body: SafeArea(
          child: Center(
            child: widget.mode == TurnPhoneMode.gyroscope
                ? _buildGyroscopeContent()
                : _buildCountdownContent(),
          ),
        ),
      ),
    );
  }

  Widget _modeBadge() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: 32),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Modo Jogo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: ColorManager.textMuted,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pre-escuta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneIllustration() {
    return SizedBox(
      width: context.screenWidth,
      child: Image.asset('assets/images/neon-phone-music-waves.png'),
    );
  }

  Widget _gradientTitle(String text) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColorManager.gradientPink, ColorManager.gradientPurple],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildGyroscopeContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          _modeBadge(),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _phoneIllustration(),
                SizedBox(height: 64),
                _gradientTitle('VIRE O TELEFONE'),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Coloque o dispositivo virado para baixo para começar a música.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          _modeBadge(),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _phoneIllustration(),
                SizedBox(height: 64),
                _gradientTitle('VIRE O TELEFONE'),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'A música começará em...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textMuted),
                  ),
                ),
                SizedBox(height: 12),
                _countdownBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownBadge() {
    return Center(
      child: Text(
        '$_secondsLeft',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
