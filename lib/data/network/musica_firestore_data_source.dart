import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/exception/musica_exceptions.dart';
import '../../domain/model/musica.dart';

/// Acesso à coleção `musicas` no Firestore.
///
/// Schema esperado do documento (id do documento = código curto do QR,
/// ex: "0006"):
/// {
///   "spotify_id": "3n3Ppam7vgaVa1iaRUc9Lp",
///   "spotify_uri": "spotify:track:3n3Ppam7vgaVa1iaRUc9Lp"
/// }
class MusicaFirestoreDataSource {
  final FirebaseFirestore _firestore;

  MusicaFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'musicas';

  Future<Musica> getByCodigo(String codigo) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore.collection(_collection).doc(codigo).get();
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
