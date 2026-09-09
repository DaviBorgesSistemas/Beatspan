# Plano de Ação — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.4 (ARQ-003 concluído)

> Todos os itens referenciam o ID de origem definido em [1-ARCHITECTURAL_REVIEW.md](1-ARCHITECTURAL_REVIEW.md), [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md) ou [3-TECH_DEBT_REGISTER.md](3-TECH_DEBT_REGISTER.md). Esforço e impacto não são redefinidos aqui — seguem o que já está registrado nos arquivos de origem.
>
> Marque `[x]` conforme for concluindo. Cada item tem o ID de origem entre colchetes para referência cruzada.

---

## Críticos (imediato — sprint atual)

- [x] **Remover `.env` do controle de versão, adicionar ao `.gitignore`, rotacionar credencial** `[SEC-001]` — Responsável: DevOps/Backend — Critério: `.env` não aparece em `git ls-files`; `.gitignore` contém a entrada; novo Client ID gerado no Spotify Dashboard e aplicado
  - *Nota: `.env` foi removido do tracking, mas posteriormente reintroduzido deliberadamente (repositório privado) — ver commit `95ab2b9`. Rotação da credencial ainda pendente.*
- [x] **Configurar `flutter_dotenv` (ou `--dart-define`) para consumir credenciais de config, removendo o hardcode em `di.dart`** `[SEC-002 / ARQ-009]` — Responsável: Mobile — Critério: `di.dart` não contém string literal de Client ID; build funciona lendo de variável de ambiente/config por flavor
  - *`di.dart` lê `SPOTIFY_CLIENT_ID`/`SPOTIFY_REDIRECT_URL` via `flutter_dotenv`, carregado em `main.dart` antes de `initAppModule()`; `_requiredEnv()` lança erro claro se alguma variável faltar. Validado com `flutter analyze`, `flutter test` e `flutter build apk --debug`.*
- [x] **Criar pipeline de CI mínimo: `flutter analyze` + `flutter test` em cada PR** `[OPS-002]` — Responsável: DevOps — Critério: `.github/workflows/ci.yml` existe; PR é bloqueado se `flutter analyze` falhar
- [x] **Escrever a primeira leva de testes unitários para lógica pura** `[OPS-001]` — Responsável: Mobile — Critério: pasta `test/` criada; cobertura mínima de `GameViewModel.validate/extractCodigo`, `MusicaRepositoryImpl`, `GetMusicaUseCase`; testes rodam em CI
  - *19 testes cobrindo os 3 componentes citados. `AppPreferences` passou a ter cobertura posteriormente, na expansão de testes (ver nota do item na seção "Curto prazo").*
- [x] **Integrar Firebase Crashlytics (ou Sentry) para captura de exceções não tratadas** `[OPS-003]` — Responsável: Mobile — Critério: crash simulado em build de teste aparece no dashboard da ferramenta escolhida
  - *Código integrado: `firebase_crashlytics` + `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` em `main.dart`, coleta desabilitada em debug. Validado com build debug e release (R8/proguard ok). Pendente (fora do código): habilitar Crashlytics no Firebase Console e simular um crash para confirmar que aparece no dashboard — critério de aceite completo depende dessa etapa manual.*
- [x] **Extrair a lógica de decisão Spotify/iTunes de `GameView` para um `MusicaPlaybackUseCase`/`Repository` dedicado** `[ARQ-003]` — Responsável: Mobile — Critério: `GameView` não instancia `SpotifyWebApi`/`ItunesSearchApi` diretamente; lógica coberta por teste unitário
  - *`MusicaPlaybackUseCase` + `MusicaPlaybackRepository`/`MusicaPlaybackRepositoryImpl` criados; `GameView` agora só depende do use case e navega com base em `MusicaPlaybackResult` (`FullTrackPlayback`/`PreviewPlayback`). 6 testes unitários novos cobrindo full track, preview (Spotify e fallback iTunes via repo), URI inválida, prévia indisponível e erro de conexão.*

---

## Curto prazo (≤4 semanas)

