// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';

import '../../domain/exception/contact_exceptions.dart';
import '../../domain/failure.dart';
import '../../domain/model/contact_message.dart';
import '../../domain/repository/contact_repository.dart';
import '../network/contact_firestore_data_source.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactFirestoreDataSource _dataSource;
  ContactRepositoryImpl(this._dataSource);

  @override
  Future<Either<ContactFailure, Unit>> send(ContactMessage message) async {
    try {
      await _dataSource.send(message);
      return const Right(unit);
    } on ContactEnvioException catch (e) {
      return Left(ContactEnvioErro(e.message));
    } catch (e) {
      return Left(ContactEnvioErro('Erro inesperado ao enviar a mensagem: $e'));
    }
  }
}
