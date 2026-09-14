// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';

import '../error_reporting.dart';
import '../failure.dart';
import '../model/playback_state.dart';
import '../repository/preview_playback_control_repository.dart';

class PreviewPlaybackUseCase {
  final PreviewPlaybackControlRepository _repository;

  PreviewPlaybackUseCase(this._repository);

  Future<Either<PreviewPlaybackFailure, Unit>> load(String previewUrl) async {
    try {
      await _repository.load(previewUrl);
      return const Right(unit);
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['PreviewPlaybackUseCase.load'],
      );
      return const Left(
        PreviewPlaybackErroInesperado(
          'Não foi possível carregar a prévia de 30 segundos.',
        ),
      );
    }
  }

  Stream<PlaybackState> get playerStateStream => _repository.playerStateStream;

  Future<void> togglePlayback({required bool isPaused}) {
    return isPaused ? _repository.play() : _repository.pause();
  }

  Future<void> dispose() => _repository.dispose();
}
