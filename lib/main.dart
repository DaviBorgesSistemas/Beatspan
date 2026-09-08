import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/app.dart';
import 'app/di.dart';
import 'firebase_options.dart';

void main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  systemChromeConfigure();

  await runZonedGuarded(
    () async {
      await dotenv.load(fileName: '.env');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _setupCrashlytics();
      await initAppModule();
      runApp(MyApp());
      FlutterNativeSplash.remove();
    },
    (error, stackTrace) {
      // Erros assíncronos não capturados (fora da árvore de widgets),
      // ex.: exceções em Future/Stream sem try/catch.
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

/// Encaminha erros de framework (ex.: exceções durante build/layout de
/// widgets) e erros não tratados do runtime (ex.: em isolates) para o
/// Crashlytics. Desabilitado em debug para não poluir o dashboard com
/// erros de desenvolvimento local.
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
