import 'package:beatspan/presentation/game/game_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameViewModel viewModel;

  setUp(() {
    viewModel = GameViewModel();
  });

  group('extractCodigo', () {
    test('extrai o código de uma URL do domínio principal', () {
      expect(viewModel.extractCodigo('https://beatspangame.com/0006'), '0006');
    });

    test('extrai o código com prefixo www.', () {
      expect(
        viewModel.extractCodigo('https://www.beatspangame.com/0006'),
        '0006',
      );
    });

    test('extrai o código de beatspan.web.app', () {
      expect(viewModel.extractCodigo('https://beatspan.web.app/0006'), '0006');
    });

    test('extrai o código de beatspan.firebaseapp.com', () {
      expect(
        viewModel.extractCodigo('https://beatspan.firebaseapp.com/0006'),
        '0006',
      );
    });

    test('extrai apenas o último segmento de path quando há mais de um', () {
      expect(
        viewModel.extractCodigo('https://beatspangame.com/br/aaaq0001/00006'),
        '00006',
      );
    });

    test('retorna null para host não reconhecido', () {
      expect(viewModel.extractCodigo('https://hitstergame.com/0006'), isNull);
    });

    test('retorna null para scheme não http/https', () {
      expect(viewModel.extractCodigo('spotify:track:0006'), isNull);
    });

    test('retorna null para URL sem path', () {
      expect(viewModel.extractCodigo('https://beatspangame.com'), isNull);
    });

    test('retorna null para URL sem path (apenas barra)', () {
      expect(viewModel.extractCodigo('https://beatspangame.com/'), isNull);
    });

    test('retorna null para string que não é uma URL válida', () {
      expect(viewModel.extractCodigo('não é uma url'), isNull);
    });
  });

  group('validate', () {
    test('retorna beatspanCode para URL válida do domínio', () {
      expect(
        viewModel.validate('https://beatspangame.com/0006'),
        QrValidationResult.beatspanCode,
      );
    });

    test('retorna invalid para URL de outro domínio', () {
      expect(
        viewModel.validate('https://open.spotify.com/track/abc123'),
        QrValidationResult.invalid,
      );
    });

    test('retorna invalid para conteúdo de QR code arbitrário', () {
      expect(
        viewModel.validate('qualquer texto escaneado'),
        QrValidationResult.invalid,
      );
    });
  });
}
