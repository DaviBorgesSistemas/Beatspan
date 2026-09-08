import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_source/faq_local_data_source.dart';
import '../data/network/musica_firestore_data_source.dart';
import '../data/network/network_info.dart';
import '../data/network/spotify_service.dart';
import '../data/repository/faq_repository_impl.dart';
import '../data/repository/musica_repository_impl.dart';
import '../domain/repository/faq_repository.dart';
import '../domain/repository/musica_repository.dart';
import '../domain/usecase/faqs_usecase.dart';
import '../domain/usecase/get_musica_usecase.dart';
import '../presentation/change_spotify/connect_spotify_premium_view_model.dart';
import '../presentation/faqs/faqs_view_model.dart';
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

Future<void> initAppModule() async {
  final sharedPrefs = await SharedPreferences.getInstance();
  if (!instance.isRegistered<SharedPreferences>()) {
    instance.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  if (!instance.isRegistered<AppPreferences>()) {
    instance.registerLazySingleton<AppPreferences>(
      () => AppPreferences(instance<SharedPreferences>()),
    );
  }

  if (!instance.isRegistered<NetworkInfo>()) {
    instance.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(Connectivity()),
    );
  }
  if (!instance.isRegistered<SpotifyService>()) {
    instance.registerLazySingleton<SpotifyService>(
      () => SpotifyService(
        clientId: _requiredEnv('SPOTIFY_CLIENT_ID'),
        redirectUrl: _requiredEnv('SPOTIFY_REDIRECT_URL'),
      ),
    );
  }

  if (!instance.isRegistered<MusicaFirestoreDataSource>()) {
    instance.registerLazySingleton<MusicaFirestoreDataSource>(
      () => MusicaFirestoreDataSource(),
    );
  }
  if (!instance.isRegistered<MusicaRepository>()) {
    instance.registerLazySingleton<MusicaRepository>(
      () => MusicaRepositoryImpl(instance()),
    );
  }
  if (!instance.isRegistered<GetMusicaUseCase>()) {
    instance.registerFactory<GetMusicaUseCase>(
      () => GetMusicaUseCase(instance()),
    );
  }
}

void initFaqsModule() {
  // 1) Data source
  if (!instance.isRegistered<FaqLocalDataSource>()) {
    instance.registerLazySingleton<FaqLocalDataSource>(
      () => FaqLocalDataSourceImpl(),
    );
  }
  // 2) Repository
  if (!instance.isRegistered<FaqRepository>()) {
    instance.registerLazySingleton<FaqRepository>(
      () => FaqRepositoryImpl(instance()),
    );
  }
  // 3) UseCase
  if (!instance.isRegistered<FaqsUseCase>()) {
    instance.registerFactory<FaqsUseCase>(() => FaqsUseCase(instance()));
  }
  // 4) ViewModel
  if (!instance.isRegistered<FaqsViewModel>()) {
    instance.registerFactory<FaqsViewModel>(() => FaqsViewModel(instance()));
  }
}

void initSpotifyModule() {
  if (!instance.isRegistered<ConnectSpotifyPremiumViewModel>()) {
    instance.registerFactory<ConnectSpotifyPremiumViewModel>(
      () => ConnectSpotifyPremiumViewModel(instance<SpotifyService>()),
    );
  }
}

void disposeFaqsModule() {
  // ordem inversa da criação

  if (instance.isRegistered<FaqsViewModel>()) {
    instance.unregister<FaqsViewModel>();
  }

  if (instance.isRegistered<FaqsUseCase>()) {
    instance.unregister<FaqsUseCase>();
  }

  if (instance.isRegistered<FaqRepository>()) {
    instance.unregister<FaqRepository>();
  }

  if (instance.isRegistered<FaqLocalDataSource>()) {
    instance.unregister<FaqLocalDataSource>();
  }
}

Future<void> resetModules() async {
  await instance.reset(); // zera tudo
  await initAppModule(); // ou re-registra o que precisar
}

/// Lê uma variável obrigatória do `.env` (carregado via flutter_dotenv
/// em main.dart antes de initAppModule()). Lança um erro claro se a
/// variável não estiver definida, em vez de seguir com um valor vazio.
String _requiredEnv(String key) {
  final value = dotenv.env[key];
  if (value == null || value.isEmpty) {
    throw StateError(
      'Variável de ambiente "$key" não definida. Copie .env.example '
      'para .env e preencha os valores antes de rodar o app.',
    );
  }
  return value;
}
