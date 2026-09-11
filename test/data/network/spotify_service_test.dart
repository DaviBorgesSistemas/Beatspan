import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/domain/exceptions/spotify_consent_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferences appPreferences;
  late SpotifyService service;

  Future<void> buildService({required bool consentAccepted}) async {
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());
    if (consentAccepted) {
      await appPreferences.setSpotifyConsentAccepted(true);
    }
    service = SpotifyService(
      clientId: 'client-id',
      redirectUrl: 'beatspan://auth',
      appPreferences: appPreferences,
    );
  }

  group('sem consentimento aceito', () {
    setUp(() => buildService(consentAccepted: false));

    test('connect() lança SpotifyConsentRequiredException', () {
      expect(
        () => service.connect(),
        throwsA(isA<SpotifyConsentRequiredException>()),
      );
    });

    test('getAccessToken() lança SpotifyConsentRequiredException', () {
      expect(
        () => service.getAccessToken(),
        throwsA(isA<SpotifyConsentRequiredException>()),
      );
    });

    test('authorizeAndConnect() lança SpotifyConsentRequiredException', () {
      expect(
        () => service.authorizeAndConnect(),
        throwsA(isA<SpotifyConsentRequiredException>()),
      );
    });
  });

  group('com consentimento aceito', () {
    setUp(() => buildService(consentAccepted: true));

    // Em `flutter test` (VM, sem host nativo), qualquer chamada que passe da
    // checagem de consentimento e alcance o spotify_sdk cai no canal de
    // plataforma sem handler registrado — MissingPluginException. Isso
    // confirma que o consentimento aceito *libera* a chamada ao SDK, em vez
    // de bloqueá-la silenciosamente.
    test('connect() tenta alcançar o spotify_sdk (MissingPluginException)', () {
      expect(() => service.connect(), throwsA(isA<MissingPluginException>()));
    });

    test(
      'getAccessToken() tenta alcançar o spotify_sdk (MissingPluginException)',
      () {
        expect(
          () => service.getAccessToken(),
          throwsA(isA<MissingPluginException>()),
        );
      },
    );
  });

  test(
    'disconnect() não exige consentimento e tenta alcançar o spotify_sdk diretamente',
    () async {
      await buildService(consentAccepted: false);

      expect(
        () => service.disconnect(),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );
}
