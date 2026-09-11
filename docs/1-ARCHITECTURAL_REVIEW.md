# Beatspan — Architectural Review

**Data da análise:** 2026-09-11
**Versão do documento:** 3.0 (reanálise completa do zero, substitui a versão 2.0)
**Commit analisado:** `577dd0c` (branch `beatspan_v2`)

> Gerado a partir de `guides/prompts/PROMPT_ANALISE_ARQUITETURAL.md`. Reanálise do zero — os IDs deste documento **não** correspondem necessariamente aos IDs da versão 2.0 (muitos itens da v2.0 foram confirmados como resolvidos e não são recriados aqui; novos achados recebem numeração própria por eixo). Investigação conduzida por 6 agentes especializados, um por eixo, cada um lendo o código atual de forma independente e reportando apenas achados com evidência real (arquivo:linha).

---

## 1. Visão geral do projeto

Beatspan é um app Flutter (Android apenas — não há diretório `ios/`) que acompanha um jogo de cartas físico no estilo Hitster. Cada carta traz um QR code apontando para `beatspangame.com/<código>`; o app resolve o código no Firestore (coleção `musicas`) para um `spotify_uri` e reproduz a faixa — via Spotify App Remote (Premium) ou prévia de 30s (Free, com fallback para iTunes Search API).

**Estado do projeto:** pré-lançamento, ativo. 90 arquivos Dart em `lib/`, 24 arquivos de teste em `test/`, plataforma única (Android).

### Stack identificada

| Categoria | Tecnologia |
|---|---|
| Framework | Flutter (SDK `^3.9.2`) |
| Injeção de dependência | `get_it` (com extension idempotente própria) |
| Result/Either | `dartz` |
| Persistência local | `shared_preferences` |
| Config por ambiente | `flutter_dotenv` |
| Backend | `firebase_core`, `cloud_firestore` (sem backend próprio) |
| Observabilidade | `firebase_crashlytics`, `firebase_analytics` (novo desde a v2.0) |
| Integração Spotify | `spotify_sdk` (App Remote) + Web API via `http` |
| QR / câmera | `mobile_scanner`, `permission_handler` |
| Áudio local | `just_audio` |
| Imagens | `cached_network_image` |
| CI | GitHub Actions (`ubuntu-latest`) |

---

## 2. Análise por eixo

### 2.1 Fundamentos — Nota: 7,5/10

O projeto mantém uma **Clean Architecture simplificada** consistente: `presentation/` por feature, `domain/`/`data/` genéricos, contratos abstratos (`MusicaRepository`, `FaqRepository`) com implementação isolada e testes por camada.

**O que a v2.0 apontava como resolvido continua resolvido, confirmado no código atual:**
- **ARQ-001** (bypass de DI no fluxo de preview) — `GameView` resolve `PreviewPlaybackUseCase` via `instance<>()`, consistente com o resto do app.
- **ARQ-002** (colisão de código de erro) — `lib/domain/failure.dart` é `sealed class Failure` com hierarquia própria por domínio (`MusicaFailure`, `MusicaPlaybackFailure`, `SpotifyPlaybackFailure`, `PreviewPlaybackFailure`, `FaqFailure`), consumida via `switch` exaustivo que o compilador obriga a tratar. Sem nenhum código `int` compartilhado remanescente.
- **ARQ-003** (crash em `barcodes.first`) — guarda explícita antes do acesso, confirmado em `lib/presentation/game/game_view.dart:75`.
- **ARQ-005** (feature morta de idioma/país) — removida por completo (enums, prefs, rota, testes, menções no README).
- **ARQ-006** (`exit(1)`) — ambos os pontos (`home_view.dart`, `first_time_view.dart`) usam `SystemNavigator.pop()`.

**Novos achados desta reanálise:**

`domain/` acopla diretamente a SDKs de infraestrutura, quebrando a regra de dependência da Clean Architecture: `lib/domain/analytics_reporting.dart` importa `firebase_analytics`, `lib/domain/error_reporting.dart` importa `firebase_crashlytics`, e `lib/domain/usecase/spotify_playback_usecase.dart` importa `flutter/services.dart` para capturar `PlatformException`/`MissingPluginException` do plugin nativo `spotify_sdk` (**ARQ-101**). É uma decisão pragmática e documentada no próprio código, não um bug, mas significa que testar esses use cases isoladamente exige o Flutter engine, e trocar de crash reporter ou SDK do Spotify exige editar `domain/`, não só `data/`.

