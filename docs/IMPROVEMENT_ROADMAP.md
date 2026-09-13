# Beatspan — Roadmap de Melhorias
**Projeto:** Beatspan
**Data da análise:** 2026-09-12
**Versão do documento:** 3.0
**Todas as iniciativas rastreadas em:** `docs/ACTION_PLAN.md`

---

## Quick Wins (Alto Impacto, Baixo Esforço)

| Iniciativa | ID(s) | Esforço | Impacto | Eixo |
|-----------|-------|---------|---------|------|
| ~~Migrar credenciais Spotify de asset para `--dart-define`; revogar Client ID atual~~ — **Resolvido em 2026-09-12** | SEC-002 | P | Alto | Segurança |
| Atualizar `path_provider_foundation` 2.5.0 → 2.6.0 | SEC-003 | P | Médio | Segurança |
| Restaurar ADRs no `docs/adr/` | DOC-001 | P | Médio | Documentação |
| Injetar `PreviewPlaybackUseCase` via construtor em `GameView` | ARQ-001 | P | Médio | Fundamentos |
| Corrigir `GameViewModel.dispose()` para cancelar async | ARQ-004 | P | Baixo | Operações |
| Limpar `MyApp` (singleton corrompido + `appState`) | ARQ-005 | P | Baixo | Fundamentos |
| Adicionar `Semantics` ao botão fechar do player | EXP-001 | P | Baixo | Experiência |
| Adicionar testes para `faq_local_data_source.dart` | DEBT-003 | P | Baixo | Operações |

---

## Fase 1 — Pré-Lançamento (Sprint Atual + Até 4 Semanas)

**Objetivo:** Tornar o app seguro para distribuição pública e corrigir violações arquiteturais imediatas.

| Iniciativa | ID(s) | Objetivo | Eixo | Dependências | Métrica de Sucesso |
|-----------|-------|----------|------|--------------|-------------------|
| Segurança de credenciais | SEC-002, SEC-003 | Remover credenciais extraíveis do APK | Segurança | Nenhuma | ✅ `.env` fora dos assets (SEC-002, 2026-09-12); `pub-outdated.json` sem retracted |
| Correções arquiteturais críticas | ARQ-001, ARQ-004, ARQ-005 | Fechar violações de DI e anti-patterns | Fundamentos | Nenhuma | `game_view.dart` sem `instance<>()` direto; `app.dart` sem `must_be_immutable` |
| Acessibilidade básica | EXP-001 | Fechar falhas de TalkBack no player | Experiência | Nenhuma | `accessibility_test.dart` cobre botão fechar |
| Cobertura mínima | DEBT-003, OPS-001 | Elevar gate para 60% e cobrir `faq_local_data_source` | Operações | Nenhuma | CI passa com threshold 60% |
| Documentação de decisões | DOC-001 | Restaurar ADRs | Documentação | Nenhuma | `docs/adr/` com ≥3 ADRs principais |

---

## Fase 2 — Produto (1 a 3 Meses)

**Objetivo:** Implementar a lógica de jogo central e expandir para iOS.

| Iniciativa | ID(s) | Objetivo | Eixo | Dependências | Métrica de Sucesso |
|-----------|-------|----------|------|--------------|-------------------|
| Lógica de jogo | DEBT-001 | Rodadas, pontuação, linha do tempo | Fundamentos / Produto | Fase 1 completa | 1 modo de jogo funcional e testado |
| iOS onboarding | DEBT-002 | Configurar build iOS completo | Infra | Fase 1 completa | CI roda `flutter build ios` sem erro |
| CD automatizado | OPS-002 | Distribuição automatizada em tag | Operações | Nenhuma | APK release gerado e distribuído pelo CI em tag semver |
| Firebase SDK major upgrade | DEBT-005 (Firebase) | Manter SDK Firebase atualizado | Infra | Fase 1 completa | `firebase_core` em v4.x; todos os pacotes Firebase compatíveis |
| LGPD / Política de privacidade | LGPD | Consentimento e link de política no app | Segurança / Compliance | Fase 1 completa | Tela de aceite presente; link na Play Store |

---

## Fase 3 — Maturidade (3 a 12 Meses)

**Objetivo:** Internacionalizar, observar e manter dependências saudáveis.

| Iniciativa | ID(s) | Objetivo | Eixo | Dependências | Métrica de Sucesso |
|-----------|-------|----------|------|--------------|-------------------|
| Internacionalização | EXP-003 | Suporte a múltiplos idiomas | Experiência | Fase 2 completa | `flutter_localizations` integrado; pt-BR + en-US |
| Logging estruturado | OPS-006 | Diagnóstico offline em debug e prod | Operações | Nenhuma | Log com nível, timestamp, contexto; não poluindo Crashlytics |
| Upgrade restante de deps | DEBT-005 (não-Firebase) | Eliminar major breaks pendentes | Infra | Fase 2 completa | `pub-outdated.json` sem major breaks resolvíveis |
| Splash adaptativo | PERF-001 | Remover duração fixa | Performance | Nenhuma | Splash encerra assim que boot conclui |
| Política de atualização de deps | DEBT-005 | Processo documentado e automatizado | Documentação | Fase 3 | `CONTRIBUTING.md` com frequência e critério de upgrade |

---

## Resumo por Eixo

| Eixo | Fase 1 | Fase 2 | Fase 3 |
|------|--------|--------|--------|
| Segurança | SEC-002, SEC-003 | LGPD, SEC-001 | — |
| Fundamentos | ARQ-001, ARQ-004, ARQ-005 | DEBT-001 | — |
| Experiência | EXP-001 | — | EXP-003 |
| Operações | DEBT-003, OPS-001 | OPS-002, DEBT-005 (Firebase) | OPS-006, DEBT-005 (restante) |
| Documentação | DOC-001 | DOC-002 | Política de deps |
| Performance | — | — | PERF-001 |
