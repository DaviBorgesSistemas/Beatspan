import 'package:dartz/dartz.dart';

import '../failure.dart';
import '../model/faqs.dart';
import '../repository/faq_repository.dart';
import 'base_usecase.dart';

class FaqsUseCase extends BaseUseCase<void, List<Faq>, FaqFailure> {
  final FaqRepository _repository;
  FaqsUseCase(this._repository);

  @override
  Future<Either<FaqFailure, List<Faq>>> execute(void input) async {
    return _repository.getFaqs();
  }
}