Tratamento de exceção "erro inesperado" é inconsistente entre repositórios: `musica_playback_repository_impl.dart` e `spotify_playback_usecase.dart` sempre chamam `reportNonFatalError` no catch genérico; já `musica_repository_impl.dart:35-36`, `faq_repository_impl.dart:20-21` e `musica_firestore_data_source.dart:49-53` capturam e retornam/lançam uma `Failure` **sem** reportar ao Crashlytics — um erro verdadeiramente inesperado nesses três pontos fica invisível em produção (**ARQ-102**).

Há duplicação literal de UI de erro entre as duas telas de player (mesmo `Icon` + `Text` + `ElevatedButton` "Voltar", byte a byte) em vez de extraída para um widget compartilhado (**ARQ-103**, evidência: `player_music_premium_view.dart:233-255` vs. `play_music_free_view.dart:110-133`).

`GameView` mistura estilos de DI dentro do mesmo arquivo: recebe dependências via construtor, mas também chama `instance<PreviewPlaybackUseCase>()` diretamente contra o Service Locator dentro de um método (**ARQ-104**, `game_view.dart:5,118,128`).

Boilerplate de registro em `lib/app/di.dart` — mesmo após a extension idempotente (ver ponto forte abaixo) — ainda soma ~180 linhas para ~15 dependências, sem abstração de "módulo" (**ARQ-105**, informativo, não urgente).

Hierarquias de `Failure` têm granularidade assimétrica: `MusicaPlaybackFailure` distingue várias causas, `PreviewPlaybackFailure` só tem uma variante genérica (**ARQ-106**, nomenclatura/consistência menor).

**Pontos fortes:**
- **ARQ-S1** — Separação domain/data/presentation real e testada nos fluxos de Música/FAQ.
- **ARQ-S2** — Exceções tipadas por camada, sem `catch (e)` genérico espalhado.
- **ARQ-S3** — DI idempotente bem implementada: extension `_IdempotentRegistration` sobre `GetIt` (`registerLazySingletonIfAbsent`/`registerFactoryIfAbsent`/`unregisterIfRegistered`), documentada com o motivo real (`lib/app/di.dart:57-71`).
- **ARQ-S4** — Retry/backoff (`lib/data/network/retry.dart`) reaplicado de forma consistente em 3 pontos de I/O externo, com distinção correta transitório vs. definitivo.
- **ARQ-S5** — Arquivos grandes de UI (`player_music_premium_view.dart`, 552 linhas) têm suíte de teste proporcional (348 linhas) — tamanho não é débito não testado.
- **ARQ-S6** — Zero TODO/FIXME/HACK remanescente em `lib/`.

### 2.2 Segurança e Compliance — Nota: 7,5/10

Perímetro de dados pequeno por design: sem conta própria, sem PII em backend próprio. Firestore Rules com deny-by-default (`firestore.rules:18-26`) — única coleção legível é `musicas` (leitura pública, escrita sempre `false`), tudo o mais bloqueado (**SEC-S1**).

O fallback silencioso de assinatura de release apontado na v2.0 (**SEC-002** antigo) está genuinamente corrigido: `android/app/build.gradle.kts` agora falha explicitamente o build de release se `android/key.properties` não existir, em vez de cair para debug sem aviso (**SEC-S2**). O consentimento do Spotify continua verificado na camada de serviço, não contornável pulando UI (**SEC-S3**). CI com `gitleaks` e `osv-scanner` (workflow oficial) rodando de fato — confirmado nesta sessão via execução real do OSV-Scanner local: **133 pacotes escaneados, 0 vulnerabilidades conhecidas** (**SEC-S6**).

