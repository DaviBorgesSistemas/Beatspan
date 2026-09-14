// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:dartz/dartz.dart';
import '../failure.dart';
import '../model/faqs.dart';

abstract class FaqRepository {
  Future<Either<FaqFailure, List<Faq>>> getFaqs();
}
