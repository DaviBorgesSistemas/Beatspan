import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/presentation/privacy_consent/privacy_consent_view.dart';
import 'package:beatspan/presentation/routes_manager.dart';
import 'package:beatspan/presentation/settings/widget/gradient_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences appPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());
  });

  Widget buildSubject() {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == Routes.firstTimeRoute) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('FIRST_TIME_STUB')),
            settings: settings,
          );
        }
        return null;
      },
      home: PrivacyConsentView(appPreferences: appPreferences),
    );
  }

  testWidgets(
    'mostra título, links legais e o switch de analytics desligado por padrão',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('PRIVACIDADE E TERMOS'), findsOneWidget);
      expect(
        find.text('Leia a Política de Privacidade completa'),
        findsOneWidget,
      );
      expect(find.text('Leia os Termos de Uso completos'), findsOneWidget);
      expect(find.text('Compartilhar dados de uso anônimos'), findsOneWidget);
    },
  );

  testWidgets(
    'aceitar sem ligar o switch persiste consentimento de privacidade aceito e analytics desligado, navegando para o first-time',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('ACEITAR E CONTINUAR'));
      await tester.pumpAndSettle();

      expect(appPreferences.hasAcceptedPrivacyConsent(), isTrue);
      expect(appPreferences.getAnalyticsConsentEnabled(), isFalse);
      expect(find.text('FIRST_TIME_STUB'), findsOneWidget);
    },
  );

  testWidgets(
    'ligar o switch de analytics antes de aceitar persiste o consentimento como true',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byType(GradientSwitch));

      await tester.tap(find.text('ACEITAR E CONTINUAR'));
      await tester.pumpAndSettle();

      expect(appPreferences.getAnalyticsConsentEnabled(), isTrue);
    },
  );
}
