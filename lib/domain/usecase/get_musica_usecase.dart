import 'package:dartz/dartz.dart';

import '../failure.dart';
import '../model/musica.dart';
import '../repository/musica_repository.dart';
import 'base_usecase.dart';

class GetMusicaUseCase extends BaseUseCase<String, Musica> {
  final MusicaRepository _repository;
  GetMusicaUseCase(this._repository);

  @override
  Future<Either<Failure, Musica>> execute(String input) async {
    return _repository.getByCodigo(input);
  }
}
