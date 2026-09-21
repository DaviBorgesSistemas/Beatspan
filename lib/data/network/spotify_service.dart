// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:async';
import 'package:spotify_sdk/spotify_sdk.dart';

import '../../app/app_prefs.dart';
import '../../domain/exceptions/spotify_consent_exception.dart';

class SpotifyService {
  final String clientId;
  final String redirectUrl;
  final String scopes;
  final AppPreferences _appPreferences;

  SpotifyService({
    required this.clientId,
    required this.redirectUrl,
    required AppPreferences appPreferences,
    this.scopes =
        'app-remote-control,user-read-playback-state,user-modify-playback-state,playlist-read-private,user-library-modify,user-library-read',
  }) : _appPreferences = appPreferences;

  void _ensureConsent() {
    if (!_appPreferences.hasAcceptedSpotifyConsent()) {
      throw const SpotifyConsentRequiredException();
    }
  }

  Future<bool> connect({String? accessToken}) async {
    _ensureConsent();
    final connected = await SpotifySdk.connectToSpotifyRemote(
      clientId: clientId,
      redirectUrl: redirectUrl,
      scope: scopes,
      accessToken: accessToken,
    );
    return connected;
  }

  Future<String> getAccessToken() async {
    _ensureConsent();
    final token = await SpotifySdk.getAccessToken(
      clientId: clientId,
      redirectUrl: redirectUrl,
      scope: scopes,
    );
    return token;
  }

  Future<bool> authorizeAndConnect() async {
    _ensureConsent();
    final token = await getAccessToken();
    return connect(accessToken: token);
  }

  Future<bool> disconnect() => SpotifySdk.disconnect();
}
