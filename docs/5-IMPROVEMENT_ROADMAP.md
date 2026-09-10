# Roadmap de Melhoria — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-09
**Versão do documento:** 2.0

> Agrupa as iniciativas definidas em [4-ACTION_PLAN.md](4-ACTION_PLAN.md) por fase. Nenhuma iniciativa nova é criada aqui. Como o projeto ainda não tem release pública, as fases usam nomenclatura por marco de maturidade (Fase 1–4).

---

## ⚡ Quick wins (alto impacto, baixo esforço)

| Iniciativa | ID(s) relacionado(s) | Esforço | Impacto |
|---|---|---|---|
| Remover `.env` do Git de novo + gate de secret-scanning no CI | SEC-001 / OPS-007 | P | Alto |
| Registrar `catch` de negócio no Crashlytics | OPS-008 | P | Alto |
| Corrigir processo de checklist do plano de ação | DOC-011 | P | Alto |
| Corrigir typo "PREMIYM" | UX-010 | P | Baixo |
| Adicionar `formats: [qrCode]` ao scanner | PERF-011 | P | Baixo |
| Cache em memória em `MusicaRepositoryImpl` | PERF-009 | P | Baixo |
| Padronizar tamanho mínimo de botões fechar/voltar | UX-011 | P | Baixo |

---

## Fase 1 — Fechar a regressão e as lacunas de observabilidade

**Objetivo:** este ciclo é diferente do anterior — não é "criar" confiabilidade do zero, é **consertar o que já foi criado e regrediu**, e fechar a lacuna mais séria descoberta agora: erros tratados são invisíveis.

**Eixo arquitetural:** Segurança, Operações

**Iniciativas:**
- Reaplicar remoção do `.env` + gate automatizado que impeça a 3ª regressão — `SEC-001` / `OPS-007`
- `recordError` nos catches de negócio (Spotify, player) — `OPS-008`
- Diferenciar mensagens de erro reais no fluxo de playback — `UX-009`
- Corrigir processo de checklist (verificação antes de marcar `[x]`) — `DOC-011`

**Dependências:** `OPS-008` deveria entrar **antes** de `UX-009` ser reescrito — sem telemetria real, o novo texto de erro corre o risco de ser um chute tão impreciso quanto o atual.

**Métrica de sucesso:** um `git log` mostrando `.env` nunca mais versionado por 90 dias consecutivos; primeiro incidente real do Spotify aparecendo no dashboard do Crashlytics com causa identificável (não só "erro de conexão").

---

## Fase 2 — Fechar o débito residual de arquitetura e segurança de release

**Objetivo:** terminar o que a Fase 1 anterior deixou pela metade — o playback ainda fora do padrão Repository/UseCase, e o app ainda não pronto para ser publicado de verdade.

**Eixo arquitetural:** Fundamentos, Segurança

**Iniciativas:**
- ~~Extrair controle de reprodução para repository/usecase~~ — `ARQ-013` (✅ concluído em 2026-09-10)
- `GameViewModel` real, injetada via construtor, absorvendo a orquestração de `GameView` — `ARQ-014` / `ARQ-019`
- Keystore de produção + ofuscação R8/ProGuard habilitada — `SEC-011`
- ~~Centralizar checagem de consentimento OAuth~~ — `SEC-012` (✅ concluído em 2026-09-10)
- Retry/backoff + tratamento de `429` — `OPS-010` / `PERF-010`
- Consolidar/arquivar branches órfãs, resgatando o que for útil de `refatore` — `OPS-012` / `DOC-006`

**Dependências:** `ARQ-014` fica mais fácil de testar depois que `ARQ-013` reduzir o que `GameView` chama diretamente. `SEC-011` é pré-requisito de negócio para qualquer submissão à Play Store.

**Métrica de sucesso:** `GameView` não chama `SpotifySdk.*` diretamente; build de release assinado com keystore própria e R8 habilitado sem quebrar; nenhuma branch de longa duração sem commit há mais de 90 dias sem decisão documentada.

---

## Fase 3 — Experiência, acessibilidade e cobertura de teste

**Objetivo:** elevar qualidade percebida e reduzir a superfície não testada do app.

**Eixo arquitetural:** Experiência, Operações

**Iniciativas:**
- Cobertura de teste para os ~54 arquivos ainda não tocados, priorizando o fluxo Spotify — `OPS-001`
- Avaliação de testes de integração/e2e — `OPS-009`
- `Semantics`/acessibilidade nas telas principais — `UX-003`
- Padronizar 100% das telas no design system — `UX-001`
- Contraste WCAG AA — `UX-004`
- Layout responsivo para os cards de player (sem dimensão fixa) — `UX-005`
- Otimização de assets + remoção de pesos de fonte não usados — `PERF-004` / `PERF-012`

**Dependências:** nenhuma dependência forte entre si; podem correr em paralelo por sub-times.

**Métrica de sucesso:** zero `TextStyle(` cru fora de `style_manager.dart` (grep de CI); cobertura de linha do projeto inteiro (não só dos arquivos tocados) acima de 50%.

---

## Fase 4 — Governança e escala

**Objetivo:** preparar o projeto para múltiplos contribuidores e releases reais.

**Eixo arquitetural:** Documentação e Governança, Performance e Escalabilidade

**Iniciativas:**
- `CHANGELOG.md` + tags semver — `DOC-004`
- ADRs retroativas — `DOC-003`
- Cadência formal de revisão destes 5 documentos — `DOC-009`
- `CONTRIBUTING.md` + Dependabot/Renovate — `DOC-007`
- Limpeza de `docs/melhorias/*` — `DOC-010`
- Avaliação de estado reativo (Provider/Riverpod/Bloc) — `PERF-008`
- Suporte a tablet com breakpoints reais — `UX-005` (parte de escopo grande)
- Firebase App Check para `musicas` — sugestão associada a `SEC-004`

**Dependências:** `DOC-006` (já deveria estar resolvido na Fase 2) é pré-requisito para `DOC-004` fazer sentido operacionalmente.

**Métrica de sucesso:** todo PR de contribuidor externo roda o projeto localmente só com `CONTRIBUTING.md`; toda release tem tag + changelog; nenhum dos 5 documentos de análise arquitetural fica mais de um trimestre sem revisão.

---

## Visão consolidada

```
Fase 1 (Fechar regressão)    Fase 2 (Débito residual)      Fase 3 (Experiência)         Fase 4 (Governança)
├─ .env + secret-scan         ├─ Extrai playback p/ usecase ├─ Cobertura de teste ampla   ├─ CHANGELOG + tags
├─ Crashlytics p/ catches     ├─ GameViewModel real          ├─ Semantics/acessibilidade  ├─ ADRs retroativas
├─ Mensagens de erro reais    ├─ Keystore + R8 release       ├─ Design system 100%        ├─ Cadência de revisão
└─ Processo de checklist      ├─ Consentimento centralizado  ├─ Contraste + responsivo    ├─ CONTRIBUTING.md
                              ├─ Retry/backoff + 429         └─ Assets otimizados         ├─ Estado reativo (avaliar)
                              └─ Consolida branches órfãs                                 └─ App Check
```

Diferença chave desta versão do roadmap em relação à v1.0: a Fase 1 não é mais "criar a fundação do zero" — é **consertar uma regressão e uma lacuna de observabilidade que só apareceram depois que a fundação foi criada**. Isso é o padrão a vigiar daqui para frente: correções sem verificação automatizada tendem a regredir silenciosamente neste projeto.