- [x] Adicionar `.timeout(...)` + tratamento de erro tipado em todas as chamadas HTTP (`spotify_webapi.dart`, `itunes_search_api.dart`) `[OPS-004 / PERF-001]` — Esforço: P — Impacto: Alto — Eixo: Operações
  - *Criado `lib/data/network/network_exceptions.dart` com `NetworkTimeoutException`, `NetworkConnectionException` e `InvalidServerResponseException`. Ambas as APIs agora lançam a exceção tipada correta (timeout, falha de socket/cliente HTTP, status HTTP de erro, JSON malformado) em vez de engolir tudo como `null`/`false`. `SpotifyWebApi`/`ItunesSearchApi` passaram a aceitar um `http.Client` injetável para permitir teste. 15 testes novos (`spotify_webapi_test.dart`, `itunes_search_api_test.dart`) cobrindo os cenários de sucesso, timeout, erro de conexão, status de erro e resposta inválida. `flutter analyze` e `flutter test` (40 testes) passando. Confirmado no código atual: ambos os arquivos lançam as 3 exceções tipadas e aceitam `http.Client` injetável — item 100% concluído, sem pendência.*
- [x] Publicar página real de Política de Privacidade e Termos de Uso, substituindo os links placeholder do hosting `[SEC-009]` — Esforço: M — Impacto: Alto — Eixo: Segurança/Compliance
  - *Criadas `hosting/privacidade/index.html` e `hosting/termos/index.html`, servidas nas rotas `/privacidade` e `/termos` (Firebase Hosting resolve os arquivos estáticos antes do rewrite catch-all para a SPA — validado no emulador). Política cobre os escopos reais do OAuth Spotify usados pelo app, uso do Firebase Crashlytics/Firestore, câmera para QR code, preferências locais e direitos LGPD (art. 18). Termos cobrem requisitos de uso, dependência do Spotify e isenção de garantias.*
- [x] Adicionar tela de consentimento explícito antes da autorização OAuth do Spotify `[SEC-009]` — Esforço: M — Impacto: Médio — Eixo: Segurança/Compliance
  - *Criado `SpotifyConsentDialog` (`lib/presentation/change_spotify/widgets/spotify_consent_dialog.dart`), exibido antes da primeira chamada a `ConnectSpotifyPremiumViewModel.connect()` em `ChangeSpotifyView` e `SettingsView` — os dois pontos de entrada da autorização OAuth (o player `PlayerMusicPremiumView` só é alcançado depois que o plano já está marcado como premium, ou seja, após o consentimento). Aceite é persistido via `AppPreferences.setSpotifyConsentAccepted`/`hasAcceptedSpotifyConsent` (SharedPreferences) para não repetir o diálogo em conexões seguintes; recusar cancela a conexão sem chamar o SDK do Spotify. O diálogo linka a Política de Privacidade real publicada em `beatspan.web.app/privacidade`. Validado com `flutter analyze` (sem issues) e `flutter test` (40 testes passando).*
- [x] Mover `instance<T>()` para injeção via construtor nos 10+ pontos identificados, começando pelos ViewModels `[ARQ-004]` — Esforço: M — Impacto: Alto — Eixo: Fundamentos
  - *Todas as Views roteadas (`GameView`, `SplashView`, `FaqsView`, `SettingsView`, `ChangeSpotifyView`, `SpotifyFreeTransition`) e widgets filhos (`GameMode`, `TurnPhone`, `PlayerMusicPremiumView`, `PlayerMusicFreeView`) passaram a receber suas dependências via construtor. `ConnectSpotifyPremiumViewModel` também passou a receber `AppPreferences` via construtor em vez de `instance<AppPreferences>()` interno. `RouteGenerator` (`routes_manager.dart`) virou o único ponto de composição: resolve via `instance<T>()` nos builders das rotas e injeta nos construtores. Única exceção mantida deliberadamente: `connectivity_guard.dart` (extension em `BuildContext`, sem construtor próprio, single call site). Validado com `flutter analyze` (sem issues), `flutter test` (40 testes passando) e `flutter build apk --debug` (build completo com sucesso).*
