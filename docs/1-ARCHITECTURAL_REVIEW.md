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

### 2.1 Fundamentos — Nota: 6,5/10

As fronteiras de camada (`domain` não depende de `data`/`presentation`, e vice-versa) hoje estão corretas, e a maioria dos fluxos de feature (FAQ, busca de música, conexão Spotify Premium) segue Repository → UseCase → `Either<Failure,T>` de forma disciplinada, com exceções tipadas e timeout na camada de rede. O núcleo de reprodução (Spotify SDK) ainda mistura infraestrutura dentro de widgets, o DI é 100% manual com boilerplate repetitivo, e não há state management estruturado.

**ARQ-001 — Domain depende de Data** · ✅ **Resolvido**
`Failure` foi movido para `lib/domain/failure.dart`. Confirmado: `grep -rn "import.*data/" lib/domain` sem resultado.

**ARQ-002 — Data depende de Presentation** · ✅ **Resolvido**
`lib/data/repository/faq_repository_impl.dart` não importa mais `presentation/resource/assets_manager.dart`. Confirmado: `grep -rn "import.*presentation" lib/data` sem resultado.

**ARQ-003 — GameView ignorava Repository/UseCase para Spotify/iTunes** · ✅ **Resolvido** (ver `ARQ-013` para residual)
`MusicaPlaybackUseCase`/`MusicaPlaybackRepositoryImpl` criados; `GameView` agora depende só do use case.

**ARQ-004 — Service locator chamado direto em widgets** · ✅ **Resolvido** (ver `ARQ-019` para exceção)
Views roteadas e widgets filhos recebem dependências via construtor; `RouteGenerator` é o único ponto de composição.

