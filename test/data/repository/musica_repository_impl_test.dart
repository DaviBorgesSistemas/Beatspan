import 'package:beatspan/data/network/musica_firestore_data_source.dart';
import 'package:beatspan/data/repository/musica_repository_impl.dart';
import 'package:beatspan/domain/exception/musica_exceptions.dart';
import 'package:beatspan/domain/failure.dart';
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
      'retorna Left(MusicaNaoEncontrada) quando a música não é encontrada',
      () async {
        when(
          () => dataSource.getByCodigo('9999'),
        ).thenThrow(MusicaNaoEncontradaException('9999'));

        final result = await repository.getByCodigo('9999');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MusicaNaoEncontrada>()),
          (_) => fail('esperava Left'),
        );
      },
    );

    test(
      'retorna Left(MusicaConsultaErro) quando há erro de consulta (rede/Firestore)',
      () async {
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenThrow(MusicaConsultaException('Sem conexão com o servidor.'));

        final result = await repository.getByCodigo('0006');

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<MusicaConsultaErro>());
          expect(failure.message, 'Sem conexão com o servidor.');
        }, (_) => fail('esperava Left'));
      },
    );

    test(
      'retorna Left(MusicaConsultaErro) para qualquer exceção inesperada',
      () async {
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenThrow(StateError('boom'));

        final result = await repository.getByCodigo('0006');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<MusicaConsultaErro>()),
          (_) => fail('esperava Left'),
        );
      },
    );

    test(
      'reusa o resultado em cache na segunda chamada para o mesmo código, sem rechamar o data source',
      () async {
        final musica = Musica(
          id: '0006',
          spotifyId: '3n3Ppam7vgaVa1iaRUc9Lp',
          spotifyUri: 'spotify:track:3n3Ppam7vgaVa1iaRUc9Lp',
        );
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenAnswer((_) async => musica);

        final first = await repository.getByCodigo('0006');
        final second = await repository.getByCodigo('0006');

        expect(first, equals(second));
        verify(() => dataSource.getByCodigo('0006')).called(1);
      },
    );

    test(
      'não cacheia "não encontrada" — chama o data source de novo',
      () async {
        when(
          () => dataSource.getByCodigo('9999'),
        ).thenThrow(MusicaNaoEncontradaException('9999'));

        await repository.getByCodigo('9999');
        await repository.getByCodigo('9999');

        verify(() => dataSource.getByCodigo('9999')).called(2);
      },
    );

    test(
      'não cacheia erro de consulta — chama o data source de novo e pode se recuperar',
      () async {
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenThrow(MusicaConsultaException('Sem conexão com o servidor.'));

        final first = await repository.getByCodigo('0006');
        expect(first.isLeft(), isTrue);

        final musica = Musica(
          id: '0006',
          spotifyId: '3n3Ppam7vgaVa1iaRUc9Lp',
          spotifyUri: 'spotify:track:3n3Ppam7vgaVa1iaRUc9Lp',
        );
        when(
          () => dataSource.getByCodigo('0006'),
        ).thenAnswer((_) async => musica);

        final second = await repository.getByCodigo('0006');

        expect(second.isRight(), isTrue);
        verify(() => dataSource.getByCodigo('0006')).called(2);
      },
    );
  });
}
