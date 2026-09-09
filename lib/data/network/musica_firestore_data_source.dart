import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/exception/musica_exceptions.dart';
import '../../domain/model/musica.dart';

class MusicaFirestoreDataSource {
  final FirebaseFirestore _firestore;

  MusicaFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'musicas';
  static const _timeout = Duration(seconds: 10);

  Future<Musica> getByCodigo(String codigo) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection(_collection)
          .doc(codigo)
          .get()
          .timeout(_timeout);
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
}
