import 'package:dartz/dartz.dart';

import '../../domain/exception/musica_exceptions.dart';
import '../../domain/model/musica.dart';
import '../../domain/repository/musica_repository.dart';
import '../failure.dart';
import '../network/musica_firestore_data_source.dart';

class MusicaRepositoryImpl implements MusicaRepository {
  final MusicaFirestoreDataSource _dataSource;
  MusicaRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Musica>> getByCodigo(String codigo) async {
    try {
      final musica = await _dataSource.getByCodigo(codigo);
      return Right(musica);
    } on MusicaNaoEncontradaException catch (e) {
      return Left(Failure(404, e.toString()));
    } on MusicaConsultaException catch (e) {
      return Left(Failure(0, e.message));
    } catch (e) {
      return Left(Failure(0, 'Erro inesperado ao buscar a música: $e'));
    }
  }
}
