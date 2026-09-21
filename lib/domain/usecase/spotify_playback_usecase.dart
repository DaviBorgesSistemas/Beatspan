// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

import '../error_reporting.dart';
import '../exceptions/rate_limited_exception.dart';
import '../exceptions/spotify_consent_exception.dart';
import '../failure.dart';
import '../model/playback_state.dart';
import '../repository/spotify_playback_control_repository.dart';

class SpotifyPlaybackUseCase {
  final SpotifyPlaybackControlRepository _repository;

  SpotifyPlaybackUseCase(this._repository);

  Future<Either<SpotifyPlaybackFailure, Unit>> startPlayback(
    String spotifyUri,
  ) async {
    try {
      await _repository.playFullTrack(spotifyUri);
      return const Right(unit);
    } on SpotifyConsentRequiredException {
      return const Left(
        SpotifyPlaybackNaoAutorizado(
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
        SpotifyPlaybackPluginAusente(
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
        SpotifyPlaybackNaoAutorizado(
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
      return Left(SpotifyPlaybackErroInesperado('Erro inesperado: $e'));
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

  Future<Either<SpotifyPlaybackFailure, bool>> saveTrack(String trackId) async {
    try {
      final saved = await _repository.saveTrack(trackId);
      return Right(saved);
    } on SpotifyConsentRequiredException {
      return const Left(
        SpotifyPlaybackNaoAutorizado(
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
        SpotifyPlaybackLimiteRequisicoes(
          'Limite de requisições do Spotify atingido. Tente novamente em '
          '${e.retryAfter.inSeconds}s.',
          e.retryAfter,
        ),
      );
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['SpotifyPlaybackUseCase.saveTrack'],
      );
      return Left(SpotifyPlaybackErroInesperado('Erro inesperado: $e'));
    }
  }
}
