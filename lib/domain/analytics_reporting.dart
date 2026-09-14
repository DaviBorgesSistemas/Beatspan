// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:firebase_analytics/firebase_analytics.dart';

/// Nomes de evento do funil de escaneamento→reprodução (`OPS-004`).
///
/// Mantidos como constantes (em vez de um enum) porque `FirebaseAnalytics`
/// já valida nome/parâmetros de evento em runtime — um enum só duplicaria
/// essa validação sem ganho.
class AnalyticsEvent {
  static const qrScanned = 'qr_scanned';
  static const qrInvalid = 'qr_invalid';
  static const musicaLookupFailed = 'musica_lookup_failed';
  static const playbackStarted = 'playback_started';
  static const playbackFailed = 'playback_failed';
  static const itunesFallbackUsed = 'itunes_fallback_used';
}

/// Fonte de reprodução usada em [AnalyticsEvent.playbackStarted]. Não
/// distingue prévia via Spotify de prévia via fallback iTunes — essa
/// distinção é reportada separadamente em [AnalyticsEvent.itunesFallbackUsed].
class PlaybackSource {
  static const spotifyFull = 'spotify_full';
  static const spotifyPreview = 'spotify_preview';
}

/// Registra um evento de analytics de produto sem deixar uma falha do
/// próprio Firebase Analytics (ex.: não inicializado, como em `flutter
/// test`) propagar para o fluxo do app — mesmo padrão de
/// `reportNonFatalError` em `error_reporting.dart`.
void reportAnalyticsEvent(String name, [Map<String, Object>? parameters]) {
  try {
    FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  } catch (_) {
    // Silencioso de propósito — analytics nunca deve mascarar/interromper o
    // fluxo real do app.
  }
}

/// Liga/desliga a coleta do Firebase Analytics conforme o consentimento de
/// privacidade do usuário (LGPD). Mesmo tratamento de falha silenciosa de
/// [reportAnalyticsEvent] — não pode quebrar o fluxo de consentimento nem
/// `flutter test` (Firebase não inicializado).
Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  } catch (_) {
    // Silencioso de propósito — mesma justificativa de reportAnalyticsEvent.
  }
}
