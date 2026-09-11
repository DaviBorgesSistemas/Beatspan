import 'package:beatspan/domain/enum/settings_enum.dart';
import 'package:beatspan/presentation/game/turn_phone_ready_view.dart';
import 'package:beatspan/presentation/routes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tamanho de tela default do flutter_test (800x600, paisagem) não
  // representa um celular real e gera overflows espúrios com o conteúdo
  // vertical desta tela (imagem + título + texto + badge). Segue o mesmo
  // padrão de test/presentation/accessibility_test.dart.
  const phoneSize = Size(390, 844);

  const accelerometerChannel = EventChannel(
    'dev.fluttercommunity.plus/sensors/accelerometer',
  );
  const accelerometerMethodChannel = MethodChannel(
    'dev.fluttercommunity.plus/sensors/method',
  );

  setUp(() {
    // `setAccelerationSamplingPeriod` é chamado via MethodChannel antes de
    // assinar o EventChannel — sem um mock handler o teste trava esperando
    // uma resposta que nunca chega.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accelerometerMethodChannel, (call) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accelerometerMethodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(accelerometerChannel, null);
  });

  Widget buildSubject({
    required TurnPhoneMode mode,
    required VoidCallback onReady,
  }) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == Routes.homeRoute) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('HOME_STUB')),
            settings: settings,
          );
        }
        return null;
      },
      home: TurnPhoneReadyView(mode: mode, onReady: onReady),
    );
  }

  group('elementos visuais comuns aos dois modos', () {
    testWidgets('modo countdown mostra título, imagem e badge "Modo Jogo"', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildSubject(mode: TurnPhoneMode.countdown, onReady: () {}),
      );
      await tester.pump();

      expect(find.text('VIRE O TELEFONE'), findsOneWidget);
      expect(find.text('Modo Jogo'), findsOneWidget);
      expect(find.text('Pre-escuta'), findsOneWidget);
      expect(find.text('A música começará em...'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Evita deixar o Timer.periodic pendente ao final do teste.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('modo gyroscope mostra título e instrução específica (smoke test)', (
      tester,
    ) async {
      // Sem mock de EventChannel, `_listenForFaceDown`/`_listenForProximity`
      // simplesmente assinam streams que não emitem nada durante o teste —
      // suficiente para verificar que a tela monta e mostra o conteúdo
      // correto do modo gyroscope, sem completar o fluxo de virar o telefone.
      await tester.binding.setSurfaceSize(phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var readyCalled = false;
      await tester.pumpWidget(
        buildSubject(
          mode: TurnPhoneMode.gyroscope,
          onReady: () => readyCalled = true,
        ),
      );
      await tester.pump();

      expect(find.text('VIRE O TELEFONE'), findsOneWidget);
      expect(
        find.text(
          'Coloque o dispositivo virado para baixo para começar a música.',
        ),
        findsOneWidget,
      );
      expect(find.text('Modo Jogo'), findsOneWidget);
      expect(readyCalled, isFalse);
    });
  });

  group('modo countdown', () {
    testWidgets(
      'contador decrementa a cada segundo e chama onReady após ~3 segundos',
      (tester) async {
        await tester.binding.setSurfaceSize(phoneSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var readyCalled = false;
        await tester.pumpWidget(
          buildSubject(
            mode: TurnPhoneMode.countdown,
            onReady: () => readyCalled = true,
          ),
        );
        await tester.pump();

        expect(find.text('3'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('2'), findsOneWidget);
        expect(readyCalled, isFalse);

        await tester.pump(const Duration(seconds: 1));
        expect(find.text('1'), findsOneWidget);
        expect(readyCalled, isFalse);

        await tester.pump(const Duration(seconds: 1));
        expect(readyCalled, isTrue);
      },
    );
  });

  group('modo gyroscope com fallback de proximidade (sem plugin nativo)', () {
    testWidgets(
      'ao detectar telefone virado para baixo via acelerômetro mockado, completa via fallback de proximidade (1500ms) e chama onReady',
      (tester) async {
        // `ProximitySensor.events` cai no branch `else` (fake stream de 1h)
        // porque `flutter test` não roda em Android/iOS — então o único jeito
        // de completar o fluxo gyroscope é através do
        // `_scheduleProximityFallback` (Timer de 1500ms), que dispara quando
        // `_isFaceDown` é true. Mockamos apenas o EventChannel do
        // acelerômetro para simular o telefone virado para baixo; a
        // proximidade real nunca é exercitada aqui (ver comentário acima
        // sobre a limitação estrutural do proximity_sensor em teste).
        await tester.binding.setSurfaceSize(phoneSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        late MockStreamHandlerEventSink accelerometerSink;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              accelerometerChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  accelerometerSink = events;
                },
              ),
            );

        var readyCalled = false;
        await tester.pumpWidget(
          buildSubject(
            mode: TurnPhoneMode.gyroscope,
            onReady: () => readyCalled = true,
          ),
        );
        await tester.pump();

        // z bem negativo => telefone virado para baixo (threshold: -8.5).
        accelerometerSink.success(<double>[
          0.0,
          0.0,
          -9.8,
          DateTime.now().microsecondsSinceEpoch.toDouble(),
        ]);
        await tester.pump();

        expect(readyCalled, isFalse);

        await tester.pump(const Duration(milliseconds: 1500));

        expect(readyCalled, isTrue);
      },
    );
  });

  group('botão voltar', () {
    testWidgets(
      'PopScope intercepta o back e navega para Routes.homeRoute removendo a pilha',
      (tester) async {
        await tester.binding.setSurfaceSize(phoneSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildSubject(mode: TurnPhoneMode.countdown, onReady: () {}),
        );
        await tester.pump();

        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        // Simula o botão de voltar do sistema (Android) / gesto de voltar.
        await widgetsAppState.didPopRoute();
        await tester.pumpAndSettle();

        expect(find.text('HOME_STUB'), findsOneWidget);
        expect(find.byType(TurnPhoneReadyView), findsNothing);

        // Encerra o Timer.periodic pendente do modo countdown antes do fim
        // do teste.
      },
    );
  });
}
