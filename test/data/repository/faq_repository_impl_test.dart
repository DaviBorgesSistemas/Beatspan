import 'package:beatspan/data/data_source/faq_local_data_source.dart';
import 'package:beatspan/data/data_source/json_assets.dart';
import 'package:beatspan/data/repository/faq_repository_impl.dart';
import 'package:beatspan/domain/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFaqLocalDataSource extends Mock implements FaqLocalDataSource {}

void main() {
  late _MockFaqLocalDataSource dataSource;
  late FaqRepositoryImpl repository;

  setUp(() {
    dataSource = _MockFaqLocalDataSource();
    repository = FaqRepositoryImpl(dataSource);
  });

  test(
    'retorna Right(List<Faq>) convertendo o JSON retornado pela data source',
    () async {
      when(() => dataSource.getDataFromJson(JsonAssets.faqs)).thenAnswer(
        (_) async => [
          {
            'title': 'FAQ 1',
            'session': [
              {'title': 'Pergunta', 'content': 'Resposta'},
            ],
          },
        ],
      );

      final result = await repository.getFaqs();

      expect(result.isRight(), isTrue);
      final faqs = result.getOrElse(() => []);
      expect(faqs, hasLength(1));
      expect(faqs.first.title, 'FAQ 1');
      expect(faqs.first.session!.first.content, 'Resposta');
    },
  );

  test('retorna Left(Failure) quando a data source lança exceção', () async {
    when(
      () => dataSource.getDataFromJson(JsonAssets.faqs),
    ).thenThrow(Exception('erro ao ler asset'));

    final result = await repository.getFaqs();

    expect(result.isLeft(), isTrue);
    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<FaqErroInesperado>());
  });
}
