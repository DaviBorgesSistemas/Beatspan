// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_source/faq_local_data_source.dart';
import '../data/network/itunes_search_api.dart';
import '../data/network/musica_firestore_data_source.dart';
import '../data/network/network_info.dart';
import '../data/network/spotify_service.dart';
import '../data/repository/faq_repository_impl.dart';
import '../data/repository/musica_playback_repository_impl.dart';
import '../data/repository/musica_repository_impl.dart';
import '../data/repository/preview_playback_control_repository_impl.dart';
import '../data/repository/spotify_playback_control_repository_impl.dart';
import '../domain/repository/faq_repository.dart';
import '../domain/repository/musica_playback_repository.dart';
import '../domain/repository/musica_repository.dart';
import '../domain/repository/spotify_playback_control_repository.dart';
import '../domain/usecase/faqs_usecase.dart';
import '../domain/usecase/get_musica_usecase.dart';
import '../domain/usecase/musica_playback_usecase.dart';
import '../domain/usecase/preview_playback_usecase.dart';
import '../domain/usecase/spotify_playback_usecase.dart';
import '../presentation/change_spotify/connect_spotify_premium_view_model.dart';
import '../presentation/faqs/faqs_view_model.dart';
import '../presentation/game/game_viewmodel.dart';
import 'app_prefs.dart';

void systemChromeConfigure() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

final instance = GetIt.instance;

/// Registro idempotente: registra apenas se [T] ainda não estiver
/// registrado em [GetIt]. Cada módulo de DI pode ser chamado mais de uma
/// vez (ex.: `initAppModule` seguido de um teste que também o chama, ou
/// `initFaqsModule`/`initSpotifyModule` acionados por navegação repetida)
/// sem lançar `StateError` de registro duplicado.
extension _IdempotentRegistration on GetIt {
  void registerLazySingletonIfAbsent<T extends Object>(
    T Function() factoryFunc,
  ) {
    if (!isRegistered<T>()) registerLazySingleton<T>(factoryFunc);
  }

  void registerFactoryIfAbsent<T extends Object>(T Function() factoryFunc) {
    if (!isRegistered<T>()) registerFactory<T>(factoryFunc);
  }

  void unregisterIfRegistered<T extends Object>() {
    if (isRegistered<T>()) unregister<T>();
  }
}

Future<void> initAppModule() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  instance.registerLazySingletonIfAbsent<SharedPreferences>(() => sharedPrefs);

  instance.registerLazySingletonIfAbsent<AppPreferences>(
    () => AppPreferences(instance<SharedPreferences>()),
  );

  instance.registerLazySingletonIfAbsent<NetworkInfo>(
    () => NetworkInfoImpl(Connectivity()),
  );
  instance.registerLazySingletonIfAbsent<SpotifyService>(
    () => SpotifyService(
      clientId: _requiredEnv(
        'SPOTIFY_CLIENT_ID',
        const String.fromEnvironment('SPOTIFY_CLIENT_ID'),
      ),
      redirectUrl: _requiredEnv(
        'SPOTIFY_REDIRECT_URL',
        const String.fromEnvironment('SPOTIFY_REDIRECT_URL'),
      ),
      appPreferences: instance<AppPreferences>(),
    ),
  );

  instance.registerLazySingletonIfAbsent<MusicaFirestoreDataSource>(
    () => MusicaFirestoreDataSource(),
  );
  instance.registerLazySingletonIfAbsent<MusicaRepository>(
    () => MusicaRepositoryImpl(instance()),
  );
  instance.registerFactoryIfAbsent<GetMusicaUseCase>(
    () => GetMusicaUseCase(instance()),
  );

  instance.registerLazySingletonIfAbsent<ItunesSearchApi>(
    () => ItunesSearchApi(),
  );
  instance.registerLazySingletonIfAbsent<MusicaPlaybackRepository>(
    () => MusicaPlaybackRepositoryImpl(
      instance<SpotifyService>(),
      instance<ItunesSearchApi>(),
    ),
  );
  instance.registerFactoryIfAbsent<MusicaPlaybackUseCase>(
    () => MusicaPlaybackUseCase(instance()),
  );

  instance.registerLazySingletonIfAbsent<SpotifyPlaybackControlRepository>(
    () => SpotifyPlaybackControlRepositoryImpl(instance<SpotifyService>()),
  );
  instance.registerFactoryIfAbsent<SpotifyPlaybackUseCase>(
    () => SpotifyPlaybackUseCase(instance()),
  );

  instance.registerFactoryIfAbsent<PreviewPlaybackUseCase>(
    () => PreviewPlaybackUseCase(PreviewPlaybackControlRepositoryImpl()),
  );

  instance.registerFactoryIfAbsent<GameViewModel>(
    () => GameViewModel(
      appPreferences: instance<AppPreferences>(),
      getMusicaUseCase: instance<GetMusicaUseCase>(),
      musicaPlaybackUseCase: instance<MusicaPlaybackUseCase>(),
    ),
  );
}

void initFaqsModule() {
  instance.registerLazySingletonIfAbsent<FaqLocalDataSource>(
    () => FaqLocalDataSourceImpl(),
  );
  instance.registerLazySingletonIfAbsent<FaqRepository>(
    () => FaqRepositoryImpl(instance()),
  );
  instance.registerFactoryIfAbsent<FaqsUseCase>(() => FaqsUseCase(instance()));
  instance.registerFactoryIfAbsent<FaqsViewModel>(
    () => FaqsViewModel(instance()),
  );
}

void initSpotifyModule() {
  instance.registerFactoryIfAbsent<ConnectSpotifyPremiumViewModel>(
    () => ConnectSpotifyPremiumViewModel(
      instance<SpotifyService>(),
      instance<AppPreferences>(),
    ),
  );
}

void disposeFaqsModule() {
  instance.unregisterIfRegistered<FaqsViewModel>();
  instance.unregisterIfRegistered<FaqsUseCase>();
  instance.unregisterIfRegistered<FaqRepository>();
  instance.unregisterIfRegistered<FaqLocalDataSource>();
}

Future<void> resetModules() async {
  await instance.reset();
  await initAppModule();
}

String _requiredEnv(String name, String value) {
  if (value.isEmpty) {
    throw StateError(
      'Variável de ambiente "$name" não definida. Rode o app com '
      '--dart-define=$name=valor ou --dart-define-from-file=env.json '
      '(veja env.json.example para a lista completa de variáveis esperadas).',
    );
  }
  return value;
}
