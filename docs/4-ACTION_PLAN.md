# Beatspan — Action Plan

**Data da análise:** 2026-09-11
**Versão do documento:** 3.0 (reanálise completa do zero, substitui a versão 2.0)
**Commit analisado:** `577dd0c` (branch `beatspan_v2`)

Esforço/impacto de cada item seguem a definição já registrada em `docs/1-ARCHITECTURAL_REVIEW.md`/`docs/3-TECH_DEBT_REGISTER.md` — não redefinidos aqui.

> Nota: esta é uma reanálise completa do zero (não incremental) — os IDs correspondem aos definidos nos documentos 1-3 desta mesma versão 3.0. A versão 2.0 deste plano documentava um histórico extenso de itens resolvidos (ver seu conteúdo no controle de versão do Git, commit anterior a `577dd0c`, se precisar consultar); vários desses itens foram confirmados como ainda resolvidos nesta reanálise e não são recriados aqui.

---

## Críticos (imediato — sprint atual)

- [ ] **Implementar a `ContactView` de fato, ou remover a rota/menção até que exista** — ID de origem: `EXP-003`/`SEC-004` — Responsável sugerido: mobile/frontend — Esforço: P — Impacto: Crítico — Eixo: Experiência/Segurança — Critério de aceite: a tela roteada em `Routes.contactRoute` exibe conteúdo real (ao menos um canal de contato funcional, ex. e-mail/WhatsApp linkado), ou a rota e as menções em `README.md`/`README.en.md` são removidas até a implementação existir.
- [ ] **Adicionar `Semantics` ao fluxo bloqueante de permissão de câmera** — ID de origem: `EXP-001` (recorte prioritário) — Responsável sugerido: mobile/frontend — Esforço: M — Impacto: Crítico — Eixo: Experiência — Critério de aceite: `lib/presentation/camera_permission/camera_permission_view.dart` tem `Semantics`/rótulo adequado nos botões de ação; testado com `androidTapTargetGuideline`/`labeledTapTargetGuideline` (padrão já usado em `test/presentation/accessibility_test.dart`) ou TalkBack manual.

## Curto prazo (≤4 semanas)

- [ ] **Expandir `Semantics` para as telas restantes identificadas** — ID de origem: `EXP-001` (continuação) — Esforço: G — Impacto: Alto — Eixo: Experiência — Escopo: `faqs_view.dart`, `rules_view.dart`, `settings/` (5 widgets), `home_view.dart`, `game_error_view.dart` (botão de fechar), `spotify_free_transition.dart`.
- [ ] **Componentizar o botão "voltar" duplicado** — ID de origem: `EXP-002` — Esforço: M — Impacto: Médio — Eixo: Experiência/Fundamentos — Critério de aceite: um único widget (`BackButtonCircle` ou similar) em `lib/presentation/share/widgets/` substitui a implementação duplicada em `faqs_view.dart`, `rules_view.dart`, `change_spotify_view.dart`, `spotify_free_transition.dart`, `camera_permission_view.dart`, já incluindo `Semantics` — resolve estruturalmente parte do `EXP-001`.
- [ ] **Adicionar tratamento de erro e testes a `SpotifyPlaybackControlRepositoryImpl`** — ID de origem: `OPS-001` — Esforço: M — Impacto: Alto — Eixo: Operações — Critério de aceite: `playFullTrack`/`subscribePlayerState`/`pause`/`resume` capturam exceções relevantes e chamam `reportNonFatalError`; cobertura do arquivo sai de 33,3% para >80%.
- [ ] **Adicionar tratamento de erro e testes a `PreviewPlaybackControlRepositoryImpl`** — ID de origem: `OPS-002` — Esforço: M — Impacto: Alto — Eixo: Operações — Critério de aceite: `load()` trata exceções do `just_audio` com `reportNonFatalError`; cobertura sai de 0%.
- [ ] **Adicionar ação de "Desconectar Spotify" em Configurações** — ID de origem: `SEC-002` — Esforço: P — Impacto: Médio — Eixo: Segurança — Critério de aceite: botão em `settings_view.dart` chama `setSpotifyConsentAccepted(false)` + `SpotifyService.disconnect()`; próxima tentativa de tocar música pede consentimento novamente.
- [ ] **Desabilitar `allowBackup` ou definir `dataExtractionRules` explícitas** — ID de origem: `SEC-003` — Esforço: P — Impacto: Médio — Eixo: Segurança — Critério de aceite: `AndroidManifest.xml` declara `android:allowBackup="false"` (ou regras de extração equivalentes), alinhando comportamento real à política de privacidade.
- [ ] **Resolver a dependência transitiva retracted (`path_provider_foundation`)** — ID de origem: `SEC-005` — Esforço: P — Impacto: Médio — Eixo: Segurança/Infra — Critério de aceite: `flutter pub outdated` não lista mais nenhuma versão `(retracted)`; `flutter test`/`flutter analyze` seguem verdes.
- [ ] **Reportar erro inesperado de forma consistente em todos os repositórios** — ID de origem: `ARQ-102` — Esforço: P — Impacto: Médio — Eixo: Fundamentos/Operações — Critério de aceite: `musica_repository_impl.dart`, `faq_repository_impl.dart` e `musica_firestore_data_source.dart` chamam `reportNonFatalError` no catch genérico, mesmo padrão já usado em `musica_playback_repository_impl.dart`.

