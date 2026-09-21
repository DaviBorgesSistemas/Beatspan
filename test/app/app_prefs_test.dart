import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/domain/enum/settings_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences appPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());
  });

  test(
    'plano retorna null quando nunca foi definido e persiste quando definido',
    () async {
      expect(await appPreferences.getAppPlanType(), isNull);

      await appPreferences.setAppPlanType(PlanType.premium);

      expect(await appPreferences.getAppPlanType(), PlanType.premium);
    },
  );

  test(
    'vire o telefone é false por padrão e persiste quando alterado',
    () async {
      expect(appPreferences.getTurnPhoneEnabled(), isFalse);

      await appPreferences.setTurnPhoneEnabled(true);

      expect(appPreferences.getTurnPhoneEnabled(), isTrue);
    },
  );

  test(
    'modo de vire o telefone é giroscópio por padrão e persiste quando alterado',
    () async {
      expect(appPreferences.getTurnPhoneMode(), TurnPhoneMode.gyroscope);

      await appPreferences.setTurnPhoneMode(TurnPhoneMode.countdown);

      expect(appPreferences.getTurnPhoneMode(), TurnPhoneMode.countdown);
    },
  );

  test(
    'modo de jogo é preview por padrão, hasGameMode reflete se já foi definido',
    () async {
      expect(appPreferences.hasGameMode(), isFalse);
      expect(appPreferences.getGameMode(), GameModeType.preview);

      await appPreferences.setGameMode(GameModeType.fullTrack);

      expect(appPreferences.hasGameMode(), isTrue);
      expect(appPreferences.getGameMode(), GameModeType.fullTrack);
    },
  );

  test(
    'consentimento do Spotify é false por padrão e persiste quando aceito',
    () async {
      expect(appPreferences.hasAcceptedSpotifyConsent(), isFalse);

      await appPreferences.setSpotifyConsentAccepted(true);

      expect(appPreferences.hasAcceptedSpotifyConsent(), isTrue);
    },
  );

  test(
    'consentimento de privacidade é false por padrão e persiste quando aceito',
    () async {
      expect(appPreferences.hasAcceptedPrivacyConsent(), isFalse);

      await appPreferences.setPrivacyConsentAccepted(true);

      expect(appPreferences.hasAcceptedPrivacyConsent(), isTrue);
    },
  );

  test(
    'consentimento de analytics é false (opt-in) por padrão e persiste quando alterado',
    () async {
      expect(appPreferences.getAnalyticsConsentEnabled(), isFalse);

      await appPreferences.setAnalyticsConsentEnabled(true);

      expect(appPreferences.getAnalyticsConsentEnabled(), isTrue);
    },
  );
}
