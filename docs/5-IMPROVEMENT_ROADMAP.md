# Roadmap de Melhoria — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.0

> Agrupa as iniciativas já definidas em [ACTION_PLAN.md](ACTION_PLAN.md) por fase. Nenhuma iniciativa nova é criada aqui — apenas reorganizada por horizonte de tempo e agrupada por objetivo comum. Como o projeto ainda não tem release pública, as fases usam nomenclatura por marco de maturidade (Fase 1–4) em vez de trimestre calendário.

---

## ⚡ Quick wins (alto impacto, baixo esforço)

Iniciativas que devem ser priorizadas independentemente da fase, por relação custo/benefício:

| Iniciativa | ID(s) relacionado(s) | Esforço | Impacto |
|---|---|---|---|
| Remover `.env` do Git e rotacionar credencial | SEC-001 | P | Alto |
| Adicionar `.timeout(...)` nas chamadas HTTP existentes | OPS-004 / PERF-001 | P | Alto |
| Remover código morto comentado (`settings_view.dart`, `play_music_free_view.dart`) | ARQ-008 / UX-002 | P | Médio |
| Corrigir link quebrado no README e sincronizar docs de planejamento | DOC-001 / DOC-002 | P | Médio |
| Mover `Failure` para fora de `data`, corrigir import invertido em `FaqRepositoryImpl` | ARQ-001 / ARQ-002 | P | Médio |
| Adotar Conventional Commits a partir de agora (sem custo de setup, só disciplina) | DOC-005 | P | Médio |

---

## Fase 1 — Fundação de confiabilidade

**Objetivo:** garantir que o app tenha o mínimo de rede de segurança antes de qualquer lançamento público — sem isso, todo o resto do roadmap é construído sobre uma base sem visibilidade de falhas.

**Eixo arquitetural:** Operações e Confiabilidade, Segurança

**Iniciativas:**
- Pipeline de CI mínimo (`flutter analyze` + `flutter test`) — `OPS-002`
- Primeira leva de testes unitários (lógica pura: parsing de QR, repositórios) — `OPS-001`
- Integração de Crashlytics/Sentry — `OPS-003`
- Remoção da credencial versionada + config por ambiente — `SEC-001`, `SEC-002`/`ARQ-009`
- Extração da lógica Spotify/iTunes de `GameView` para Repository/UseCase — `ARQ-003`

**Dependências entre iniciativas:** `SEC-001` deve ser concluído antes de qualquer outra iniciativa que toque `di.dart` (evita retrabalho); `OPS-002` (CI) deve existir antes de `OPS-001` (testes) ganhar valor total, já que testes sem CI não protegem contra regressão automaticamente; `OPS-003` (observabilidade) idealmente entra antes de `ARQ-003` para medir o impacto real da refatoração em produção.

**Métrica de sucesso:** PR não pode ser mergeado sem `flutter analyze` limpo; cobertura de teste > 0% nos módulos `domain/usecase` e `domain/repository`; crash em produção aparece em dashboard de observabilidade em até 5 minutos do evento.

---

## Fase 2 — Consolidação arquitetural e compliance

**Objetivo:** eliminar as inversões de dependência entre camadas e fechar a lacuna de compliance antes de abrir o app a usuários reais.

**Eixo arquitetural:** Fundamentos, Segurança e Compliance

**Iniciativas:**
- Corrigir inversões de dependência (`domain`→`data`, `data`→`presentation`) — `ARQ-001`, `ARQ-002`
- Mover `instance<T>()` para injeção via construtor — `ARQ-004`
- Remover duplicação `_nextCardButton()` — `ARQ-007`
- Política de Privacidade e Termos de Uso reais + tela de consentimento OAuth — `SEC-009`
- Scanner de dependências integrado + upgrade de majors críticos (`firebase_core`, `cloud_firestore`, `spotify_sdk`) — `SEC-010`

**Dependências entre iniciativas:** `ARQ-004` (DI via construtor) torna `ARQ-003`/testes da Fase 1 mais fáceis de expandir — por isso entra logo na sequência, não em paralelo puro. `SEC-009` é pré-requisito de negócio para publicação nas lojas (Apple/Google exigem política de privacidade linkada).

