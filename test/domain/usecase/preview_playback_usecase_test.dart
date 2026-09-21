import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/playback_state.dart';
import 'package:beatspan/domain/repository/preview_playback_control_repository.dart';
import 'package:beatspan/domain/usecase/preview_playback_usecase.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreviewPlaybackControlRepository extends Mock
    implements PreviewPlaybackControlRepository {}

void main() {
  late _MockPreviewPlaybackControlRepository repository;
  late PreviewPlaybackUseCase useCase;

  const previewUrl = 'https://preview.example/track.mp3';

  setUp(() {
    repository = _MockPreviewPlaybackControlRepository();
    useCase = PreviewPlaybackUseCase(repository);
  });

  group('load', () {
    test('retorna sucesso quando o repository carrega a prévia', () async {
      when(() => repository.load(previewUrl)).thenAnswer((_) async {});

      final result = await useCase.load(previewUrl);

      expect(result, const Right(unit));
    });

    test('converte qualquer erro em falha amigável', () async {
      when(
        () => repository.load(previewUrl),
      ).thenThrow(Exception('falha ao carregar url'));

      final result = await useCase.load(previewUrl);

      expect(
        result,
        isA<Left>().having(
          (l) => l.value,
          'value',
          isA<PreviewPlaybackErroInesperado>(),
        ),
      );
    });
  });

  group('togglePlayback', () {
    test('chama play quando estava pausado', () async {
      when(() => repository.play()).thenAnswer((_) async {});

      await useCase.togglePlayback(isPaused: true);

      verify(() => repository.play()).called(1);
      verifyNever(() => repository.pause());
    });

    test('chama pause quando estava tocando', () async {
      when(() => repository.pause()).thenAnswer((_) async {});

      await useCase.togglePlayback(isPaused: false);

      verify(() => repository.pause()).called(1);
      verifyNever(() => repository.play());
    });
  });

  test('playerStateStream delega ao repository', () {
    final stream = Stream<PlaybackState>.fromIterable([
      const PlaybackState(isPaused: false),
    ]);
    when(() => repository.playerStateStream).thenAnswer((_) => stream);

    expect(useCase.playerStateStream, same(stream));
  });

  test('dispose delega ao repository', () async {
    when(() => repository.dispose()).thenAnswer((_) async {});

    await useCase.dispose();

    verify(() => repository.dispose()).called(1);
  });
}
