import 'package:dartz/dartz.dart';

import '../enum/settings_enum.dart';
import '../error_reporting.dart';
import '../exceptions/playback_exceptions.dart';
import '../failure.dart';
import '../model/musica_playback_result.dart';
import '../repository/musica_playback_repository.dart';
import 'base_usecase.dart';

const int musicaPlaybackInvalidUriCode = 1;

const int musicaPlaybackPreviewUnavailableCode = 2;

/// Falha real de rede/conectividade (timeout, sem internet, resposta
/// inválida do servidor) — distinto de [musicaPlaybackSpotifyAuthErrorCode].
const int musicaPlaybackConnectionErrorCode = 3;

/// Falha de autorização/configuração do Spotify (app não autorizado, plugin
/// ausente, erro de autenticação do SDK) — não é um problema de internet.
const int musicaPlaybackSpotifyAuthErrorCode = 4;

/// Qualquer outra falha não classificada.
const int musicaPlaybackUnexpectedErrorCode = 5;

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
    extends BaseUseCase<MusicaPlaybackInput, MusicaPlaybackResult> {
  final MusicaPlaybackRepository _repository;

  MusicaPlaybackUseCase(this._repository);

  @override
  Future<Either<Failure, MusicaPlaybackResult>> execute(
    MusicaPlaybackInput input,
  ) async {
    final usePreview =
        input.plan == PlanType.free ||
        input.gameMode == GameModeType.preview;

    if (!usePreview) {
      return Right(FullTrackPlayback(input.spotifyUri));
    }

    final trackId = _extractTrackId(input.spotifyUri);
    if (trackId == null) {
      return Left(Failure(musicaPlaybackInvalidUriCode, 'URI inválida'));
    }

    try {
      final preview = await _repository.resolvePreview(trackId);
      if (preview == null) {
        return Left(
          Failure(musicaPlaybackPreviewUnavailableCode, 'Prévia indisponível'),
        );
      }
      return Right(preview);
    } on PlaybackAuthException catch (e) {
      return Left(Failure(musicaPlaybackSpotifyAuthErrorCode, e.message));
    } on PlaybackNetworkException catch (e) {
      return Left(Failure(musicaPlaybackConnectionErrorCode, e.message));
    } catch (e, s) {
      reportNonFatalError(
        e,
        s,
        information: const ['MusicaPlaybackUseCase.execute: erro não classificado'],
      );
      return Left(
        Failure(musicaPlaybackUnexpectedErrorCode, 'Erro inesperado: $e'),
      );
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
