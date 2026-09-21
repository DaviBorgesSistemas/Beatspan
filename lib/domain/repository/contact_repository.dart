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

abstract class ContactRepository {
  Future<Either<ContactFailure, Unit>> send(ContactMessage message);
}
