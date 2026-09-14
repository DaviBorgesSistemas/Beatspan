// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_prefs.dart';
import '../../../domain/analytics_reporting.dart';
import '../../resource/color_manager.dart';
import '../../resource/legal_links.dart';
import 'gradient_switch.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key, required this.appPreferences});

  final AppPreferences appPreferences;

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  late final AppPreferences _appPreferences = widget.appPreferences;
  late bool _analyticsEnabled = _appPreferences.getAnalyticsConsentEnabled();

  Future<void> _onAnalyticsChanged(bool value) async {
    setState(() => _analyticsEnabled = value);
    await _appPreferences.setAnalyticsConsentEnabled(value);
    await setAnalyticsCollectionEnabled(value);
  }

  Future<void> _openLink(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacidade',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorManager.textMuted,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: ColorManager.cardBackground,
            border: Border.all(
              width: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              GradientSwitch(
                value: _analyticsEnabled,
                onChanged: _onAnalyticsChanged,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhar dados de uso anônimos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.textLight,
                      ),
                    ),
                    Text(
                      'Opcional, via Firebase Analytics.',
                      style: TextStyle(color: ColorManager.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openLink(privacyPolicyUrl),
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
                  'Política de Privacidade',
                  style: TextStyle(fontSize: 18, color: ColorManager.textLight),
                ),
                Icon(Icons.link, color: ColorManager.textLight),
              ],
            ),
          ),
        ),
        SizedBox(height: 1),
        GestureDetector(
          onTap: () => _openLink(termsOfUseUrl),
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
                  'Termos de Uso',
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
