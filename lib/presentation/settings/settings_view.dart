import 'package:flutter/material.dart';

import '../../app/app_prefs.dart';
import '../../domain/enum/settings_enum.dart';
import '../../domain/exceptions/spotify_consent_exception.dart';
import '../change_spotify/connect_spotify_premium_view_model.dart';
import '../change_spotify/widgets/spotify_consent_dialog.dart';
import 'widget/game_mode.dart';
import 'widget/general_settings.dart';
import 'widget/turn_phone.dart';

class SettingsView extends StatefulWidget {
  final AppPreferences appPreferences;
  final ConnectSpotifyPremiumViewModel viewModel;

  const SettingsView({
    super.key,
    required this.appPreferences,
    required this.viewModel,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final AppPreferences _appPreferences = widget.appPreferences;
  late final ConnectSpotifyPremiumViewModel _viewModel = widget.viewModel;
  late final ValueNotifier<bool> _isTurnPhoneEnabled = ValueNotifier<bool>(
    _appPreferences.getTurnPhoneEnabled(),
  );
  PlanType? _planType;

  @override
  void initState() {
    super.initState();
    _loadPlanType();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _isTurnPhoneEnabled.dispose();
    super.dispose();
  }

  Future<void> _loadPlanType() async {
    final plan = await _appPreferences.getAppPlanType();
    if (!mounted) return;
    setState(() => _planType = plan);
  }

  Future<void> _connectSpotify() async {
    try {
      await _viewModel.connect();
    } on SpotifyConsentRequiredException {
      if (!mounted) return;
      final accepted = await SpotifyConsentDialog.show(context);
      if (!accepted) return;
      await _appPreferences.setSpotifyConsentAccepted(true);
      if (!mounted) return;
      await _viewModel.connect();
    }
    await _loadPlanType();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _planType == PlanType.premium;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0XFF08050D),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Configurações',
            style: TextStyle(
              color: Color(0XFFCDBDFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                GeneralSettings(),
                SizedBox(height: 32),
                Text(
                  'Configurações do spotify',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0XFFA9A2B5),
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: isPremium ? null : _connectSpotify,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0XFF110B1A),
                      border: Border.all(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              color: Color(0XFF1DB954),
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Spotify',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0XFF1DB954),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isPremium ? 'PREMIUM' : 'FREE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0XFF1DB954),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                GameMode(
                  appPreferences: _appPreferences,
                  isPremium: isPremium,
                  onTap: (value) {
                    _isTurnPhoneEnabled.value = value == 1;
                  },
                ),
                SizedBox(height: 32),
                TurnPhone(
                  appPreferences: _appPreferences,
                  isTurnPhoneEnabled: _isTurnPhoneEnabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
