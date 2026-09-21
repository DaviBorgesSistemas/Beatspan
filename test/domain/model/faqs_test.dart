import 'package:beatspan/domain/model/faqs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Session', () {
    test('fromJson lê title e content', () {
      final session = Session.fromJson({
        'title': 'Pergunta',
        'content': 'Resposta',
      });

      expect(session.title, 'Pergunta');
      expect(session.content, 'Resposta');
    });

    test('toJson serializa title e content', () {
      final session = Session(title: 'Pergunta', content: 'Resposta');

      expect(session.toJson(), {'title': 'Pergunta', 'content': 'Resposta'});
    });
  });

  group('Faq', () {
    test('fromJson lê title e a lista de sessões', () {
      final faq = Faq.fromJson({
        'title': 'Categoria',
        'session': [
          {'title': 'P1', 'content': 'R1'},
          {'title': 'P2', 'content': 'R2'},
        ],
      });

      expect(faq.title, 'Categoria');
      expect(faq.session, hasLength(2));
      expect(faq.session![0].title, 'P1');
      expect(faq.session![1].content, 'R2');
    });

    test('fromJson sem "session" deixa a lista nula', () {
      final faq = Faq.fromJson({'title': 'Categoria'});

      expect(faq.session, isNull);
    });

    test('toJson serializa title e sessões quando presentes', () {
      final faq = Faq(
        title: 'Categoria',
        session: [Session(title: 'P1', content: 'R1')],
      );

      expect(faq.toJson(), {
        'title': 'Categoria',
        'session': [
          {'title': 'P1', 'content': 'R1'},
        ],
      });
    });

    test('toJson omite "session" quando nula', () {
      final faq = Faq(title: 'Categoria');

      expect(faq.toJson(), {'title': 'Categoria'});
    });
  });
}