**Achado novo relevante:** `SPOTIFY_CLIENT_ID` esteve versionado em `.env` no histórico git (commits `0d5d678`, `95ab2b9`, removido em `9d66a14`) e esses commits são ancestrais de `HEAD` na branch atual — ou seja, ainda alcançável no histórico. Verificação nesta sessão (`GET https://api.github.com/repos/davicezarborgesdeveloper/Beatspan` → `404`) confirma que **o repositório é privado**, o que reduz o risco de exposição pública. Combinado com o fato de um `client_id` OAuth mobile (fluxo PKCE, sem `client_secret`) não ser, por design do protocolo, uma credencial que exija sigilo absoluto, a severidade real é **Média**, não Alta (**SEC-001**, ver detalhamento em `docs/2-SECURITY_REPORT.md`).

Não há mecanismo de revogação de consentimento do Spotify dentro do app — só é possível aceitar (`setSpotifyConsentAccepted(true)`), nunca resetar a flag local mesmo que o usuário revogue o acesso pelo lado do Spotify (**SEC-002**). `AndroidManifest.xml` não desabilita `allowBackup`, o que pode contradizer a promessa da política de privacidade de que preferências locais "não são transmitidas a nós nem a terceiros" (**SEC-003**). A tela `ContactView` é um placeholder vazio mas roteada — o único canal de contato real para exercício de direitos LGPD é o e-mail na política de privacidade (**SEC-004**, também referenciado em Experiência como EXP-004).

Ver `docs/2-SECURITY_REPORT.md` para detalhamento completo, severidades e checklist LGPD/GDPR.

### 2.3 Experiência — Nota: 5,5/10

**UX:** mensagens de erro específicas e acionáveis em português claro continuam sendo o ponto mais forte (`game_viewmodel.dart:98-167`) (**EXP-S1**). O padrão correto de acessibilidade já existe e está em uso em 8 arquivos (`Semantics(button: true, label: ..., excludeSemantics: true)`), servindo de referência replicável (**EXP-S2**). A migração de cores hardcoded (antigo **EXP-002**) está 100% concluída — zero ocorrências fora de `color_manager.dart` (**EXP-S3**). O ícone ausente em `game_error_view.dart` (corrigido em sessão anterior) está confirmado renderizado (**EXP-S4**).

**Acessibilidade continua sendo o problema central do eixo, com escopo maior do que documentado antes:** apenas 8 dos muitos arquivos de `lib/presentation/` têm `Semantics`, e `Tooltip` tem zero ocorrências em todo o app. Telas com botões interativos sem nenhum rótulo incluem `faqs_view.dart`, `rules_view.dart`, toda `settings/`, `home_view.dart` (os dois botões de ação primária da tela inicial), `game_error_view.dart` (o botão de fechar, apesar do ícone corrigido), `spotify_free_transition.dart` e, criticamente, `camera_permission_view.dart` — um fluxo **bloqueante** para jogar (**EXP-001**, crítico, escopo revisado).

O mecanismo raiz por trás disso: o botão "voltar" (círculo com ícone) está duplicado literalmente em pelo menos 5 arquivos em vez de componentizado — quando a acessibilidade foi corrigida em um lugar, não se propagou (**EXP-002**, atenção/DX).

**Achado crítico novo:** `lib/presentation/contact/contact_view.dart` é um `Container()` vazio com título hardcoded em inglês ("Contact", único texto em inglês num app que o próprio README declara ser pt-BR apenas), mas está roteado e navegável, e tanto `README.md` quanto `README.en.md` listam "contato" como funcionalidade de Settings entregue (**EXP-003**, crítico).

Outros achados de atenção: estado de erro do FAQ cai silenciosamente em um `Container()` vazio sem mensagem nem retry, quebrando a paridade com o padrão de recuperação de erro do fluxo de jogo (**EXP-004**); uso inconsistente dos tokens de design (`AppPadding`/`FontSize`) já existentes — 22+ ocorrências de valores mágicos idênticos aos tokens (**EXP-005**); o token central de cor de fundo tem um typo perpetuado (`bagroundColor`, usado em 17 arquivos) que atrapalha autocomplete/descoberta (**EXP-006**); nomenclatura em português (`Musica*`, 9+ arquivos) destoando do restante do código em inglês (**EXP-007**).

