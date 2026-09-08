import 'package:dartz/dartz.dart';

import '../../data/failure.dart';
import '../model/musica.dart';

abstract class MusicaRepository {
  /// Busca a música pelo código curto extraído da URL do QR code
  /// (ex: "0006"). Em caso de falha, `Failure.code` é 404 quando o
  /// código não existe no Firestore, ou 0 para qualquer outro erro
  /// (sem internet, Firestore indisponível, etc).
  Future<Either<Failure, Musica>> getByCodigo(String codigo);
}
