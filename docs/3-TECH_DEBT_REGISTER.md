# Beatspan — Tech Debt Register

**Data da análise:** 2026-09-10
**Versão do documento:** 2.0 (reanálise completa)
**Commit analisado:** `8f2ae1e` (branch `beatspan_v2`)

IDs referenciam `docs/1-ARCHITECTURAL_REVIEW.md`/`docs/2-SECURITY_REPORT.md` quando já levantados lá.

---

## 1. Catálogo de débito técnico

| ID | Categoria | Descrição | Severidade | Esforço | Impacto se não resolvido |
|---|---|---|---|---|---|
| ARQ-003 | Código | `capture.barcodes.first` sem checar lista vazia em `GameView._onDetect` | **Crítica** | P (pequeno) | Crash não tratado ao escanear, em produção, sem stacktrace útil se não cair no Crashlytics antes de travar a UI |
| OPS-001 | Testes | ~~Cobertura de testes concentrada; arquivos de rede críticos (`spotify_service.dart`, `musica_firestore_data_source.dart`) em 0%~~ — **resolvido**: ambos cobertos (90%/96%); `musica_firestore_data_source.dart` já tinha teste, `spotify_service.dart` ganhou `test/data/network/spotify_service_test.dart` | ~~Crítica~~ Resolvido | — | Restam lacunas menores: `faq_local_data_source.dart` (0%) e a maioria das telas de `presentation/` |
| EXP-001 | Código/UX | Zero `Semantics`/`Tooltip` em todo `lib/presentation` | **Crítica** | M (médio) | App inacessível a jogadores que dependem de leitor de tela; risco de compliance de acessibilidade caso o app seja publicado em lojas com políticas de acessibilidade |
| ARQ-001 | Arquitetura | ~~Bypass do padrão de DI (`get_it`) no fluxo de preview~~ — **resolvido** | ~~Média~~ Resolvido | — | — |
| ARQ-002 | Arquitetura | ~~Códigos de erro de `Failure` (`int`) colidem entre use cases distintos~~ — **resolvido**: `Failure` é `sealed class` com subclasse tipada por domínio | ~~Média~~ Resolvido | — | — |
| ARQ-005 | Código/Produto | ~~`LanguageType`/`CountryType` persistidos mas nunca lidos de volta~~ — **resolvido**: decisão de produto (app só em português), código removido | ~~Média~~ Resolvido | — | — |
| SEC-001 | Infra | Config Firebase versionada sem confirmação de restrição de API key | Média | P (verificação) | Risco de abuso da API key se não houver restrição configurada no Google Cloud Console (não é um problema de código) |
| SEC-002 | Infra | Fallback silencioso para assinatura de debug no release | Média | P | Risco de publicar build mal assinado sem alerta |
| SEC-003 | Infra/CI | ~~Sem scan de dependências automatizado no CI~~ — **resolvido** (job `osv-scan`) | ~~Média~~ Resolvido | — | — |
| OPS-002 | CI | ~~CI não mede/gateia cobertura de testes~~ — **resolvido**: gate de 40% (abaixo do real medido, 43,4%) + artefato de cobertura publicado | ~~Média~~ Resolvido | — | — |
| EXP-002 | Código/Design | ~~18 arquivos (na prática, 29) com cor hardcoded fora do design system~~ — **resolvido**: todos migrados para `ColorManager` | ~~Média~~ Resolvido | — | — |
| ARQ-004 | Código | Boilerplate repetitivo de `if (!instance.isRegistered<X>())` em `di.dart` | Baixa | P | Nenhum risco funcional; apenas manutenção mais verbosa que o necessário |
| ARQ-006 | Código | `exit(1)` (dart:io) para encerrar o app em 2 pontos, em vez de `SystemNavigator.pop()` | Baixa | P | Pula o ciclo de vida do engine/plugins nativos ao fechar; comportamento pode variar entre fabricantes Android |
| OPS-003 | Observabilidade | `debugPrint` em vez de `reportNonFatalError` em 2 pontos (`faqs_view_model.dart`, `session_tile.dart`) | Baixa | P | Erros nesses 2 pontos específicos não aparecem no Crashlytics em produção |
| OPS-004 | Produto/Observabilidade | Sem analytics de produto (funil de jogo, taxa de erro de QR) | Baixa | G | Decisões de produto pré-lançamento sem dado de uso real — aceitável agora, arriscado se mantido pós-lançamento |
| DOC-001 | Docs | README afirma que não há Crashlytics em produção — já integrado | Baixa | P | Novo dev/stakeholder lendo o README forma uma impressão incorreta do estado do projeto |
| DOC-002 | Docs/Processo | ~~Sem `CHANGELOG.md` nem tags Git~~ — **parcial**: `CHANGELOG.md` criado (seção `[Unreleased]` pronta); tags ainda dependem da próxima release real | Baixa | P | Sem tags, ainda não há como identificar exatamente qual commit corresponde a qual build publicado |
| DOC-004 | Docs/Processo | Histórico de commits pré-Conventional Commits não reescrito | Informativo | — | Nenhum — decisão deliberada, já aceita (ver seção 2) |
| DOC-003 | Docs | ~~Sem ADRs para decisões de arquitetura relevantes~~ — **resolvido**: `docs/adr/` criado com os 3 ADRs mínimos | ~~Baixa~~ Resolvido | — | — |
| PERF-001 | Código | Caches em memória (`_cache`, `_previewCache`) sem TTL/limite de tamanho | Baixa | P | Sem impacto perceptível no tamanho de uso atual; não escala se o volume por sessão crescer ordens de magnitude |