**DX:** onboarding via README (bilíngue, sincronizado, completo) continua acima da média para o porte do projeto (**EXP-S5**).

### 2.4 Operações e Confiabilidade — Nota: 7,5/10

**Testabilidade:** cobertura real subiu de 27,8% (medição defasada da v2.0) para **54,27% (1576/2904 linhas)**, medido nesta sessão via `flutter test --coverage` — quase o dobro, com o gate de CI (40%) confortavelmente abaixo do real. O fluxo crítico de negócio (scan→resolve→toca) está excepcionalmente coberto: `player_music_premium_view.dart` 97,7%, `play_music_free_view.dart` 98,5%, `game_error_view.dart` 100%, `scanner_overlay.dart` 98,7%, `game_viewmodel.dart` 87,0% (**OPS-S5**).

**Lacuna real identificada:** `SpotifyPlaybackControlRepositoryImpl` (play/pause/resume — o que o usuário toca durante a partida) não tem try/catch nem `reportNonFatalError` em nenhum dos 4 métodos, e está em apenas 33,3% de cobertura (só `saveTrack` é testado) (**OPS-001**). `PreviewPlaybackControlRepositoryImpl` (implementação real via `just_audio`) está em 0% de cobertura e também sem tratamento de erro em `load()` (**OPS-002**). O guard de conectividade (`network_info.dart`, `connectivity_guard.dart`) está em 0% (**OPS-003**).

Mais de 1000 linhas de telas de uso frequente (Settings, FAQ, Home, Splash, Rules, `routes_manager.dart`, `app/di.dart`) permanecem sem nenhum teste — não bloqueia o gate porque a média global é puxada pelo fluxo de jogo, mas significa ausência de rede de segurança de regressão nessas telas (**OPS-004**).

**Observabilidade:** o antigo débito de `debugPrint` solto (**OPS-003** da v2.0) está genuinamente corrigido — zero ocorrências confirmadas em `lib/`. Analytics de produto (antigo **OPS-004** da v2.0) foi implementado nesta sessão, instrumentando o funil completo (`qr_scanned`, `qr_invalid`, `musica_lookup_failed`, `playback_started`, `playback_failed`, `itunes_fallback_used`) com o mesmo padrão defensivo de `error_reporting.dart` (**OPS-S3**).

**CI/CD:** pipeline evoluiu desde a v2.0 — agora gateia cobertura (40%, publica `lcov.info` como artifact) além de gitleaks, Conventional Commits, analyze e format (**OPS-S4**). Segue sendo só gate de qualidade, sem geração de artefato de build/deploy (**OPS-005**, informativo, aceito para o estágio atual).

**Resiliência:** `retry.dart` continua ponto forte do projeto, 100% coberto, reaplicado nos 3 pontos de I/O externo com classificação correta de erro transitório/definitivo (**OPS-S1**).

### 2.5 Documentação e Governança — Nota: 7/10

README bilíngue sincronizado e atualizado com o código real (a nota sobre ARQ-001 já foi removida do texto porque o achado foi resolvido) (**DOC-S1**). Os 3 ADRs existentes (`docs/adr/`) são honestos sobre suas limitações metodológicas em vez de inventar contexto retroativo (**DOC-S2**), e documentam trade-offs negativos genuínos, não só benefícios (**DOC-S3**). Conventional Commits tem enforcement real no CI, não só documentação (**DOC-S4**).

**Achado estrutural:** os 5 documentos de análise (`docs/1` a `5`) ainda declaram cabeçalho `2026-09-10`/`8f2ae1e` mesmo após 3 commits que resolveram 15 itens — um leitor que confie só no cabeçalho concluiria erroneamente qual é o estado real documentado (**DOC-001**, corrigido nesta própria versão 3.0).

`CHANGELOG.md` documenta apenas 1 de ~15 mudanças relevantes ocorridas desde sua criação — risco de virar documento decorativo se o padrão não mudar (**DOC-002**). Nenhuma tag Git existe; `pubspec.yaml` está congelado em `1.0.0+1` desde o primeiro commit, sem nenhum critério documentado de quando isso deve mudar (**DOC-003**).

