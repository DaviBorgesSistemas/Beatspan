// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import 'dart:ffi';
import '../../domain/enum/flow_state.dart';
import '../../domain/error_reporting.dart';
import '../../domain/model/faqs.dart';
import '../../domain/usecase/faqs_usecase.dart';

class FaqsViewModel {
  final FaqsUseCase _faqsUseCase;
  FaqsViewModel(this._faqsUseCase);

  final state = ValueNotifier(FlowState.content);

  final faqs = ValueNotifier<List<Faq>?>(null);

  int get faqCount {
    return faqs.value?.length ?? 0;
  }

  void start() {
    _getFaqs();
  }

  void _getFaqs() async {
    state.value = FlowState.loading;
    (await _faqsUseCase.execute(Void)).fold(
      (failure) {
        reportNonFatalError(
          Exception(failure.message),
          StackTrace.current,
          information: [
            'FaqsViewModel._getFaqs',
            'Failure.runtimeType=${failure.runtimeType}',
          ],
        );
        state.value = FlowState.error;
      },
      (success) {
        faqs.value = success;
        state.value = FlowState.success;
      },
    );
  }
}
