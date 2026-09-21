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
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      _PrivacyGraphic(),
                      const SizedBox(height: 24),
                      Text(
                        'PRIVACIDADE E TERMOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: ColorManager.textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Para funcionar, o BEATSPAN consulta o catálogo de '
                        'músicas no Firestore e conecta com sua conta '
                        'Spotify para tocar as faixas das cartas. Também '
                        'usamos o Firebase Crashlytics para diagnosticar '
                        'erros e manter o app estável.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.textLight.withValues(alpha: 0.70),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _LegalLink(
                            label: 'Política de Privacidade',
                            onTap: () => _openLink(privacyPolicyUrl),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: ColorManager.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _LegalLink(
                            label: 'Termos de Uso',
                            onTap: () => _openLink(termsOfUseUrl),
                          ),
                        ],
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
                                  const SizedBox(height: 2),
                                  Text(
                                    'Opcional. Ajuda a melhorar o app via '
                                    'Firebase Analytics. Pode ser alterado '
                                    'depois em Configurações.',
                                    style: TextStyle(
                                      color: ColorManager.textMuted,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ), 
              Padding(
                padding: const EdgeInsets.all(24),
                child: Semantics(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Leia $label',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: ColorManager.yellowLink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _PrivacyGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: ColorManager.gradientPink),
        boxShadow: [
          BoxShadow(
            color: ColorManager.gradientPink,
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.cardBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield_outlined,
          size: 44,
          color: ColorManager.primary,
        ),
      ),
    );
  }
}
