import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../error_reporting.dart';
import '../exceptions/rate_limited_exception.dart';
import '../exceptions/spotify_consent_exception.dart';
import '../failure.dart';
import '../model/playback_state.dart';
import '../repository/spotify_playback_control_repository.dart';

const int spotifyPlaybackAuthErrorCode = 1;

const int spotifyPlaybackUnexpectedErrorCode = 2;

/// O plugin nativo `spotify_sdk` não está registrado para este engine/build
/// — distinto de uma falha de autorização, pois nem chega a tentar conectar.
const int spotifyPlaybackPluginMissingErrorCode = 3;

/// Limite de requisições da Web API do Spotify atingido (HTTP 429), mesmo
/// após o retry automático que já respeita o header `Retry-After`.
const int spotifyPlaybackRateLimitedErrorCode = 4;

class SpotifyPlaybackUseCase {
  final SpotifyPlaybackControlRepository _repository;

  SpotifyPlaybackUseCase(this._repository);

  Future<Either<Failure, Unit>> startPlayback(String spotifyUri) async {
    try {
      await _repository.playFullTrack(spotifyUri);
      return const Right(unit);
    } on SpotifyConsentRequiredException {
      return Left(
        Failure(
          spotifyPlaybackAuthErrorCode,
          'É necessário aceitar o consentimento do Spotify antes de tocar as faixas.',
        ),
      );
    } on MissingPluginException catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['SpotifyPlaybackUseCase.startPlayback'],
      );
      return Left(
        Failure(
          spotifyPlaybackPluginMissingErrorCode,
          'Plugin spotify_sdk não foi encontrado/registrado para este engine.\n$e',
        ),
      );
    } on PlatformException catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: [
          'SpotifyPlaybackUseCase.startPlayback',
          'PlatformException.code=${e.code}',
        ],
      );
      return Left(
        Failure(
          spotifyPlaybackAuthErrorCode,
          'Falha ao autorizar o acesso ao Spotify (${e.code}).',
        ),
      );
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const [
          'SpotifyPlaybackUseCase.startPlayback: erro não classificado',
        ],
      );
      return Left(
        Failure(spotifyPlaybackUnexpectedErrorCode, 'Erro inesperado: $e'),
      );
    }
  }

  Stream<PlaybackState> subscribePlayerState() =>
      _repository.subscribePlayerState();

  Future<void> togglePlayback({required bool isPaused}) {
    return isPaused ? _repository.resume() : _repository.pause();
  }

  Future<void> pause() async {
    try {
      await _repository.pause();
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['SpotifyPlaybackUseCase.pause'],
      );
    }
  }

  Future<Either<Failure, bool>> saveTrack(String trackId) async {
    try {
      final saved = await _repository.saveTrack(trackId);
      return Right(saved);
    } on SpotifyConsentRequiredException {
      return Left(
        Failure(
          spotifyPlaybackAuthErrorCode,
          'É necessário aceitar o consentimento do Spotify antes de salvar faixas.',
        ),
      );
    } on RateLimitedException catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['SpotifyPlaybackUseCase.saveTrack'],
      );
      return Left(
        Failure(
          spotifyPlaybackRateLimitedErrorCode,
          'Limite de requisições do Spotify atingido. Tente novamente em '
          '${e.retryAfter.inSeconds}s.',
        ),
      );
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['SpotifyPlaybackUseCase.saveTrack'],
      );
      return Left(
        Failure(spotifyPlaybackUnexpectedErrorCode, 'Erro inesperado: $e'),
      );
    }
  }
}
