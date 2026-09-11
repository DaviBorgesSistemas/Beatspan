# Beatspan — Architectural Review

**Data da análise:** 2026-09-10
**Versão do documento:** 2.0 (reanálise completa, substitui a versão anterior)
**Commit analisado:** `8f2ae1e` (branch `beatspan_v2`)

> Gerado a partir de `guides/prompts/PROMPT_ANALISE_ARQUITETURAL.md`. Esta é uma reanálise do zero — os IDs deste documento **não** correspondem aos IDs da versão anterior dos documentos em `docs/`.

---

## 1. Visão geral do projeto

Beatspan é um app Flutter (Android apenas — não há diretório `ios/`) que acompanha um jogo de cartas físico no estilo Hitster. Cada carta traz um QR code apontando para `beatspangame.com/<código>`; o app resolve o código no Firestore (coleção `musicas`) para um `spotify_uri` e reproduz a faixa — via Spotify App Remote (Premium) ou prévia de 30s (Free, com fallback para iTunes Search API).

**Estado do projeto:** pré-lançamento, ativo. 89 arquivos Dart em `lib/` (~7.600 linhas), 18 arquivos de teste em `test/` (~2.450 linhas), plataforma única (Android).

### Stack identificada

| Categoria | Tecnologia |
|---|---|
| Framework | Flutter (SDK `^3.9.2`) |
| Injeção de dependência | `get_it` |
| Result/Either | `dartz` |
| Persistência local | `shared_preferences` |
| Config por ambiente | `flutter_dotenv` |
| Backend | `firebase_core`, `cloud_firestore` (sem backend próprio) |
| Observabilidade | `firebase_crashlytics` |
| Integração Spotify | `spotify_sdk` (App Remote) + Web API via `http` |
| QR / câmera | `mobile_scanner`, `permission_handler` |
| Áudio local | `just_audio` |
| Imagens | `cached_network_image` |
| CI | GitHub Actions (`ubuntu-latest`) |

---

## 2. Análise por eixo

### 2.1 Fundamentos

O projeto segue uma **Clean Architecture simplificada**: `presentation/` organizada por feature, `domain/` e `data/` genéricos por toda a aplicação. Os fluxos de Música (Firestore) e FAQ implementam a stack completa — `repository` abstrato em `domain/`, implementação em `data/`, `usecase` intermediando, `datasource` isolando a fonte de dados concreta. Essa separação é real e testável: todos os repositórios e use cases têm testes dedicados com `mocktail`.

~~O ponto de atrito estava no fluxo de reprodução dentro de `GameView`/`PlayerMusic*View`: em vez de resolver `PreviewPlaybackUseCase` via `get_it`, a view construía a cadeia diretamente~~ (**ARQ-001**, **resolvido**: `GameView` agora usa `instance<PreviewPlaybackUseCase>()`, consistente com o resto do app).

O modelo de erro do domínio (`Failure`, um simples `{code: int, message: String}`) é genérico demais para o número de fluxos que o usam: cada use case define suas próprias constantes `int` para código de erro, e esses códigos colidem entre domínios — `1` significa "erro de autorização do Spotify" em `SpotifyPlaybackUseCase`, mas "URI inválida" em `MusicaPlaybackUseCase` (**ARQ-002**). Hoje isso não causa bug porque cada `Either<Failure, T>` é consumido no mesmo arquivo onde o código é definido, mas é uma armadilha para quem reaproveitar um `Failure` fora desse contexto.

Um ponto de correção genuína: `GameView._onDetect` lê `capture.barcodes.first` sem checar se a lista está vazia (**ARQ-003**) — se o `mobile_scanner` emitir um `BarcodeCapture` sem detecções (frame de transição, formato não reconhecido antes do filtro), isso lança uma exceção não tratada.

~~A feature de idioma/país (enums `LanguageType`, `CountryType`...) não tinha nenhum ponto de leitura no app~~ (**ARQ-005**, **resolvido**: decisão de produto confirmada — app é só em português; os enums, getters/setters e a rota morta `/language` foram removidos do código e do README).

**Pontos fortes:**
- **ARQ-S1** — Separação consistente domain/data/presentation nos fluxos principais, com contratos abstratos (`MusicaRepository`, `FaqRepository`) e testes de unidade por camada.
- **ARQ-S2** — Exceções tipadas por camada (`MusicaConsultaException`, `PlaybackAuthException`, `NetworkTimeoutException`...) em vez de `catch (e)` genérico espalhado pelo app.

### 2.2 Segurança e Compliance