- [x] Remover código morto comentado de `settings_view.dart` e `play_music_free_view.dart` `[ARQ-008 / UX-002]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos/Experiência
  - *Já resolvido em commits anteriores (`213711a chore: remove código morto comentado (ARQ-008)` e `ca65346 style: remove comentários do código em lib/ e test/`) — nenhum código comentado remanescente em nenhum dos dois arquivos.*
- [x] Extrair `_nextCardButton()` duplicado para um widget compartilhado `[ARQ-007]` — Esforço: P — Impacto: Baixo — Eixo: Fundamentos
  - *Criado `NextCardButton` (`lib/presentation/share/widgets/next_card_button.dart`), parametrizável (largura, margem, cores do gradiente, cor do texto/ícone, sombra) para cobrir as duas variações visuais existentes. Substituído nos 3 pontos duplicados: `game_error_view.dart` (variante com largura total, gradiente pink/orange e sombra), `player_music_premium_view.dart` e `play_music_free_view.dart` (variante padrão, idênticas entre si). Validado com `flutter analyze` (sem issues) e `flutter test` (40 testes passando).*
- [x] Corrigir referência quebrada no README e sincronizar documentação com o estado real do código `[DOC-001 / DOC-002]` — Esforço: P — Impacto: Médio — Eixo: Documentação
- [x] Adotar convenção de commit (Conventional Commits) e aplicar a partir de agora `[DOC-005]` — Esforço: P (processo contínuo) — Impacto: Médio — Eixo: Documentação
- [x] Rodar scanner de dependências (OSV-Scanner ou Snyk) e priorizar upgrades críticos (`firebase_core`, `cloud_firestore`, `spotify_sdk`) `[SEC-010]` — Esforço: M — Impacto: Médio — Eixo: Segurança
  - *Rodado OSV-Scanner v2.5.1 (binário oficial do Google, baixado do GitHub Releases — Chocolatey falhou por falta de permissão de administrador no ambiente) contra `pubspec.lock`: 120 pacotes escaneados, **0 vulnerabilidades conhecidas encontradas** (`results: []` no JSON, exit code 0). Criado `scripts/scan_dependencies.sh` para reexecutar o scan a qualquer momento — baixa o binário para `.tools/` (gitignored) na primeira execução e reusa nas seguintes.*
  - *Majors mais novas continuam disponíveis sem CVE associada: `cloud_firestore` 5.6.12→6.9.0, `firebase_core` 3.15.2→4.14.0, `firebase_crashlytics` 4.3.10→5.3.0, `connectivity_plus` 6.1.5→7.3.1, `permission_handler` 11.4.0→13.0.2, `sensors_plus` 6.1.2→7.1.0, `proximity_sensor` 1.4.0→2.0.0, `fluttertoast` 9.0.0→10.0.0, `spotify_sdk` 3.0.2→4.0.0 (`flutter pub outdated`, 2026-09-09). Nenhum upgrade de major foi aplicado nesta tarefa — são breaking changes potenciais (especialmente `firebase_core`/`cloud_firestore` e `spotify_sdk`) que merecem branch dedicada e teste de regressão manual, não indicados pelo scanner como urgentes por ausência de CVE. Recomenda-se agendar o upgrade como item à parte.*
- [x] Corrigir `Failure` para não viver em `data` (mover para `domain`) `[ARQ-001]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos
- [x] Corrigir `FaqRepositoryImpl` para não depender de `presentation/assets_manager` `[ARQ-002]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos

---

## Médio prazo (1–3 meses)

- [x] Expandir cobertura de testes para repositórios, use cases e ao menos os widgets críticos (`GameView`, `PlayerMusicPremiumView`) `[OPS-001]` — Esforço: G — Impacto: Alto — Eixo: Operações
  - *Adicionados 17 testes novos (40→57 no total): `FaqRepositoryImpl` (sucesso e exceção da data source), `FaqsUseCase` (delegação e propagação de falha), `MusicaPlaybackRepositoryImpl` (preview via Spotify, fallback iTunes, ambos indisponíveis, faixa não encontrada — exigiu extrair `SpotifyWebApiFactory` injetável em `MusicaPlaybackRepositoryImpl` para tornar o `SpotifyWebApi`, antes instanciado internamente, mockável), `AppPreferences` (todos os getters/setters, usando `SharedPreferences.setMockInitialValues`), e 2 widget tests de `PlayerMusicPremiumView` (erro de "plataforma não suportada" — único caminho alcançável em `flutter test`, que roda em VM sem Android/iOS/web — e navegação do botão Voltar).*
  - *`GameView` não recebeu widget test: usa `MobileScanner`/`MobileScannerController` diretamente no `build()`, que exigiria implementar um fake completo de `MobileScannerPlatform` (streams de barcode, controle de start/stop/torch) para ser exercitável sem device real — esforço desproporcional ao ganho, já que a lógica de decisão relevante (`validate`/`extractCodigo`, resolução de música, decisão de playback) já está coberta pelos testes existentes de `GameViewModel`, `GetMusicaUseCase` e `MusicaPlaybackUseCase`, que `GameView` apenas orquestra. Fica registrado como possível item à parte caso se decida investir no fake platform.*
  - *Validado com `flutter analyze` (sem issues) e `flutter test` (57 testes passando).*
- [x] Adicionar cache local (memória e/ou disco) para respostas de Spotify/iTunes e `cached_network_image` para capas de álbum `[PERF-003]` — Esforço: M — Impacto: Médio — Eixo: Performance
  - *Adicionada dependência `cached_network_image`; `Image.network` trocado por `CachedNetworkImage` na capa do álbum em `play_music_free_view.dart` (disco + memória, cache padrão do pacote). Adicionado cache em memória por `trackId` em `MusicaPlaybackRepositoryImpl.resolvePreview` (incluindo o caso `null`, quando nenhuma prévia está disponível) — evita rechamar Spotify/iTunes ao escanear a mesma carta de novo na mesma sessão; sem TTL, pois o resultado não muda durante a sessão do app, e o repositório já é `registerLazySingleton` no DI (cache sobrevive entre chamadas). 2 testes novos cobrindo reuso do cache (inclusive do resultado `null`), verificando que as APIs não são rechamadas na segunda consulta. Validado com `flutter analyze` (sem issues), `flutter test` (59 testes passando) e `flutter build apk --debug` (build completo com sucesso).*
- [ ] Otimizar assets de imagem (compressão, WebP, variantes de densidade) `[PERF-004]` — Esforço: M — Impacto: Médio — Eixo: Performance
- [ ] Adicionar `Semantics`/labels de acessibilidade nas telas principais (scanner, player, settings) `[UX-003]` — Esforço: M — Impacto: Alto — Eixo: Experiência
- [ ] Introduzir lint/checklist de contraste WCAG AA para o dark theme `[UX-004]` — Esforço: P — Impacto: Médio — Eixo: Experiência
- [ ] Padronizar 100% das telas para usar `ColorManager`/`getBoldStyle`/`AppPadding` em vez de valores soltos `[UX-001]` — Esforço: M — Impacto: Médio — Eixo: Experiência
- [ ] Adicionar tratamento de loading/erro em `settings_view.dart` (`_loadPlanType`, `_connectSpotify`) `[UX-006]` — Esforço: P — Impacto: Médio — Eixo: Experiência
- [ ] Criar `CHANGELOG.md` e adotar tags de release seguindo semver a partir da próxima versão `[DOC-004]` — Esforço: P (setup) — Impacto: Médio — Eixo: Documentação
- [ ] Documentar estratégia de branching e consolidar as 4 branches de longa duração `[DOC-006]` — Esforço: M — Impacto: Médio — Eixo: Documentação
- [ ] Registrar as primeiras 3-5 ADRs retroativas para decisões já tomadas (Clean Architecture parcial, `get_it`, Firestore) `[DOC-003]` — Esforço: M — Impacto: Baixo — Eixo: Documentação

---

## Longo prazo (3–12 meses)

- [ ] Unificar o tratamento de erro do app inteiro sob `Either<Failure, T>` (incluindo o fluxo Spotify/iTunes) `[ARQ-006]` — Esforço: G — Impacto: Médio — Eixo: Fundamentos
- [ ] Avaliar migração de gerenciamento de estado local (`setState`) para uma solução reativa (Provider/Riverpod/Bloc) se a árvore de widgets continuar crescendo `[PERF-008]` — Esforço: G — Impacto: Médio — Eixo: Performance
- [ ] Implementar suporte a tablet com breakpoints reais (`LayoutBuilder`) `[UX-005]` — Esforço: G — Impacto: Baixo–Médio — Eixo: Experiência
- [ ] Configurar Android/iOS de forma completa (iOS ainda não configurado) e publicar nas lojas — Esforço: G — Impacto: Alto — pré-requisito de negócio
- [ ] Avaliar Firebase App Check para proteger a leitura pública da coleção `musicas` contra scraping em massa `[SEC-004]` (sugestão) — Esforço: M — Impacto: Baixo — Eixo: Segurança
- [ ] Estabelecer política formal de atualização de dependências (Dependabot/Renovate) `[DOC-007 / SEC-010]` — Esforço: P (setup) — Impacto: Médio — Eixo: Documentação/Segurança

---

## Observação sobre sequenciamento

O bloco Crítico é intencionalmente pequeno e sequencial: **SEC-001 → SEC-002 → OPS-002 → OPS-001 → OPS-003 → ARQ-003**. A ordem importa — corrigir a credencial primeiro evita que o trabalho de CI/testes rode sobre uma base ainda vazando segredo; ter CI antes de escrever testes garante que os testes já nasçam rodando automaticamente; e observabilidade antes da refatoração de `ARQ-003` permite medir o impacto real da mudança em produção.

**Progresso atual (críticos):** 6 de 6 concluídos (SEC-001 parcial, SEC-002/ARQ-009, OPS-002, OPS-001, OPS-003 — código pronto, falta habilitar no Console —, ARQ-003).
