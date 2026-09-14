import 'dart:convert';

import 'package:beatspan/data/data_source/faq_local_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FaqLocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = FaqLocalDataSourceImpl();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  void mockAsset(String fileName, String content) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == fileName) {
            return ByteData.sublistView(
              Uint8List.fromList(utf8.encode(content)),
            );
          }
          return null;
        });
  }

  test('decodifica o JSON do asset quando ele existe', () async {
    mockAsset('assets/faq.json', '{"perguntas": [1, 2, 3]}');

    final result = await dataSource.getDataFromJson('assets/faq.json');

    expect(result, {
      'perguntas': [1, 2, 3],
    });
  });

  test(
    'propaga o erro quando o asset não existe (rootBundle lança FlutterError, '
    'não Exception, então o catch em getDataFromJson não o intercepta)',
    () async {
      mockAsset('assets/faq.json', '{}');

      await expectLater(
        () => dataSource.getDataFromJson('assets/inexistente.json'),
        throwsA(isA<FlutterError>()),
      );
    },
  );

  test(
    'retorna string vazia quando o conteúdo do asset não é um JSON válido',
    () async {
      mockAsset('assets/faq_invalido.json', 'não é json');

      final result = await dataSource.getDataFromJson(
        'assets/faq_invalido.json',
      );

      expect(result, '');
    },
  );
}
