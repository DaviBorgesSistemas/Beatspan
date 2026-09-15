// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

enum ContactSubject { duvida, sugestao, problemaTecnico, outro }

extension ContactSubjectLabel on ContactSubject {
  String get label => switch (this) {
    ContactSubject.duvida => 'Dúvida',
    ContactSubject.sugestao => 'Sugestão',
    ContactSubject.problemaTecnico => 'Problema técnico',
    ContactSubject.outro => 'Outro',
  };
}

class ContactMessage {
  final String name;
  final String email;
  final String itemNumber;
  final ContactSubject subject;
  final String message;

  const ContactMessage({
    required this.name,
    required this.email,
    required this.itemNumber,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'item_number': itemNumber,
      'subject': subject.name,
      'message': message,
    };
  }
}