O perímetro de dados do app é pequeno por design: não há conta de usuário própria, não há PII armazenada em backend próprio. Os dados sensíveis que existem são (a) credenciais do Spotify do desenvolvedor (`.env`), (b) config do Firebase e (c) o token OAuth do Spotify do jogador, que nunca passa pelo app — é gerenciado pelo próprio Spotify SDK.

```
// firestore.rules — coleção `musicas`
match /musicas/{codigo} {
  allow read: if true;
  allow write: if false;
}
match /{document=**} {
  allow read, write: if false;
}
```

Essa regra é correta para o caso de uso (o app precisa ler o catálogo sem autenticar o jogador) e fecha tudo o mais por padrão — **SEC-S1**.

`.env`, `android/key.properties` e `*.jks`/`*.keystore` estão no `.gitignore` e confirmei via `git ls-files` que nenhum desses arquivos reais está versionado — só os `.example`/`.properties.example` (**SEC-S2**). O consentimento do Spotify é verificado no nível de serviço (`SpotifyService._ensureConsent()`), não só na UI — qualquer chamada ao SDK sem consentimento aceito lança `SpotifyConsentRequiredException` antes de tentar conectar (**SEC-S3**). O CI roda `gitleaks` em todo push/PR (**SEC-S4**), e o build de release Android tem assinatura de produção configurável + `isMinifyEnabled`/`isShrinkResources`/ProGuard habilitados (**SEC-S5**).

Dois arquivos com dados de configuração do Firebase estão versionados no Git: `android/app/google-services.json` e `lib/firebase_options.dart` (confirmado via `git ls-files`, ambos contêm `api_key`/`project_id`). Isso é prática comum em projetos Firebase — essas chaves não são segredos de servidor, e a fronteira de segurança real são as Firestore Rules (já auditadas como sólidas acima). Mas exige uma confirmação que não é possível fazer a partir do repositório: se a API key está restrita por assinatura/pacote no Google Cloud Console (**SEC-001**).

O build de release cai silenciosamente para a assinatura de **debug** quando `android/key.properties` não existe — sem erro, sem warning de build:

```kotlin
// android/app/build.gradle.kts
signingConfig = if (hasKeystoreProperties) {
    signingConfigs.getByName("release")
} else {
    signingConfigs.getByName("debug")
}
```

Isso é deliberado (mantém `flutter build apk --debug`/CI funcionando sem a keystore de produção, conforme o comentário no próprio arquivo), mas significa que um pipeline de release mal configurado pode publicar um artefato assinado com a chave de debug sem que ninguém note (**SEC-002**).

~~Não há scan de dependências automatizado no CI.~~ **Resolvido**: `.github/workflows/ci.yml` ganhou um job `osv-scan` usando o workflow reutilizável oficial do OSV-Scanner (Linux), escaneando `pubspec.lock` em todo push/PR (**SEC-003**). O script local `scripts/scan_dependencies.sh` (binário Windows) continua existindo para uso manual. Não executei o scanner de fato nesta sessão (o job roda no GitHub Actions, não localmente); o status real das dependências (CVEs) só será conhecido na primeira execução real do CI após o merge.

Ver `docs/2-SECURITY_REPORT.md` para o detalhamento completo, severidades e checklist LGPD/GDPR.

### 2.3 Experiência

**UX:** o fluxo principal (escanear → resolver → tocar) é direto e as mensagens de erro são específicas e em português claro (ex.: "PRÉVIA INDISPONÍVEL... Tente outra carta ou use o Spotify Premium", em `game_viewmodel.dart`). O diálogo de consentimento do Spotify explica objetivamente o que é acessado e linka a política de privacidade antes do aceite — boa prática de transparência (**EXP-S1**).

**Acessibilidade:** nenhum arquivo em `lib/presentation` usa `Semantics(` ou `Tooltip(` — confirmado por busca textual no diretório inteiro (0 ocorrências de ambos). Botões customizados são `GestureDetector`/`InkWell` sobre `Container`s estilizados (ex.: `spotify_consent_dialog.dart`, `first_time_view.dart`), sem rótulo explícito para leitor de tela. Para um app que depende de interações de toque rápidas durante uma partida física, isso é uma lacuna real de WCAG — qualquer jogador usando TalkBack não consegue operar o app (**EXP-001**).

**Design system:** `lib/presentation/resource/color_manager.dart` e `theme_manager.dart` centralizam cores/tema, mas 18 arquivos em `presentation/` usam `Color(0x...)` hardcoded fora desses managers (ex.: `first_time_view.dart` linhas 73, 85, 99-116) — inconsistência que torna uma mudança de paleta de marca mais arriscada do que deveria ser (**EXP-002**).

