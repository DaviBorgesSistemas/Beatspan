import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/faqs.dart';
import 'package:beatspan/domain/repository/faq_repository.dart';
import 'package:beatspan/domain/usecase/faqs_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFaqRepository extends Mock implements FaqRepository {}

void main() {
  late _MockFaqRepository repository;
  late FaqsUseCase useCase;

  setUp(() {
    repository = _MockFaqRepository();
    useCase = FaqsUseCase(repository);
  });

  test('delega a busca ao repositório e repassa o resultado de sucesso', () async {
    final faqs = [Faq(title: 'FAQ', session: [])];
    when(() => repository.getFaqs()).thenAnswer((_) async => Right(faqs));

    final result = await useCase.execute(null);

    expect(result, Right(faqs));
    verify(() => repository.getFaqs()).called(1);
  });

  test('repassa a falha do repositório sem alterá-la', () async {
    final failure = Failure(0, 'erro ao ler asset');
    when(() => repository.getFaqs()).thenAnswer((_) async => Left(failure));

    final result = await useCase.execute(null);

    expect(result, Left(failure));
  });
}
