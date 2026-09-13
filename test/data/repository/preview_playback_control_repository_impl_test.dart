import 'package:beatspan/data/repository/preview_playback_control_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late _MockAudioPlayer player;
  late PreviewPlaybackControlRepositoryImpl repository;

  const previewUrl = 'https://preview.example/track.mp3';

  setUp(() {
    player = _MockAudioPlayer();
    repository = PreviewPlaybackControlRepositoryImpl(player: player);
  });

  test('load define a url e inicia a reprodução', () async {
    when(() => player.setUrl(previewUrl)).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});

    await repository.load(previewUrl);

    verify(() => player.setUrl(previewUrl)).called(1);
    verify(() => player.play()).called(1);
  });

  test('playerStateStream mapeia playing para isPaused invertido', () async {
    when(() => player.playerStateStream).thenAnswer(
      (_) => Stream.fromIterable([
        PlayerState(true, ProcessingState.ready),
        PlayerState(false, ProcessingState.ready),
      ]),
    );

    final states = await repository.playerStateStream.toList();

    expect(states[0].isPaused, isFalse);
    expect(states[1].isPaused, isTrue);
  });

  test('play delega ao AudioPlayer', () async {
    when(() => player.play()).thenAnswer((_) async {});

    await repository.play();

    verify(() => player.play()).called(1);
  });

  test('pause delega ao AudioPlayer', () async {
    when(() => player.pause()).thenAnswer((_) async {});

    await repository.pause();

    verify(() => player.pause()).called(1);
  });

  test('dispose delega ao AudioPlayer', () async {
    when(() => player.dispose()).thenAnswer((_) async {});

    await repository.dispose();

    verify(() => player.dispose()).called(1);
  });
}
