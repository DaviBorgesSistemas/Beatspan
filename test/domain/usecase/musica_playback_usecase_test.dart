import 'package:beatspan/domain/enum/settings_enum.dart';
import 'package:beatspan/domain/exceptions/playback_exceptions.dart';
import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/musica_playback_result.dart';
import 'package:beatspan/domain/repository/musica_playback_repository.dart';
import 'package:beatspan/domain/usecase/musica_playback_usecase.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMusicaPlaybackRepository extends Mock
    implements MusicaPlaybackRepository {}

void main() {
  late _MockMusicaPlaybackRepository repository;
  late MusicaPlaybackUseCase useCase;

  const spotifyUri = 'spotify:track:abc123';

  setUp(() {
    repository = _MockMusicaPlaybackRepository();
    useCase = MusicaPlaybackUseCase(repository);
  });

  test(
    'retorna FullTrackPlayback para plano premium fora do modo prévia',
    () async {
      final result = await useCase.execute(
        const MusicaPlaybackInput(
          spotifyUri: spotifyUri,
          plan: PlanType.premium,
          gameMode: GameModeType.fullTrack,
        ),
      );

      expect(result, Right(const FullTrackPlayback(spotifyUri)));
      verifyZeroInteractions(repository);
    },
  );

  test('retorna PreviewPlayback para plano free', () async {
    const preview = PreviewPlayback(
      trackId: 'abc123',
      previewUrl: 'https://preview',
      trackName: 'Nome',
      artistName: 'Artista',
      albumArtUrl: 'https://art',
    );
    when(
      () => repository.resolvePreview('abc123'),
    ).thenAnswer((_) async => preview);

    final result = await useCase.execute(
      const MusicaPlaybackInput(
        spotifyUri: spotifyUri,
        plan: PlanType.free,
        gameMode: GameModeType.fullTrack,
      ),
    );

    expect(result, const Right(preview));
    verify(() => repository.resolvePreview('abc123')).called(1);
  });

  test('retorna PreviewPlayback para plano premium em modo prévia', () async {
    const preview = PreviewPlayback(
      trackId: 'abc123',
      previewUrl: 'https://preview',
    );
    when(
      () => repository.resolvePreview('abc123'),
    ).thenAnswer((_) async => preview);

    final result = await useCase.execute(
      const MusicaPlaybackInput(
        spotifyUri: spotifyUri,
        plan: PlanType.premium,
        gameMode: GameModeType.preview,
      ),
    );

    expect(result, const Right(preview));
  });

  test('retorna falha de URI inválida sem consultar o repositório', () async {
    final result = await useCase.execute(
      const MusicaPlaybackInput(
        spotifyUri: 'spotify:album:abc123',
        plan: PlanType.free,
        gameMode: GameModeType.fullTrack,
      ),
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<MusicaPlaybackUriInvalida>());
    verifyZeroInteractions(repository);
  });

  test(
    'retorna falha de prévia indisponível quando repositório retorna null',
    () async {
      when(
        () => repository.resolvePreview('abc123'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute(
        const MusicaPlaybackInput(
          spotifyUri: spotifyUri,
          plan: PlanType.free,
          gameMode: GameModeType.fullTrack,
        ),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<MusicaPlaybackPreviaIndisponivel>());
    },
  );

  test(
    'retorna falha de conexão quando repositório lança PlaybackNetworkException',
    () async {
      when(
        () => repository.resolvePreview('abc123'),
      ).thenThrow(const PlaybackNetworkException('Tempo de conexão esgotado.'));

      final result = await useCase.execute(
        const MusicaPlaybackInput(
          spotifyUri: spotifyUri,
          plan: PlanType.free,
          gameMode: GameModeType.fullTrack,
        ),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<MusicaPlaybackErroConexao>());
      expect(failure!.message, 'Tempo de conexão esgotado.');
    },
  );

  test(
    'retorna falha de autorização do Spotify quando repositório lança PlaybackAuthException',
    () async {
      when(
        () => repository.resolvePreview('abc123'),
      ).thenThrow(const PlaybackAuthException('Falha ao autorizar o Spotify.'));

      final result = await useCase.execute(
        const MusicaPlaybackInput(
          spotifyUri: spotifyUri,
          plan: PlanType.free,
          gameMode: GameModeType.fullTrack,
        ),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<MusicaPlaybackSpotifyNaoAutorizado>());
      expect(failure!.message, 'Falha ao autorizar o Spotify.');
    },
  );

  test(
    'retorna falha inesperada quando repositório lança exceção não classificada',
    () async {
      when(
        () => repository.resolvePreview('abc123'),
      ).thenThrow(Exception('algo diferente'));

      final result = await useCase.execute(
        const MusicaPlaybackInput(
          spotifyUri: spotifyUri,
          plan: PlanType.free,
          gameMode: GameModeType.fullTrack,
        ),
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<MusicaPlaybackErroInesperado>());
    },
  );
}
