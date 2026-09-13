# Beatspan — Registro de Débito Técnico
**Projeto:** Beatspan
**Data da análise:** 2026-09-12
**Versão do documento:** 3.0
**Fonte primária de IDs:** `docs/ARCHITECTURAL_REVIEW.md`

---

## Catálogo de Débitos

| ID | Descrição | Categoria | Severidade | Esforço | Impacto se Não Resolvido |
|----|-----------|-----------|-----------|---------|--------------------------|
| DEBT-001 | Nenhuma lógica de jogo implementada | Arquitetura / Produto | Alto | G | App não pode ser lançado como produto completo |
| DEBT-002 | Build iOS não configurado | Infra | Médio | M | App limitado a Android; metade do mercado mobile excluído |
| SEC-002 | `.env` com credenciais Spotify no APK — **Resolvido em 2026-09-12** | Segurança | Alto | P | Credenciais extraíveis de qualquer APK baixado |
| SEC-003 | `path_provider_foundation` 2.5.0 retracted | Infra | Médio | P | Comportamento indefinido no iOS; bug potencial não diagnosticado |
| DEBT-005 | 7 dependências diretas com major break pendente | Infra | Médio | M | Acúmulo de breaking changes torna upgrades futuros exponencialmente mais custosos |
| ARQ-001 | `GameView` resolve `PreviewPlaybackUseCase` via `instance<>()` | Código | Médio | P | Violação de Clean Architecture; dificulta mock em testes de widget |
| DOC-001 | ADRs ausentes do disco | Docs | Médio | P | Decisões arquiteturais sem rastreamento; novos contribuidores repetem discussões já feitas |
| OPS-001 | Gate de cobertura 40% conservador | Testes | Médio | P | Falsa sensação de segurança; regressões em módulos novos passam despercebidas |
| OPS-002 | Sem CD — release totalmente manual | Infra | Médio | M | Erros humanos no processo de release; velocidade de entrega limitada |
| ARQ-004 | `GameViewModel.dispose()` não cancela async | Código | Baixo | P | Flutter debug error se widget desmontado durante busca; corrigível com `Completer`/flag |
| ARQ-005 | `MyApp` broken singleton + mutable StatefulWidget | Código | Baixo | P | Código morto enganoso; suppress de lint `must_be_immutable` |
| DEBT-003 | `faq_local_data_source.dart` com 0% cobertura | Testes | Baixo | P | Regressão silenciosa em carregamento do FAQ |
| DOC-002 | Sem CHANGELOG / versionamento semântico | Docs | Baixo | P | Rastreamento de releases impossível para stakeholders |
| EXP-001 | Botão fechar player sem `Semantics` | Código | Baixo | P | Falha de acessibilidade (TalkBack não anuncia ação) |
| ARQ-002 | `ColorManager` com `static Color` mutáveis | Código | Baixo | P | Substituição acidental em runtime possível |
| ARQ-003 | Cache sem limite de tamanho em memória | Código | Baixo | P | Crescimento ilimitado em sessões muito longas (improvável mas sem garantia) |
| SEC-001 | Firebase API key no VCS | Segurança | Baixo | P | Reconhecimento automatizado por scanners; baixo risco real com Security Rules corretas |
| SEC-004 | QR sem validação de tamanho antes do Firestore | Código | Baixo | P | Request desnecessário ao Firestore com input arbitrário |
| PERF-001 | Splash de duração fixa sem correlação com boot | Código | Baixo | P | UX degradada se boot for mais rápido que a animação |
| EXP-002 | Typo `bagroundColor` em `ColorManager` | Código | Mínimo | P | Confusão de nomenclatura; sem impacto funcional |
| DEBT-004 | `pubspec.yaml` description padrão | Docs | Mínimo | P | Sem impacto funcional; má impressão em contributors |

**Legenda de Esforço:** P = Pequeno (< 2h), M = Médio (2h–2d), G = Grande (> 2d)

---

## Débitos Críticos (Requerem Ação Antes do Lançamento)

### DEBT-001 — Lógica de Jogo Ausente
O app resolve QR codes e reproduz músicas corretamente, mas não implementa nenhuma mecânica de jogo (rodadas, pontuação, linha do tempo, multiplayer). O produto não pode ser lançado como jogo sem essa camada.

**Justificativa para aceitar temporariamente:** MVP de validação técnica. Prazo deve ser estabelecido antes do lançamento.

### SEC-002 — `.env` Embutido no APK
**Resolvido em 2026-09-12.** `.env` removido dos assets; credenciais migradas para `--dart-define-from-file=env.json`; Client ID Spotify revogado e substituído por um novo no dashboard.

---

## Débitos Aceitáveis com Justificativa

| ID | Justificativa para Aceitar Agora |
|----|----------------------------------|
| DEBT-002 | App declarado Android-only. iOS pode aguardar demanda de mercado comprovada. |
| ARQ-003 | Catálogo pequeno (<1000 cartas esperadas); risco real de OOM é negligenciável. |
| PERF-001 | UX issue menor; usuário só vê o splash na abertura do app. |
| EXP-003 | App exclusivo para mercado pt-BR no MVP. Internacionalização pode aguardar. |

---

## Recomendação de Priorização

**Sprint atual (bloqueante):** SEC-003 (SEC-002 resolvido em 2026-09-12)

**Próximas 2 sprints:** ARQ-001, DOC-001, OPS-001, DEBT-005 (iniciar pelo bloco Firebase)

**Trimestre:** DEBT-002 (iOS), OPS-002 (CD), ARQ-004, ARQ-005, DEBT-003

**Backlog:** Todos os restantes (Baixo/Mínimo)