**ARQ-013 — Controle de reprodução (play/pause/salvar) ainda chama SDK direto do widget** · Severidade: Atenção · **Novo**
[lib/presentation/game/player_music/player_music_premium_view.dart:62-66](../lib/presentation/game/player_music/player_music_premium_view.dart#L62-L66), [play_music_free_view.dart:72-74](../lib/presentation/game/player_music/play_music_free_view.dart#L72-L74). Ao contrário de "achar a música" (já migrado, `ARQ-003`), "tocar/salvar a música" (`SpotifySdk.play`, `SpotifySdk.subscribePlayerState`, `SpotifyWebApi` instanciado inline) continua direto no `State`, não testável isoladamente. Esforço: M.

**ARQ-014 — `GameViewModel` anêmica; orquestração real mora em `GameView`** · Severidade: Atenção · **Novo** (residual de `ARQ-005`)
[lib/presentation/game/game_viewmodel.dart:1-32](../lib/presentation/game/game_viewmodel.dart) (32 linhas, só parsing) vs [game_view.dart:89-225](../lib/presentation/game/game_view.dart#L89-L225) (137 linhas: orquestra 2 use cases, decide 4 tipos de navegação de erro). `connect_spotify_premium_view_model.dart:34-70` mostra que o padrão correto já existe no projeto — só não foi aplicado à tela mais crítica. Esforço: M.

**ARQ-019 — `GameViewModel` não é injetada via construtor** · Severidade: Atenção · **Novo**
[lib/presentation/game/game_view.dart:37](../lib/presentation/game/game_view.dart#L37) — `final GameViewModel controller = GameViewModel();` instanciado direto no `State`, diferente de `ChangeSpotifyView`/`SettingsView` (recebem via `required this.viewModel`). Única exceção ao padrão de `ARQ-004`, resolvido em todo o resto do app. Esforço: P/M.

**ARQ-015 — DI manual com boilerplate repetitivo; `disposeFaqsModule()` nunca chamada** · Severidade: Atenção · **Novo**
[lib/app/di.dart:46-104](../lib/app/di.dart#L46-L104) — 15 registros em 3 funções, cada um com guard manual `if (!instance.isRegistered<T>())`. `routes_manager.dart` chama `initSpotifyModule()`/`initFaqsModule()` a cada navegação; `disposeFaqsModule()` existe mas não há call site fora de `di.dart`. Esforço: M.

**ARQ-016 — `dart:ffi`'s `Void` usado como sentinela de "sem input"** · Severidade: Baixa · **Novo**
[lib/presentation/faqs/faqs_view_model.dart:2,25](../lib/presentation/faqs/faqs_view_model.dart#L25) — `import 'dart:ffi'` só para usar `Void` como argumento de `execute(void input)`. O idiomático já disponível na stack (`dartz`) é `Unit`/`unit`. Esforço: P.

**ARQ-017 — `MyApp` implementa pseudo-singleton incorreto + campo morto** · Severidade: Baixa · **Novo**
[lib/app/app.dart:6-11](../lib/app/app.dart#L6-L11) — `static MyApp get instance => MyApp._internal();` recria uma instância nova a cada chamada, não é singleton de fato. `appState` declarado, nunca lido/escrito. Esforço: P.

**ARQ-018 — Catch genérico em `MusicaPlaybackUseCase` descarta exceções tipadas** · Severidade: Baixa · **Novo**
[lib/domain/usecase/musica_playback_usecase.dart:58-61](../lib/domain/usecase/musica_playback_usecase.dart#L58-L61) — captura tudo com `catch (e)` genérico, perdendo a distinção entre `NetworkTimeoutException`/`NetworkConnectionException`/`InvalidServerResponseException` que a camada de dados já tipa corretamente. Esforço: P.

**ARQ-006 — Dois padrões de tratamento de erro** · Severidade: Média · Ainda **Aberto**
Fluxo Spotify ainda não usa `Either<Failure,T>` de ponta a ponta (ver `ARQ-013`).

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

**ARQ-005 — `GameView` "God Widget"** · Severidade: Atenção · Ainda **Aberto**, reduzido
[lib/presentation/game/game_view.dart](../lib/presentation/game/game_view.dart) (271 linhas) não fala mais direto com SDKs, mas ainda concentra apresentação + navegação + coordenação de fluxo (9 métodos privados). Ver `ARQ-014`.

---

### 2.2 Segurança e Compliance — Nota: 5,5/10

Ver relatório dedicado: [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md). Resumo: núcleo técnico sólido (Rules, HTTPS, permissões mínimas, consentimento LGPD implementado), mas **`SEC-001` foi corrigido e revertido em menos de 24h** — a credencial do Spotify está de volta ao Git, sem `.gitignore` — e o build de release usa chave de assinatura de debug (`SEC-011`, novo).

---

### 2.3 Experiência — Nota: 4,5/10

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

**UX-010 — Typo visível: "BEATSPAN SEM SPOTIFY PREMIYM"** · Severidade: Baixa · **Novo**
[lib/presentation/spotify_free_transition/spotify_free_transition.dart:44](../lib/presentation/spotify_free_transition/spotify_free_transition.dart#L44). Esforço: P.

**UX-011 — Alvos de toque < 48dp em botões de fechar/voltar** · Severidade: Atenção · **Novo**
`change_spotify_view.dart:61-75`, `spotify_free_transition.dart:20-34`, `game_error_view.dart:29-33` sem `width`/`height` explícitos. Contraste: `player_music_premium_view.dart:141-151` já usa `Container(width: 44, height: 44)` — padrão correto existe, mas não é uniforme. Esforço: P.

**UX-012 — `play_music_free_view.dart` com tratamento de estado granular** · Severidade: Ponto forte · **Novo**
Loading/erro/vazio explícitos e `CachedNetworkImage` com `placeholder`/`errorWidget` corretos ([play_music_free_view.dart:35-58,232-245](../lib/presentation/game/player_music/play_music_free_view.dart#L35-L58)) — melhor exemplo do app, deveria ser replicado.

**UX-013 — Mensagens de erro específicas no fluxo Premium** · Severidade: Ponto forte · **Novo**
[lib/presentation/change_spotify/connect_spotify_premium_view_model.dart:79-108](../lib/presentation/change_spotify/connect_spotify_premium_view_model.dart#L79-L108) diferencia app não instalado / autorização negada / fallback — é o padrão que `UX-009` deveria seguir.

---

### 2.4 Operações e Confiabilidade — Nota: 5/10

**OPS-001 — Ausência de testes** · Severidade: Alta · Parcialmente **Resolvido**, cobertura insuficiente
`flutter test --coverage`: 60 testes passam, mas só **22 de 76 arquivos de `lib/`** aparecem no relatório de cobertura — ou seja, ~70% do projeto nunca é sequer importado por um teste. Dentro dos 22 tocados, cobertura de linha é 259/520 (~49,8%). Fluxo de conexão Spotify (`connect_spotify_premium_view_model.dart`) e `GameView` (orquestração do jogo) seguem sem nenhum teste.

**OPS-002 — Pipeline de CI** · ✅ **Resolvido**, com lacunas — ver `OPS-007`.

**SEC-001 — `.env` versionado** · ⚠️ **Reaberto** — ver [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md#sec-001).

**OPS-003 — Observabilidade/crash reporting** · ✅ **Resolvido parcialmente** — Crashlytics integrado para exceções não tratadas, mas ver `OPS-008` (crítico).

**OPS-008 — Exceções tratadas (`catch`) nunca chegam ao Crashlytics** · Severidade: **Crítica** · **Novo**
`connect_spotify_premium_view_model.dart:76` (`catch (_) {}` silencioso em `disconnect()`), `player_music_premium_view.dart:47` (`.catchError((_) {})`), `play_music_free_view.dart:86`. Nenhum chama `FirebaseCrashlytics.instance.recordError(...)` — só os handlers globais de `main.dart` (erros *não tratados*) alimentam o Crashlytics. Os erros mais comuns e acionáveis em produção (Spotify indisponível, Firestore fora do ar) ficam invisíveis no dashboard. Esforço: P.

**OPS-004 / PERF-001 — Chamadas HTTP sem timeout** · ✅ **Resolvido** — timeout de 10s + exceções tipadas em todas as fontes de rede, bem testado.

**OPS-005 — Crash logs de build tool versionados** · Severidade: Baixa · Não reverificado nesta rodada (fora do escopo desta reexecução).

**OPS-006 — Firestore sem cache local** · Severidade: Baixa · Ainda **Aberto** — ver `PERF-009`.

**OPS-009 — Zero testes de integração/e2e** · Severidade: Atenção · **Novo**
Nenhuma pasta `integration_test/`. Regressões de contrato (schema Firestore, `spotify_sdk`) só apareceriam em teste manual/produção. Esforço: G.

**OPS-010 — Sem retry/backoff em nenhuma chamada de rede** · Severidade: Atenção · **Novo**
Timeout existe (`OPS-004`), retry não. Um timeout transitório (comum em rede de evento ao vivo) já propaga direto para a tela de erro. Esforço: M.

**OPS-011 — Sem fallback automático Premium → Free quando Spotify falha** · Severidade: Atenção · **Novo**
[connect_spotify_premium_view_model.dart:60-108](../lib/presentation/change_spotify/connect_spotify_premium_view_model.dart#L60-L108) — falha só gera mensagem + deep link manual, sem degradação automática para o modo Free. Decisão de produto, não só técnica.

**OPS-012 — Branches órfãs; trabalho de segurança perdido em `refatore`** · Severidade: Atenção · **Novo**
`0a`/`developer` são ancestrais estritos de `beatspan_v2` (0 commits próprios — mortas). `refatore` tem 4 commits nunca mesclados, incluindo introdução de `flutter_secure_storage` — confirmado ausente em `beatspan_v2` (`pubspec.yaml` não o lista). Esse trabalho foi efetivamente abandonado, não apenas adiado. Esforço: M.

**OPS-014 — Fallback gracioso Spotify → iTunes com cache** · Severidade: Ponto forte · **Novo**
`musica_playback_repository_impl_test.dart` confirma fallback automático + cache por `trackId` — melhor exemplo de resiliência do projeto.

**OPS-007 — CI sem gate de cobertura, build ou secret-scanning** · Severidade: Atenção · **Novo**
`.github/workflows/ci.yml` roda analyze/format/test, mas não builda artefato, não mede cobertura, e não teria pego a regressão de `SEC-001` (nenhum step de detecção de segredos). Esforço: P.

---

### 2.5 Documentação e Governança — Nota: 4/10

Ver detalhamento completo em seção própria — resumo: README continua um ponto forte real, mas o próprio checklist do plano de ação (`4-ACTION_PLAN.md`) afirmava um item de segurança crítico como concluído quando ele já havia regredido (`DOC-011`, novo), e a convenção de commits documentada (`DOC-005`) não sobreviveu nem um dia (o commit de topo da branch auditada ainda é `...`).

**DOC-001 / DOC-002** · ✅ **Resolvidos**.
**DOC-003, DOC-004, DOC-006, DOC-007** · Ainda **Abertos**, sem mudança relevante.
**DOC-005 — Convenção de commits** · ⚠️ **Reaberto** — ver [4-ACTION_PLAN.md](4-ACTION_PLAN.md).
**DOC-009, DOC-010, DOC-011** · **Novos** — ver [4-ACTION_PLAN.md](4-ACTION_PLAN.md) e [3-TECH_DEBT_REGISTER.md](3-TECH_DEBT_REGISTER.md).

---

### 2.6 Performance e Escalabilidade — Nota: 8/10

A decisão arquitetural central — leitura de música por `doc(id)` direto no Firestore, sem queries — é excelente e escala para milhões de cartas. O debounce do scanner está correto. Os pontos negativos são todos otimizações pontuais, nenhum estrutural.

**PERF-001 / OPS-004 — Sem timeout** · ✅ **Resolvido**.
**PERF-002 — Sem retry** · Ainda **Aberto** — ver `OPS-010`.
**PERF-003 — Sem cache de rede/imagem** · ✅ **Resolvido** — cache em memória por `trackId` + `cached_network_image` em uso real.
**PERF-004 — Assets grandes** · Ainda **Aberto**, sem mudança relevante além de `PERF-012`.
**PERF-005 — `const` inconsistente** · Ainda **Aberto**, evidência nova em `home_view.dart`.
**PERF-006 — Firestore sem N+1** · Ponto forte, confirmado sem mudança.
**PERF-007 — Disposal correto** · Ponto forte, não reverificado nesta rodada.
**PERF-008 — Estado local sem granularidade** · Informativo, sem mudança.

**PERF-009 — `MusicaRepositoryImpl` sem cache (ao contrário do repositório irmão)** · Severidade: Atenção · **Novo**
[lib/data/repository/musica_repository_impl.dart:9-25](../lib/data/repository/musica_repository_impl.dart#L9-L25) — escanear a mesma carta duas vezes dispara novo round-trip ao Firestore; `musica_playback_repository_impl.dart` já cacheia. Esforço: P.

**PERF-010 — Sem tratamento de rate limit 429 do Spotify** · Severidade: Atenção · **Novo**
[lib/data/network/spotify_webapi.dart:33-40](../lib/data/network/spotify_webapi.dart#L33-L40) — `429` cai na branch de erro genérica, sem respeitar `Retry-After`. Esforço: M.

**PERF-011 — `MobileScannerController` sem restrição de formato** · Severidade: Atenção · **Novo**
[lib/presentation/game/game_view.dart:36](../lib/presentation/game/game_view.dart#L36) — analisa todos os formatos de barcode, não só QR, consumindo CPU/bateria de forma desnecessária durante o estado em que o usuário mais tempo passa. Esforço: P (adicionar `formats: [BarcodeFormat.qrCode]`).

**PERF-012 — Pesos de fonte Montserrat não usados** · Severidade: Baixa · **Novo**
`w100`/`w200`/`w500` declarados no `pubspec.yaml` sem nenhum call site — ~970KB de peso morto no app. Esforço: P.

**PERF-013 — Cantos do scanner overlay recriados a cada frame de animação** · Severidade: Baixa · **Novo**
[lib/presentation/game/widget/scanner_overlay.dart:89-152](../lib/presentation/game/widget/scanner_overlay.dart#L89-L152) — 4 `_corner()` dentro do `builder` do `AnimatedBuilder` sem depender do valor animado. Esforço: P.

---

## 3. Tabela de pontuações

> **Atualização 2026-09-09 (mesmo dia):** os 4 itens críticos abaixo foram corrigidos após a nota original ter sido calculada — ver notas em [4-ACTION_PLAN.md](4-ACTION_PLAN.md) para o "como". A tabela e o escore já refletem essa correção; a nota entre parênteses é o valor antes dela.

| Eixo | Nota | Justificativa |
|---|---|---|
| Fundamentos | 6,5/10 | Camadas corrigidas de fato; núcleo de playback e DI ainda com débito |
| Segurança | 6,5/10 (5,5) | `SEC-001` corrigido de novo + `OPS-007` (gate de secret-scanning no CI) — mas ainda não commitado e rotação do Client ID no Spotify Dashboard segue pendente |
| Experiência | 5,5/10 (4,5) | `UX-009` (mensagem que mascarava erro real) corrigido; design system ainda ignorado por ~85% das telas |
| Operações | 6/10 (5) | `OPS-008` (erros tratados agora chegam ao Crashlytics) corrigido; cobertura de teste continua baixa |
| Documentação | 4,5/10 (4) | `DOC-011` tem mecanismo (template de PR) mas não é gate automatizado; demais débitos documentais sem mudança |
| Performance | 8/10 | Eixo mais maduro do projeto, não tocado nesta correção |

**Escore geral: 6,2/10** (v2.0 antes da correção: 5,6/10 · v1.0: 4,3/10)

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
- ARQ-013, ARQ-014, ARQ-015, ARQ-019 — débito residual de arquitetura no fluxo de playback
- UX-001, UX-003, UX-005, UX-011 — design system, acessibilidade, responsividade, alvos de toque
- OPS-009, OPS-010, OPS-011, OPS-012 — sem e2e, sem retry, sem fallback de plano, branches órfãs
- PERF-009, PERF-010, PERF-011 — cache assimétrico, rate limit, filtro de scanner
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
