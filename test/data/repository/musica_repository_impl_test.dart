import 'package:beatspan/data/network/musica_firestore_data_source.dart';
import 'package:beatspan/data/repository/musica_repository_impl.dart';
import 'package:beatspan/domain/exception/musica_exceptions.dart';
import 'package:beatspan/domain/model/musica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMusicaFirestoreDataSource extends Mock
    implements MusicaFirestoreDataSource {}

void main() {
  late _MockMusicaFirestoreDataSource dataSource;
  late MusicaRepositoryImpl repository;

  setUp(() {
    dataSource = _MockMusicaFirestoreDataSource();
    repository = MusicaRepositoryImpl(dataSource);
  });

  group('getByCodigo', () {
    test(
      'retorna Right(Musica) quando o data source encontra a música',
      () async {
        final musica = Musica(
          id: '0006',
          spotifyId: '3n3Ppam7vgaVa1iaRUc9Lp',
          spotifyUri: 'spotify:track:3n3Ppam7vgaVa1iaRUc9Lp',
        );
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenAnswer((_) async => musica);

        final result = await repository.getByCodigo('0006');

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('esperava Right'),
          (m) => expect(m.spotifyUri, 'spotify:track:3n3Ppam7vgaVa1iaRUc9Lp'),
        );
      },
    );

    test(
      'retorna Left(Failure(404, ...)) quando a música não é encontrada',
      () async {
        when(
          () => dataSource.getByCodigo('9999'),
        ).thenThrow(MusicaNaoEncontradaException('9999'));

        final result = await repository.getByCodigo('9999');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.code, 404),
          (_) => fail('esperava Left'),
        );
      },
    );

    test(
      'retorna Left(Failure(0, ...)) quando há erro de consulta (rede/Firestore)',
      () async {
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenThrow(MusicaConsultaException('Sem conexão com o servidor.'));

        final result = await repository.getByCodigo('0006');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure.code, 0);
          expect(failure.message, 'Sem conexão com o servidor.');
        }, (_) => fail('esperava Left'));
      },
    );

    test(
      'retorna Left(Failure(0, ...)) para qualquer exceção inesperada',
      () async {
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenThrow(StateError('boom'));

        final result = await repository.getByCodigo('0006');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.code, 0),
          (_) => fail('esperava Left'),
        );
      },
    );
  });
}
