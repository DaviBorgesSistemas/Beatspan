import 'package:beatspan/presentation/camera_permission/camera_permission_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPermissionHandlerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PermissionHandlerPlatform {}

void main() {
  late PermissionHandlerPlatform originalPlatform;
  late _MockPermissionHandlerPlatform mockPlatform;

  setUpAll(() {
    registerFallbackValue(<Permission>[Permission.camera]);
  });

  setUp(() {
    originalPlatform = PermissionHandlerPlatform.instance;
    mockPlatform = _MockPermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = mockPlatform;
  });

  tearDown(() {
    PermissionHandlerPlatform.instance = originalPlatform;
  });

  Widget buildSubject() {
    return const MaterialApp(home: CameraPermissionView());
  }

  testWidgets('monta e mostra os textos e o botão esperados', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(
      find.text('BEATSPAN PRECISA ACESSAR\nSUA CÂMERA.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'O app BEATSPAN precisa acessar a câmera do dispositivo para escanear os QR codes das cartas.',
      ),
      findsOneWidget,
    );
    expect(find.text('PERMITIR'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
  });

  testWidgets('botão fechar (ícone X) faz Navigator.pop(false)', (
    tester,
  ) async {
    bool? poppedValue;
    const sentinel = Object();
    dynamic result = sentinel;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const CameraPermissionView(),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(CameraPermissionView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    poppedValue = result == sentinel ? null : result as bool?;
    expect(poppedValue, isFalse);
    expect(find.byType(CameraPermissionView), findsNothing);
  });

  testWidgets(
    'tocar em PERMITIR com status granted faz Navigator.pop(true)',
    (tester) async {
      when(() => mockPlatform.requestPermissions(any())).thenAnswer(
        (_) async => {Permission.camera: PermissionStatus.granted},
      );

      const sentinel = Object();
      dynamic result = sentinel;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const CameraPermissionView(),
                      ),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PERMITIR'));
      await tester.pumpAndSettle();

      final poppedValue = result == sentinel ? null : result as bool?;
      expect(poppedValue, isTrue);
      expect(find.byType(CameraPermissionView), findsNothing);
      verify(() => mockPlatform.requestPermissions([Permission.camera]))
          .called(1);
    },
  );
}
