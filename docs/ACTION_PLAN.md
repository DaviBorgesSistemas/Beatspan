# Plano de Ação — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.0

> Todos os itens referenciam o ID de origem definido em [ARCHITECTURAL_REVIEW.md](ARCHITECTURAL_REVIEW.md), [SECURITY_REPORT.md](SECURITY_REPORT.md) ou [TECH_DEBT_REGISTER.md](TECH_DEBT_REGISTER.md). Esforço e impacto não são redefinidos aqui — seguem o que já está registrado nos arquivos de origem.

---

## Críticos (imediato — sprint atual)

| Tarefa | ID de origem | Responsável sugerido | Critério de aceite |
|---|---|---|---|
| Remover `.env` do controle de versão, adicionar ao `.gitignore`, rotacionar credencial | SEC-001 | DevOps/Backend | `.env` não aparece em `git ls-files`; `.gitignore` contém a entrada; novo Client ID gerado no Spotify Dashboard e aplicado |
| Configurar `flutter_dotenv` (ou `--dart-define`) para consumir credenciais de config, removendo o hardcode em `di.dart` | SEC-002 / ARQ-009 | Mobile | `di.dart` não contém string literal de Client ID; build funciona lendo de variável de ambiente/config por flavor |
| Criar pipeline de CI mínimo: `flutter analyze` + `flutter test` (mesmo vazio) em cada PR | OPS-002 | DevOps | `.github/workflows/ci.yml` existe; PR é bloqueado se `flutter analyze` falhar |
| Escrever a primeira leva de testes unitários para lógica pura: `GameViewModel.validate/extractCodigo`, `MusicaRepositoryImpl`, `AppPreferences` | OPS-001 | Mobile | Pasta `test/` criada; cobertura mínima dos 3 componentes citados; testes rodam em CI |
| Integrar Firebase Crashlytics (ou Sentry) para captura de exceções não tratadas | OPS-003 | Mobile | Crash simulado em build de teste aparece no dashboard da ferramenta escolhida |
| Extrair a lógica de decisão Spotify/iTunes de `GameView` para um `MusicaPlaybackUseCase`/`Repository` dedicado | ARQ-003 | Mobile | `GameView` não instancia `SpotifyWebApi`/`ItunesSearchApi` diretamente; lógica coberta por teste unitário |

---

## Curto prazo (≤4 semanas)

| Tarefa | ID de origem | Esforço | Impacto | Eixo |
|---|---|---|---|---|
| Adicionar `.timeout(...)` + tratamento de erro tipado em todas as chamadas HTTP (`spotify_webapi.dart`, `itunes_search_api.dart`) | OPS-004 / PERF-001 | P | Alto | Operações |
| Publicar página real de Política de Privacidade e Termos de Uso, substituindo os links placeholder do hosting | SEC-009 | M | Alto | Segurança/Compliance |
| Adicionar tela de consentimento explícito antes da autorização OAuth do Spotify | SEC-009 | M | Médio | Segurança/Compliance |
| Mover `instance<T>()` para injeção via construtor nos 10+ pontos identificados, começando pelos ViewModels | ARQ-004 | M | Alto | Fundamentos |
| Remover código morto comentado de `settings_view.dart` e `play_music_free_view.dart` | ARQ-008 / UX-002 | P | Médio | Fundamentos/Experiência |
| Extrair `_nextCardButton()` duplicado para um widget compartilhado | ARQ-007 | P | Baixo | Fundamentos |
| Corrigir referência quebrada no README e sincronizar `docs/ESTADO-ATUAL.md`/`ROADMAP_CONCLUSAO.md` com o estado real do código | DOC-001 / DOC-002 | P | Médio | Documentação |
| Adotar convenção de commit (Conventional Commits) e aplicar a partir de agora | DOC-005 | P (processo contínuo) | Médio | Documentação |
| Rodar scanner de dependências (OSV-Scanner ou Snyk) e priorizar upgrades críticos (`firebase_core`, `cloud_firestore`, `spotify_sdk`) | SEC-010 | M | Médio | Segurança |
| Corrigir `Failure` para não viver em `data` (mover para `domain` ou camada neutra) | ARQ-001 | P | Médio | Fundamentos |
| Corrigir `FaqRepositoryImpl` para não depender de `presentation/assets_manager` | ARQ-002 | P | Médio | Fundamentos |

