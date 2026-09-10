# Plano de Ação — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-09
**Versão do documento:** 2.0 (reexecução completa — ver nota sobre `SEC-001` abaixo)

> Todos os itens referenciam o ID de origem definido em [1-ARCHITECTURAL_REVIEW.md](1-ARCHITECTURAL_REVIEW.md), [2-SECURITY_REPORT.md](2-SECURITY_REPORT.md) ou [3-TECH_DEBT_REGISTER.md](3-TECH_DEBT_REGISTER.md). Esforço e impacto não são redefinidos aqui.
>
> **Lição da v1.4 deste documento:** o item `SEC-001` foi marcado `[x]` em 2026-09-08 e, na prática, havia sido revertido no código ~15 minutos depois — sem que o checklist fosse atualizado. A partir desta versão, um item só é marcado `[x]` **depois** de confirmado diretamente no código/HEAD atual, não pela lembrança de que "já foi feito". Itens herdados da v1.4 foram todos reverificados nesta rodada (ver `Status` ao lado de cada um).

---

## Críticos (imediato — sprint atual)

- [x] **Remover `.env` do controle de versão de novo, restaurar `.gitignore`, e adicionar gate de secret-scanning ao CI** `[SEC-001 / OPS-007]` — Responsável: DevOps — Critério: `.env` não aparece em `git ls-files`; `.gitignore` contém a entrada; `.github/workflows/ci.yml` tem um step de detecção de segredos (ex. gitleaks) que quebraria o build se isso se repetir; Client ID rotacionado no Spotify Dashboard.
  - *Status: Reaberto. Confirmado nesta rodada que a correção da v1.4 foi revertida no commit `95ab2b9` e nunca reaplicada.*
  - *2026-09-09: `.env` removido do índice de novo (`git rm --cached .env`, arquivo continua no disco local) e `.gitignore` restaurado com a entrada — ambos ainda **não commitados**, aguardando o usuário revisar e commitar. Adicionado step `gitleaks/gitleaks-action@v2` em `.github/workflows/ci.yml` (com `fetch-depth: 0` no checkout), rodando antes de qualquer outro step para falhar rápido se um segredo for reintroduzido. **Pendente, fora do meu alcance:** rotacionar o Client ID no Spotify Developer Dashboard — o valor exposto no histórico do Git continua válido até isso ser feito manualmente.*
- [x] **Registrar erros tratados (`catch`) de negócio no Crashlytics** `[OPS-008]` — Responsável: Mobile — Critério: `connect_spotify_premium_view_model.dart:76`, `player_music_premium_view.dart:47` e `play_music_free_view.dart:86` chamam `FirebaseCrashlytics.instance.recordError(e, s, fatal: false)` antes ou ao invés de engolir a exceção.
  - *2026-09-09: os 3 pontos citados agora chamam `FirebaseCrashlytics.instance.recordError(e, s, fatal: false)` em vez de engolir a exceção — `disconnect()` (catch genérico), `dispose()` do player Premium (`SpotifySdk.pause().catchError(...)`) e `_saveToSpotify()` do player Free. Validado com `flutter analyze` (sem issues) e `flutter test` (59 testes passando). Não commitado ainda. Fora do escopo desta tarefa (não citados no critério original): outros catches silenciosos no restante do app (ex. `GameView`, `game_error_view.dart`) continuam sem telemetria.*
- [x] **Corrigir o processo de checklist do plano de ação** `[DOC-011]` — Responsável: quem revisar o PR que marca um item `[x]` — Critério: nenhum item é marcado concluído sem um comando/evidência reproduzível colado na nota do item (não just "lembro que fiz isso").
  - *2026-09-09: criado `.github/PULL_REQUEST_TEMPLATE.md` com uma seção obrigatória que pede evidência reproduzível por item marcado `[x]` neste plano de ação, mais um checklist de revisor que exige rodar/conferir essa evidência antes de aprovar. Isso dá ao critério um mecanismo que aparece automaticamente em todo PR (via template do GitHub), em vez de depender só de disciplina/memória — que foi exatamente o que falhou na v1.4. Limite reconhecido: o GitHub não bloqueia merge se a seção do template for deixada em branco; a garantia é de visibilidade no review, não um gate automatizado (diferente do `gitleaks` em `OPS-007`, que quebra o CI).*
