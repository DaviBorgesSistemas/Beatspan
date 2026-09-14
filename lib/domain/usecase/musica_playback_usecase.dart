import 'package:dartz/dartz.dart';

import '../enum/settings_enum.dart';
import '../error_reporting.dart';
import '../exceptions/playback_exceptions.dart';
import '../failure.dart';
import '../model/musica_playback_result.dart';
import '../repository/musica_playback_repository.dart';
import 'base_usecase.dart';

class MusicaPlaybackInput {
  final String spotifyUri;
  final PlanType plan;
  final GameModeType gameMode;

  const MusicaPlaybackInput({
    required this.spotifyUri,
    required this.plan,
    required this.gameMode,
  });
}

class MusicaPlaybackUseCase
    extends
        BaseUseCase<
          MusicaPlaybackInput,
          MusicaPlaybackResult,
          MusicaPlaybackFailure
        > {
  final MusicaPlaybackRepository _repository;

  MusicaPlaybackUseCase(this._repository);

  @override
  Future<Either<MusicaPlaybackFailure, MusicaPlaybackResult>> execute(
    MusicaPlaybackInput input,
  ) async {
    final usePreview =
        input.plan == PlanType.free || input.gameMode == GameModeType.preview;

    if (!usePreview) {
      return Right(FullTrackPlayback(input.spotifyUri));
    }

    final trackId = _extractTrackId(input.spotifyUri);
    if (trackId == null) {
      return const Left(MusicaPlaybackUriInvalida());
    }

    try {
      final preview = await _repository.resolvePreview(trackId);
      if (preview == null) {
        return const Left(MusicaPlaybackPreviaIndisponivel());
      }
      return Right(preview);
    } on PlaybackAuthException catch (e) {
      return Left(MusicaPlaybackSpotifyNaoAutorizado(e.message));
    } on PlaybackNetworkException catch (e) {
      return Left(MusicaPlaybackErroConexao(e.message));
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const [
          'MusicaPlaybackUseCase.execute: erro não classificado',
        ],
      );
      return Left(MusicaPlaybackErroInesperado('Erro inesperado: $e'));
    }
  }

  String? _extractTrackId(String spotifyUri) {
    final parts = spotifyUri.split(':');
    if (parts.length != 3 || parts[0] != 'spotify' || parts[1] != 'track') {
      return null;
    }
    final id = parts[2];
    return id.isEmpty ? null : id;
  }
}