---

## Médio prazo (1–3 meses)

| Tarefa | ID de origem | Esforço | Impacto | Eixo |
|---|---|---|---|---|
| Expandir cobertura de testes para repositórios, use cases e ao menos os widgets críticos (`GameView`, `PlayerMusicPremiumView`) | OPS-001 | G | Alto | Operações |
| Adicionar cache local (memória e/ou disco) para respostas de Spotify/iTunes e `cached_network_image` para capas de álbum | PERF-003 | M | Médio | Performance |
| Otimizar assets de imagem (compressão, WebP, variantes de densidade) | PERF-004 | M | Médio | Performance |
| Adicionar `Semantics`/labels de acessibilidade nas telas principais (scanner, player, settings) | UX-003 | M | Alto | Experiência |
| Introduzir lint/checklist de contraste WCAG AA para o dark theme | UX-004 | P | Médio | Experiência |
| Padronizar 100% das telas para usar `ColorManager`/`getBoldStyle`/`AppPadding` em vez de valores soltos | UX-001 | M | Médio | Experiência |
| Adicionar tratamento de loading/erro em `settings_view.dart` (`_loadPlanType`, `_connectSpotify`) | UX-006 | P | Médio | Experiência |
| Criar `CHANGELOG.md` e adotar tags de release seguindo semver a partir da próxima versão | DOC-004 | P (setup) | Médio | Documentação |
| Documentar estratégia de branching e consolidar as 4 branches de longa duração | DOC-006 | M | Médio | Documentação |
| Registrar as primeiras 3-5 ADRs retroativas para decisões já tomadas (Clean Architecture parcial, `get_it`, Firestore) | DOC-003 | M | Baixo | Documentação |

---

## Longo prazo (3–12 meses)

| Tarefa | ID de origem | Esforço | Impacto | Eixo |
|---|---|---|---|---|
| Unificar o tratamento de erro do app inteiro sob `Either<Failure, T>` (incluindo o fluxo Spotify/iTunes) | ARQ-006 | G | Médio | Fundamentos |
| Avaliar migração de gerenciamento de estado local (`setState`) para uma solução reativa (Provider/Riverpod/Bloc) se a árvore de widgets continuar crescendo | PERF-008 | G | Médio | Performance |
| Implementar suporte a tablet com breakpoints reais (`LayoutBuilder`) | UX-005 | G | Baixo–Médio | Experiência |
| Configurar Android/iOS de forma completa (iOS ainda não configurado) e publicar nas lojas | — (pré-requisito de negócio) | G | Alto | — |
| Avaliar Firebase App Check para proteger a leitura pública da coleção `musicas` contra scraping em massa | SEC-004 (sugestão) | M | Baixo | Segurança |
| Estabelecer política formal de atualização de dependências (Dependabot/Renovate) | DOC-007 / SEC-010 | P (setup) | Médio | Documentação/Segurança |

---

## Observação sobre sequenciamento

O bloco Crítico é intencionalmente pequeno e sequencial: **SEC-001 → SEC-002 → OPS-002 → OPS-001 → OPS-003 → ARQ-003**. A ordem importa — corrigir a credencial primeiro evita que o trabalho de CI/testes rode sobre uma base ainda vazando segredo; ter CI antes de escrever testes garante que os testes já nasçam rodando automaticamente; e observabilidade antes da refatoração de `ARQ-003` permite medir o impacto real da mudança em produção.
