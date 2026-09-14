// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/exception/musica_exceptions.dart';
import '../../domain/model/musica.dart';
import 'retry.dart';

class MusicaFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final Duration _timeout;
  final Duration Function(int attempt) _retryBackoff;

  MusicaFirestoreDataSource({
    FirebaseFirestore? firestore,
    Duration timeout = _defaultTimeout,
    Duration Function(int attempt)? retryBackoff,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _timeout = timeout,
       _retryBackoff = retryBackoff ?? defaultRetryBackoff;

  static const String _collection = 'musicas';
  static const _defaultTimeout = Duration(seconds: 10);

  static const _transientFirebaseCodes = {
    'unavailable',
    'deadline-exceeded',
    'aborted',
    'internal',
  };

  Future<Musica> getByCodigo(String codigo) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await withRetry(
        () => _firestore
            .collection(_collection)
            .doc(codigo)
            .get()
            .timeout(_timeout),
        shouldRetry: _isTransientFirestoreError,
        backoff: _retryBackoff,
      );
    } on FirebaseException catch (e) {
      throw MusicaConsultaException(
        e.message ?? 'Falha ao consultar o Firestore.',
        cause: e,
      );
    } catch (e) {
      throw MusicaConsultaException(
        'Sem conexão com o servidor. Verifique sua internet.',
        cause: e,
      );
    }

    if (!snapshot.exists || snapshot.data() == null) {
      throw MusicaNaoEncontradaException(codigo);
    }

    final musica = Musica.fromMap(snapshot.id, snapshot.data()!);
    if (musica.spotifyUri.isEmpty) {
      throw MusicaNaoEncontradaException(codigo);
    }
    return musica;
  }

  bool _isTransientFirestoreError(Object error) {
    if (error is FirebaseException) {
      return _transientFirebaseCodes.contains(error.code);
    }
    return error is TimeoutException;
  }
}
