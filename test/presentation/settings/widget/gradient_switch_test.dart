import 'package:beatspan/presentation/settings/widget/gradient_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza ligado e chama onChanged(false) ao tocar', (
    tester,
  ) async {
    bool? received;
    await tester.pumpWidget(
      MaterialApp(
        home: GradientSwitch(value: true, onChanged: (v) => received = v),
      ),
    );

    await tester.tap(find.byType(GradientSwitch));
    await tester.pump(const Duration(milliseconds: 150));

    expect(received, isFalse);
  });

  testWidgets('renderiza desligado e chama onChanged(true) ao tocar', (
    tester,
  ) async {
    bool? received;
    await tester.pumpWidget(
      MaterialApp(
        home: GradientSwitch(value: false, onChanged: (v) => received = v),
      ),
    );

    await tester.tap(find.byType(GradientSwitch));
    await tester.pump(const Duration(milliseconds: 150));

    expect(received, isTrue);
  });
}
