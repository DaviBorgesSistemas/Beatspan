# Beatspan — Plano de Ação
**Projeto:** Beatspan
**Data da análise:** 2026-09-12
**Versão do documento:** 3.0
**Fonte de IDs e esforços:** `docs/ARCHITECTURAL_REVIEW.md`, `docs/SECURITY_REPORT.md`, `docs/TECH_DEBT_REGISTER.md`

---

## Críticos — Sprint Atual (Imediato)

| Título | ID | Esforço | Impacto | Responsável Sugerido | Critério de Aceite |
|--------|----|---------|---------|---------------------|-------------------|
| ~~Remover `.env` dos assets; migrar para `--dart-define`; revogar Client ID Spotify atual~~ — **Resolvido em 2026-09-12** | SEC-002 | P | Alto | Backend / DevOps | ✅ `.env` ausente de `pubspec.yaml`; ✅ `flutter_dotenv` removido; ✅ `String.fromEnvironment` + `--dart-define-from-file=env.json` em `lib/app/di.dart`; ✅ novo Client ID ativo no Spotify Dashboard |
| ~~Atualizar `path_provider_foundation` para 2.6.0~~ — **Resolvido em 2026-09-12** | SEC-003 | P | Médio | DevOps / Mobile | ✅ `pubspec.lock` reflete versão 2.6.0; ✅ sem versão retracted (`flutter pub outdated`); ✅ `flutter analyze` e `flutter test` (174/174) passando |

---

## Curto Prazo — Até 4 Semanas

| Título | ID | Esforço | Impacto | Responsável Sugerido | Critério de Aceite |
|--------|----|---------|---------|---------------------|-------------------|
| ~~Injetar `PreviewPlaybackUseCase` via construtor em `GameView`~~ — **Resolvido em 2026-09-12** | ARQ-001 | P | Médio | Mobile | ✅ `game_view.dart` não contém nenhuma chamada `instance<>()` direta (recebe `previewPlaybackUseCaseFactory` via construtor); ✅ `routes_manager.dart` injeta a factory; ✅ `flutter analyze` e `flutter test` (174/174) passando |
| ~~Restaurar e manter ADRs para decisões arquiteturais existentes~~ — **Resolvido em 2026-09-12** | DOC-001 | P | Médio | Tech Lead | ✅ `docs/adr/` recriado com ADRs para: dartz/Either (002), Clean Architecture (001), sem backend próprio (003), flutter_dotenv vs dart-define (004 — novo) |
| ~~Elevar gate de cobertura de 40% para 60%~~ — **Resolvido em 2026-09-12** | OPS-001 | M | Médio | Mobile | ✅ `.github/workflows/ci.yml` com threshold 60%; ✅ CI local passa (cobertura real 62,6%, 213/213 testes, `flutter analyze` e `dart format` limpos); ✅ `faq_local_data_source.dart` coberto |
| ~~Adicionar testes para `faq_local_data_source.dart` (0% cobertura)~~ — **Resolvido em 2026-09-12** | DEBT-003 | P | Baixo | Mobile | ✅ `test/data/data_source/faq_local_data_source_test.dart` cobre sucesso, erro do `rootBundle` e JSON inválido; ✅ `flutter test` desse arquivo passa (3/3) |
| ~~Corrigir `GameViewModel.dispose()` para cancelar operações async~~ — **Resolvido em 2026-09-12** | ARQ-004 | P | Baixo | Mobile | ✅ Flag `_disposed` adicionada em `game_viewmodel.dart`; emissões de `navigationEvent` passam por `_emitNavigation`, que ignora eventos após dispose; ✅ novo teste em `game_viewmodel_test.dart` cobre dispose durante busca ativa sem lançar `FlutterError` |
| ~~Limpar `MyApp` (remover singleton corrompido e `appState`)~~ — **Resolvido em 2026-09-12** | ARQ-005 | P | Baixo | Mobile | ✅ `app.dart` sem `// ignore: must_be_immutable`; ✅ `appState`, `_internal`/`instance`/`factory` removidos; `MyApp` agora é um `StatefulWidget` const simples; ✅ `main.dart` atualizado para `const MyApp()`; `flutter analyze` limpo |
| ~~Adicionar `Semantics` ao botão fechar do `PlayerMusicFreeView`~~ — **Resolvido em 2026-09-12** | EXP-001 | P | Baixo | Mobile | ✅ `Semantics(button: true, label: 'Fechar')` envolve o `GestureDetector` de fechar em `play_music_free_view.dart`; ✅ `accessibility_test.dart` cobre o widget (nó semântico "Fechar" com flag de botão); `flutter analyze` limpo |
| ~~Iniciar upgrade do bloco Firebase (core → analytics → crashlytics → firestore)~~ — **Resolvido em 2026-09-12** (pendente smoke test manual em device) | DEBT-005 | M | Médio | Mobile / DevOps | ✅ `firebase_core` 4.14.0, `firebase_analytics` 12.5.0, `firebase_crashlytics` 5.3.0, `cloud_firestore` 6.9.0 em `pubspec.yaml`/`pubspec.lock`; ✅ `flutter analyze --fatal-infos`, `dart format --set-exit-if-changed` e `flutter test --coverage` (215/215, 62,8%) passando; ⚠️ smoke test em device real ainda não realizado (fora do alcance deste ambiente) |