**Métrica de sucesso:** zero import de `data` em `domain` ou de `presentation` em `data` (verificável por lint de arquitetura, ex. `import_lint` ou regra customizada); política de privacidade acessível publicamente com URL estável; nenhuma dependência com CVE confirmada de severidade Alta/Crítica em aberto.

---

## Fase 3 — Experiência e performance

**Objetivo:** elevar a qualidade percebida pelo usuário final — consistência visual, acessibilidade e responsividade de rede.

**Eixo arquitetural:** Experiência, Performance

**Iniciativas:**
- Padronizar 100% das telas no design system existente — `UX-001`
- Adicionar `Semantics`/acessibilidade nas telas principais — `UX-003`
- Checklist/lint de contraste WCAG AA — `UX-004`
- Cache de rede (Spotify/iTunes) + `cached_network_image` — `PERF-003`
- Otimização de assets de imagem — `PERF-004`
- Tratamento de loading/erro uniforme (`settings_view.dart` e demais telas incompletas) — `UX-006`

**Dependências entre iniciativas:** nenhuma dependência forte entre si — podem rodar em paralelo por sub-times (design system e acessibilidade são trabalho de UI; cache e assets são trabalho de dados/build). `UX-001` idealmente conclui antes de `UX-004`, já que padronizar cores primeiro facilita auditar contraste depois em um único lugar (`ColorManager`) em vez de N telas.

**Métrica de sucesso:** zero ocorrência de `TextStyle(` cru fora de `style_manager.dart` (grep de CI); tempo de carregamento de tela do player reduzido em cenário de scan repetido (cache hit); relatório de contraste sem violação AA nas cores do `ColorManager`.

---

## Fase 4 — Governança e escala

**Objetivo:** preparar o projeto para crescer com mais de um contribuidor e mais de uma versão em produção simultânea.

**Eixo arquitetural:** Documentação e Governança, Performance e Escalabilidade

**Iniciativas:**
- `CHANGELOG.md` + tags de release semver — `DOC-004`
- Consolidação de estratégia de branching — `DOC-006`
- ADRs retroativas para decisões já tomadas — `DOC-003`
- `CONTRIBUTING.md` + política de atualização de dependências — `DOC-007`
- Avaliação de gerenciamento de estado reativo (Provider/Riverpod/Bloc) se a árvore crescer — `PERF-008`
- Suporte a tablet com breakpoints reais — `UX-005`
- Firebase App Check para a coleção `musicas` — sugestão associada a `SEC-004`

**Dependências entre iniciativas:** `DOC-006` (branching) deve ser resolvido antes de `DOC-004` (tags/release) fazer sentido operacionalmente — não há por que taguear releases se não está claro qual branch é a fonte de verdade. `PERF-008` e `UX-005` são as únicas iniciativas de escopo grande (G) do roadmap inteiro e devem ser tratadas como projetos à parte, não tarefas de sprint.

**Métrica de sucesso:** todo PR de contribuidor externo consegue rodar o projeto localmente seguindo só o `CONTRIBUTING.md`, sem perguntar no chat da equipe; toda release tem tag + entrada no changelog.

---

## Visão consolidada

```
Fase 1 (Fundação)          Fase 2 (Arquitetura)         Fase 3 (Experiência)         Fase 4 (Governança)
├─ CI mínimo                ├─ Fix inversões deps         ├─ Design system 100%        ├─ CHANGELOG + tags
├─ Testes unitários          ├─ DI via construtor          ├─ Acessibilidade            ├─ Branching
├─ Crashlytics/Sentry        ├─ Dedup player buttons       ├─ Contraste WCAG            ├─ ADRs retroativas
├─ Remove .env do Git        ├─ Privacidade/Termos         ├─ Cache de rede             ├─ CONTRIBUTING.md
└─ Extrai lógica p/ UseCase  └─ Scanner de dependências    ├─ Otimização de assets      ├─ Estado reativo (avaliar)
                                                            └─ Loading/erro uniforme     ├─ Suporte tablet
                                                                                         └─ App Check
```

Cada fase pressupõe a anterior concluída nos itens críticos (não necessariamente 100% dos itens médios/baixos), mas as fases podem se sobrepor parcialmente para itens sem dependência direta — por exemplo, `DOC-005` (Conventional Commits) e as demais quick wins podem começar imediatamente, em paralelo à Fase 1.
