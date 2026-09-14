// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_prefs.dart';
import '../../domain/analytics_reporting.dart';
import '../resource/color_manager.dart';
import '../resource/legal_links.dart';
import '../routes_manager.dart';
import '../settings/widget/gradient_switch.dart';

class PrivacyConsentView extends StatefulWidget {
  final AppPreferences appPreferences;

  const PrivacyConsentView({super.key, required this.appPreferences});

  @override
  State<PrivacyConsentView> createState() => _PrivacyConsentViewState();
}

class _PrivacyConsentViewState extends State<PrivacyConsentView> {
  late final AppPreferences _appPreferences = widget.appPreferences;
  bool _analyticsEnabled = false;

  Future<void> _openLink(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _accept() async {
    await _appPreferences.setPrivacyConsentAccepted(true);
    await _appPreferences.setAnalyticsConsentEnabled(_analyticsEnabled);
    await setAnalyticsCollectionEnabled(_analyticsEnabled);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.firstTimeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: ColorManager.backgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIVACIDADE E TERMOS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: ColorManager.textLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para funcionar, o BEATSPAN consulta o catálogo de músicas '
                  'no Firestore e conecta com sua conta Spotify para tocar as '
                  'faixas das cartas. Também usamos o Firebase Crashlytics '
                  'para diagnosticar erros e manter o app estável.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  link: true,
                  label: 'Leia a Política de Privacidade completa',
                  excludeSemantics: true,
                  onTap: () => _openLink(privacyPolicyUrl),
                  child: GestureDetector(
                    onTap: () => _openLink(privacyPolicyUrl),
                    child: Text(
                      'Leia a Política de Privacidade completa',
                      style: TextStyle(
                        color: ColorManager.yellowLink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  link: true,
                  label: 'Leia os Termos de Uso completos',
                  excludeSemantics: true,
                  onTap: () => _openLink(termsOfUseUrl),
                  child: GestureDetector(
                    onTap: () => _openLink(termsOfUseUrl),
                    child: Text(
                      'Leia os Termos de Uso completos',
                      style: TextStyle(
                        color: ColorManager.yellowLink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
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
                        onChanged: (value) {
                          setState(() => _analyticsEnabled = value);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compartilhar dados de uso anônimos',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: ColorManager.textLight,
                              ),
                            ),
                            Text(
                              'Opcional. Ajuda a melhorar o app via Firebase '
                              'Analytics. Pode ser alterado depois em '
                              'Configurações.',
                              style: TextStyle(color: ColorManager.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: 'Aceitar e continuar',
                  excludeSemantics: true,
                  onTap: _accept,
                  child: Container(
                    height: 56,
                    width: double.infinity,
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
                        onTap: _accept,
                        child: const Center(
                          child: Text(
                            'ACEITAR E CONTINUAR',
                            style: TextStyle(
                              color: Colors.white,
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
        ),
      ),
    );
  }
}
