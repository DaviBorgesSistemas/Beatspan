// Verificação automatizada de acessibilidade (WCAG) para as telas/widgets
// que ganharam Semantics nesta sessão (EXP-001, docs/4-ACTION_PLAN.md).
// Usa os guidelines embutidos do flutter_test em vez de um teste manual com
// TalkBack — não substitui a validação em dispositivo real, mas garante que
// todo nó tocável tem rótulo semântico e tamanho mínimo de toque.

import 'package:beatspan/app/app_prefs.dart';
import 'package:beatspan/data/network/spotify_service.dart';
import 'package:beatspan/presentation/change_spotify/change_spotify_view.dart';
import 'package:beatspan/presentation/change_spotify/connect_spotify_premium_view_model.dart';
import 'package:beatspan/presentation/change_spotify/widgets/spotify_consent_dialog.dart';
import 'package:beatspan/presentation/first_time/first_time_view.dart';
import 'package:beatspan/presentation/share/widgets/next_card_button.dart';
import 'package:beatspan/presentation/share/widgets/no_internet_view.dart';
import 'package:beatspan/presentation/share/widgets/scaffold_hitster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSpotifyService extends Mock implements SpotifyService {}

void main() {
  // Tamanho de tela default do flutter_test (800x600, paisagem) não
  // representa um celular real e gera overflows espúrios em telas com
  // bastante conteúdo vertical. Um celular Android pequeno típico em
  // retrato evita falso-positivo de layout nos testes abaixo.
  const phoneSize = Size(390, 844);

  Future<void> checkGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }

  testWidgets('NoInternetView: botões tocáveis têm rótulo e tamanho mínimo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: NoInternetView()));
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('NextCardButton: botão tem rótulo e tamanho mínimo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NextCardButton(onTap: () {})),
      ),
    );
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('FirstTimeView: botões "Ler as regras"/"Continuar" têm rótulo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: FirstTimeView()));
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets(
    'SpotifyConsentDialog: link e botão "Aceitar e conectar" têm rótulo',
    (tester) async {
      await tester.binding.setSurfaceSize(phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SpotifyConsentDialog())),
      );
      await checkGuidelines(tester);
      handle.dispose();
    },
  );

  testWidgets('ScaffoldHitster: ícones de ajuda/fechar têm rótulo (tooltip)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: ScaffoldHitster(sndRoute: '/close')),
    );
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('ChangeSpotifyView: botão voltar e CTAs principais têm rótulo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appPreferences = AppPreferences(
      await SharedPreferences.getInstance(),
    );
    final viewModel = ConnectSpotifyPremiumViewModel(
      _MockSpotifyService(),
      appPreferences,
    );

    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeSpotifyView(
          appPreferences: appPreferences,
          viewModel: viewModel,
        ),
      ),
    );
    await checkGuidelines(tester);
    handle.dispose();
    viewModel.dispose();
  });
}
