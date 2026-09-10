# Análise Arquitetural — Beatspan

**Projeto:** Beatspan (app Flutter — jogo de adivinhação musical via QR code + Spotify)
**Data da análise:** 2026-09-09
**Versão do documento:** 2.0 (reexecução completa da análise arquitetural — branch `beatspan_v2`)

> Esta é a segunda rodada desta análise (a primeira é de 2026-09-08, um dia antes). A maioria dos itens críticos da v1.0 foi de fato corrigida no código — confirmado por evidência nova, não copiado do plano de ação. Um item (`SEC-001`) foi corrigido e **revertido** nesse intervalo; está marcado abaixo como **Reaberto**.

---

## 1. Visão geral do projeto e stack

Beatspan é um app Flutter (Dart SDK ^3.9.2) que reproduz o conceito do jogo Hitster (versão gospel): cartas físicas com QR code, lidas pela câmera do celular, disparam a reprodução de uma faixa via Spotify (SDK nativo `spotify_sdk` para Premium, `just_audio`/prévia de 30s via iTunes para Free).

**Stack identificada:**
- **Frontend:** Flutter/Dart, Material, fonte Montserrat custom
- **Estado/DI:** `get_it` (service locator manual), `ValueNotifier`/`ListenableBuilder` local, sem Provider/Riverpod/Bloc
- **Backend:** Firebase (Firestore para catálogo de músicas, Crashlytics, Hosting para privacidade/termos)
- **Integrações externas:** Spotify SDK (App Remote + Web API), iTunes Search API (fallback de prévia)
- **Scanner:** `mobile_scanner` (ML Kit)
- **Persistência local:** `shared_preferences`
- **Arquitetura:** Clean Architecture-like (`lib/data`, `lib/domain`, `lib/presentation`), Repository + UseCase + `Either<Failure, T>` (dartz)
- **Plataformas:** Android configurado; iOS não configurado (sem pasta `ios/`)
- **Testes:** 11 arquivos em `test/`, ~60 casos, `flutter_test` + `mocktail`
- **CI/CD:** `.github/workflows/ci.yml` (analyze + format + test)

Projeto pré-lançamento (v1.0.0+1, sem tags de release, sem app publicado).

---

## 2. Análise por eixo

### 2.1 Fundamentos — Nota: 7,5/10 (6,5 antes de 2026-09-10)

As fronteiras de camada (`domain` não depende de `data`/`presentation`, e vice-versa) hoje estão corretas, e a maioria dos fluxos de feature (FAQ, busca de música, conexão Spotify Premium, e agora controle de reprodução e orquestração de `GameView`) segue Repository → UseCase → `Either<Failure,T>` de forma disciplinada, com exceções tipadas e timeout na camada de rede. Em 2026-09-10, `ARQ-013` (playback ainda direto no SDK), `ARQ-014`/`ARQ-019` (`GameViewModel` anêmica e não injetada) e parte de `ARQ-006` foram resolvidos — os dois débitos mais relevantes do eixo. Resta o DI 100% manual com boilerplate repetitivo (`ARQ-015`) e a ausência de state management estruturado, ambos de severidade menor.

**ARQ-001 — Domain depende de Data** · ✅ **Resolvido**
`Failure` foi movido para `lib/domain/failure.dart`. Confirmado: `grep -rn "import.*data/" lib/domain` sem resultado.

**ARQ-002 — Data depende de Presentation** · ✅ **Resolvido**
`lib/data/repository/faq_repository_impl.dart` não importa mais `presentation/resource/assets_manager.dart`. Confirmado: `grep -rn "import.*presentation" lib/data` sem resultado.

**ARQ-003 — GameView ignorava Repository/UseCase para Spotify/iTunes** · ✅ **Resolvido** (ver `ARQ-013` para residual)
`MusicaPlaybackUseCase`/`MusicaPlaybackRepositoryImpl` criados; `GameView` agora depende só do use case.

**ARQ-004 — Service locator chamado direto em widgets** · ✅ **Resolvido** (ver `ARQ-019` para exceção)
Views roteadas e widgets filhos recebem dependências via construtor; `RouteGenerator` é o único ponto de composição.

