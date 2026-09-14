import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/presentation/settings/widget/gradient_switch.dart';
import 'package:beatspan/presentation/settings/widget/privacy_settings.dart';
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
      home: Scaffold(body: PrivacySettings(appPreferences: appPreferences)),
    );
  }

  testWidgets(
    'mostra o switch desligado por padrão e os links de Política de Privacidade e Termos de Uso',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Política de Privacidade'), findsOneWidget);
      expect(find.text('Termos de Uso'), findsOneWidget);

      final gradientSwitch = tester.widget<GradientSwitch>(
        find.byType(GradientSwitch),
      );
      expect(gradientSwitch.value, isFalse);
    },
  );

  testWidgets('tocar no switch liga e persiste o consentimento de analytics', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(GradientSwitch));
    await tester.pump();

    expect(appPreferences.getAnalyticsConsentEnabled(), isTrue);

    final gradientSwitch = tester.widget<GradientSwitch>(
      find.byType(GradientSwitch),
    );
    expect(gradientSwitch.value, isTrue);
  });
}
