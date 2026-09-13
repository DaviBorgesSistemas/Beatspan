import 'package:beatspan/presentation/resource/font_manager.dart';
import 'package:beatspan/presentation/resource/style_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const color = Colors.white;

  test('getRegularStyle usa peso regular e fonte/tamanho padrão', () {
    final style = getRegularStyle(color: color);

    expect(style.fontWeight, FontWeightManager.regular);
    expect(style.fontFamily, FontConstants.fontFamily);
    expect(style.fontSize, FontSize.s12);
    expect(style.color, color);
  });

  test('getLightStyle usa peso light', () {
    expect(
      getLightStyle(color: color, fontSize: FontSize.s14).fontWeight,
      FontWeightManager.light,
    );
  });

  test('getBoldStyle usa peso bold', () {
    expect(getBoldStyle(color: color).fontWeight, FontWeightManager.bold);
  });

  test('getSemiBoldStyle usa peso semiBold', () {
    expect(
      getSemiBoldStyle(color: color).fontWeight,
      FontWeightManager.semiBold,
    );
  });

  test('getMediumStyle usa peso medium', () {
    expect(getMediumStyle(color: color).fontWeight, FontWeightManager.medium);
  });
}