**ARQ-013 — Controle de reprodução (play/pause/salvar) ainda chama SDK direto do widget** · ✅ **Resolvido** (2026-09-10)
Extraído para dois pares Repository/UseCase (tecnologias não relacionadas — SDK nativo do Spotify vs. `just_audio` para prévia — mereciam abstrações separadas, não uma única artificial): [spotify_playback_control_repository.dart](../lib/domain/repository/spotify_playback_control_repository.dart)/[_impl](../lib/data/repository/spotify_playback_control_repository_impl.dart) + [spotify_playback_usecase.dart](../lib/domain/usecase/spotify_playback_usecase.dart), e [preview_playback_control_repository.dart](../lib/domain/repository/preview_playback_control_repository.dart)/[_impl](../lib/data/repository/preview_playback_control_repository_impl.dart) + [preview_playback_usecase.dart](../lib/domain/usecase/preview_playback_usecase.dart). Novo modelo [playback_state.dart](../lib/domain/model/playback_state.dart) evita vazar tipos do `spotify_sdk`/`just_audio` para `domain`. `player_music_premium_view.dart`/`play_music_free_view.dart` não chamam mais `SpotifySdk`/`SpotifyWebApi`/`AudioPlayer` diretamente. 21 testes novos cobrindo a lógica antes intestável (ver `docs/4-ACTION_PLAN.md` para detalhe completo).

**ARQ-014 — `GameViewModel` anêmica; orquestração real mora em `GameView`** · ✅ **Resolvido** (2026-09-10)
[game_viewmodel.dart](../lib/presentation/game/game_viewmodel.dart) agora recebe `AppPreferences`/`GetMusicaUseCase`/`MusicaPlaybackUseCase` via construtor e absorve toda a orquestração que antes vivia em `_GameViewState` (decisão de qual dos 5 tipos de erro/navegação disparar, coordenação dos 2 use cases). Comunica a decisão à View via um evento tipado (`ValueNotifier<GameNavigationEvent?>`, nova sealed class em [game_navigation_event.dart](../lib/presentation/game/game_navigation_event.dart)), sem o ViewModel importar `Navigator`/`BuildContext`. `game_view.dart` só traduz evento→tela.

**ARQ-019 — `GameViewModel` não é injetada via construtor** · ✅ **Resolvido** (2026-09-10, junto com `ARQ-014`)
`GameView` agora recebe `viewModel` via construtor (`required this.viewModel`), igual a `ChangeSpotifyView`/`SettingsView`; DI registra `GameViewModel` como `registerFactory` e `routes_manager.dart` injeta via `instance<GameViewModel>()`.

