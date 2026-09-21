// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/app.dart';
import 'app/app_prefs.dart';
import 'app/di.dart';
import 'domain/analytics_reporting.dart';
import 'firebase_options.dart';

void main() async {
  await runZonedGuarded(
    () async {
      final WidgetsBinding widgetsBinding =
          WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      systemChromeConfigure();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _setupCrashlytics();
      await initAppModule();
      await _syncAnalyticsConsent();
      runApp(const MyApp());
      FlutterNativeSplash.remove();
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

Future<void> _syncAnalyticsConsent() async {
  final appPreferences = instance<AppPreferences>();
  final collectionEnabled =
      appPreferences.hasAcceptedPrivacyConsent() &&
      appPreferences.getAnalyticsConsentEnabled();
  await setAnalyticsCollectionEnabled(collectionEnabled);
}

Future<void> _setupCrashlytics() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };
}
