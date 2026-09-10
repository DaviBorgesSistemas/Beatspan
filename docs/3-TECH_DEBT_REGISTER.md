# Registro de Débito Técnico — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-09
**Versão do documento:** 2.0

---

## Tabela de débitos

| ID | Descrição | Categoria | Severidade | Esforço | Status | Impacto se não resolvido |
|---|---|---|---|---|---|---|
| SEC-001 | `.env` com credencial versionada no Git, corrigido e revertido em <24h | Infra/Segurança | Alta | P | ⚠️ Reaberto | Credencial permanece exposta indefinidamente; sinal de processo sem verificação |
| OPS-008 | Exceções tratadas (`catch`) nunca reportadas ao Crashlytics | Infra | Crítica | P | Novo | Erros mais comuns/acionáveis em produção ficam invisíveis |
| DOC-011 | Plano de ação afirma item crítico (`SEC-001`) como concluído quando já havia regredido | Docs/Processo | Crítica | P | Novo | Checklist perde credibilidade; decisões futuras baseadas em falsa confiança |
| UX-009 | Mensagem genérica "verifique sua internet" mascara falha real de config/autorização do Spotify | Código | Crítica | M | Novo | Suporte e usuário não conseguem diagnosticar o problema real (confirmado em produção) |
| OPS-001 | Só 22/76 arquivos de `lib/` tocados por teste; cobertura ~50% onde tocado | Testes | Alta | G | Parcial | Fluxos críticos (Spotify connect, GameView) sem rede de segurança |
| SEC-011 | Release Android assinado com chave de debug, sem minify/ofuscação | Infra/Segurança | Alta | M | Novo | Impede publicação real; facilita engenharia reversa do binário |
| ARQ-013 | Controle de reprodução Spotify ainda chama SDK direto do widget | Arquitetura | Média | M | ✅ Resolvido (2026-09-10) | ~~Lógica de playback não testável isoladamente~~ — extraído para `SpotifyPlaybackUseCase`/`PreviewPlaybackUseCase`, 21 testes novos |
| ARQ-014 | `GameViewModel` anêmica; orquestração real mora em `GameView` | Arquitetura | Média | M | Novo (residual ARQ-005) | Tela mais crítica do app sem separação testável de fluxo |
| OPS-012 | Branches órfãs (`0a`,`developer`); 4 commits de segurança perdidos em `refatore` (`flutter_secure_storage`) | Infra/Processo | Média | M | ✅ Resolvido (2026-09-10) | ~~Trabalho de segurança já feito uma vez foi descartado sem registro~~ — branches remotas apagadas por decisão explícita do usuário, sem reintegração prévia; commits recuperáveis por hash até GC do GitHub |
| DOC-005 | Convenção de commits documentada não sobrevive nem 1 dia — HEAD ainda usa `...` | Docs/Processo | Média | P (contínuo) | ✅ Resolvido (2026-09-10) | ~~`git blame`/changelog automático continuam inviáveis~~ — gate no CI + hook local opt-in (`.githooks/commit-msg`) impedem novos commits fora do padrão |
| SEC-012 | Gate de consentimento OAuth não centralizado — 2 caminhos de gameplay o ignoram | Segurança/Compliance | Média | M | ✅ Resolvido (2026-09-10) | ~~Possível autorização OAuth sem disclosure, a confirmar~~ — checagem centralizada em `SpotifyService` |
| OPS-009 | Zero testes de integração/e2e | Testes | Média | G | Novo | Regressão de contrato (Firestore/`spotify_sdk`) só aparece manualmente |
| OPS-010 | Nenhuma chamada de rede tem retry/backoff | Código | Média | M | Novo | Timeout transitório já propaga para tela de erro, sem 2ª tentativa |
| OPS-011 | Sem fallback automático Premium → Free quando Spotify falha | Produto/Código | Média | M | Novo | Usuário travado até ação manual |
| ARQ-015 | DI manual com boilerplate; `disposeFaqsModule()` nunca chamada | Arquitetura | Média | M | Novo | Registros nunca desalocados; boilerplate replicado por feature nova |
| PERF-010 | Sem tratamento de rate limit 429 da Web API do Spotify | Código | Média | M | Novo | Indistinguível de "sem internet" em uso de festa (scans rápidos) |
| OPS-007 | CI sem gate de cobertura, build ou secret-scanning | Infra | Média | P | Novo | Não teria pego a regressão de `SEC-001` |
| UX-001 | Design system usado em <15% das telas (5/46), 53 cores hardcoded em 18 arquivos | Código | Alta | M | Aberto, quantificado | Inconsistência visual; manutenção de tema em N lugares |
| UX-003 | Zero uso de `Semantics`/acessibilidade | Código | Alta | M | Aberto | App inacessível a leitor de tela |
| PERF-009 | `MusicaRepositoryImpl` sem cache (repositório irmão já tem) | Performance | Baixa | P | Novo | Scan repetido da mesma carta refaz round-trip ao Firestore |
| PERF-011 | `MobileScannerController` sem `formats: [qrCode]` | Performance | Baixa | P | Novo | CPU/bateria gastos analisando formatos irrelevantes |
| ARQ-019 | `GameViewModel` não injetada via construtor (única exceção ao padrão) | Arquitetura | Baixa | P/M | Novo | Regra de "como uma tela recebe dependências" não é única |
| DOC-009 | Docs 1/3/5 nunca revisados desde a criação (1 dia) — sem cadência de revisão | Docs/Processo | Baixa | M (processo) | Novo | Documentos divergem do código em dias, não meses |
| UX-011 | Alvos de toque < 48dp em botões fechar/voltar (inconsistente) | Código | Baixa | P | Novo | Risco de não conformidade WCAG 2.5.5 |
| PERF-012 | 3 pesos de fonte Montserrat (w100/w200/w500) sem uso, ~970KB mortos | Performance | Baixa | P | Novo | Tamanho de app maior sem benefício |
| ARQ-016 | `dart:ffi`'s `Void` usado como sentinela em vez de `dartz.Unit` | Código | Baixa | P | Novo | Import de FFI sem necessidade real; ruído cognitivo |
| ARQ-017 | `MyApp` pseudo-singleton incorreto + campo morto `appState` | Código | Baixa | P | Novo | Complexidade sem função real |
| ARQ-018 | Catch genérico em `MusicaPlaybackUseCase` descarta exceções tipadas | Código | Baixa | P | Novo | Perde distinção timeout/conexão/resposta inválida já tipada |
| UX-008 | Fallback "Erro desconhecido" em SnackBar sem próxima ação | Código | Baixa | P | Novo | Armadilha silenciosa se invariante for quebrada no futuro |
| UX-010 | Typo "PREMIYM" visível ao usuário Free | Conteúdo | Baixa | P | Novo | Falta de revisão de texto |
| PERF-013 | Cantos do scanner overlay recriados a cada frame de animação | Performance | Baixa | P | Novo | Custo de rebuild não medido, mas evitável |
| DOC-010 | `docs/melhorias/*` vazias e não versionadas | Docs | Baixa | P | Novo | Estrutura incompleta, diverge entre clone e ambiente do autor |
| ARQ-010 | Model `Musica.fromMap` retorna string vazia silenciosamente | Código | Baixa | P | Aberto | Erros de dado incompleto só aparecem depois |
| ARQ-012 | Nomenclatura de arquivo inconsistente (`*viewmodel*` vs `*_view_model*`) | Código | Baixa | P | Aberto | Ruído cognitivo mínimo |
| DOC-003 | Sem ADRs | Docs | Média | M (contínuo) | Aberto | Decisões perdem contexto histórico |
| DOC-004 | Sem CHANGELOG/tags de release | Docs | Média | P (setup) | Aberto | Impossível saber o que mudou entre builds |
| DOC-006 | Estratégia de branching pouco clara | Docs/Processo | Média | M | Aberto, agravado por `OPS-012` | Confusão sobre fonte de verdade |
| DOC-007 | Sem política de atualização de dependências / Dependabot | Docs | Baixa | P | Aberto | Atualizações de segurança dependem de lembrete manual |
| UX-004 | Contraste dark theme não verificado sistematicamente | Código | Média | P | Aberto | Risco WCAG AA não detectado antes de produção |
| UX-005 | Responsividade só smartphone, sem breakpoints | Código | Média | M | Aberto, evidência nova | Layout fixo (320x320) pode estourar em telas pequenas |
| UX-006 | Loading/erro desigual entre telas | Código | Média | P | Aberto parcial | Falha silenciosa em telas sem tratamento |
| ARQ-006 | Dois padrões de erro (`Either` vs exceptions cruas) | Arquitetura | Média | G | Aberto | Curva de aprendizado maior; UX de erro inconsistente |
| PERF-004 | Assets de imagem grandes sem otimização | Performance | Média | M | Aberto | App maior; decodificação mais lenta |
| PERF-005 | `const` inconsistente em widgets | Performance | Baixa | P | Aberto, evidência nova (`home_view.dart`) | Rebuilds marginalmente mais custosos |