- [x] **Diferenciar "sem internet" de "Spotify mal configurado/não autorizado" na tela de erro do jogo** `[UX-009]` — Responsável: Mobile — Critério: `MusicaPlaybackUseCase`/`GameView` propagam pelo menos 3 mensagens distintas (timeout de rede real, falha de autorização/config do Spotify, música não encontrada) em vez de uma única "verifique sua internet"; erro real é logado via `OPS-008` antes de qualquer decisão de UI.
  - *2026-09-09: criadas exceções de domínio `PlaybackNetworkException`/`PlaybackAuthException` (`lib/domain/exceptions/playback_exceptions.dart`) para não reintroduzir a dependência `domain`→`data` que o `ARQ-001`/`ARQ-002` corrigiram. `MusicaPlaybackRepositoryImpl._fetchPreview` (camada `data`, pode depender de `domain`) agora classifica `PlatformException`/`MissingPluginException` do `spotify_sdk` como falha de autorização, e `NetworkTimeoutException`/`NetworkConnectionException`/`InvalidServerResponseException` como falha de rede real — logando o erro original via `reportNonFatalError` (novo `lib/domain/error_reporting.dart`, usado também pelos 3 pontos do `OPS-008`) antes de relançar a exceção de domínio. `MusicaPlaybackUseCase` mapeia essas duas exceções para os novos códigos `musicaPlaybackSpotifyAuthErrorCode`/`musicaPlaybackUnexpectedErrorCode` (antes só existia `musicaPlaybackConnectionErrorCode` para tudo). `GameView` ganhou `_goToSpotifyAuthError()` ("SPOTIFY NÃO AUTORIZADO", com instrução de verificar app/conta) e `_goToUnexpectedError()` ("ALGO DEU ERRADO"), distintos de `_goToConnectionError()` (agora só sobre internet de verdade) e de `_goToMusicaNaoEncontrada()` (já existia, código 404). Total de 4 mensagens distintas para o fluxo de tocar música, mais a de "música não encontrada" do fluxo de busca — acima do mínimo de 3 pedido. Descoberto no processo: `FirebaseCrashlytics.instance` lança exceção se o Firebase não foi inicializado (caso de `flutter test`) — `reportNonFatalError` envolve a chamada em try/catch para que uma falha do próprio logging nunca mascare o erro original sendo tratado; sem isso, os novos testes que exercitam esse caminho quebravam. Validado com `flutter analyze --fatal-infos` (sem issues) e `flutter test` (65 testes passando, 6 novos). Não commitado ainda.*

---

## Curto prazo (≤4 semanas)

- [ ] Configurar keystore de produção e habilitar `isMinifyEnabled`/`isShrinkResources` no build de release Android `[SEC-011]` — Esforço: M — Impacto: Alto — Eixo: Segurança
- [ ] Centralizar a checagem de consentimento Spotify dentro de `SpotifyService` (não em cada tela chamadora) `[SEC-012]` — Esforço: M — Impacto: Médio — Eixo: Segurança/Compliance
- [ ] Decidir o destino das branches `0a`, `developer`, `refatore`: arquivar formalmente ou reintegrar o trabalho útil (`flutter_secure_storage` de `refatore`) antes de apagar `[OPS-012 / DOC-006]` — Esforço: M — Impacto: Médio — Eixo: Operações/Documentação
- [ ] Reaplicar disciplina de Conventional Commits com verificação (commitlint/hook), não só documentação `[DOC-005]` — Esforço: P (setup) + contínuo — Impacto: Médio — Eixo: Documentação
  - *Status: Reaberto — confirmado que o commit de topo da branch auditada (`6433da0`) ainda usa `...`, mesmo após a convenção ter sido documentada no README.*
- [ ] Extrair o controle de reprodução (play/pause/salvar faixa) de `player_music_premium_view.dart`/`play_music_free_view.dart` para um repository/usecase dedicado `[ARQ-013]` — Esforço: M — Impacto: Médio — Eixo: Fundamentos
- [ ] Mover orquestração de `GameView` (decisão de navegação de erro, coordenação dos 2 use cases) para uma `GameViewModel` real, injetada via construtor `[ARQ-014 / ARQ-019]` — Esforço: M — Impacto: Alto — Eixo: Fundamentos
- [ ] Adicionar retry/backoff simples (1-2 tentativas) nas chamadas de rede existentes (Spotify Web API, iTunes, Firestore) `[OPS-010]` — Esforço: M — Impacto: Médio — Eixo: Operações
- [ ] Tratar `429` da Web API do Spotify de forma distinta (respeitar `Retry-After`) `[PERF-010]` — Esforço: M — Impacto: Médio — Eixo: Performance
- [ ] Adicionar `formats: [BarcodeFormat.qrCode]` ao `MobileScannerController` `[PERF-011]` — Esforço: P — Impacto: Baixo — Eixo: Performance
- [ ] Adicionar cache em memória a `MusicaRepositoryImpl`, igual ao já existente em `MusicaPlaybackRepositoryImpl` `[PERF-009]` — Esforço: P — Impacto: Baixo — Eixo: Performance
- [ ] Corrigir typo "PREMIYM" em `spotify_free_transition.dart` `[UX-010]` — Esforço: P — Impacto: Baixo — Eixo: Experiência
- [ ] Padronizar tamanho mínimo (44x44) dos botões de fechar/voltar `[UX-011]` — Esforço: P — Impacto: Baixo — Eixo: Experiência

---

## Médio prazo (1–3 meses)