**DX:** onboarding é bem suportado pelo README (setup de `.env`, Firebase, comandos via `rps.yaml`), convenção de commits aplicada por hook local opcional + CI obrigatório, e a estrutura de pastas é previsível (**EXP-S2**).

### 2.4 Operações e Confiabilidade

**Testabilidade:** 18 arquivos de teste cobrem principalmente `domain/usecase` e `data/repository`, com uso correto de `mocktail` e casos de borda (ex.: `musica_playback_usecase_test.dart` testa 7 cenários distintos, incluindo exceções não classificadas). O relatório `coverage/lcov.info` lido na primeira versão desta análise mostrava 49,8% (259/520) sobre só 22 arquivos instrumentados, com `spotify_service.dart` e `musica_firestore_data_source.dart` em 0% — mas esse `lcov.info` estava desatualizado (não refletia testes já presentes em `test/`, ex. `game_view_test.dart`). **Atualização (regerado com `flutter test --coverage` nesta sessão):** `musica_firestore_data_source.dart` já estava coberto por um teste dedicado (23/24 linhas, 96%) — o 0% inicial era só do relatório obsoleto. `spotify_service.dart` estava genuinamente em 0%; ganhou `test/data/network/spotify_service_test.dart` (consentimento negado nos 3 métodos + verificação de que o consentimento aceito de fato alcança o `spotify_sdk`), agora em 18/20 (90%) — ver **OPS-001**, já resolvido. Com mais arquivos agora instrumentados, o agregado real é 753/2705 (27,8%); `faq_local_data_source.dart` (0/5) e `player_music_premium_view.dart` (cobertura parcial) continuam como lacunas reais, não cobertas por este item.

**CI/CD:** pipeline único (`.github/workflows/ci.yml`) roda em todo push para `master`/`beatspan_v2` e PR: gitleaks, validação de Conventional Commits, `flutter analyze --fatal-infos`, `dart format --set-exit-if-changed`, `flutter test`. Não gera artefato de build (APK/AAB) nem publica cobertura — é um gate de qualidade, não um pipeline de entrega (**OPS-002**, razoável para o estágio atual, mas vale nomear a lacuna).

**Observabilidade:** Crashlytics integrado com um wrapper (`reportNonFatalError`) que captura erro+stacktrace sem deixar uma falha do próprio Crashlytics mascarar o erro original — detalhe de engenharia maduro (**OPS-S3**). Mas o uso não é uniforme: `faqs_view_model.dart:27` e `session_tile.dart:101` usam `debugPrint` simples em vez de `reportNonFatalError`, perdendo visibilidade desses erros em produção (builds de release descartam `debugPrint`) (**OPS-003**). Não há analytics de produto (funil de jogo, taxa de erro de QR, taxa de fallback iTunes) — aceitável em pré-lançamento, mas deveria entrar no roadmap antes do lançamento (**OPS-004**).

**Resiliência:** ponto forte do projeto. `lib/data/network/retry.dart` implementa retry com backoff, com distinção clara entre erro transitório (timeout/conexão — vale repetir) e erro definitivo (resposta de erro do servidor, JSON malformado — repetir não ajuda), reaplicado em `MusicaFirestoreDataSource`, `SpotifyWebApi` e `ItunesSearchApi`, e testado em `retry_test.dart` (**OPS-S1**). `SpotifyWebApi` trata rate limit (HTTP 429) respeitando o header `Retry-After` com um limite de espera máximo configurável.

**Custo em cloud:** arquitetura serverless (Firestore + Firebase Hosting, sem servidor próprio) — sem infraestrutura own para provisionar/custear além dos limites de uso do Firebase, que cresce com uso real. Nenhum padrão de leitura custoso identificado (ver 2.6).

### 2.5 Documentação e Governança

`README.md`/`README.en.md` são bem mantidos, com arquitetura, fluxo do jogo, setup de Spotify/Firebase e convenção de commits documentados — acima da média para um projeto deste porte (**DOC-S1**). Há `.github/PULL_REQUEST_TEMPLATE.md` e o CI impõe Conventional Commits (**DOC-S2**).

Uma afirmação do README está desatualizada: a seção "Status do projeto" diz "Sem observabilidade/crash reporting em produção (Crashlytics/Sentry)", mas `firebase_crashlytics` já está integrado e ativo (`lib/domain/error_reporting.dart`, dependência em `pubspec.yaml`, commit `557ebee feat: integra Firebase Crashlytics`) (**DOC-001**).

