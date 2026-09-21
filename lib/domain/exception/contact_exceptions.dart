// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

class ContactEnvioException implements Exception {
  final String message;
  final Object? cause;
  ContactEnvioException(this.message, {this.cause});

  @override
  String toString() => 'Erro ao enviar mensagem de contato: $message';
}
