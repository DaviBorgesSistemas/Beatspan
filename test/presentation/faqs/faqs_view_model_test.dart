import 'package:beatspan/domain/enum/flow_state.dart';
import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/faqs.dart';
import 'package:beatspan/domain/usecase/faqs_usecase.dart';
import 'package:beatspan/presentation/faqs/faqs_view_model.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFaqsUseCase extends Mock implements FaqsUseCase {}

void main() {
  late _MockFaqsUseCase faqsUseCase;
  late FaqsViewModel viewModel;

  setUp(() {
    faqsUseCase = _MockFaqsUseCase();
    viewModel = FaqsViewModel(faqsUseCase);
  });

  test('faqCount é 0 quando faqs ainda não foi carregado', () {
    expect(viewModel.faqCount, 0);
  });

  test('start() com sucesso popula faqs e marca estado como success', () async {
    final faqs = [
      Faq(
        title: 'Título',
        session: [Session(title: 't', content: 'c')],
      ),
    ];
    when(() => faqsUseCase.execute(any())).thenAnswer((_) async => Right(faqs));

    viewModel.start();
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.value, FlowState.success);
    expect(viewModel.faqs.value, faqs);
    expect(viewModel.faqCount, 1);
  });

  test('start() com falha marca estado como error e reporta o erro', () async {
    when(
      () => faqsUseCase.execute(any()),
    ).thenAnswer((_) async => const Left(FaqErroInesperado('falhou')));

    viewModel.start();
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.value, FlowState.error);
    expect(viewModel.faqs.value, isNull);
  });
}
