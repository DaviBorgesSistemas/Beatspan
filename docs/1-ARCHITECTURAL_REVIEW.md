# Análise Arquitetural — Beatspan

**Projeto:** Beatspan (app Flutter — jogo de adivinhação musical via QR code + Spotify)
**Data da análise:** 2026-09-08
**Versão do documento:** 1.0

---

## 1. Visão geral do projeto e stack

Beatspan é um app Flutter (Dart SDK ^3.9.2) que reproduz o conceito do jogo Hitster: cartas físicas com QR code, lidas pela câmera do celular, disparam a reprodução de uma faixa via Spotify (SDK nativo `spotify_sdk` para Premium, `just_audio` + prévia de 30s para Free), e os jogadores tentam adivinhar o ano de lançamento.

**Stack identificada:**
- **Frontend:** Flutter/Dart, Material, fonte Montserrat custom
- **Estado/DI:** `get_it` (service locator), `ValueNotifier`/`ListenableBuilder` local, sem Provider/Riverpod/Bloc
- **Backend:** Firebase (Firestore para catálogo de músicas, Firebase Hosting para landing de download/QR fallback)
- **Integrações externas:** Spotify SDK (App Remote + Web API), iTunes Search API (fallback de prévia)
- **Scanner:** `mobile_scanner`
- **Persistência local:** `shared_preferences`
- **Arquitetura pretendida:** Clean Architecture-like (`lib/data`, `lib/domain`, `lib/presentation`), com Repository + UseCase + `Either<Failure, T>` (dartz) em alguns fluxos
- **Plataformas:** Android configurado e funcional; iOS não configurado (`firebase_options.dart` lança erro para essa plataforma)
- **Testes:** nenhum
- **CI/CD:** nenhum

O projeto está em fase pré-lançamento (v1.0.0+1, sem tags de release, sem app publicado nas lojas segundo o histórico da conversa de desenvolvimento).

---

## 2. Análise por eixo

### 2.1 Fundamentos — Nota: 4,5/10

A estrutura de pastas nomeia corretamente as camadas de uma Clean Architecture (`lib/data`, `lib/domain`, `lib/presentation`), e dois fluxos do app (FAQ, busca de música por código no Firestore) seguem o padrão Repository + UseCase + `Either<Failure, T>` de forma disciplinada. Mas essa disciplina não é geral: a tela central do app — o scanner de QR e reprodução de música — ignora completamente essa arquitetura em favor de chamadas diretas a serviços de rede dentro do próprio widget.

