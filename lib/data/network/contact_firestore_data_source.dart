// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/exception/contact_exceptions.dart';
import '../../domain/model/contact_message.dart';
import 'retry.dart';

class ContactFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final Duration _timeout;
  final Duration Function(int attempt) _retryBackoff;

  ContactFirestoreDataSource({
    FirebaseFirestore? firestore,
    Duration timeout = _defaultTimeout,
    Duration Function(int attempt)? retryBackoff,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _timeout = timeout,
       _retryBackoff = retryBackoff ?? defaultRetryBackoff;

  static const String _collection = 'contact_messages';
  static const _defaultTimeout = Duration(seconds: 10);

  static const _transientFirebaseCodes = {
    'unavailable',
    'deadline-exceeded',
    'aborted',
    'internal',
  };

  Future<void> send(ContactMessage message) async {
    try {
      await withRetry(
        () => _firestore
            .collection(_collection)
            .add({
              ...message.toMap(),
              'created_at': FieldValue.serverTimestamp(),
            })
            .timeout(_timeout),
        shouldRetry: _isTransientFirestoreError,
        backoff: _retryBackoff,
      );
    } on FirebaseException catch (e) {
      throw ContactEnvioException(
        e.message ?? 'Falha ao enviar a mensagem.',
        cause: e,
      );
    } catch (e) {
      throw ContactEnvioException(
        'Sem conexão com o servidor. Verifique sua internet.',
        cause: e,
      );
    }
  }

  bool _isTransientFirestoreError(Object error) {
    if (error is FirebaseException) {
      return _transientFirebaseCodes.contains(error.code);
    }
    return error is TimeoutException;
  }
}
