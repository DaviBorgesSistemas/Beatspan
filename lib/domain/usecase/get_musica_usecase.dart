// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';

import '../failure.dart';
import '../model/musica.dart';
import '../repository/musica_repository.dart';
import 'base_usecase.dart';

class GetMusicaUseCase extends BaseUseCase<String, Musica, MusicaFailure> {
  final MusicaRepository _repository;
  GetMusicaUseCase(this._repository);

  @override
  Future<Either<MusicaFailure, Musica>> execute(String input) async {
    return _repository.getByCodigo(input);
  }
}