Não há `CHANGELOG.md` nem tags Git (`git tag -l` vazio) apesar de `pubspec.yaml` declarar `version: 1.0.0+1` — não há como saber, a partir do repositório, o que mudou entre uma versão e outra (**DOC-002**). O histórico de commits anterior à adoção de Conventional Commits usa mensagens genéricas (`...`, `,,,,`, nomes de tela soltos) e não foi reescrito — decisão deliberada e documentada no próprio README (reescrever histórico público traria mais risco/custo do que benefício) (**DOC-004**). Não há ADRs registrando decisões de arquitetura (por que Clean Architecture simplificada, por que `dartz`/Either em vez de exceptions, por que sem backend próprio) — essas decisões só aparecem como comentários pontuais no código (**DOC-003**).

### 2.6 Performance e Escalabilidade

A busca de música no Firestore é por chave de documento (`_firestore.collection('musicas').doc(codigo).get()`), não por query com filtro — leitura O(1) indexada por padrão, sem necessitar índices compostos (`firestore.indexes.json` está vazio, coerente com isso) (**PERF-S1**). `cached_network_image` evita redownload/redecodificação de artes de álbum já vistas (**PERF-S2**).

Dois caches em memória (`MusicaRepositoryImpl._cache`, `MusicaPlaybackRepositoryImpl._previewCache`) não têm TTL nem limite de tamanho — crescem enquanto a sessão do app durar. Para uma sessão de jogo física (dezenas/centenas de cartas), o impacto de memória é desprezível hoje; é um padrão que não escala se o volume por sessão crescer ordens de magnitude, mas não é urgente (**PERF-001**).

Não há backend próprio sob controle do time para otimizar — a escala horizontal é delegada ao Firebase e ao Spotify. Os únicos limites de contenção possíveis (quota de leitura do Firestore, rate limit da Web API do Spotify) já são tratados no código-cliente com retry/backoff (ver OPS-S1) (**PERF-002**, informativo).

---

## 3. Tabela de pontuações

| Eixo | Nota | Justificativa |
|---|---|---|
| Fundamentos | 7/10 | Separação de camadas real e testada nos fluxos principais; debt concentrado em inconsistência de DI, modelo de erro genérico demais e uma feature morta (idioma/país) |
| Segurança | 7/10 | Controles corretos onde importam (Firestore rules, gitignore, consentimento, gitleaks); gaps de verificação (API key do Firebase, scan de dependências) e um fallback de assinatura silencioso |
| Experiência | 5/10 | UX funcional e textos claros, mas zero acessibilidade (WCAG) em toda a base e inconsistência de design tokens |
| Operações | 6/10 | CI real e resiliência de rede exemplar; cobertura de testes baixa e não gated concentrada fora dos caminhos críticos do jogo |
| Documentação | 7/10 | Acima da média para o porte do projeto, com uma afirmação desatualizada e ausência de changelog/ADRs |
| Performance | 7/10 | Arquitetura serverless bem desenhada para o caso de uso atual; únicos riscos são de baixa severidade e não urgentes |

**Escore geral: 6,8/10**

---

## 4. Pontos fortes, atenções e críticos

### Pontos fortes
| ID | Descrição | Evidência |
|---|---|---|
| ARQ-S1 | Clean Architecture consistente nos fluxos de Música/FAQ | `lib/domain/repository/`, `lib/data/repository/` |
| ARQ-S2 | Exceções tipadas por camada | `lib/domain/exceptions/`, `lib/data/network/network_exceptions.dart` |
| SEC-S1 | Firestore rules restritivas por padrão | `firestore.rules:18-26` |
| SEC-S2 | Segredos reais corretamente fora do Git | `.gitignore:50-56` |
| SEC-S3 | Consentimento Spotify aplicado no serviço | `lib/data/network/spotify_service.dart:21-25` |
| SEC-S4 | Gitleaks no CI | `.github/workflows/ci.yml` |
| SEC-S5 | Assinatura de release + minify/shrink/ProGuard | `android/app/build.gradle.kts:55-76` |
| EXP-S1 | Diálogo de consentimento transparente | `lib/presentation/change_spotify/widgets/spotify_consent_dialog.dart:43-63` |
| EXP-S2 | Onboarding de dev bem documentado | `README.md` |
| OPS-S1 | Retry/backoff testado e reaplicado | `lib/data/network/retry.dart` |
| OPS-S2 | Pipeline de CI real (analyze/format/test/gitleaks/commits) | `.github/workflows/ci.yml` |
| OPS-S3 | Wrapper de Crashlytics que não mascara erro original | `lib/domain/error_reporting.dart` |
| DOC-S1 | README bilíngue e detalhado | `README.md`, `README.en.md` |
| DOC-S2 | PR template + Conventional Commits aplicado | `.github/PULL_REQUEST_TEMPLATE.md` |
| PERF-S1 | Leitura Firestore O(1) por chave de documento | `lib/data/network/musica_firestore_data_source.dart:37-40` |
| PERF-S2 | `cached_network_image` para artes de álbum | `pubspec.yaml` |