## Médio prazo (1–3 meses)

- [ ] **Adicionar teste ao guard de conectividade** — ID de origem: `OPS-003` — Esforço: P — Impacto: Médio — Eixo: Operações.
- [ ] **Expandir cobertura de testes para Settings, FAQ, Home, Splash, Rules** — ID de origem: `OPS-004` — Esforço: G — Impacto: Médio — Eixo: Operações — Nota: mais de 1000 linhas hoje sem nenhum teste; priorizar Settings (mais interativo) antes de Splash (menos lógica).
- [ ] **Extrair widget compartilhado de UI de erro do player** — ID de origem: `ARQ-103` — Esforço: P — Impacto: Baixo — Eixo: Fundamentos.
- [ ] **Corrigir o estado de erro do FAQ para mostrar mensagem e retry** — ID de origem: `EXP-004` — Esforço: P — Impacto: Médio — Eixo: Experiência — Critério de aceite: `EmptyContainer` é substituído por um componente com mensagem e ação de retry no branch `error` de `faqs_view.dart`, com paridade ao padrão já usado em `game_error_view.dart`.
- [ ] **Aplicar os tokens de design (`AppPadding`/`FontSize`) de forma consistente** — ID de origem: `EXP-005` — Esforço: M — Impacto: Baixo — Eixo: Experiência.
- [ ] **Instrumentar telemetria de cache (hit/miss, tamanho) antes de decidir sobre TTL** — ID de origem: `PERF-001` — Esforço: P — Impacto: Baixo — Eixo: Performance — Critério de aceite: evento de analytics (ou log estruturado) reporta tamanho de `_cache`/`_previewCache` periodicamente ou em eventos-chave, fechando o ciclo de "reavaliar com dado real" mencionado desde a análise anterior.
- [ ] **Publicar cobertura de forma visível no PR (badge ou comentário automático)** — ID de origem: `OPS-005` — Esforço: P — Impacto: Baixo — Eixo: Operações.
- [ ] **Atualizar `CHANGELOG.md` retroativamente para o período não coberto** — ID de origem: `DOC-002` — Esforço: P — Impacto: Baixo — Eixo: Documentação — Critério de aceite: entradas em `[Changed]`/`[Fixed]`/`[Removed]` cobrindo pelo menos as mudanças de maior impacto visível ao usuário desde a criação do arquivo (remoção de idioma/país, correção do ícone de `game_error_view`, etc.).
- [ ] **Corrigir o typo `bagroundColor` → `backgroundColor` (rename amplo)** — ID de origem: `EXP-006` — Esforço: M — Impacto: Baixo — Eixo: Experiência/Fundamentos — Nota: 17 arquivos afetados; usar rename via IDE/`dart fix` para evitar erro manual.

## Longo prazo (3–12 meses)

- [ ] **Reduzir acoplamento de `domain/` a SDKs de infraestrutura** — ID de origem: `ARQ-101` — Esforço: G — Impacto: Baixo — Eixo: Fundamentos — Nota: decisão pragmática atual é defensável; só vale revisitar se o custo de troca de fornecedor (Crashlytics/Analytics) ou de testabilidade se tornar um problema real.
- [ ] **Consolidar estilo único de DI em `GameView`** — ID de origem: `ARQ-104` — Esforço: P — Impacto: Baixo — Eixo: Fundamentos.
- [ ] **Introduzir tags Git e alinhar `pubspec.yaml` à primeira release real** — ID de origem: `DOC-003` — Esforço: P — Impacto: Baixo — Eixo: Documentação — Nota: decisão do time no momento da primeira release pública, não antecipar sem uma release de fato.
- [ ] **Documentar política de cadência de atualização de dependências** — ID de origem: `DOC-004` — Esforço: P — Impacto: Baixo — Eixo: Documentação.
- [ ] **Avaliar upgrade das 8 dependências com major version disponível** — ID de origem: `SEC-005` (continuação) — Esforço: G — Impacto: Médio — Eixo: Segurança/Infra — Nota: branch dedicada, regressão completa de testes; nenhuma tem CVE confirmado, então não é urgente.
- [ ] **Registrar ADRs para as decisões de produto/governança já tomadas** — ID de origem: `DOC-006` — Esforço: P — Impacto: Baixo — Eixo: Documentação — Escopo: decisão de idioma único (pt-BR) e racional do gate de cobertura de 40%.
- [ ] **Uniformizar nomenclatura `Musica*` → inglês, ou documentar a exceção deliberadamente** — ID de origem: `EXP-007` — Esforço: G — Impacto: Baixo — Eixo: Experiência/Fundamentos — Nota: rename amplo (9+ arquivos); alternativa de esforço menor é documentar a decisão em ADR em vez de renomear.
- [ ] **Avaliar Firebase App Check para a coleção `musicas`** — ID de origem: `SEC-006` — Esforço: M — Impacto: Baixo — Eixo: Segurança — Nota: só se o catálogo completo passar a ser considerado informação de negócio sensível.
- [ ] **Reduzir boilerplate de `di.dart` com abstração de módulo** — ID de origem: `ARQ-105` — Esforço: M — Impacto: Baixo — Eixo: Fundamentos.
- [ ] **Cachear token de acesso do Spotify explicitamente no lado Dart** — ID de origem: `PERF-002` — Esforço: P — Impacto: Baixo — Eixo: Performance.