---

## 2. Débitos críticos vs. aceitáveis

### Críticos — requerem ação antes do próximo ciclo de trabalho
- **ARQ-003**: é um bug de crash potencial no caminho mais usado do app (escanear carta). Correção é trivial (checar `capture.barcodes.isEmpty` antes de `.first`) — não há motivo para não resolver no curto prazo.
- **EXP-001**: zero acessibilidade em toda a base é estrutural, não um item isolado — quanto mais tempo passar sem um padrão de `Semantics` estabelecido, mais telas novas nascerão também sem ele.
- **OPS-001** (resolvido): os arquivos que integravam com serviços externos (Spotify, Firestore) e estavam sem teste — os mais caros de diagnosticar sem cobertura — já foram endereçados.

### Aceitos por ora (com justificativa explícita)
- **ARQ-004** (boilerplate no DI) e **ARQ-006** (`exit(1)`) — baixo risco, baixo esforço, mas não bloqueiam nada; resolver quando a área for tocada por outro motivo (não justifica uma tarefa dedicada isolada).
- **OPS-004** (sem analytics de produto) — aceitável enquanto o app estiver em pré-lançamento sem tráfego real para analisar; deve ser reavaliado antes do lançamento público.
- **PERF-001** (caches sem TTL) — o padrão de uso atual (sessão de jogo física, catálogo limitado) não expõe esse risco na prática; manter sob observação, não agir preventivamente sem dado de uso real que justifique.
- ~~**DOC-003** (sem ADRs)~~ — **resolvido em 2026-09-11**: os 3 ADRs mínimos foram registrados (ver `docs/adr/`), com nota honesta onde a alternativa considerada não pôde ser reconstruída. O hábito de registrar novas decisões a partir de agora continua sendo o valor principal, não a reconstrução retroativa em si.
- **DOC-004** (histórico de commits não reescrito) — já aceito e documentado no próprio README; reescrever histórico Git público de um repositório compartilhado é mais arriscado do que o problema que resolveria.

---

## 3. Recomendação de priorização

1. **ARQ-003** (crash no scanner) — corrigir imediatamente, é uma linha de código.
2. **EXP-001** (acessibilidade) — estabelecer o padrão (`Semantics` nos componentes de `resource/`/`share/widgets/` reutilizáveis primeiro) antes de tentar cobrir 100% das telas de uma vez.
3. ~~**OPS-001** (cobertura nos arquivos de rede)~~ — **resolvido**: `spotify_service.dart` e `musica_firestore_data_source.dart` cobertos. Lacuna remanescente, menor: `faq_local_data_source.dart` (0%) e a maior parte das telas de `presentation/`.
4. **SEC-002** e **SEC-003** — ambos são configuração de pipeline, não código; podem ser resolvidos em paralelo sem dependência entre si.
5. Demais itens médios (**ARQ-001**, **ARQ-002**, **ARQ-005**, **EXP-002**, **OPS-002**) — tratar conforme a área for tocada por outras mudanças, exceto se o time decidir abrir uma iniciativa dedicada de "consistência" (ver `docs/5-IMPROVEMENT_ROADMAP.md`).
