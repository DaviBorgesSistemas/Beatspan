import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/musica.dart';
import 'package:beatspan/domain/repository/musica_repository.dart';
import 'package:beatspan/domain/usecase/get_musica_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMusicaRepository extends Mock implements MusicaRepository {}

void main() {
  late _MockMusicaRepository repository;
  late GetMusicaUseCase useCase;

  setUp(() {
    repository = _MockMusicaRepository();
    useCase = GetMusicaUseCase(repository);
  });

  test(
    'delega a busca ao repositório e repassa o resultado de sucesso',
    () async {
      final musica = Musica(
        id: '0006',
        spotifyId: 'abc123',
        spotifyUri: 'spotify:track:abc123',
      );
      when(
        () => repository.getByCodigo('0006'),
      ).thenAnswer((_) async => Right(musica));

      final result = await useCase.execute('0006');

      expect(result, Right(musica));
      verify(() => repository.getByCodigo('0006')).called(1);
    },
  );

  test('repassa a falha do repositório sem alterá-la', () async {
    final failure = const MusicaNaoEncontrada();
    when(
      () => repository.getByCodigo('9999'),
    ).thenAnswer((_) async => Left(failure));

    final result = await useCase.execute('9999');

    expect(result, Left(failure));
  });
}