**Achado quantificado nesta sessão:** `flutter pub outdated` real mostra **18 dependências diretas desatualizadas, 8 com major version disponível** (`cloud_firestore` 5.6→6.9, `firebase_core` 3.15→4.14, `spotify_sdk` 3.0→4.0, entre outras), e uma dependência transitiva (`path_provider_foundation`) travada numa versão **retracted** (retirada do pub.dev) — sem política de cadência de atualização documentada em nenhum lugar (**DOC-004**). Nenhuma vulnerabilidade confirmada nessas versões (osv-scanner rodou limpo), então é débito de manutenibilidade, não de segurança confirmada.

Descrições de commit genéricas (`fix: apontamentos`, `fix:curto prazo`) persistem mesmo após a adoção formal de Conventional Commits, fora do escopo do que o README já reconhece e aceita para o histórico anterior (**DOC-005**). ADRs não cobrem pelo menos duas decisões de produto/governança relevantes já tomadas (idioma único pt-BR, gate de cobertura em 40%) — hoje registradas só como linhas de plano de ação (**DOC-006**).

### 2.6 Performance e Escalabilidade — Nota: 8/10

Busca de música no Firestore por chave de documento (O(1), sem necessidade de índice composto) confirmado coerente com `firestore.indexes.json` vazio (**PERF-S1**). `cached_network_image` corretamente usado para artes de álbum, único ponto de imagem remota do app (**PERF-S2**). Retry com backoff seletivo (**PERF-S3**) e rate-limit do Spotify tratado respeitando `Retry-After` com teto de espera (**PERF-S4**).

Nenhum problema crítico de performance identificado — sem query O(n) desnecessária, sem N+1, sem chamada bloqueante, sem widget pesado sem justificativa.

Os dois caches em memória sem TTL (`_cache`, `_previewCache`, antigo **PERF-001**) continuam sem TTL/limite — confirmado que vivem pela vida do processo (registrados como singleton em `di.dart`), não "por sessão de jogo" como o comentário do código sugere. O volume esperado ainda torna isso aceitável, mas a adição do `firebase_analytics` nesta sessão criou a oportunidade de fechar esse ciclo de "reavaliar com dado real" — hoje nenhum evento mede tamanho/hit-rate do cache, então a decisão de não agir continua sendo suposição informada, não conclusão medida (**PERF-001**, atenção, não crítico).

O token de acesso do Spotify é obtido via platform channel a cada resolução de prévia sem cache/verificação de expiração no lado Dart — não é possível confirmar estaticamente se o SDK nativo já cacheia internamente (**PERF-002**, atenção, baixo impacto dado o volume). `_GlyphRingsPainter` reconstrói geometria a cada frame com `shouldRepaint => true` incondicional — plausivelmente barato dado o tamanho da área (320×320) e a simplicidade da geometria, mas sem cache de `Path` (**PERF-003**, informativo/cosmético).

---

## 3. Tabela de pontuações

| Eixo | Nota | Justificativa |
|---|---|---|
| Fundamentos | 7,5/10 | Modelo de erro e DI corrigidos com soluções idiomáticas; resta acoplamento domain→infra e duplicação de UI |
| Segurança | 7,5/10 | Controles técnicos sólidos e verificados nesta sessão (0 CVEs); lacunas de ciclo de consentimento e um segredo de risco atenuado no histórico |
| Experiência | 5,5/10 | Acessibilidade ausente na maioria absoluta das telas, incluindo fluxo bloqueante; uma feature documentada como entregue está vazia em produção |
| Operações | 7,5/10 | Cobertura dobrou (54,3% real) com foco correto no caminho crítico; lacuna real na camada de controle de playback em tempo real |
| Documentação | 7/10 | Estrutura de governança acima da média, mas execução sustentada (CHANGELOG, versionamento, dependências) ainda não consolidada |
| Performance | 8/10 | Nenhum problema crítico; decisões de cache permanecem defensáveis mas sem dado real para fechar o ciclo de reavaliação |

**Escore geral: 7,2/10**

---

## 4. Pontos fortes, atenções e críticos

