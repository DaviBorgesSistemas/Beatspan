// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';

import '../../domain/enum/flow_state.dart';
import '../../domain/error_reporting.dart';
import '../../domain/model/contact_message.dart';
import '../../domain/usecase/send_contact_message_usecase.dart';

class ContactViewModel {
  final SendContactMessageUseCase _sendContactMessageUseCase;
  ContactViewModel(this._sendContactMessageUseCase);

  final state = ValueNotifier(FlowState.content);
  final errorMessage = ValueNotifier<String?>(null);

  Future<bool> send(ContactMessage message) async {
    state.value = FlowState.loading;
    final result = await _sendContactMessageUseCase.execute(message);
    return result.fold(
      (failure) {
        reportNonFatalError(
          Exception(failure.message),
          StackTrace.current,
          information: [
            'ContactViewModel.send',
            'Failure.runtimeType=${failure.runtimeType}',
          ],
        );
        errorMessage.value = failure.message;
        state.value = FlowState.error;
        return false;
      },
      (_) {
        state.value = FlowState.success;
        return true;
      },
    );
  }

  void dispose() {
    state.dispose();
    errorMessage.dispose();
  }
}
