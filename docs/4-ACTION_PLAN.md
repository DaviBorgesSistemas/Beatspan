# Plano de Ação — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.3 (OPS-003 concluído)

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
  - *19 testes cobrindo os 3 componentes citados (exceto `AppPreferences`, ainda sem cobertura).*
- [x] **Integrar Firebase Crashlytics (ou Sentry) para captura de exceções não tratadas** `[OPS-003]` — Responsável: Mobile — Critério: crash simulado em build de teste aparece no dashboard da ferramenta escolhida
  - *Código integrado: `firebase_crashlytics` + `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` em `main.dart`, coleta desabilitada em debug. Validado com build debug e release (R8/proguard ok). Pendente (fora do código): habilitar Crashlytics no Firebase Console e simular um crash para confirmar que aparece no dashboard — critério de aceite completo depende dessa etapa manual.*
- [ ] **Extrair a lógica de decisão Spotify/iTunes de `GameView` para um `MusicaPlaybackUseCase`/`Repository` dedicado** `[ARQ-003]` — Responsável: Mobile — Critério: `GameView` não instancia `SpotifyWebApi`/`ItunesSearchApi` diretamente; lógica coberta por teste unitário

---

## Curto prazo (≤4 semanas)

- [x] Adicionar `.timeout(...)` + tratamento de erro tipado em todas as chamadas HTTP (`spotify_webapi.dart`, `itunes_search_api.dart`) `[OPS-004 / PERF-001]` — Esforço: P — Impacto: Alto — Eixo: Operações
- [ ] Publicar página real de Política de Privacidade e Termos de Uso, substituindo os links placeholder do hosting `[SEC-009]` — Esforço: M — Impacto: Alto — Eixo: Segurança/Compliance
- [ ] Adicionar tela de consentimento explícito antes da autorização OAuth do Spotify `[SEC-009]` — Esforço: M — Impacto: Médio — Eixo: Segurança/Compliance
- [ ] Mover `instance<T>()` para injeção via construtor nos 10+ pontos identificados, começando pelos ViewModels `[ARQ-004]` — Esforço: M — Impacto: Alto — Eixo: Fundamentos
- [x] Remover código morto comentado de `settings_view.dart` e `play_music_free_view.dart` `[ARQ-008 / UX-002]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos/Experiência
- [ ] Extrair `_nextCardButton()` duplicado para um widget compartilhado `[ARQ-007]` — Esforço: P — Impacto: Baixo — Eixo: Fundamentos
- [x] Corrigir referência quebrada no README e sincronizar documentação com o estado real do código `[DOC-001 / DOC-002]` — Esforço: P — Impacto: Médio — Eixo: Documentação
- [x] Adotar convenção de commit (Conventional Commits) e aplicar a partir de agora `[DOC-005]` — Esforço: P (processo contínuo) — Impacto: Médio — Eixo: Documentação
- [ ] Rodar scanner de dependências (OSV-Scanner ou Snyk) e priorizar upgrades críticos (`firebase_core`, `cloud_firestore`, `spotify_sdk`) `[SEC-010]` — Esforço: M — Impacto: Médio — Eixo: Segurança
- [x] Corrigir `Failure` para não viver em `data` (mover para `domain`) `[ARQ-001]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos
- [x] Corrigir `FaqRepositoryImpl` para não depender de `presentation/assets_manager` `[ARQ-002]` — Esforço: P — Impacto: Médio — Eixo: Fundamentos

---

## Médio prazo (1–3 meses)

- [ ] Expandir cobertura de testes para repositórios, use cases e ao menos os widgets críticos (`GameView`, `PlayerMusicPremiumView`) `[OPS-001]` — Esforço: G — Impacto: Alto — Eixo: Operações
- [ ] Adicionar cache local (memória e/ou disco) para respostas de Spotify/iTunes e `cached_network_image` para capas de álbum `[PERF-003]` — Esforço: M — Impacto: Médio — Eixo: Performance
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

**Progresso atual (críticos):** 5 de 6 concluídos (SEC-001 parcial, SEC-002/ARQ-009, OPS-002, OPS-001, OPS-003 — código pronto, falta habilitar no Console). Falta: ARQ-003.
