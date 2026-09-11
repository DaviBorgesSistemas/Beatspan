# Beatspan — Improvement Roadmap

**Data da análise:** 2026-09-11
**Versão do documento:** 3.0 (reanálise completa do zero, substitui a versão 2.0)
**Commit analisado:** `577dd0c` (branch `beatspan_v2`)

> Agrupa as iniciativas de `docs/4-ACTION_PLAN.md` por fase, já que o projeto está em pré-lançamento (fases em vez de trimestres calendário). Nenhuma iniciativa nova é criada aqui — todas rastreiam de volta a um ID já definido nos documentos 1-4 desta versão.

---

## ⚡ Quick wins (alto impacto, baixo esforço)

| Iniciativa | ID(s) | Esforço | Impacto |
|---|---|---|---|
| Implementar ou remover a `ContactView` vazia | `EXP-003`/`SEC-004` | P | Crítico |
| Adicionar "Desconectar Spotify" em Configurações | `SEC-002` | P | Médio |
| Desabilitar `allowBackup` no manifest Android | `SEC-003` | P | Médio |
| Resolver dependência transitiva retracted | `SEC-005` | P | Médio |
| Reportar erro inesperado de forma consistente entre repositórios | `ARQ-102` | P | Médio |
| Adicionar teste ao guard de conectividade | `OPS-003` | P | Médio |

Esses 6 itens somam esforço P (pequeno) cada e endereçam, juntos, o item crítico de maior visibilidade externa (`ContactView`) mais um conjunto de lacunas de compliance/resiliência de baixo custo de implementação — recomendado como primeira leva de trabalho após esta análise.

---

## Fase 1 — Fechar lacunas críticas de UX e compliance (imediato)

**Objetivo:** eliminar os dois achados classificados como críticos nesta análise antes de qualquer expansão de escopo.
**Eixo:** Experiência, Segurança
**Dependências:** nenhuma — pode começar imediatamente.
**Iniciativas:**
- Implementar/remover `ContactView` (`EXP-003`/`SEC-004`)
- Acessibilidade no fluxo bloqueante de permissão de câmera (`EXP-001`, recorte prioritário)

**Métrica de sucesso:** zero telas roteadas e documentadas como entregues que estejam vazias; `camera_permission_view.dart` operável via TalkBack/leitor de tela.

---

## Fase 2 — Resiliência do controle de reprodução (curto prazo)

**Objetivo:** fechar a maior lacuna de confiabilidade identificada — a camada que controla play/pause/resume em tempo real durante a partida não tem rede de segurança.
**Eixo:** Operações
**Dependências:** nenhuma, mas se beneficia de rodar em paralelo com a Fase 1 (times/pessoas diferentes).
**Iniciativas:**
- Tratamento de erro + testes em `SpotifyPlaybackControlRepositoryImpl` (`OPS-001`)
- Tratamento de erro + testes em `PreviewPlaybackControlRepositoryImpl` (`OPS-002`)

**Métrica de sucesso:** cobertura de ambos os arquivos acima de 80%; nenhuma exceção não tratada nos 4+2 métodos de controle de playback.

---

## Fase 3 — Acessibilidade completa e componentização (curto/médio prazo)

**Objetivo:** estender a correção pontual de acessibilidade da Fase 1 para o restante do app, resolvendo a causa raiz (duplicação de componentes) em vez de repetir a correção manualmente tela por tela.
**Eixo:** Experiência, Fundamentos
**Dependências:** a componentização do botão "voltar" (`EXP-002`) deveria vir **antes ou junto** da expansão de `Semantics` (`EXP-001` continuação) — resolver a duplicação primeiro evita ter que aplicar `Semantics` manualmente em 5+ lugares que poderiam ser 1.
**Iniciativas:**
- Componentizar botão "voltar" (`EXP-002`)
- Expandir `Semantics` para telas restantes (`EXP-001` continuação)
- Corrigir estado de erro do FAQ (`EXP-004`)
- Aplicar tokens de design consistentemente (`EXP-005`)

**Métrica de sucesso:** `Semantics` presente em 100% dos botões interativos de `lib/presentation/`; zero componentes de UI visualmente idênticos duplicados em mais de 1 arquivo.

---

## Fase 4 — Cobertura de testes das telas administrativas (médio prazo)

**Objetivo:** estender a alta cobertura já existente no fluxo crítico de jogo para as telas de uso frequente que hoje têm zero teste.
**Eixo:** Operações
**Dependências:** nenhuma direta, mas conflita em arquivos com a Fase 3 (várias das telas sem teste — Settings, FAQ — são as mesmas que ganharão `Semantics` na Fase 3; recomenda-se testar depois de estabilizar a UI, não antes).
**Iniciativas:**
- Cobertura de Settings, FAQ, Home, Splash, Rules (`OPS-004`)
- Extração de widget de erro compartilhado do player (`ARQ-103`, menor, pode ser feito em paralelo)

**Métrica de sucesso:** cobertura global do projeto acima de 65% (hoje 54,3%); nenhum arquivo de `lib/presentation/` em 0% de cobertura, exceto os que não têm lógica testável (ex. Splash puramente decorativo).

---

## Fase 5 — Consolidação de governança e manutenção contínua (médio/longo prazo)

**Objetivo:** fazer os mecanismos de governança já criados (CHANGELOG, ADRs, gate de cobertura) resistirem ao ritmo real de desenvolvimento — hoje criados, mas ainda não seguidos com disciplina total.
**Eixo:** Documentação
**Dependências:** nenhuma técnica; depende de adoção de processo pela equipe, não de código.
**Iniciativas:**
- Atualizar `CHANGELOG.md` retroativamente (`DOC-002`)
- Documentar política de cadência de dependências (`DOC-004`)
- ADRs para decisões de produto/governança já tomadas (`DOC-006`)
- Introduzir tags Git na primeira release real (`DOC-003`)
- Avaliar upgrade das dependências com major version disponível (`SEC-005` continuação)

**Métrica de sucesso:** todo PR relevante adiciona sua entrada em `CHANGELOG.md [Unreleased]` (verificável no CI, se desejado); primeira tag `vX.Y.Z` criada na próxima release publicada.

---

## Fase 6 — Refinamentos arquiteturais e de performance (longo prazo, não urgente)

**Objetivo:** itens de baixo impacto imediato, mantidos no radar para quando o produto crescer em escala ou complexidade.
**Eixo:** Fundamentos, Performance
**Dependências:** nenhuma — podem ser feitos a qualquer momento sem bloquear outras fases.
**Iniciativas:**
- Reduzir acoplamento de `domain/` a SDKs de infraestrutura (`ARQ-101`)
- Consolidar estilo único de DI em `GameView` (`ARQ-104`)
- Reduzir boilerplate de `di.dart` (`ARQ-105`)
- Instrumentar telemetria de cache antes de decidir sobre TTL (`PERF-001`)
- Cachear token do Spotify explicitamente (`PERF-002`)
- Uniformizar nomenclatura `Musica*` ou documentar a exceção (`EXP-007`)
- Avaliar Firebase App Check (`SEC-006`)
- Publicar cobertura de forma visível no PR (`OPS-005`)
- Corrigir typo `bagroundColor` (`EXP-006`)

**Métrica de sucesso:** não aplicável como meta de fase única — cada item é independente e deve ser avaliado por custo/benefício no momento em que for priorizado, não por um prazo fixo.