**ARQ-001 — Domain depende de Data (inversão de dependência quebrada)** · Severidade: Alta
Arquivos: [lib/domain/usecase/base_usecase.dart:3](../lib/domain/usecase/base_usecase.dart#L3), `faqs_usecase.dart:3`, `get_musica_usecase.dart:3`, `faq_repository.dart:2`, `musica_repository.dart:3`
Todos importam `data/failure.dart`. Em Clean Architecture, `domain` é a camada mais interna e não deveria depender de `data` — a classe `Failure` deveria estar em `domain` ou numa camada neutra (`core`/`shared`).
```dart
// lib/domain/usecase/base_usecase.dart
import '../../data/failure.dart';
abstract class BaseUseCase<In, Out> {
  Future<Either<Failure, Out>> execute(In input);
}
```

**ARQ-002 — Data depende de Presentation** · Severidade: Alta
Arquivo: [lib/data/repository/faq_repository_impl.dart:7](../lib/data/repository/faq_repository_impl.dart#L7)
```dart
import '../../presentation/resource/assets_manager.dart';
```
O repositório importa `JsonAssets` da camada de apresentação para saber o caminho do JSON de FAQs — dependência de camada invertida.

**ARQ-003 — GameView ignora Repository/UseCase para o fluxo Spotify/iTunes** · Severidade: Crítica
Arquivo: [lib/presentation/game/game_view.dart:118-140](../lib/presentation/game/game_view.dart#L118-L140)
`_GameViewState` chama `instance<SpotifyService>()`, instancia `SpotifyWebApi` e `ItunesSearchApi` diretamente no widget, faz parsing de resposta e decide fallback de preview — lógica de domínio inteira dentro da camada de apresentação. Isso só foi encapsulado em UseCase para a busca no Firestore (`GetMusicaUseCase`), criando dois padrões coexistentes na mesma tela.

**ARQ-004 — Service locator (`instance<T>()`) chamado direto em widgets** · Severidade: Alta
Ocorre em pelo menos 10 arquivos: `game_view.dart:29-30,120`, `player_music_premium_view.dart:62`, `play_music_free_view.dart:73`, `change_spotify_view.dart:26`, `connect_spotify_premium_view_model.dart:21`, `faqs_view.dart:29`, `settings_view.dart:19,30`, `settings/widget/game_mode.dart:18`, `settings/widget/turn_phone.dart:19`, `share/widgets/connectivity_guard.dart:11`, `splash_view.dart:18`, `spotify_free_transition.dart:79`.
Acopla widgets ao GetIt globalmente, dificultando testes unitários (sem injeção de mocks via construtor).

**ARQ-005 — GameView é um "God Widget"** · Severidade: Alta
Arquivo: [lib/presentation/game/game_view.dart](../lib/presentation/game/game_view.dart) (281 linhas)
Acumula: controle de QR scanner, orquestração de use case, chamadas diretas a 3 serviços de rede, regra de negócio (decidir premium vs free preview), navegação customizada duplicada, e 5 métodos de navegação para telas de erro distintas. O `GameViewModel` associado faz apenas parsing de URL — a maior parte da lógica de negócio real não está nele.

**ARQ-006 — Inconsistência do padrão `Either<Failure, T>` entre módulos** · Severidade: Média
`FaqsUseCase` e `GetMusicaUseCase` seguem `Either` corretamente. O fluxo Spotify (`SpotifyService`, `SpotifyWebApi`, `ItunesSearchApi`) não tem repository/usecase e não usa `Either` — lança exceptions cruas ou retorna `null`, tratado com `try/catch` ad-hoc no widget ([game_view.dart:137](../lib/presentation/game/game_view.dart#L137)). Duas filosofias de erro coexistem.

**ARQ-007 — Duplicação entre `player_music_premium_view.dart` e `play_music_free_view.dart`** · Severidade: Média
[player_music_premium_view.dart:232-269](../lib/presentation/game/player_music/player_music_premium_view.dart#L232-L269) vs [play_music_free_view.dart:420-457](../lib/presentation/game/player_music/play_music_free_view.dart#L420-L457) — método `_nextCardButton()` duplicado quase identicamente, sem widget compartilhado extraído.

**ARQ-008 — Código morto extenso comentado** · Severidade: Média
[play_music_free_view.dart:234-295](../lib/presentation/game/player_music/play_music_free_view.dart#L234-L295) (62 linhas de versão antiga comentada). [settings_view.dart](../lib/presentation/settings/settings_view.dart): **133 de 278 linhas (48%) são código comentado**, incluindo uma implementação alternativa inteira usando `ScaffoldHitster`.

**ARQ-009 / SEC-002 — Client ID do Spotify hardcoded** · Severidade: Média (ver detalhe e recomendação em [SECURITY_REPORT.md](SECURITY_REPORT.md#sec-002))
[lib/app/di.dart:58-59](../lib/app/di.dart#L58-L59) — `clientId`/`redirectUrl` como string literal, duplicando o que o `.env` (não consumido) deveria fornecer.

**ARQ-010 — Model `Musica` anêmico, sem validação de formato** · Severidade: Baixa
[lib/domain/model/musica.dart:8-14](../lib/domain/model/musica.dart#L8-L14) — `fromMap` retorna string vazia silenciosamente se o Firestore não tiver o campo; validação de "URI vazia = não encontrada" fica na camada de dados, não no model.

**ARQ-011 / OPS-001 — Ausência total de testes** · Severidade: Alta (detalhado em [ACTION_PLAN.md](ACTION_PLAN.md))
Nenhuma pasta `test/`. Zero cobertura unit/widget/integration, mesmo havendo contratos (`FaqRepository`, `MusicaRepository`) triviais de mockar.

**ARQ-012 — Nomenclatura inconsistente entre camadas equivalentes** · Severidade: Baixa
`game_viewmodel.dart` vs `connect_spotify_premium_view_model.dart`/`faqs_view_model.dart` — duas convenções de nome de arquivo para o mesmo conceito.

---

### 2.2 Segurança e Compliance — Nota: 6,5/10

Ver relatório dedicado: [SECURITY_REPORT.md](SECURITY_REPORT.md). Resumo: núcleo técnico sólido (Firestore Rules corretas com deny-by-default, 100% HTTPS, permissões Android mínimas), mas penalizado por credencial versionada no Git (`SEC-001`) e ausência de política de privacidade real apesar do app usar OAuth do Spotify com escopos amplos (`SEC-009`).

---

### 2.3 Experiência — Nota: 4,5/10

**UX-001 — Design system aplicado de forma inconsistente** · Severidade: Alta
`lib/presentation/resource/{style_manager,color_manager,font_manager,value_manager}.dart` formam um design system real e é seguido consistentemente em `rules_view.dart`. Mas [settings_view.dart:57,62-65,79-81,110-113,120-123](../lib/presentation/settings/settings_view.dart#L57) usa `Color(0XFF08050D)` e `TextStyle(...)` diretamente. 17 arquivos de tela usam `TextStyle(` cru em vez dos helpers (`camera_permission_view.dart`, `change_spotify_view.dart`, `first_time_view.dart`, `game_error_view.dart`, `home_view.dart`, `splash_view.dart`, entre outros).

**UX-002 — Código morto/comentado extenso em produção** · Severidade: Alta
Mesmo achado de [ARQ-008](#21-fundamentos--nota-45/10) — ~130 linhas mortas em `settings_view.dart:144-276`.

**UX-003 — Zero uso de `Semantics`/acessibilidade** · Severidade: Alta
`grep -rln "Semantics(" lib` retorna zero arquivos em ~40 telas/widgets. Sem `semanticLabel` em `Icon`/`Image`, sem suporte documentado a leitor de tela.

**UX-004 — Contraste em dark theme não verificado sistematicamente** · Severidade: Média
`ColorManager.bagroundColor = '#08050D'` combinado com textos acinzentados (`Colors.white.withValues(alpha: 0.6)` em [game_error_view.dart:48](../lib/presentation/game/game_error_view.dart#L48), `Color(0XFFA9A2B5)` em `settings_view.dart:81`) sem teste de contraste documentado ou lint configurado.

**UX-005 — Responsividade cobre só smartphone** · Severidade: Média
[lib/presentation/resource/screen_manager.dart:7-22](../lib/presentation/resource/screen_manager.dart#L7-L22) oferece apenas multiplicadores percentuais de tela — sem breakpoints, `LayoutBuilder` ou reflow para tablets.

**UX-006 — Tratamento de loading/erro desigual entre telas** · Severidade: Média
`game_view.dart` tem tratamento granular (`_goToError`, `_goToMusicaNaoEncontrada`, `_goToPreviewUnavailable`, `_goToConnectionError`). `settings_view.dart:41-50` não tem estado de loading/erro para `_loadPlanType()`/`_connectSpotify()`.

**UX-007 — Referência quebrada no README** · Severidade: Baixa
[README.md:97](../README.md#L97) referencia `docs/PROMPT_ANALISE_ARQUITETURAL.md`, que não existia no repositório no momento desta análise (o prompt usado para gerar este próprio relatório vivia fora do repo, em `guides/prompts/`). Além disso, o README não documenta corretamente como o `.env` é (não) consumido — ver `SEC-002`.

---

### 2.4 Operações e Confiabilidade — Nota: 2/10

**OPS-001 — Nenhuma pasta `test/` no projeto** · Severidade: Crítica
`find test -type f` → nenhum resultado. Zero cobertura unit/widget/integration. Funções puras fáceis de testar (`GameViewModel.validate/extractCodigo`) não têm cobertura.

**OPS-002 — Sem pipeline de CI/CD** · Severidade: Crítica
`.github/` contém apenas `.github/modernize/java-upgrade/hooks/scripts/*` (tooling de modernização Java, não CI). Não existe `.github/workflows/*.yml`. Nenhum build, lint ou teste automatizado em PR.

**SEC-001 — `.env` com credenciais versionado no Git** · Severidade: Alta (detalhado em [SECURITY_REPORT.md](SECURITY_REPORT.md#sec-001))
`.env` rastreado desde commit `0d5d678`, ausente do `.gitignore`, contendo comentário interno próprio alertando contra isso.

**OPS-003 — Zero observabilidade/crash reporting em produção** · Severidade: Crítica
`grep -rli "crashlytics\|sentry" lib pubspec.yaml` → nada. `firebase_crashlytics` não está no `pubspec.yaml`. `grep -rn "debugPrint\|print("` em `lib` → apenas 2 ocorrências em todo o app. Se o app falhar em produção, não há captura, telemetria ou alerta algum.

**OPS-004 / PERF-001 — Chamadas HTTP sem timeout, sem retry, tratamento de erro raso** · Severidade: Alta
[lib/data/network/spotify_webapi.dart:24-26,52-53,62-63](../lib/data/network/spotify_webapi.dart#L24-L26) e [itunes_search_api.dart:19-20](../lib/data/network/itunes_search_api.dart#L19-L20) — `http.get`/`http.put` sem `.timeout(...)`. Erros retornam `null` sem distinguir causa (rede vs 404 vs 401 vs 429). Exceção positiva: [musica_firestore_data_source.dart:24-36](../lib/data/network/musica_firestore_data_source.dart#L24-L36) tem exceções de domínio tipadas, mas também sem timeout.

**OPS-005 — Crash logs de build tool versionados no diretório de trabalho** · Severidade: Média
`hs_err_pid29876.log` (70KB) e `replay_pid29876.log` (1.5MB) na raiz — `OutOfMemoryError` do daemon Gradle durante build Kotlin. Não estão no índice do Git (`.gitignore` cobre `*.log`), mas sua presença recorrente indica instabilidade do ambiente de build (heap/`org.gradle.jvmargs` não configurado em `gradle.properties`).

**OPS-006 — Modelagem do Firestore é eficiente, mas sem cache local** · Severidade: Baixa (achado misto — positivo no design, lacuna na resiliência)
[musica_firestore_data_source.dart:22-47](../lib/data/network/musica_firestore_data_source.dart#L22-L47) — leitura de documento único por scan (1 request = 1 leitura, sem overhead de listener), custo linear e previsível. Mas sem `GetOptions(source: Source.cache)`, toda leitura em rede instável falha sem fallback local (o erro é tratado com mensagem amigável, mas sem cache).

---

### 2.5 Documentação e Governança — Nota: 5/10

**DOC-001 — Documentação de planejamento já desatualizada frente ao código** · Severidade: Alta
`docs/ESTADO-ATUAL.md:70-71` descreve navegação comentada e credenciais placeholder que não correspondem mais ao código atual (`game_view.dart:148-156` já tem a navegação ativa; `di.dart:59` já tem client ID real). `docs/ROADMAP_CONCLUSAO.md:42` descreve `RulesView` como vazia — hoje tem 524 linhas de conteúdo completo.

**DOC-002 — README referencia arquivo inexistente** · Severidade: Alta
Mesmo achado de `UX-007` — [README.md:97](../README.md#L97).

**DOC-003 — Sem ADRs (Architecture Decision Records)** · Severidade: Média
Nenhuma pasta `docs/adr/` ou convenção equivalente. Decisões como "por que Clean Architecture só na feature FAQ" ou "por que `get_it` em vez de Provider/Riverpod" não estão registradas formalmente.

**DOC-004 — Sem CHANGELOG, sem tags de release** · Severidade: Média
`pubspec.yaml:6` tem `version: 1.0.0+1`. `git tag -l` retorna vazio (confirmado nesta análise). Sem `CHANGELOG.md` no repositório.

**DOC-005 — Histórico de commits com baixíssima qualidade descritiva** · Severidade: Alta
`git log --oneline -30`: **17 de 30 commits recentes têm mensagem `...` ou `..`**, sem descrição. Mensagens existentes são genéricas (`settings` 2x, `landpage`, `splash`, `icone`, `estrurtura firebase` — com erro de digitação). Uma exceção isolada de qualidade segue Conventional Commits, mas não é o padrão do projeto.

**DOC-006 — Estratégia de branching pouco clara** · Severidade: Média
`git branch -a`: branch ativa `beatspan_v2`, mais `master`, `origin/developer`, `origin/refatore` — quatro branches de longa duração sem convenção aparente (nomes em PT/EN misturados, sem GitFlow/trunk-based documentado).

**DOC-007 — Sem política de atualização de dependências** · Severidade: Baixa
Nenhum `CONTRIBUTING.md`, sem Dependabot/Renovate configurado, sem cadência de atualização documentada.

**DOC-008 — README é o ponto forte da documentação** · Severidade: Informativo (positivo)
`README.md`/`README.en.md` (111/109 linhas) bem estruturados, descrevem stack, arquitetura, fluxo principal, e admitem limitações abertamente — incomum e positivo.

---

### 2.6 Performance e Escalabilidade — Nota: 6/10

**PERF-001 — Nenhum timeout nas chamadas HTTP** · Severidade: Alta (mesmo achado de `OPS-004`, ver acima)

**PERF-002 — Nenhuma estratégia de retry** · Severidade: Média
Confirmado: `pubspec.yaml` não lista `dio`, `retry` ou similar — `http: ^1.6.0` é a única lib HTTP, usada sem qualquer backoff.

**PERF-003 — Nenhum cache para respostas de rede** · Severidade: Média
Cada scan de carta dispara chamadas novas a `SpotifyWebApi.getTrack`/`ItunesSearchApi.searchTrack` ([game_view.dart:123,130](../lib/presentation/game/game_view.dart#L123)), sem cache em memória/disco. `cached_network_image` ausente do pubspec — imagens de capa recarregam a cada rebuild/navegação.

**PERF-004 — Assets de imagem grandes sem otimização** · Severidade: Média
```
How-to-Play.png              ~500 KB
neon-phone-music-waves.png   ~444 KB
icon.png                     ~278 KB
soundblaster.png             ~276 KB
beatspan_icon.png            ~367 KB
splash_logo.png              ~505 KB
```
Sem variantes de densidade, sem WebP, sem `cacheWidth`/`cacheHeight` no código para downscale em runtime.

**PERF-005 — Uso de `const` inconsistente** · Severidade: Baixa
Ex.: [play_music_free_view.dart:165,188,227](../lib/presentation/game/player_music/play_music_free_view.dart#L165) — `SizedBox(height: 32)` sem `const` em valores literais. Dentro do `StreamBuilder` de `_playButton()` (linhas 337-418), widgets internos não são const e são reconstruídos a cada emissão do stream.

**PERF-006 — Firestore: ponto único de acesso, sem N+1** · Severidade: Informativo (positivo)
Único ponto de acesso é `doc(codigo).get()` — sem queries de coleção, sem necessidade de índice composto.

**PERF-007 — Disposal de recursos correto onde auditado** · Severidade: Informativo (positivo)
Verificado em `turn_phone_ready_view.dart:130-138`, `player_music_premium_view.dart:41-44`, `play_music_free_view.dart:62-65`, `splash_view.dart`, `scanner_overlay.dart` — sem vazamentos óbvios de `StreamSubscription`/`AnimationController`.

**PERF-008 — Gerenciamento de estado local, sem granularidade** · Severidade: Informativo
20 `StatefulWidget` vs 13 `StatelessWidget`. Tudo via `setState` local — aceitável na escala atual, mas não escalável a rebuilds granulares se a árvore crescer (sem Provider/Riverpod/Bloc).

---

## 3. Tabela de pontuações

| Eixo | Nota | Justificativa |
|---|---|---|
| Fundamentos | 4,5/10 | Camadas nomeadas corretamente mas com inversões de dependência reais e a tela mais crítica do app (GameView) fora do padrão arquitetural |
| Segurança | 6,5/10 | Rules e permissões exemplares; puxado para baixo por segredo versionado e ausência de política de privacidade |
| Experiência | 4,5/10 | Design system real mas aplicado em menos da metade das telas; zero acessibilidade |
| Operações | 2/10 | Zero testes, zero CI/CD, zero observabilidade — maior lacuna do projeto |
| Documentação | 5/10 | README forte, mas docs de planejamento desatualizados e histórico de commits ilegível |
| Performance | 6/10 | Disposal correto, mas zero cache/retry e assets pesados |

**Escore geral: 4,3/10**

---

## 4. Pontos fortes, atenções e críticos

### Pontos fortes
- **SEC-004** — Firestore Security Rules com deny-by-default correto ([firestore.rules:18-26](../firestore.rules#L18-L26))
- **PERF-007** — Disposal de `StreamSubscription`/`AnimationController` consistente onde auditado
- **SEC-005** — 100% das chamadas de rede em HTTPS, sem bypass de certificado
- **SEC-007** — Permissões Android mínimas (só `CAMERA`)
- **DOC-008** — README honesto, admite limitações abertamente
- Runbook `docs/TROUBLESHOOTING_SPOTIFY.md` registra causa raiz e resolução de 6 bugs reais — qualidade rara em projetos pequenos

### Atenções (relevantes, não bloqueantes)
- UX-001, ARQ-008/UX-002 — inconsistência de design system e código morto
- PERF-003, PERF-004 — ausência de cache de rede e assets pesados
- DOC-001, DOC-005, DOC-006 — documentação desatualizada e histórico de commits ilegível
- UX-003, UX-005 — acessibilidade e responsividade tablet ausentes

### Críticos (ação imediata)
- **SEC-001** — `.env` com credencial versionado no Git
- **OPS-001** — zero testes automatizados
- **OPS-002** — zero CI/CD
- **OPS-003** — zero observabilidade/crash reporting
- **ARQ-003** — lógica de negócio crítica (Spotify/iTunes) fora da arquitetura, direto no widget
- **SEC-009** — ausência de política de privacidade real apesar do OAuth do Spotify

---

## 5. Cobertura da análise

Investigado com profundidade: `lib/` completo (data/domain/presentation), `firestore.rules`, `pubspec.yaml`, `AndroidManifest.xml`, histórico Git (log, branches, tags), `docs/*.md`, `README*.md`, `.github/`.

**Não investigado em profundidade** (por escopo/tempo):
- Execução real do app (profiling de performance/frames, DevTools Timeline)
- Build e configuração iOS (não configurado — `firebase_options.dart` lança erro para essa plataforma)
- CVEs reais confirmadas nas dependências desatualizadas (requer scanner dedicado — ver [SECURITY_REPORT.md](SECURITY_REPORT.md))
- Restrição da API Key do Firebase/Google Cloud Console (só verificável no console)
- Comportamento interno do plugin nativo `spotify_sdk` quanto a persistência de token
- Branch protection rules no GitHub (requer acesso à API/web)
- `firestore.indexes.json` e configuração de billing/rate-limiting no Firebase Console