### Pontos fortes
| ID | Descrição | Evidência |
|---|---|---|
| ARQ-S1 | Clean Architecture consistente nos fluxos de Música/FAQ | `lib/domain/repository/`, `lib/data/repository/` |
| ARQ-S2 | Exceções tipadas por camada | `lib/domain/exceptions/` |
| ARQ-S3 | DI idempotente via extension própria | `lib/app/di.dart:57-71` |
| ARQ-S4 | Retry/backoff testado e reaplicado | `lib/data/network/retry.dart` |
| ARQ-S5 | Arquivos grandes de UI com teste proporcional | `test/presentation/game/player_music_premium_view_test.dart` |
| ARQ-S6 | Zero TODO/FIXME/HACK em `lib/` | busca textual |
| SEC-S1 | Firestore rules deny-by-default | `firestore.rules:18-26` |
| SEC-S2 | Build de release falha explicitamente sem keystore | `android/app/build.gradle.kts:24-33` |
| SEC-S3 | Consentimento Spotify aplicado no serviço | `lib/data/network/spotify_service.dart:21-25` |
| SEC-S6 | Supply chain limpo (verificado nesta sessão) | osv-scanner: 133 pacotes, 0 vulnerabilidades |
| EXP-S1 | Mensagens de erro específicas e acionáveis | `lib/presentation/game/game_viewmodel.dart:98-167` |
| EXP-S2 | Padrão correto de acessibilidade já existe e é replicável | `change_spotify_view.dart:76-99` |
| EXP-S3 | Migração de cores hardcoded 100% concluída | busca 0 ocorrências fora de `color_manager.dart` |
| EXP-S5 | Onboarding de dev bilíngue e sincronizado | `README.md`, `README.en.md` |
| OPS-S1 | Retry/backoff 100% coberto | `lib/data/network/retry.dart` |
| OPS-S3 | Analytics de produto cobrindo funil completo | `lib/domain/analytics_reporting.dart` |
| OPS-S4 | CI com gate de cobertura + gitleaks + osv-scan | `.github/workflows/ci.yml` |
| OPS-S5 | Cobertura do fluxo crítico de negócio >87% em todos os arquivos-chave | `coverage/lcov.info` (medido nesta sessão) |
| DOC-S1 | README sincronizado com código real | `README.md`, `README.en.md` |
| DOC-S2 | ADRs honestos sobre limitações metodológicas | `docs/adr/001,002,003` |
| DOC-S4 | Conventional Commits com enforcement real no CI | `.github/workflows/ci.yml:22-46` |
| PERF-S1 | Leitura Firestore O(1) por chave de documento | `lib/data/network/musica_firestore_data_source.dart:36-39` |
| PERF-S4 | Rate-limit do Spotify tratado com `Retry-After` | `lib/data/network/spotify_webapi.dart:116-146` |

