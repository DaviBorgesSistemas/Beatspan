import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/domain/enum/flow_state.dart';
import 'package:beatspan/presentation/change_spotify/connect_spotify_premium_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSpotifyService extends Mock implements SpotifyService {}

void main() {
  late _MockSpotifyService spotifyService;
  late AppPreferences appPreferences;
  late ConnectSpotifyPremiumViewModel viewModel;

  setUp(() async {
    spotifyService = _MockSpotifyService();
    SharedPreferences.setMockInitialValues({});
    appPreferences = AppPreferences(await SharedPreferences.getInstance());
    viewModel = ConnectSpotifyPremiumViewModel(spotifyService, appPreferences);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('estado inicial é content, isConnected false, sem mensagem de erro', () {
    expect(viewModel.state.value, FlowState.content);
    expect(viewModel.isConnected.value, isFalse);
    expect(viewModel.errorMessage.value, isNull);
  });

  test('start() reseta o estado para content', () {
    viewModel.state.value = FlowState.error;

    viewModel.start();

    expect(viewModel.state.value, FlowState.content);
  });

  group('connect (VM roda em plataforma não suportada pelo spotify_sdk)', () {
    // `flutter test` roda em VM (não Android/iOS/web), então
    // `_isSupportedPlatform` é sempre false — o único caminho de fato
    // exercitável sem um device real, e reflete o comportamento real do
    // app nesse ambiente (proteção explícita contra plataformas sem o
    // plugin nativo do spotify_sdk).
    test(
      'define erro de plataforma não suportada, sem chamar o SpotifyService',
      () async {
        await viewModel.connect();

        expect(viewModel.state.value, FlowState.error);
        expect(
          viewModel.errorMessage.value,
          'Spotify SDK só funciona em Android/iOS nativos.',
        );
        verifyZeroInteractions(spotifyService);
      },
    );

    test('passa por loading antes de cair em erro', () async {
      final states = <FlowState>[];
      viewModel.state.addListener(() => states.add(viewModel.state.value));

      await viewModel.connect();

      expect(states, [FlowState.loading, FlowState.error]);
    });

    test('substitui a errorMessage de uma tentativa anterior', () async {
      viewModel.errorMessage.value = 'erro anterior';

      await viewModel.connect();

      expect(
        viewModel.errorMessage.value,
        'Spotify SDK só funciona em Android/iOS nativos.',
      );
    });
  });

  group('disconnect', () {
    test('desconecta com sucesso e zera isConnected', () async {
      viewModel.isConnected.value = true;
      when(() => spotifyService.disconnect()).thenAnswer((_) async => true);

      await viewModel.disconnect();

      expect(viewModel.isConnected.value, isFalse);
      verify(() => spotifyService.disconnect()).called(1);
    });

    test(
      'reporta erro não fatal e não propaga exceção quando disconnect falha',
      () async {
        viewModel.isConnected.value = true;
        when(
          () => spotifyService.disconnect(),
        ).thenThrow(Exception('falha ao desconectar'));

        await expectLater(viewModel.disconnect(), completes);

        expect(
          viewModel.isConnected.value,
          isTrue,
          reason: 'estado não deveria mudar quando a chamada falha',
        );
      },
    );
  });

  test(
    'appPreferences não é alterada quando a plataforma não é suportada',
    () async {
      await viewModel.connect();

      expect(await appPreferences.getAppPlanType(), isNull);
      expect(appPreferences.hasGameMode(), isFalse);
    },
  );
}