**ARQ-015 — DI manual com boilerplate repetitivo; `disposeFaqsModule()` nunca chamada** · Severidade: Atenção · **Novo**
[lib/app/di.dart:46-104](../lib/app/di.dart#L46-L104) — 15 registros em 3 funções, cada um com guard manual `if (!instance.isRegistered<T>())`. `routes_manager.dart` chama `initSpotifyModule()`/`initFaqsModule()` a cada navegação; `disposeFaqsModule()` existe mas não há call site fora de `di.dart`. Esforço: M.

**ARQ-016 — `dart:ffi`'s `Void` usado como sentinela de "sem input"** · Severidade: Baixa · **Novo**
[lib/presentation/faqs/faqs_view_model.dart:2,25](../lib/presentation/faqs/faqs_view_model.dart#L25) — `import 'dart:ffi'` só para usar `Void` como argumento de `execute(void input)`. O idiomático já disponível na stack (`dartz`) é `Unit`/`unit`. Esforço: P.

**ARQ-017 — `MyApp` implementa pseudo-singleton incorreto + campo morto** · Severidade: Baixa · **Novo**
[lib/app/app.dart:6-11](../lib/app/app.dart#L6-L11) — `static MyApp get instance => MyApp._internal();` recria uma instância nova a cada chamada, não é singleton de fato. `appState` declarado, nunca lido/escrito. Esforço: P.

**ARQ-018 — Catch genérico em `MusicaPlaybackUseCase` descarta exceções tipadas** · Severidade: Baixa · **Novo**
[lib/domain/usecase/musica_playback_usecase.dart:58-61](../lib/domain/usecase/musica_playback_usecase.dart#L58-L61) — captura tudo com `catch (e)` genérico, perdendo a distinção entre `NetworkTimeoutException`/`NetworkConnectionException`/`InvalidServerResponseException` que a camada de dados já tipa corretamente. Esforço: P.

**ARQ-006 — Dois padrões de tratamento de erro** · Severidade: Média · Parcialmente **Resolvido** (2026-09-10, via `ARQ-013`)
O fluxo de controle de reprodução (play/pause/resume/save) agora usa `Either<Failure,T>` de ponta a ponta em `SpotifyPlaybackUseCase`/`PreviewPlaybackUseCase`. Ressalva: `startPlayback`/`saveTrack` ainda capturam exceção com `catch (e)` genérico ao final (mesmo padrão do `ARQ-018`, não reaberto aqui) — a distinção fina de tipo de exceção continua limitada aos casos já mapeados explicitamente.

**ARQ-007 — Duplicação `_nextCardButton()`** · ✅ **Resolvido** — extraído para `NextCardButton` compartilhado.

**ARQ-008 — Código morto comentado** · ✅ **Resolvido** — confirmado sem remanescente em `settings_view.dart`/`play_music_free_view.dart`.

**ARQ-009 / SEC-002 — Client ID hardcoded** · ✅ **Resolvido** — agora via `flutter_dotenv` (ver `SEC-001` sobre o `.env` em si).

**ARQ-010 — Model `Musica` anêmico** · Severidade: Baixa · Ainda **Aberto**, sem mudança.

**ARQ-011 / OPS-001 — Ausência de testes** · Severidade: Alta · Parcialmente resolvido, ver [OPERAÇÕES](#24-operações-e-confiabilidade--nota-510).

**ARQ-012 — Nomenclatura inconsistente de arquivo** · Severidade: Baixa · Ainda **Aberto**.

**ARQ-020 — Fronteiras de camada limpas** · Severidade: Ponto forte · **Novo**
Confirmado via grep: nenhum import invertido entre `domain`/`data`/`presentation`. Correção estrutural real, não cosmética.

**ARQ-021 — Timeout + erro tipado em toda chamada de rede** · Severidade: Ponto forte · **Novo**
`musica_firestore_data_source.dart`, `spotify_webapi.dart`, `itunes_search_api.dart` — todos com timeout de 10s e exceções tipadas, bem testados.

**ARQ-022 — `GetMusicaUseCase` é passthrough anêmico** · Severidade: Informativo · **Novo**
[lib/domain/usecase/get_musica_usecase.dart:12-15](../lib/domain/usecase/get_musica_usecase.dart#L12-L15) — uma linha delegando ao repositório, sem regra própria. Não é erro, é sinal a observar se o projeto crescer.

**ARQ-005 — `GameView` "God Widget"** · Severidade: Baixa · Bastante **Reduzido** (2026-09-10, via `ARQ-014`)
[lib/presentation/game/game_view.dart](../lib/presentation/game/game_view.dart) não fala mais direto com SDKs (já era assim) e não decide mais qual erro/navegação disparar nem coordena os 2 use cases — isso migrou para `GameViewModel`. A View ficou com o papel legítimo de uma View: escutar o evento de navegação e traduzi-lo em `Navigator.push`/decidir a interposição de `TurnPhoneReadyView` (que é puramente de UI/sensor). Não reclassificado como totalmente resolvido porque a View ainda mistura essa tradução de evento com o próprio controle do `MobileScannerController` (start/stop do scanner) — aceitável, mas seria o próximo passo caso a tela cresça mais.

---

### 2.2 Segurança e Compliance — Nota: 6,5/10 (5,5 antes de 2026-09-09/10)

Ver relatório dedicado: [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md). Núcleo técnico sólido (Rules, HTTPS, permissões mínimas, consentimento LGPD implementado). Em 2026-09-09, `SEC-001` foi corrigido de novo (após ter sido revertido em <24h) e `SEC-011` (keystore de debug em release) também; em 2026-09-10, `SEC-012` (gate de consentimento Spotify não centralizado) foi resolvido, fechando os 2 caminhos de gameplay que disparavam OAuth sem checagem. Pendente: essas correções não foram commitadas ainda, e a rotação do Client ID no Spotify Dashboard (necessária por causa da exposição histórica do `SEC-001`) segue fora do alcance de uma sessão de código.

---

### 2.3 Experiência — Nota: 6/10 (5,5 antes de 2026-09-10, 4,5 antes de 2026-09-09)

Em 2026-09-10, `UX-010` (typo "PREMIYM") e `UX-011` (alvos de toque abaixo do mínimo em 3 botões) foram resolvidos — ambos de severidade baixa, mas eram os débitos mais fáceis de fechar do eixo. O item de maior impacto (`UX-001`, design system ignorado por ~85% das telas) segue aberto.

**UX-001 — Design system aplicado de forma inconsistente** · Severidade: Alta · Ainda **Aberto**, quantificado
`AppPadding`/`AppSize`/estilos de `style_manager.dart` usados em só 5 de 46 arquivos de `lib/presentation/`. 53 ocorrências de `Color(0x...)` hardcoded em 18 arquivos (`settings_view.dart`, `change_spotify_view.dart`, `spotify_free_transition.dart`, `first_time_view.dart`, entre outros) — inclusive misturado com `ColorManager` na mesma tela.

**UX-002 / ARQ-008 — Código morto** · ✅ **Resolvido**.

**UX-003 — Zero uso de `Semantics`** · Severidade: Alta · Ainda **Aberto**, confirmado
`grep -rln "Semantics(" lib` → zero em 46 arquivos. Botões só-ícone sem rótulo em `player_music_premium_view.dart`/`play_music_free_view.dart`.

**UX-009 — "Verifique sua internet" mascara falha real de configuração/autorização do Spotify** · Severidade: **Crítica** · **Novo**
[lib/presentation/game/game_view.dart:187-197](../lib/presentation/game/game_view.dart#L187-L197), [lib/domain/usecase/musica_playback_usecase.dart:58-61](../lib/domain/usecase/musica_playback_usecase.dart#L58-L61). `MusicaPlaybackUseCase.execute` engole toda exceção (client ID inválido, app não autorizado, token expirado, `429`) num único `Failure` genérico, sempre exibido como "Não foi possível conectar ao Spotify. Verifique sua internet [...]". **Confirmado com evidência real de produção nesta própria sessão de suporte**: um usuário reportou exatamente esse erro; o log completo mostrava `AUTHENTICATION_SERVICE_UNKNOWN_ERROR` causado por um Redirect URI incorreto no `.env` (nada a ver com internet) — a mensagem da UI ativamente atrapalhou o diagnóstico. Esforço: M.

**UX-004 — Contraste não verificado sistematicamente** · Severidade: Média · Ainda **Aberto**.

**UX-005 — Responsividade só por percentual de tela** · Severidade: Média · Ainda **Aberto**, com evidência nova
[lib/presentation/game/player_music/player_music_premium_view.dart:289-291,313](../lib/presentation/game/player_music/player_music_premium_view.dart#L289-L291) — `Container(width: 320, height: 320)` fixo, pode estourar em telas < 360dp.

**UX-006 — Tratamento de loading/erro desigual** · Severidade: Média · Ainda **Aberto** parcialmente (ver ponto forte `UX-012`).

**UX-007 — Referência quebrada no README** · ✅ **Resolvido**.

**UX-008 — Fallback genérico "Erro desconhecido" em SnackBar** · Severidade: Baixa · **Novo**
[lib/presentation/change_spotify/change_spotify_view.dart:38-39](../lib/presentation/change_spotify/change_spotify_view.dart#L38-L39) — `_viewModel.errorMessage.value ?? 'Erro desconhecido'`. Raramente dispara hoje, mas é uma armadilha silenciosa para mudanças futuras. Esforço: P.

**UX-010 — Typo visível: "BEATSPAN SEM SPOTIFY PREMIYM"** · ✅ **Resolvido** (2026-09-10)
Corrigido para "PREMIUM" em [spotify_free_transition.dart](../lib/presentation/spotify_free_transition/spotify_free_transition.dart).

**UX-011 — Alvos de toque < 48dp em botões de fechar/voltar** · ✅ **Resolvido** (2026-09-10)
Levantamento completo encontrou 10 ocorrências no app: 7 já cumpriam o mínimo (4 dentro de `AppBar.leading`, forçado a 56x56 pelo Flutter; `player_music_premium_view.dart`/`play_music_free_view.dart` já usavam `Container(width: 44, height: 44)`; 2 `IconButton` em `scaffold_hitster.dart` já têm 48x48 por padrão do Material). Os 3 abaixo do mínimo — `camera_permission_view.dart` (28px), `no_internet_view.dart` (32px), `game_error_view.dart` (28px), ícone solto sem `Container`/padding — agora têm `SizedBox(width: 44, height: 44)` envolvendo o ícone, preservando a aparência visual e só ampliando a área de toque.

**UX-012 — `play_music_free_view.dart` com tratamento de estado granular** · Severidade: Ponto forte · **Novo**
Loading/erro/vazio explícitos e `CachedNetworkImage` com `placeholder`/`errorWidget` corretos ([play_music_free_view.dart:35-58,232-245](../lib/presentation/game/player_music/play_music_free_view.dart#L35-L58)) — melhor exemplo do app, deveria ser replicado.

**UX-013 — Mensagens de erro específicas no fluxo Premium** · Severidade: Ponto forte · **Novo**
[lib/presentation/change_spotify/connect_spotify_premium_view_model.dart:79-108](../lib/presentation/change_spotify/connect_spotify_premium_view_model.dart#L79-L108) diferencia app não instalado / autorização negada / fallback — é o padrão que `UX-009` deveria seguir.

---

### 2.4 Operações e Confiabilidade — Nota: 7/10 (6 antes de 2026-09-10, 5 antes de 2026-09-09)

Em 2026-09-10, `OPS-006`/`OPS-010` (retry/backoff em toda chamada de rede) e `OPS-012` (branches órfãs decididas — apagadas) foram resolvidos. Continuam abertos: `OPS-001` (cobertura de teste ainda baixa fora dos arquivos tocados nesta sessão), `OPS-007` (CI sem gate de cobertura/build), `OPS-009` (zero e2e), `OPS-011` (sem fallback automático Premium→Free).

**OPS-001 — Ausência de testes** · Severidade: Alta · Parcialmente **Resolvido**, cobertura insuficiente
`flutter test --coverage`: 60 testes passam, mas só **22 de 76 arquivos de `lib/`** aparecem no relatório de cobertura — ou seja, ~70% do projeto nunca é sequer importado por um teste. Dentro dos 22 tocados, cobertura de linha é 259/520 (~49,8%). Fluxo de conexão Spotify (`connect_spotify_premium_view_model.dart`) e `GameView` (orquestração do jogo) seguem sem nenhum teste.

**OPS-002 — Pipeline de CI** · ✅ **Resolvido**, com lacunas — ver `OPS-007`.

**SEC-001 — `.env` versionado** · ⚠️ **Reaberto** — ver [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md#sec-001).

**OPS-003 — Observabilidade/crash reporting** · ✅ **Resolvido parcialmente** — Crashlytics integrado para exceções não tratadas, mas ver `OPS-008` (crítico).

**OPS-008 — Exceções tratadas (`catch`) nunca chegam ao Crashlytics** · Severidade: **Crítica** · **Novo**
`connect_spotify_premium_view_model.dart:76` (`catch (_) {}` silencioso em `disconnect()`), `player_music_premium_view.dart:47` (`.catchError((_) {})`), `play_music_free_view.dart:86`. Nenhum chama `FirebaseCrashlytics.instance.recordError(...)` — só os handlers globais de `main.dart` (erros *não tratados*) alimentam o Crashlytics. Os erros mais comuns e acionáveis em produção (Spotify indisponível, Firestore fora do ar) ficam invisíveis no dashboard. Esforço: P.

**OPS-004 / PERF-001 — Chamadas HTTP sem timeout** · ✅ **Resolvido** — timeout de 10s + exceções tipadas em todas as fontes de rede, bem testado.

**OPS-005 — Crash logs de build tool versionados** · Severidade: Baixa · Não reverificado nesta rodada (fora do escopo desta reexecução).

**OPS-006 — Firestore sem cache local** · Severidade: Baixa · ✅ **Resolvido** (2026-09-10, junto com `PERF-009`).

**OPS-009 — Zero testes de integração/e2e** · Severidade: Atenção · **Novo**
Nenhuma pasta `integration_test/`. Regressões de contrato (schema Firestore, `spotify_sdk`) só apareceriam em teste manual/produção. Esforço: G.

**OPS-010 — Sem retry/backoff em nenhuma chamada de rede** · ✅ **Resolvido** (2026-09-10)
Helper [retry.dart](../lib/data/network/retry.dart) (`withRetry<T>`, 1 tentativa original + 1 retry por padrão, backoff configurável) aplicado a `ItunesSearchApi`, `SpotifyWebApi` (predicado compartilhado `isTransientHttpError`: timeout/socket/client exception) e `MusicaFirestoreDataSource` (predicado próprio para códigos `FirebaseException` transitórios). Erros não-transitórios (resposta de erro, JSON malformado) não são repetidos.

**OPS-011 — Sem fallback automático Premium → Free quando Spotify falha** · Severidade: Atenção · **Novo**
[connect_spotify_premium_view_model.dart:60-108](../lib/presentation/change_spotify/connect_spotify_premium_view_model.dart#L60-L108) — falha só gera mensagem + deep link manual, sem degradação automática para o modo Free. Decisão de produto, não só técnica.

**OPS-012 — Branches órfãs; trabalho de segurança perdido em `refatore`** · Severidade: Atenção · **Novo**
`0a`/`developer` são ancestrais estritos de `beatspan_v2` (0 commits próprios — mortas). `refatore` tem 4 commits nunca mesclados, incluindo introdução de `flutter_secure_storage` — confirmado ausente em `beatspan_v2` (`pubspec.yaml` não o lista). Esse trabalho foi efetivamente abandonado, não apenas adiado. Esforço: M.

**OPS-014 — Fallback gracioso Spotify → iTunes com cache** · Severidade: Ponto forte · **Novo**
`musica_playback_repository_impl_test.dart` confirma fallback automático + cache por `trackId` — melhor exemplo de resiliência do projeto.

**OPS-007 — CI sem gate de cobertura, build ou secret-scanning** · Severidade: Atenção · **Novo**
`.github/workflows/ci.yml` roda analyze/format/test, mas não builda artefato, não mede cobertura, e não teria pego a regressão de `SEC-001` (nenhum step de detecção de segredos). Esforço: P.

---

### 2.5 Documentação e Governança — Nota: 5/10 (4,5 antes de 2026-09-10, 4 antes de 2026-09-09)

Em 2026-09-10, `DOC-005` (convenção de commits documentada mas nunca seguida) ganhou verificação automática de fato — hook local + gate no CI —, diferente do `DOC-011` (que tem só um mecanismo de visibilidade via template de PR, não um gate automatizado).

Ver detalhamento completo em seção própria — resumo: README continua um ponto forte real, mas o próprio checklist do plano de ação (`4-ACTION_PLAN.md`) afirmava um item de segurança crítico como concluído quando ele já havia regredido (`DOC-011`, novo), e a convenção de commits documentada (`DOC-005`) não sobreviveu nem um dia (o commit de topo da branch auditada ainda é `...`).

**DOC-001 / DOC-002** · ✅ **Resolvidos**.
**DOC-003, DOC-004, DOC-006, DOC-007** · Ainda **Abertos**, sem mudança relevante.
**DOC-005 — Convenção de commits** · ⚠️ **Reaberto** — ver [4-ACTION_PLAN.md](4-ACTION_PLAN.md).
**DOC-009, DOC-010, DOC-011** · **Novos** — ver [4-ACTION_PLAN.md](4-ACTION_PLAN.md) e [3-TECH_DEBT_REGISTER.md](3-TECH_DEBT_REGISTER.md).

---

### 2.6 Performance e Escalabilidade — Nota: 9/10 (8/10 antes de 2026-09-10)

A decisão arquitetural central — leitura de música por `doc(id)` direto no Firestore, sem queries — é excelente e escala para milhões de cartas. O debounce do scanner está correto. Em 2026-09-10, `PERF-009` (cache assimétrico), `PERF-010` (sem tratamento de 429) e `PERF-011` (scanner sem filtro de formato) foram resolvidos — já era o eixo mais maduro do projeto, e os 3 achados de severidade "Atenção" que restavam foram fechados. Só sobram itens de severidade Baixa/Informativa (`PERF-004`, `PERF-005`, `PERF-008`, `PERF-012`, `PERF-013`).

**PERF-001 / OPS-004 — Sem timeout** · ✅ **Resolvido**.
**PERF-002 — Sem retry** · ✅ **Resolvido** (2026-09-10, junto com `OPS-010`).
**PERF-003 — Sem cache de rede/imagem** · ✅ **Resolvido** — cache em memória por `trackId` + `cached_network_image` em uso real.
**PERF-004 — Assets grandes** · Ainda **Aberto**, sem mudança relevante além de `PERF-012`.
**PERF-005 — `const` inconsistente** · Ainda **Aberto**, evidência nova em `home_view.dart`.
**PERF-006 — Firestore sem N+1** · Ponto forte, confirmado sem mudança.
**PERF-007 — Disposal correto** · Ponto forte, não reverificado nesta rodada.
**PERF-008 — Estado local sem granularidade** · Informativo, sem mudança.

**PERF-009 — `MusicaRepositoryImpl` sem cache (ao contrário do repositório irmão)** · ✅ **Resolvido** (2026-09-10)
[musica_repository_impl.dart](../lib/data/repository/musica_repository_impl.dart) agora cacheia em memória por código, mas só o caminho de sucesso — diferente de `musica_playback_repository_impl.dart`, que também cacheia o resultado "sem preview" (`null`). Aqui, "não encontrada" e erros de rede sempre re-consultam o Firestore, para não mascarar uma carta cadastrada depois do app já estar rodando.

**PERF-010 — Sem tratamento de rate limit 429 do Spotify** · ✅ **Resolvido** (2026-09-10)
[spotify_webapi.dart](../lib/data/network/spotify_webapi.dart) (`_send`) agora detecta `429`, espera o `Retry-After` do header (com teto configurável) e tenta de novo automaticamente; se persistir, lança `RateLimitedException` — propagada como `PlaybackNetworkException`/código de failure dedicado nas camadas superiores, em vez de cair no tratamento de erro genérico.

**PERF-011 — `MobileScannerController` sem restrição de formato** · ✅ **Resolvido** (2026-09-10)
[game_view.dart](../lib/presentation/game/game_view.dart) agora passa `formats: [BarcodeFormat.qrCode]` ao `MobileScannerController`.

**PERF-012 — Pesos de fonte Montserrat não usados** · Severidade: Baixa · **Novo**
`w100`/`w200`/`w500` declarados no `pubspec.yaml` sem nenhum call site — ~970KB de peso morto no app. Esforço: P.

**PERF-013 — Cantos do scanner overlay recriados a cada frame de animação** · Severidade: Baixa · **Novo**
[lib/presentation/game/widget/scanner_overlay.dart:89-152](../lib/presentation/game/widget/scanner_overlay.dart#L89-L152) — 4 `_corner()` dentro do `builder` do `AnimatedBuilder` sem depender do valor animado. Esforço: P.

---

## 3. Tabela de pontuações

> **Atualização 2026-09-10:** uma segunda rodada de correções fechou 12 itens do plano de ação (`SEC-012`, `ARQ-013`, `ARQ-014`, `ARQ-019`, `DOC-005`, `OPS-012`, `OPS-010`, `PERF-011`, `PERF-009`, `PERF-010`, `UX-010`, `UX-011`) — ver notas em [4-ACTION_PLAN.md](4-ACTION_PLAN.md) para o "como" de cada um, com evidência reproduzível (comandos de `flutter analyze`/`flutter test` rodados). A tabela e o escore já refletem essa correção; a nota entre parênteses é o valor imediatamente anterior (2026-09-09), e a nota entre colchetes é o valor da v1.0/v2.0 original (2026-09-08/09).

| Eixo | Nota | Justificativa |
|---|---|---|
| Fundamentos | 7,5/10 (6,5) | `ARQ-013`/`ARQ-014`/`ARQ-019` (playback direto no SDK + `GameViewModel` anêmica/não injetada) resolvidos — os dois débitos mais relevantes do eixo; resta DI manual (`ARQ-015`) |
| Segurança | 6,5/10 (5,5) | `SEC-012` (gate de consentimento Spotify centralizado) some-se a `SEC-001`/`OPS-007` já corrigidos — mas nada commitado ainda e rotação do Client ID no Spotify Dashboard segue pendente |
| Experiência | 6/10 (5,5) | `UX-010`/`UX-011` (typo + alvos de toque) resolvidos; design system ainda ignorado por ~85% das telas (`UX-001`, maior débito do eixo, segue aberto) |
| Operações | 7/10 (6) | `OPS-010` (retry/backoff) e `OPS-012` (branches órfãs decididas) resolvidos; cobertura de teste (`OPS-001`) e ausência de e2e (`OPS-009`) continuam em aberto |
| Documentação | 5/10 (4,5) | `DOC-005` ganhou gate automatizado de fato (hook + CI), diferente do `DOC-011` (só visibilidade via template) |
| Performance | 9/10 (8) | `PERF-009`/`PERF-010`/`PERF-011` resolvidos — os 3 achados de severidade "Atenção" que restavam no eixo mais maduro do projeto |

**Escore geral: 6,9/10** (antes desta rodada: 6,2/10 · v2.0 original: 5,6/10 · v1.0: 4,3/10)

---

## 4. Pontos fortes, atenções e críticos

### Pontos fortes
- **ARQ-020, ARQ-021** — camadas limpas + timeout/erro tipado em toda rede
- **OPS-014 / PERF-003** — fallback Spotify→iTunes com cache
- **SEC-004, SEC-005, SEC-006, SEC-007** — Rules, HTTPS, storage local e permissões corretos
- **UX-012, UX-013** — tratamento de estado granular e mensagens de erro específicas (onde aplicado)
- **DOC-008** — README honesto e completo
- **PERF-006, PERF-007** — Firestore sem N+1, disposal de recursos consistente

### Atenções (relevantes, não bloqueantes)
- ARQ-015 — débito residual de arquitetura no fluxo de playback (`ARQ-013`, `ARQ-014`, `ARQ-019` resolvidos em 2026-09-10)
- UX-001, UX-003, UX-005 — design system, acessibilidade, responsividade (`UX-011` resolvido em 2026-09-10)
- OPS-009, OPS-011 — sem e2e, sem fallback de plano (`OPS-010`, `OPS-012` resolvidos em 2026-09-10)
- (`PERF-009`, `PERF-010`, `PERF-011` resolvidos em 2026-09-10)
- DOC-003, DOC-004, DOC-005 (reaberto), DOC-006, DOC-007, DOC-009, DOC-010 — governança documental
- **Residual do bloco crítico:** correções de `SEC-001`/`OPS-007`/`OPS-008`/`UX-009` ainda não commitadas; rotação do Client ID no Spotify Dashboard depende só do usuário

### Críticos (ação imediata)
Nenhum item crítico em aberto no momento — os 4 abaixo foram fechados em 2026-09-09 (ver [4-ACTION_PLAN.md](4-ACTION_PLAN.md) para evidência):
- ~~SEC-001 (Reaberto)~~ → ✅ corrigido de novo, com gate `OPS-007` para não regredir uma terceira vez
- ~~DOC-011~~ → ✅ template de PR com seção de evidência obrigatória
- ~~OPS-008~~ → ✅ `reportNonFatalError` nos 3 pontos citados
- ~~UX-009~~ → ✅ 3 mensagens de erro distintas + logging antes da decisão de UI

---

## 5. Cobertura da análise

Investigado com profundidade: `lib/` completo, `firestore.rules`, `pubspec.yaml`/`pubspec.lock`, `AndroidManifest.xml`, `android/app/build.gradle.kts`, histórico Git completo (log, branches, divergência entre elas), `.github/workflows/ci.yml`, todos os 11 arquivos de `test/` + `coverage/lcov.info` gerado nesta rodada, `docs/*.md`, `README*.md`, `hosting/`.

**Não investigado em profundidade** (por escopo/tempo):
- Execução real do app em dispositivo (profiling, DevTools Timeline, teste com leitor de tela)
- Build/configuração iOS (inexistente)
- Restrição de API Key do Firebase/Google Cloud Console e Redirect URIs do Spotify Developer Dashboard (só verificável nos consoles)
- CVEs reais confirmadas nas dependências desatualizadas (reaproveitado o scanner OSV-Scanner rodado um dia antes; não rerodado nesta sessão)
- Comportamento interno do plugin nativo `spotify_sdk` (persistência de token)
- PRs e branch protection no GitHub (`gh` CLI indisponível neste ambiente)