### Atenções
| ID | Descrição | Evidência |
|---|---|---|
| ARQ-101 | `domain/` acopla a SDKs de infraestrutura (Crashlytics/Analytics/plugin Spotify) | `lib/domain/analytics_reporting.dart:1`, `error_reporting.dart:1` |
| ARQ-102 | Reporte de erro inesperado inconsistente entre repositórios | `musica_repository_impl.dart:35-36`, `faq_repository_impl.dart:20-21` |
| ARQ-103 | UI de erro duplicada entre telas de player | `player_music_premium_view.dart:233-255` vs `play_music_free_view.dart:110-133` |
| ARQ-104 | Estilo de DI misto dentro do mesmo arquivo | `lib/presentation/game/game_view.dart:5,118,128` |
| ARQ-105 | Boilerplate de registro ainda alto (informativo) | `lib/app/di.dart:73-133` |
| SEC-001 | `SPOTIFY_CLIENT_ID` no histórico git (repo confirmado privado, risco atenuado) | `git log --all --diff-filter=A -- .env` |
| SEC-002 | Sem revogação de consentimento Spotify no app | `lib/presentation/settings/settings_view.dart:61` |
| SEC-003 | `allowBackup` não desabilitado (contradiz promessa da política) | `android/app/src/main/AndroidManifest.xml` |
| SEC-004 | `ContactView` vazio, único canal LGPD real é e-mail externo | `lib/presentation/contact/contact_view.dart` |
| SEC-005 | 18 dependências desatualizadas, 1 transitiva retracted | `flutter pub outdated` (executado nesta sessão) |
| EXP-002 | Botão "voltar" duplicado sem componentização | 5+ arquivos, ver `docs/3-TECH_DEBT_REGISTER.md` |
| EXP-004 | Estado de erro do FAQ sem mensagem nem retry | `faqs_view.dart:89-99`, `empty_container.dart` |
| EXP-005 | Uso inconsistente de tokens de design já existentes | `home_view.dart:76,105` |
| EXP-006 | Typo `bagroundColor` propagado em 17 arquivos | `color_manager.dart:13` |
| EXP-007 | Nomenclatura português/inglês mista (`Musica*`) | `lib/domain/model/musica.dart` |
| OPS-001 | `SpotifyPlaybackControlRepositoryImpl` sem tratamento de erro/teste (33,3% cobertura) | `lib/data/repository/spotify_playback_control_repository_impl.dart` |
| OPS-002 | `PreviewPlaybackControlRepositoryImpl` (just_audio) em 0% de cobertura | mesmo arquivo |
| OPS-003 | Guard de conectividade sem teste | `network_info.dart`, `connectivity_guard.dart` |
| OPS-004 | >1000 linhas de telas frequentes sem nenhum teste | Settings, FAQ, Home, Splash, Rules |
| DOC-002 | CHANGELOG defasado (1 de ~15 mudanças documentadas) | `CHANGELOG.md` |
| DOC-003 | Sem tags Git, versão congelada desde o commit inicial | `git tag -l` vazio, `pubspec.yaml:5` |
| DOC-004 | Dependências desatualizadas sem política de cadência | `flutter pub outdated` |
| DOC-006 | ADRs não cobrem decisões de produto/governança relevantes já tomadas | idioma único, gate de cobertura 40% |
| PERF-001 | Caches em memória sem TTL/limite, sem telemetria para reavaliar | `musica_repository_impl.dart:18`, `musica_playback_repository_impl.dart:25` |
| PERF-002 | Token Spotify sem cache/expiração explícita no lado Dart | `spotify_service.dart:38-46` |

### Críticos
| ID | Descrição | Evidência |
|---|---|---|
| EXP-001 | Acessibilidade ausente na maioria absoluta das telas, incluindo fluxo bloqueante de permissão de câmera | busca em `lib/presentation` (8 de muitos arquivos têm `Semantics`) |
| EXP-003 | `ContactView` é placeholder vazio mas documentado como funcionalidade entregue no README | `lib/presentation/contact/contact_view.dart`, `README.md:15,50` |

---

## 5. Cobertura da análise — o que não foi investigado em profundidade

- **Visibilidade real do repositório GitHub**: inferida via `404` da API pública sem autenticação (indicativo de privado), não confirmada diretamente nas configurações do GitHub.
- **Restrição da API key do Firebase no Google Cloud Console**: não verificável a partir do repositório (mesma limitação da v2.0).
- **Dependências nativas Gradle/Android**: o `osv-scanner` rodado cobriu apenas o ecossistema Dart/pub via `pubspec.lock`, não plugins/dependências Java/Kotlin nativas.
- **Teste dinâmico (DAST) ou tráfego de rede real**: toda a análise de rede foi estática, por leitura de código.
- **FPS/latência real em device físico**: afirmações de custo de CPU em `_GlyphRingsPainter` (PERF-003) são estimativas qualitativas, não medições de profiling.
- **Conteúdo integral de `hosting/termos/index.html`**: não lido linha a linha nesta rodada (fora do escopo direto dos 6 eixos).
- **Uso real de PRs no GitHub**: histórico local mostra só 1 merge de PR — não foi possível confirmar via `gh` (não disponível neste ambiente) se o `PULL_REQUEST_TEMPLATE.md` é de fato preenchido na prática.
- **Build/configuração iOS**: não existe (`ios/` ausente) — não avaliado por não haver o que avaliar.
