# Registro de Débito Técnico — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.0

---

## Tabela de débitos

| ID | Descrição | Categoria | Severidade | Esforço | Impacto se não resolvido |
|---|---|---|---|---|---|
| OPS-001 | Ausência total de testes automatizados (unit/widget/integration) | Testes | Crítica | G | Regressões silenciosas a cada mudança; impossível refatorar com confiança |
| OPS-002 | Sem pipeline de CI/CD (`.github/workflows` inexistente) | Infra | Crítica | M | Bugs chegam a produção sem gate automatizado; nenhuma automação de build/lint |
| SEC-001 | `.env` com credencial versionada no Git, fora do `.gitignore` | Infra/Segurança | Alta | P | Credencial permanece exposta no histórico indefinidamente |
| OPS-003 | Zero observabilidade/crash reporting (sem Crashlytics/Sentry, sem logging estruturado) | Infra | Crítica | M | Falhas em produção são invisíveis; impossível diagnosticar bugs reportados por usuários |
| ARQ-003 | `GameView` chama serviços de rede (Spotify/iTunes) direto no widget, sem Repository/UseCase | Arquitetura | Alta | G | Lógica de negócio crítica não é testável isoladamente; mudanças de fluxo exigem editar UI |
| ARQ-001 | `domain` depende de `data` (`Failure` na camada errada) | Arquitetura | Alta | P | Inversão de dependência dificulta trocar a camada de dados sem tocar no domínio |
| ARQ-002 | `data` depende de `presentation` (`FaqRepositoryImpl` importa `assets_manager`) | Arquitetura | Alta | P | Mesma classe de problema — camadas acopladas na direção errada |
| ARQ-004 | Service locator (`instance<T>()`) chamado direto em 10+ widgets | Arquitetura | Alta | M | Impede injeção de mocks em testes; acoplamento oculto ao GetIt |
| OPS-004 | Chamadas HTTP sem timeout/retry (`spotify_webapi.dart`, `itunes_search_api.dart`) | Código | Alta | P | Requisição pode travar indefinidamente em rede instável, sem feedback ao usuário |
| UX-001 | Design system (`ColorManager`/`getBoldStyle` etc.) seguido em menos da metade das telas | Código | Alta | M | Inconsistência visual; mudanças de tema exigem editar N lugares em vez de 1 |
| UX-003 | Zero uso de `Semantics`/acessibilidade em todo o app | Código | Alta | M | App inacessível a usuários de leitor de tela; risco de não conformidade com diretrizes de loja |
| DOC-005 | 17 de 30 commits recentes com mensagem `...`/`..`, sem descrição | Docs | Alta | P (por commit) / M (retroativo) | `git blame`/`git log` inúteis para entender evolução do código |
| ARQ-008 / UX-002 | ~130 linhas de código morto comentado em `settings_view.dart` (48% do arquivo) | Código | Média | P | Ruído para novos devs; risco de reativar código obsoleto por engano |
| ARQ-006 | Dois padrões de tratamento de erro coexistindo (`Either<Failure,T>` vs exceptions cruas/`null`) | Arquitetura | Média | M | Curva de aprendizado maior para novos devs; inconsistência de UX de erro |
| ARQ-007 | `_nextCardButton()` duplicado entre `player_music_premium_view.dart` e `play_music_free_view.dart` | Código | Média | P | Correção de bug/estilo precisa ser replicada manualmente em 2 lugares |
| PERF-003 | Nenhum cache de respostas de rede (Spotify/iTunes) nem de imagens (`cached_network_image` ausente) | Performance | Média | M | Recargas de rede desnecessárias a cada scan repetido; consumo de dados do usuário |
| PERF-004 | Assets de imagem grandes sem otimização (até ~500KB cada) | Performance | Média | P | Tamanho de app maior; tempo de decodificação de imagem maior em runtime |
| SEC-009 | Ausência de política de privacidade/termos de uso reais | Compliance | Média | M | Risco de não conformidade LGPD e violação dos Spotify Developer Terms |
| SEC-010 | Dependências majors desatualizadas sem scanner de vulnerabilidades no fluxo | Infra | Média | M | CVEs futuras podem passar despercebidas; débito de migração acumula |
| DOC-001 | Documentação de planejamento (`docs/ESTADO-ATUAL.md`, `ROADMAP_CONCLUSAO.md`) desatualizada frente ao código | Docs | Alta | P | Novo dev pode tomar decisões baseado em informação obsoleta |
| DOC-002 / UX-007 | README referencia `docs/PROMPT_ANALISE_ARQUITETURAL.md`, arquivo ausente do repositório | Docs | Alta | P | Link quebrado na porta de entrada do projeto |
| DOC-003 | Sem ADRs — decisões arquiteturais relevantes não documentadas | Docs | Média | M (processo contínuo) | Decisões (por que `get_it`, por que Firestore) perdem contexto com o tempo |
| DOC-004 | Sem `CHANGELOG.md`, sem tags de release (`git tag` vazio) | Docs | Média | P (setup) / contínuo | Impossível saber o que mudou entre builds sem ler todo o diff |
| DOC-006 | Estratégia de branching pouco clara (4 branches de longa duração sem convenção) | Docs/Processo | Média | P | Confusão sobre qual branch é a fonte de verdade |
| UX-004 | Contraste em dark theme não verificado sistematicamente (sem lint de acessibilidade) | Código | Média | P | Risco de não conformidade WCAG AA não detectado antes de produção |
| UX-005 | Responsividade cobre só smartphone, sem breakpoints para tablet | Código | Média | M | Layout estica sem reflow em telas maiores |
| UX-006 | Tratamento de loading/erro desigual entre telas (`settings_view.dart` sem fallback) | Código | Média | P | Usuário sem feedback em falha silenciosa de `SharedPreferences`/conexão |
| OPS-005 | Crash logs de build tool (`hs_err_pid*.log`, `replay_pid*.log`) recorrentes no ambiente local | Infra | Baixa | P | Sintoma de `OutOfMemoryError` do Gradle — heap não configurado |
| ARQ-009 / SEC-002 | Spotify Client ID hardcoded em `di.dart`, duplicando `.env` não consumido | Código | Média | P | Nenhuma segregação de configuração por ambiente (dev/staging/prod) |
| ARQ-010 | Model `Musica.fromMap` retorna string vazia silenciosamente em campo ausente | Código | Baixa | P | Erros de dado incompleto no Firestore só aparecem depois, sem contexto |
| ARQ-012 | Nomenclatura de arquivo inconsistente (`game_viewmodel.dart` vs `*_view_model.dart`) | Código | Baixa | P | Ruído cognitivo mínimo, sem impacto funcional |
| DOC-007 | Sem política de atualização de dependências documentada, sem `CONTRIBUTING.md` | Docs | Baixa | P | Onboarding de contribuidor externo mais lento |
| PERF-005 | Uso de `const` inconsistente em widgets com valores literais | Performance | Baixa | P | Rebuilds marginalmente mais custosos; impacto real pequeno na escala atual |

