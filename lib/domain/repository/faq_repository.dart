import 'package:dartz/dartz.dart';
import '../failure.dart';
import '../model/faqs.dart';

abstract class FaqRepository {
  Future<Either<Failure, List<Faq>>> getFaqs();
}
