// As classes de cloud_firestore mockadas abaixo (CollectionReference,
// DocumentReference, DocumentSnapshot) são `sealed` no pacote — implementá-las
// via Mock funciona normalmente em runtime, mas o analyzer marca isso como
// aviso. Não há fake_cloud_firestore no projeto para uma alternativa "oficial".
// ignore_for_file: subtype_of_sealed_class

import 'package:beatspan/data/network/musica_firestore_data_source.dart';
import 'package:beatspan/domain/exception/musica_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late _MockFirebaseFirestore firestore;
  late _MockCollectionReference collection;
  late _MockDocumentReference document;
  late _MockDocumentSnapshot snapshot;
  late MusicaFirestoreDataSource dataSource;

  const codigo = '0006';

  setUp(() {
    firestore = _MockFirebaseFirestore();
    collection = _MockCollectionReference();
    document = _MockDocumentReference();
    snapshot = _MockDocumentSnapshot();

    when(() => firestore.collection('musicas')).thenReturn(collection);
    when(() => collection.doc(codigo)).thenReturn(document);

    dataSource = MusicaFirestoreDataSource(
      firestore: firestore,
      retryBackoff: (_) => Duration.zero,
    );
  });

  test('retorna a Musica quando o documento existe e tem spotifyUri', () async {
    when(() => document.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.id).thenReturn(codigo);
    when(() => snapshot.data()).thenReturn({
      'spotify_id': 'abc123',
      'spotify_uri': 'spotify:track:abc123',
    });

    final musica = await dataSource.getByCodigo(codigo);

    expect(musica.id, codigo);
    expect(musica.spotifyUri, 'spotify:track:abc123');
  });

  test(
    'lança MusicaNaoEncontradaException quando o documento não existe',
    () async {
      when(() => document.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);
      when(() => snapshot.data()).thenReturn(null);

      await expectLater(
        () => dataSource.getByCodigo(codigo),
        throwsA(isA<MusicaNaoEncontradaException>()),
      );
    },
  );

  test(
    'lança MusicaNaoEncontradaException quando spotifyUri está vazio',
    () async {
      when(() => document.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.id).thenReturn(codigo);
      when(
        () => snapshot.data(),
      ).thenReturn({'spotify_id': 'abc123', 'spotify_uri': ''});

      await expectLater(
        () => dataSource.getByCodigo(codigo),
        throwsA(isA<MusicaNaoEncontradaException>()),
      );
    },
  );

  test(
    'tenta de novo e recupera quando FirebaseException("unavailable") na 1ª tentativa',
    () async {
      var attempts = 0;
      when(() => document.get()).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
          );
        }
        return snapshot;
      });
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.id).thenReturn(codigo);
      when(() => snapshot.data()).thenReturn({
        'spotify_id': 'abc123',
        'spotify_uri': 'spotify:track:abc123',
      });

      final musica = await dataSource.getByCodigo(codigo);

      expect(musica.spotifyUri, 'spotify:track:abc123');
      expect(attempts, 2);
    },
  );

  test(
    'converte FirebaseException não transitória em MusicaConsultaException sem retry',
    () async {
      var attempts = 0;
      when(() => document.get()).thenAnswer((_) async {
        attempts++;
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'sem permissão',
        );
      });

      await expectLater(
        () => dataSource.getByCodigo(codigo),
        throwsA(isA<MusicaConsultaException>()),
      );
      expect(attempts, 1, reason: 'erro não transitório não tenta de novo');
    },
  );

  test(
    'converte FirebaseException transitória em MusicaConsultaException após esgotar retries',
    () async {
      var attempts = 0;
      when(() => document.get()).thenAnswer((_) async {
        attempts++;
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'deadline-exceeded',
        );
      });

      await expectLater(
        () => dataSource.getByCodigo(codigo),
        throwsA(isA<MusicaConsultaException>()),
      );
      expect(attempts, 2);
    },
  );

  test(
    'converte erro inesperado em MusicaConsultaException genérica',
    () async {
      when(() => document.get()).thenThrow(StateError('boom'));

      await expectLater(
        () => dataSource.getByCodigo(codigo),
        throwsA(isA<MusicaConsultaException>()),
      );
    },
  );
}