---

## Médio Prazo — 1 a 3 Meses

| Título | ID | Esforço | Impacto | Responsável Sugerido | Critério de Aceite |
|--------|----|---------|---------|---------------------|-------------------|
| Implementar lógica de jogo (rodadas, pontuação, linha do tempo) | DEBT-001 | G | Alto | Produto / Mobile | Ao menos 1 modo de jogo completo funcional com rodadas e placar; documentado no README |
| Configurar build iOS (Firebase, entitlements, CI) | DEBT-002 | M | Médio | Mobile / DevOps | `firebase_options.dart` com configuração iOS; CI roda `flutter test` e `flutter build ios` sem erro |
| Implementar CD (build e distribuição automatizada) | OPS-002 | M | Médio | DevOps | CI gera APK de release em tag semver; upload para Play Store internal track ou Firebase App Distribution automatizado |
| Criar CHANGELOG e adotar versionamento semântico | DOC-002 | P | Baixo | Tech Lead | `CHANGELOG.md` criado; `pubspec.yaml` versão atualizada; processo de release documentado |
| Finalizar upgrade de dependências restantes (`connectivity_plus`, `permission_handler`, `sensors_plus`, `spotify_sdk`) | DEBT-005 | M | Médio | Mobile | `pub-outdated.json` sem major breaks resolvíveis; CI passa |
| Validar Firebase Security Rules no console | SEC-001 | P | Médio | Backend / DevOps | Regras revisadas e documentadas; acesso ao Firestore sem autenticação negado ou restrito ao catálogo público |
| Tela de política de privacidade e aceite LGPD | SEC-001 / LGPD | M | Médio | Mobile / Produto | Tela acessível no app antes do primeiro uso; link na Play Store; consentimento de Analytics opcional |
| Adicionar validação de tamanho/formato ao `extractCodigo()` | SEC-004 | P | Baixo | Mobile | QR com >100 chars no path retorna `null` sem chamar Firestore |
| Correção do typo `bagroundColor` → `backgroundColor` | EXP-002 | P | Mínimo | Mobile | Nenhuma referência a `bagroundColor` no codebase |

---

## Longo Prazo — 3 a 12 Meses

| Título | ID | Esforço | Impacto | Responsável Sugerido | Critério de Aceite |
|--------|----|---------|---------|---------------------|-------------------|
| Internacionalização (pt-BR base + en-US) | EXP-003 | G | Médio | Mobile | `flutter_localizations` integrado; strings externalizadas; seleção de idioma nas configurações |
| Logging estruturado local (debug + prod) | OPS-006 | M | Baixo | Mobile | `logger` ou equivalente integrado; logs com nível, timestamp e contexto; não enviados ao Crashlytics em debug |
| Correlacionar duração do splash com tempo real de boot | PERF-001 | P | Baixo | Mobile | Splash remove-se assim que `runZonedGuarded` conclui, sem duração mínima artificial acima de 500ms |
| Política de atualização de dependências documentada | DEBT-005 | P | Baixo | Tech Lead | `CONTRIBUTING.md` ou `docs/` com política de: frequência de `pub outdated`, critério de upgrade menor vs. maior |