- [ ] Expandir cobertura de testes para os arquivos ainda não tocados (22/76 hoje) — priorizar `connect_spotify_premium_view_model.dart` e um teste de widget para `GameView` `[OPS-001]` — Esforço: G — Impacto: Alto — Eixo: Operações
- [ ] Avaliar viabilidade de testes de integração/e2e para o fluxo scan→música→player `[OPS-009]` — Esforço: G — Impacto: Alto — Eixo: Operações
- [ ] Avaliar fallback automático Premium→Free quando a conexão Spotify falhar (decisão de produto + implementação) `[OPS-011]` — Esforço: M — Impacto: Médio — Eixo: Produto/Operações
- [ ] Extrair helper genérico `_registerIfAbsent<T>()` no DI e garantir que `disposeFaqsModule()` seja de fato chamada (ou removê-la se não for necessária) `[ARQ-015]` — Esforço: M — Impacto: Médio — Eixo: Fundamentos
- [ ] Adicionar gate de cobertura mínima e um step de build de artefato ao CI `[OPS-007]` — Esforço: P — Impacto: Médio — Eixo: Operações
- [ ] Otimizar assets de imagem (compressão, WebP) `[PERF-004]` — Esforço: M — Impacto: Médio — Eixo: Performance
- [ ] Remover os 3 pesos de fonte Montserrat não utilizados (w100/w200/w500) `[PERF-012]` — Esforço: P — Impacto: Baixo — Eixo: Performance
- [ ] Adicionar `Semantics`/labels de acessibilidade nas telas principais `[UX-003]` — Esforço: M — Impacto: Alto — Eixo: Experiência
- [ ] Padronizar 100% das telas para usar `ColorManager`/`style_manager`/`AppPadding` `[UX-001]` — Esforço: M — Impacto: Médio — Eixo: Experiência
- [ ] Introduzir checklist/lint de contraste WCAG AA para o dark theme `[UX-004]` — Esforço: P — Impacto: Médio — Eixo: Experiência
- [ ] Substituir dimensões fixas (320x320) por `LayoutBuilder`/`AspectRatio` nos cards de player `[UX-005]` — Esforço: M — Impacto: Médio — Eixo: Experiência
- [ ] Criar `CHANGELOG.md` e adotar tags semver a partir da próxima versão `[DOC-004]` — Esforço: P — Impacto: Médio — Eixo: Documentação
- [ ] Registrar as primeiras 3-5 ADRs retroativas `[DOC-003]` — Esforço: M — Impacto: Baixo — Eixo: Documentação
- [ ] Definir cadência de revisão periódica destes 5 documentos (ex.: a cada release) `[DOC-009]` — Esforço: P (processo) — Impacto: Médio — Eixo: Documentação
- [ ] Popular ou remover as pastas vazias `docs/melhorias/*` `[DOC-010]` — Esforço: P — Impacto: Baixo — Eixo: Documentação

---

## Longo prazo (3–12 meses)

- [ ] Unificar tratamento de erro do app inteiro sob `Either<Failure, T>`, incluindo o fluxo Spotify/iTunes `[ARQ-006]` — Esforço: G — Impacto: Médio — Eixo: Fundamentos
- [ ] Avaliar migração de `setState` para uma solução reativa (Provider/Riverpod/Bloc) se a árvore continuar crescendo `[PERF-008]` — Esforço: G — Impacto: Médio — Eixo: Performance
- [ ] Implementar suporte a tablet com breakpoints reais `[UX-005]` (parte de escopo grande) — Esforço: G — Impacto: Baixo-Médio — Eixo: Experiência
- [ ] Configurar iOS de forma completa e publicar nas lojas — Esforço: G — Impacto: Alto — pré-requisito de negócio
- [ ] Avaliar Firebase App Check para a coleção `musicas` `[SEC-004]` (sugestão) — Esforço: M — Impacto: Baixo — Eixo: Segurança
- [ ] Estabelecer política formal de atualização de dependências (Dependabot/Renovate) `[DOC-007 / SEC-010]` — Esforço: P (setup) — Impacto: Médio — Eixo: Documentação/Segurança

---

## Observação sobre sequenciamento

O bloco Crítico desta versão é deliberadamente pequeno e sequencial: **SEC-001+OPS-007 → OPS-008 → DOC-011 → UX-009**. A ordem importa: corrigir o `.env` com um gate automatizado evita a terceira regressão; ter `OPS-008` em produção antes de mexer em `UX-009` permite medir com dados reais quais causas de erro são mais comuns antes de decidir como reescrever as mensagens; `DOC-011` é sobre processo, não código, e pode rodar em paralelo aos demais.

**Progresso herdado da v1.4 (reverificado nesta rodada):**
- ✅ Confirmados como de fato resolvidos no código atual: `ARQ-001`, `ARQ-002`, `ARQ-003`, `ARQ-004`, `ARQ-007`, `ARQ-008`/`UX-002`, `ARQ-009`/`SEC-002`, `OPS-002`, `OPS-004`/`PERF-001`, `PERF-003`, `SEC-009`, `DOC-001`/`DOC-002`.
- ⚠️ Marcado `[x]` na v1.4 mas **reaberto** nesta rodada: `SEC-001` (revertido no código), `DOC-005` (convenção não sobreviveu no histórico de commits).
- 🟡 Marcado `[x]` na v1.4 mas com lacuna relevante descoberta agora: `OPS-001` (testes existem, mas cobrem só ~30% dos arquivos), `OPS-003` (Crashlytics integrado, mas só para exceções não tratadas — ver `OPS-008`).
