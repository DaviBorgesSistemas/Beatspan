# Beatspan — Improvement Roadmap

**Data da análise:** 2026-09-10
**Versão do documento:** 2.0 (reanálise completa)
**Commit analisado:** `8f2ae1e` (branch `beatspan_v2`)

Iniciativas agrupadas a partir dos IDs de `docs/4-ACTION_PLAN.md` — nenhuma iniciativa nova é introduzida aqui.

---

## ⚡ Quick wins (alto impacto, baixo esforço)

| Iniciativa | ID(s) | Esforço | Impacto |
|---|---|---|---|
| Corrigir crash do scanner (`barcodes.isEmpty`) | `ARQ-003` | P | Alto |
| Falhar build de release sem `key.properties` | `SEC-002` | P | Médio |
| Confirmar restrição da API key do Firebase | `SEC-001` | P | Alto |
| Atualizar README sobre Crashlytics | `DOC-001` | P | Baixo |
| `reportNonFatalError` nos 2 pontos com `debugPrint` | `OPS-003` | P | Baixo |

Essas 5 iniciativas resolvem os 2 achados críticos mais baratos de corrigir (o terceiro, cobertura de testes, é estrutural e não cabe como quick win) e 3 das atenções de segurança, sem exigir mudança de arquitetura.

---

## Fase 1 — Estabilização (0–1 mês)

**Objetivo:** eliminar os riscos críticos e de segurança imediatos antes de qualquer novo trabalho de produto.

| Iniciativa | IDs relacionados | Eixo | Dependências | Métrica de sucesso |
|---|---|---|---|---|
| Corrigir bug do scanner | `ARQ-003` | Fundamentos | Nenhuma | Zero crashes reportados no Crashlytics com origem em `GameView._onDetect` após deploy |
| Endurecer pipeline de release Android | `SEC-001`, `SEC-002` | Segurança | Nenhuma | Build de release falha explicitamente sem keystore; API key confirmada restrita |
| Scan de dependências no CI | `SEC-003` | Segurança | Nenhuma | Step de OSV-Scanner rodando em todo PR, sem bloquear o pipeline indevidamente |
| Higiene de documentação e observabilidade | `DOC-001`, `OPS-003` | Documentação/Operações | Nenhuma | README reflete o estado real do código; 0 ocorrências de `debugPrint` para erro em `lib/presentation` |

---

## Fase 2 — Qualidade e confiabilidade (1–3 meses)

**Objetivo:** elevar a cobertura de teste e a consistência do app nos pontos que mais custam caro em produção.

| Iniciativa | IDs relacionados | Eixo | Dependências | Métrica de sucesso |
|---|---|---|---|---|
| Cobrir integrações de rede críticas com testes | `OPS-001` | Operações | Nenhuma | `spotify_service.dart` e `musica_firestore_data_source.dart` saem de 0% de cobertura; meta mínima acordada (ex.: 70%) |
| ~~Gate de cobertura no CI~~ — resolvido (meta de 40%, abaixo do real 43,4%) | `OPS-002` | Operações | — | CI falha (ou alerta) se a cobertura cair abaixo da meta acordada |
| Padrão de acessibilidade | `EXP-001` | Experiência | Nenhuma | Componentes reutilizáveis de `share/widgets/` com `Semantics`; ao menos o fluxo principal navegável com TalkBack |
| ~~Consistência de design tokens~~ — resolvido (29 arquivos migrados para `ColorManager`) | `EXP-002` | Experiência | — | 0 arquivos com `Color(0x...)` fora de `resource/` (ou justificativa documentada por exceção) |

---

## Fase 3 — Consistência arquitetural (3–6 meses)

**Objetivo:** resolver debt estrutural que não é urgente, mas que cresce com cada tela nova se não for endereçado.

| Iniciativa | IDs relacionados | Eixo | Dependências | Métrica de sucesso |
|---|---|---|---|---|
| Unificar resolução de dependências via `get_it` | `ARQ-001`, `ARQ-004` | Fundamentos | Nenhuma | Nenhuma instanciação direta de repositório/use case fora de `lib/app/di.dart` |
| ~~Redesenhar modelo de erro de domínio~~ — resolvido (`Failure` já é `sealed class` por domínio) | `ARQ-002` | Fundamentos | — | Códigos de erro não colidem mais entre use cases distintos (ex.: tipo selado por domínio) |
| ~~Decisão sobre idioma/país~~ — resolvido (removido) | `ARQ-005` | Fundamentos/Produto | — | Enums `LanguageType`/`CountryType`, getters/setters e rota `/language` removidos do código |
| Saída de app idiomática | `ARQ-006` | Fundamentos | Nenhuma | `SystemNavigator.pop()` substitui `exit(1)` nos 2 pontos identificados |

---

## Fase 4 — Maturidade pré-lançamento (6–12 meses)

**Objetivo:** o que falta antes de tratar o app como pronto para lançamento público em escala.

| Iniciativa | IDs relacionados | Eixo | Dependências | Métrica de sucesso |
|---|---|---|---|---|
| Analytics de produto | `OPS-004` | Operações | Nenhuma (mas ideal após Fase 1 de observabilidade) | Funil de escaneamento→reprodução instrumentado; taxa de fallback iTunes visível em dashboard |
| Processo de release formal — **parcial**: `CHANGELOG.md` criado, tags pendentes da próxima release | `DOC-002` | Documentação | Nenhuma | `CHANGELOG.md` mantido a partir da próxima tag; tags Git correspondendo a `pubspec.yaml` |
| ~~Registro de decisões arquiteturais~~ — resolvido (3 ADRs mínimos registrados) | `DOC-003` | Documentação | — | ADRs cobrindo ao menos: escolha de Clean Architecture simplificada, `dartz`/Either, ausência de backend próprio |
| Revisão de escalabilidade dos caches em memória | `PERF-001` | Performance | Depende de dado real de uso (analytics da Fase 4) | Decisão informada por dado real: manter, ou adicionar TTL/limite |

---

## Notas de sequenciamento

- As iniciativas de **Segurança** (Fase 1) não têm dependência entre si nem com as demais fases — podem rodar em paralelo com qualquer outra fase.
- **Gate de cobertura no CI** (`OPS-002`) foi resolvido com uma meta calibrada ao valor real medido (40%, abaixo dos 43,4% reais) em vez de esperar a cobertura subir primeiro — evita travar o pipeline desde o dia 1 sem precisar da sequência original proposta aqui.
- A decisão sobre **idioma/país** (`ARQ-005`) já foi resolvida: app segue só em português, código morto removido.
- **Analytics de produto** (`OPS-004`) é o único item cujo valor aumenta com o tempo (mais útil perto do lançamento do que hoje) — por isso está na fase mais tardia, não porque seja menos importante.