**Esforço:** P = Pequeno (horas/1-2 dias) · M = Médio (dias/1-2 semanas) · G = Grande (múltiplas semanas)

---

## Débitos críticos vs. aceitáveis

### Críticos — ação imediata, não devem persistir além do próximo ciclo
- **SEC-001 (Reaberto)** — trivial de corrigir (esforço P), mas já regrediu uma vez; corrigir sem um gate automatizado (`OPS-007`) é resolver o sintoma, não a causa.
- **DOC-011** — o próprio mecanismo de controle de progresso (o plano de ação) mentiu sobre o estado do código. Sem corrigir isso, nenhum checklist futuro é confiável.
- **OPS-008** — mudança barata (adicionar `recordError` nos catches de negócio) com alto retorno: hoje a equipe não sabe quais erros reais os usuários enfrentam.
- **UX-009** — confirmado com evidência de produção nesta sessão; usuários e suporte perdem tempo real por causa de uma mensagem errada.

### Aceitáveis a curto prazo (com justificativa)
- **ARQ-016, ARQ-017, ARQ-018** — impacto real baixo, não afetam corretude nem UX percebida; adiar até ciclo de "polish".
- **PERF-012, PERF-013** — otimizações pontuais sem sinal de jank reportado.
- **DOC-010** — decisão de organização, não bug.

---

## Recomendação de priorização

1. **Bloco de confiança em processo** (`SEC-001` + `DOC-011` + `OPS-007`) — sem um gate automatizado de secret-scanning, corrigir `SEC-001` de novo só adia a próxima regressão.
2. **`OPS-008`** — isolado, barato, e é pré-requisito prático para diagnosticar `UX-009` e qualquer bug futuro relatado por usuário.
3. **`UX-009`** — distinguir causas reais (config/auth vs. rede) no fluxo de playback; depende parcialmente de `OPS-008` estar em produção para validar a correção com dados reais.
4. **`ARQ-013`/`ARQ-014`** — fechar o débito residual de `ARQ-003`/`ARQ-005` antes de adicionar novas features ao fluxo de jogo.
5. **`OPS-012`** — decidir o destino de `0a`/`developer`/`refatore` (arquivar ou reintegrar) antes que mais trabalho seja perdido.
6. Débitos de Documentação (`DOC-003`, `DOC-004`, `DOC-006`, `DOC-009`) e Performance pontuais (`PERF-009` a `PERF-013`) podem ser tratados em paralelo, por serem baratos e não bloqueantes.

Ver sequenciamento detalhado por prazo em [4-ACTION_PLAN.md](4-ACTION_PLAN.md).
