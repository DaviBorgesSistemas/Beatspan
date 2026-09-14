// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../app/app_prefs.dart';
import '../app/di.dart';
import '../domain/usecase/musica_playback_usecase.dart';
import '../domain/usecase/preview_playback_usecase.dart';
import '../domain/usecase/spotify_playback_usecase.dart';
import 'change_spotify/change_spotify_view.dart';
import 'change_spotify/connect_spotify_premium_view_model.dart';
import 'contact/contact_view.dart';
import 'faqs/faqs_view.dart';
import 'faqs/faqs_view_model.dart';
import 'first_time/first_time_view.dart';
import 'game/game_view.dart';
import 'game/game_viewmodel.dart';
import 'home/home_view.dart';
import 'privacy_consent/privacy_consent_view.dart';
import 'rules/rules_view.dart';
import 'settings/settings_view.dart';
import 'splash/splash_view.dart';
import 'spotify_free_transition/spotify_free_transition.dart';

class Routes {
  static const String splashRoute = '/splash';
  static const String privacyConsentRoute = '/privacy-consent';
  static const String firstTimeRoute = '/first';
  static const String rulesRoute = '/rules';
  static const String changeSpotifyRoute = '/change-spotify';
  static const String changeSpotifyFreeRoute = '/connect-spotify-free';
  static const String homeRoute = '/home';
  static const String faqRoute = '/faq';
  static const String settingsRoute = '/settings';
  static const String contactRoute = '/contact';
  static const String gameRoute = '/game';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splashRoute:
        return MaterialPageRoute(
          builder: (_) =>
              SplashView(appPreferences: instance<AppPreferences>()),
        );
      case Routes.privacyConsentRoute:
        return _fadeRoute(
          PrivacyConsentView(appPreferences: instance<AppPreferences>()),
        );
      case Routes.firstTimeRoute:
        return _fadeRoute(const FirstTimeView());
      case Routes.rulesRoute:
        return MaterialPageRoute(builder: (_) => const RulesView());
      case Routes.changeSpotifyRoute:
        initSpotifyModule();
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => ChangeSpotifyView(
            appPreferences: instance<AppPreferences>(),
            viewModel: instance<ConnectSpotifyPremiumViewModel>(),
          ),
        );
      case Routes.changeSpotifyFreeRoute:
        return MaterialPageRoute(
          builder: (_) =>
              SpotifyFreeTransition(appPreferences: instance<AppPreferences>()),
        );
      case Routes.homeRoute:
        return _fadeRoute(const HomeView());
      case Routes.faqRoute:
        initFaqsModule();
        return MaterialPageRoute(
          builder: (_) => FaqsView(viewModel: instance<FaqsViewModel>()),
        );
      case Routes.settingsRoute:
        initSpotifyModule();
        return MaterialPageRoute(
          builder: (_) => SettingsView(
            appPreferences: instance<AppPreferences>(),
            viewModel: instance<ConnectSpotifyPremiumViewModel>(),
          ),
        );
      case Routes.contactRoute:
        return MaterialPageRoute(builder: (_) => const ContactView());
      case Routes.gameRoute:
        return MaterialPageRoute(
          builder: (_) => GameView(
            appPreferences: instance<AppPreferences>(),
            viewModel: instance<GameViewModel>(),
            spotifyPlaybackUseCase: instance<SpotifyPlaybackUseCase>(),
            musicaPlaybackUseCase: instance<MusicaPlaybackUseCase>(),
            previewPlaybackUseCaseFactory: () =>
                instance<PreviewPlaybackUseCase>(),
          ),
        );
      default:
        return undefinedRoute();
    }
  }

  static Route<dynamic> _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  static Route<dynamic> undefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Rota Inexistente')),
        body: const Center(child: Text('Rota Inexistente')),
      ),
    );
  }
}
