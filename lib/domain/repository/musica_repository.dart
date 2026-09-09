import 'package:dartz/dartz.dart';

import '../failure.dart';
import '../model/musica.dart';

abstract class MusicaRepository {
  Future<Either<Failure, Musica>> getByCodigo(String codigo);
}
