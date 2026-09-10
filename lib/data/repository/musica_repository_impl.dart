import 'package:dartz/dartz.dart';

import '../../domain/exception/musica_exceptions.dart';
import '../../domain/failure.dart';
import '../../domain/model/musica.dart';
import '../../domain/repository/musica_repository.dart';
import '../network/musica_firestore_data_source.dart';

class MusicaRepositoryImpl implements MusicaRepository {
  final MusicaFirestoreDataSource _dataSource;
  MusicaRepositoryImpl(this._dataSource);

  // Cache em memória por código: a mesma carta escaneada de novo na mesma
  // sessão do app reaproveita a consulta anterior em vez de rechamar o
  // Firestore. Só sucesso é cacheado — "não encontrada" e erros de rede
  // seguem re-consultando, pois o catálogo pode mudar e falhas são
  // transitórias.
  final Map<String, Musica> _cache = {};

  @override
  Future<Either<Failure, Musica>> getByCodigo(String codigo) async {
    final cached = _cache[codigo];
    if (cached != null) {
      return Right(cached);
    }

    try {
      final musica = await _dataSource.getByCodigo(codigo);
      _cache[codigo] = musica;
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