### Atenções
| ID | Descrição | Evidência |
|---|---|---|
| ARQ-001 | ~~Bypass do padrão de DI no fluxo de preview~~ — **resolvido** | `lib/presentation/game/game_view.dart` |
| ARQ-002 | Códigos de erro de `Failure` colidem entre use cases | `lib/domain/usecase/{spotify_playback,musica_playback,preview_playback}_usecase.dart` |
| ARQ-004 | Boilerplate repetitivo de registro no DI | `lib/app/di.dart` |
| ARQ-005 | ~~Idioma/país persistidos mas nunca lidos de volta~~ — **resolvido** (removido; app é só em português) | `lib/app/app_prefs.dart`, `lib/domain/enum/settings_enum.dart` |
| ARQ-006 | `exit(1)` para encerrar o app em vez de `SystemNavigator.pop()` | `lib/presentation/first_time/first_time_view.dart:35`, `lib/presentation/home/home_view.dart:38` |
| SEC-001 | Config Firebase versionada — API key sem restrição confirmada | `android/app/google-services.json`, `lib/firebase_options.dart` |
| SEC-002 | Fallback silencioso para assinatura de debug | `android/app/build.gradle.kts:67-73` |
| SEC-003 | ~~Sem scan de dependências no CI~~ — **resolvido**: job `osv-scan` adicionado | `.github/workflows/ci.yml` |
| SEC-004 | Retenção de dados do Crashlytics não documentada | — (requer revisão jurídica) |
| EXP-002 | 18 arquivos com cor hardcoded fora do design system | ex.: `lib/presentation/first_time/first_time_view.dart` |
| EXP-003 | Botões customizados sem rótulo/role explícito | `spotify_consent_dialog.dart`, `first_time_view.dart` |
| OPS-002 | CI não gera/gateia cobertura de testes | `.github/workflows/ci.yml` |
| OPS-003 | `debugPrint` em vez de `reportNonFatalError` em 2 pontos | `faqs_view_model.dart:27`, `session_tile.dart:101` |
| OPS-004 | Sem analytics de produto | — |
| DOC-001 | README desatualizado sobre Crashlytics | `README.md:139` |
| DOC-002 | Sem CHANGELOG/tags | `git tag -l` vazio |
| DOC-004 | Histórico de commits pré-Conventional Commits não reescrito (aceito, não é uma falha) | `git log --oneline`, `README.md` |
| DOC-003 | Sem ADRs | — |
| PERF-001 | Caches em memória sem TTL/limite | `musica_repository_impl.dart:18`, `musica_playback_repository_impl.dart:24` |

### Críticos
| ID | Descrição | Evidência |
|---|---|---|
| ARQ-003 | `barcodes.first` sem checar lista vazia — crash potencial ao escanear | `lib/presentation/game/game_view.dart:76` |
| EXP-001 | Zero acessibilidade (`Semantics`/`Tooltip`) em todo o app | busca em `lib/presentation` (0 ocorrências) |
| OPS-001 | ~~Cobertura de testes baixa e concentrada fora dos caminhos críticos~~ — **resolvido**: `spotify_service.dart` e `musica_firestore_data_source.dart` agora cobertos (90%/96%) | `coverage/lcov.info`, `test/data/network/spotify_service_test.dart` |

---

## 5. Cobertura da análise — o que não foi investigado em profundidade

- **Scan de vulnerabilidades de dependências**: não executei o OSV-Scanner nem `dart pub outdated` nesta sessão. O script `scripts/scan_dependencies.sh` existe mas não foi rodado — ver SEC-003.
- **Conteúdo integral da política de privacidade/termos**: li por amostragem de palavras-chave (`hosting/privacidade/index.html`, 282 linhas), não linha a linha contra cada requisito LGPD/GDPR. Recomenda-se revisão jurídica dedicada antes de tratar o checklist da seção 2.2/SECURITY_REPORT como suficiente.
- **Build/configuração iOS**: não existe (`ios/` ausente do repositório) — não avaliado porque não há o que avaliar.
- **Testes de widget/integração end-to-end do fluxo completo de jogo**: avaliados pela leitura dos arquivos de teste existentes, não executados nesta sessão (não é objetivo desta análise rodar a suíte).
- **Conteúdo real de `.env`**: não lido, por conter potenciais credenciais reais (só `.env.example` foi inspecionado).
