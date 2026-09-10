import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Registra um erro não fatal no Crashlytics sem deixar uma falha do próprio
/// Crashlytics (ex.: Firebase não inicializado, como em `flutter test`)
/// mascarar o erro original que estava sendo tratado.
void reportNonFatalError(
  Object error,
  StackTrace stackTrace, {
  Iterable<String>? information,
}) {
  try {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: false,
      information: information?.toList() ?? const [],
    );
  } catch (_) {
    // Silencioso de propósito — logging nunca deve mascarar o erro original.
  }
}
