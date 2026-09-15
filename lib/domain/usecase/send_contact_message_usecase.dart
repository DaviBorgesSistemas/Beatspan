// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';

import '../failure.dart';
import '../model/contact_message.dart';
import '../repository/contact_repository.dart';
import 'base_usecase.dart';

class SendContactMessageUseCase
    extends BaseUseCase<ContactMessage, Unit, ContactFailure> {
  final ContactRepository _repository;
  SendContactMessageUseCase(this._repository);

  @override
  Future<Either<ContactFailure, Unit>> execute(ContactMessage input) async {
    return _repository.send(input);
  }
}
