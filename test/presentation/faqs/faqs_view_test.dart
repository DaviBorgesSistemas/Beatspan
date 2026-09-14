import 'dart:async';

import 'package:beatspan/domain/failure.dart';
import 'package:beatspan/domain/model/faqs.dart';
import 'package:beatspan/domain/usecase/faqs_usecase.dart';
import 'package:beatspan/presentation/faqs/faqs_view.dart';
import 'package:beatspan/presentation/faqs/faqs_view_model.dart';
import 'package:beatspan/presentation/faqs/widgets/faq_tile.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFaqsUseCase extends Mock implements FaqsUseCase {}

void main() {
  late _MockFaqsUseCase faqsUseCase;

  setUp(() {
    faqsUseCase = _MockFaqsUseCase();
  });

  Widget buildSubject(FaqsViewModel viewModel) {
    return MaterialApp(home: FaqsView(viewModel: viewModel));
  }

  testWidgets('mostra loading enquanto o use case não resolve', (tester) async {
    final completer = Completer<Either<FaqFailure, List<Faq>>>();
    when(() => faqsUseCase.execute(any())).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildSubject(FaqsViewModel(faqsUseCase)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(Right([Faq(title: 'Categoria', session: const [])]));
    await tester.pumpAndSettle();
  });

  testWidgets('mostra as FaqTiles quando o use case resolve com sucesso', (
    tester,
  ) async {
    when(() => faqsUseCase.execute(any())).thenAnswer(
      (_) async => Right([
        Faq(title: 'Categoria 1', session: const []),
        Faq(title: 'Categoria 2', session: const []),
      ]),
    );

    await tester.pumpWidget(buildSubject(FaqsViewModel(faqsUseCase)));
    await tester.pumpAndSettle();

    expect(find.byType(FaqTile), findsNWidgets(2));
    expect(find.text('Perguntas frequentes'), findsOneWidget);
  });

  testWidgets('mostra EmptyContainer quando o use case falha', (tester) async {
    when(
      () => faqsUseCase.execute(any()),
    ).thenAnswer((_) async => const Left(FaqErroInesperado('erro')));

    await tester.pumpWidget(buildSubject(FaqsViewModel(faqsUseCase)));
    await tester.pumpAndSettle();

    expect(find.byType(FaqTile), findsNothing);
  });

  testWidgets('botão de voltar chama Navigator.pop', (tester) async {
    when(
      () => faqsUseCase.execute(any()),
    ).thenAnswer((_) async => Right(<Faq>[]));

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => FaqsView(viewModel: FaqsViewModel(faqsUseCase)),
        ),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/faqs'),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(FaqsView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(FaqsView), findsNothing);
  });
}