**Esforço:** P = Pequeno (horas/1-2 dias) · M = Médio (alguns dias/1-2 semanas) · G = Grande (múltiplas semanas, envolve refatoração estrutural)

---

## Débitos críticos vs. aceitáveis

### Críticos — não devem ser aceitos além do lançamento inicial
- **OPS-001** (zero testes), **OPS-002** (zero CI/CD) e **OPS-003** (zero observabilidade) formam um bloco: sem eles, qualquer bug em produção é descoberto por reclamação de usuário, sem meio de reproduzir, sem gate para evitar regressão, e sem cobertura para refatorar com segurança. Este é o maior risco estrutural do projeto hoje.
- **SEC-001** (`.env` versionado) é crítico por ser trivial de corrigir (esforço P) e ficar mais caro de corrigir quanto mais tempo passa (histórico cresce, mais devs clonam o repo).
- **ARQ-003** (lógica de negócio no widget) é crítico não pelo risco imediato, mas porque é o padrão que qualquer feature nova tende a copiar — quanto mais tempo passa, mais telas replicam o antipattern.

### Aceitáveis a curto prazo (com justificativa)
- **PERF-005** (const inconsistente) e **ARQ-012** (nomenclatura de arquivo) — impacto real muito baixo na escala atual do app (poucas telas, sem sinal de jank reportado). Aceitável adiar até haver um ciclo de "polish" dedicado.
- **DOC-007** (sem `CONTRIBUTING.md`) — aceitável enquanto o time for pequeno/único mantenedor; torna-se relevante ao primeiro contribuidor externo.
- **ARQ-010** (model anêmico) — o comportamento atual (string vazia → erro tratado na camada de dados) já produz um erro amigável ao usuário; o débito é de robustez de design, não de bug ativo.

---

## Recomendação de priorização

1. **Bloco de confiabilidade mínima** (OPS-001 + OPS-002 + OPS-003) antes de qualquer lançamento público — sem isso, não há como saber se o app está funcionando em produção.
2. **SEC-001** — correção isolada e barata (esforço P), deve ser feita imediatamente e em paralelo a qualquer outra frente.
3. **ARQ-003 + ARQ-004** — refatorar o fluxo de reprodução de música para Repository/UseCase antes de adicionar novas features ao `GameView`, para não acumular mais dívida sobre a mesma base.
4. Débitos de Documentação (DOC-001, DOC-002, DOC-005) podem ser tratados em paralelo por serem baratos e não bloquearem outras frentes.
5. Débitos de Performance/UX (PERF-003, PERF-004, UX-003, UX-005) podem esperar um ciclo dedicado pós-lançamento, priorizados por feedback real de usuário.

Ver sequenciamento detalhado por prazo em [ACTION_PLAN.md](ACTION_PLAN.md).
