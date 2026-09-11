import 'package:dartz/dartz.dart';

import '../failure.dart';

abstract class BaseUseCase<In, Out, F extends Failure> {
  Future<Either<F, Out>> execute(In input);
}
