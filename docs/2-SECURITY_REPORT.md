# Beatspan — Security Report

**Data da análise:** 2026-09-11
**Versão do documento:** 3.0 (reanálise completa do zero, substitui a versão 2.0)
**Commit analisado:** `577dd0c` (branch `beatspan_v2`)

> Referencia os IDs `SEC-xxx` já levantados em `docs/1-ARCHITECTURAL_REVIEW.md` (seção 2.2), mais detalhamento completo aqui. Metodologia: leitura direta do código, `git log`/`git ls-files` no histórico completo, execução real de `flutter pub outdated` e `osv-scanner.exe --lockfile=pubspec.lock` (133 pacotes escaneados) nesta sessão. Nenhum valor real de segredo é reproduzido neste documento.

---

## 1. Vulnerabilidades por severidade

### Alta

Nenhum achado de severidade Alta confirmado nesta reanálise. O achado que poderia ser classificado como Alta (`SEC-001`, segredo no histórico git) foi rebaixado para Média após confirmação de que o repositório é privado — ver detalhamento abaixo.

### Média

**SEC-001 — `SPOTIFY_CLIENT_ID` esteve versionado em `.env` e permanece alcançável no histórico git**

- **Localização:** `.env` (removido do tracking em `9d66a14`, mas presente nos commits `0d5d678` e `95ab2b9`, ambos ancestrais de `HEAD` na branch `beatspan_v2`).
- **Descrição:** o commit `9d66a14` ("security: remove .env do controle de versão") já removeu o arquivo do tracking atual, mas não reescreveu o histórico — o valor do `SPOTIFY_CLIENT_ID` continua recuperável por qualquer pessoa com acesso de leitura ao repositório e ao histórico completo (`git log -p` num commit antigo).
- **Verificação de impacto real feita nesta sessão:** `GET https://api.github.com/repos/davicezarborgesdeveloper/Beatspan` (sem autenticação) retornou `404` — indicativo de que o repositório é **privado** (um repositório público retornaria `200` com metadados via API sem necessidade de token). Isso reduz drasticamente a superfície de exposição real.
- **Fator atenuante adicional:** um `client_id` OAuth de app mobile (fluxo PKCE, sem `client_secret` associado) não é, por design do próprio protocolo OAuth, uma credencial que exija sigilo absoluto — ele trafega em toda autorização e é visível em logs de rede do próprio dispositivo do usuário final. Não é equivalente a uma chave de API de servidor ou a um `client_secret` confidencial.
- **Impacto potencial (se o repositório se tornasse público no futuro):** alguém poderia usar o `client_id` para tentar se passar pela aplicação Beatspan em fluxos OAuth do Spotify — mitigável pelo próprio Spotify via validação de `redirect_uri` registrada.
- **Recomendação:**
  1. Confirmar formalmente (via configurações do GitHub, não só inferência de API) que o repositório é e continuará privado.
  2. Se o repositório for tornado público em algum momento (ex.: para portfolio), rotacionar o `SPOTIFY_CLIENT_ID` no dashboard do Spotify Developer antes disso.
  3. Documentar essa decisão de risco residual (não reescrever histórico) explicitamente neste relatório — feito agora, nesta seção.

**SEC-002 — Nenhum mecanismo de revogação de consentimento do Spotify dentro do app**

- **Localização:** `lib/app/app_prefs.dart:60-66` (`setSpotifyConsentAccepted`), único call site em `lib/presentation/settings/settings_view.dart:61`.
- **Descrição:** existe API para aceitar o consentimento, mas nenhuma ação de UI para revogá-lo (setar `false`). A política de privacidade orienta o usuário a revogar via `spotify.com/account/apps`, mas isso só invalida o token no lado do Spotify — a flag local `hasAcceptedSpotifyConsent()` continua `true`, e o app se comporta como se o consentimento seguisse ativo.
- **Impacto:** o usuário não tem, dentro do próprio app, uma forma de "desconectar" de fato — inconsistente com o princípio de facilidade de revogação equivalente à de concessão (LGPD art. 8º, §5º e §6º).
- **Recomendação:** adicionar um botão "Desconectar Spotify" em Configurações que chame `setSpotifyConsentAccepted(false)` e `SpotifyService.disconnect()` (método já existe em `spotify_service.dart:54`, apenas não é exposto na UI).

**SEC-003 — Backup automático do Android não desabilitado explicitamente**

- **Localização:** `android/app/src/main/AndroidManifest.xml` (sem `android:allowBackup="false"` nem `android:dataExtractionRules`).
- **Descrição:** o padrão do Android é `allowBackup=true`, incluindo `SharedPreferences` (flag de consentimento Spotify, preferências de jogo) em backups automáticos do Google/Android.
- **Impacto:** baixo em termos de sensibilidade do dado em si (confirmado que não há PII/token persistido localmente), mas contradiz a promessa da política de privacidade (seção 2.3): "preferências... não são transmitidas a nós nem a terceiros" — tecnicamente, com `allowBackup` padrão, elas podem sair do dispositivo via backup do sistema, o que a política não menciona.
- **Recomendação:** adicionar `android:allowBackup="false"` ou `dataExtractionRules` explícitas alinhando comportamento real à promessa da política.

**SEC-004 — Canal de contato para exercício de direitos LGPD não implementado no app**

- **Localização:** `lib/presentation/contact/contact_view.dart` (placeholder vazio, roteado em `routes_manager.dart:76`).
- **Descrição:** o único canal de contato funcional para exercício de direitos (LGPD art. 18) é o e-mail citado na política de privacidade. A tela dedicada dentro do app está vazia, apesar de roteada e listada como funcionalidade em `README.md`/`README.en.md`.
- **Impacto:** inconsistência entre o que é documentado como entregue e o que está implementado — pode confundir uma auditoria de compliance que verifique o app e encontre uma tela de contato sem conteúdo. Também tratado como achado de Experiência (`EXP-003`, crítico) por ser uma feature "fantasma" na UX.
- **Recomendação:** implementar a tela de fato (mesmo que só linkando o e-mail/WhatsApp) ou remover a rota/menção até que exista.

**SEC-005 — Dependências desatualizadas, incluindo uma transitiva retracted**

- **Localização:** `pubspec.yaml`/`pubspec.lock`.
- **Descrição (verificado nesta sessão via `flutter pub outdated`):** `path_provider_foundation` está travado em `2.5.0`, marcada como **retracted** (retirada do pub.dev pelo mantenedor). Além disso, 18 dependências diretas têm versões mais novas disponíveis, 8 delas com major version nova: `cached_network_image` 3.4.1→4.0.0, `cloud_firestore` 5.6.12→6.9.0, `connectivity_plus` 6.1.5→7.3.1, `firebase_analytics` 11.6.0→12.5.0, `firebase_core` 3.15.2→4.14.0, `firebase_crashlytics` 4.3.10→5.3.0, `permission_handler` 11.4.0→13.0.2, `spotify_sdk` 3.0.2→4.0.0.
- **Verificação de vulnerabilidade real:** `osv-scanner.exe --lockfile=pubspec.lock` rodado nesta sessão contra os 133 pacotes resolvidos retornou **"No issues found"** — nenhuma CVE confirmada em nenhuma dessas versões atuais.
- **Severidade:** Média por ser risco de manutenibilidade/suporte (uma versão retracted pode ser removida do pub.dev a qualquer momento, quebrando builds futuros), não por vulnerabilidade confirmada.
- **Recomendação:** priorizar a saída da versão retracted (via `flutter pub upgrade` da dependência que a puxa transitivamente) e planejar upgrade das majors em branch dedicada com regressão completa de testes.

### Baixa

**SEC-006 — Sem rate limiting/anti-abuso para leitura pública da coleção `musicas`**

- **Localização:** `firestore.rules:18-21` (`allow read: if true`, sem limitação de taxa).
- **Descrição:** o Firestore não suporta rate limiting nativo em Rules; isso dependeria de Firebase App Check ou Cloud Functions intermediárias, nenhum dos quais está em uso (confirmado: sem `app_check` em `pubspec.yaml`).
- **Impacto:** baixo — o catálogo é público por design (qualquer jogador lê qualquer código de carta válido) e não contém dado sensível, mas um scraping completo do catálogo (todos os `spotify_id`/`spotify_uri`) é tecnicamente possível enumerando códigos.
- **Recomendação:** avaliar Firebase App Check apenas se o catálogo completo for considerado informação de negócio sensível a proteger de concorrentes.

**SEC-007 — Retenção de dados do Analytics/Crashlytics documentada mas pendente de validação jurídica formal**

- **Localização:** `hosting/privacidade/index.html`, seções 2.2 e 5.
- **Descrição:** o texto já cobre tecnicamente Crashlytics (90 dias) e Analytics (14 meses), com links para a política do Firebase, e é coerente com o que o código de fato coleta (verificado: nenhum parâmetro de evento identifica o usuário — ver SEC-S8 abaixo). O texto é declaradamente um rascunho de engenharia, não uma peça revisada por advogado.
- **Recomendação:** já registrada nos planos de ação anteriores (`SEC-004`/`OPS-004` da v2.0) — segue pendente como item de processo, não de código.

---

## 2. Pontos fortes de segurança

| ID | Descrição | Evidência |
|---|---|---|
| SEC-S1 | Firestore Rules deny-by-default: única coleção legível é `musicas` (leitura pública, escrita sempre negada); tudo o mais bloqueado | `firestore.rules:18-26` |
| SEC-S2 | Build de release falha explicitamente sem `key.properties`, eliminando o fallback silencioso para assinatura de debug identificado na análise anterior | `android/app/build.gradle.kts:24-33` |
| SEC-S3 | Consentimento do Spotify verificado na camada de serviço (`_ensureConsent()`), não contornável pulando uma tela de UI | `lib/data/network/spotify_service.dart:21-25,28,39,49` |
| SEC-S4 | Diálogo de consentimento específico, não dispensável sem escolha (`barrierDismissible: false`), com finalidades listadas e link à política | `lib/presentation/change_spotify/widgets/spotify_consent_dialog.dart` |
| SEC-S5 | CI com `gitleaks-action` e workflow oficial do OSV-Scanner rodando em todo push/PR, publicando SARIF no Code Scanning | `.github/workflows/ci.yml:17-20,87-96` |
| SEC-S6 | Supply chain limpo — verificado nesta sessão via execução real do OSV-Scanner: 133 pacotes, 0 vulnerabilidades conhecidas | execução local desta sessão |
| SEC-S7 | Rede HTTP corretamente tratada: apenas HTTPS, timeout de 10s, tratamento de 429 com `Retry-After`, parsing de JSON com tratamento de erro tipado | `lib/data/network/spotify_webapi.dart` |
| SEC-S8 | Minimização de dados no Analytics: parâmetros de evento são só `reason` (tipo de exceção) e `source` (enum interno) — nenhum código de carta, ID de música ou identificador de usuário enviado | verificado nos 7 call-sites de `reportAnalyticsEvent` |
| SEC-S9 | Código do QR tratado como chave opaca de lookup, sem vetor de injeção NoSQL | `lib/data/repository/musica_repository_impl.dart` |
| SEC-S10 | ProGuard/R8 com regras minimalistas (não `-keep class **` genérico) | `android/app/proguard-rules.pro` |
| SEC-S11 | `google-services.json`/`firebase_options.dart` versionados são aceitáveis — a fronteira de segurança real são as Firestore Rules, não o sigilo dessas chaves | prática padrão do ecossistema FlutterFire |

---

## 3. Checklist de compliance LGPD/GDPR

| Item | Status | Evidência |
|---|---|---|
| Política de privacidade publicada e acessível | OK | `hosting/privacidade/index.html`, linkada no diálogo de consentimento |
| Identificação do controlador e canal de contato | Parcial | E-mail funciona; canal in-app (`ContactView`) vazio — ver SEC-004 |
| Base legal / consentimento específico para dado de terceiro (Spotify) | OK | Diálogo explícito, não dispensável, escopos detalhados |
| Consentimento aplicado tecnicamente, não só na UI | OK | Gate em `SpotifyService._ensureConsent()` |
| Revogação de consentimento | Parcial | Só possível externamente via Spotify; sem ação no app — ver SEC-002 |
| Minimização de dados coletados | OK | Sem conta própria, sem PII armazenada |
| Transparência sobre Crashlytics (finalidade, dado, retenção) | OK (conteúdo) / Pendente (processo) | Seções 2.2 e 5; revisão jurídica formal ainda não concluída |
| Transparência sobre Analytics (finalidade, dado, retenção) | OK (conteúdo) / Pendente (processo) | Idem; parâmetros reais verificados como não-identificáveis |
| Compartilhamento com terceiros declarado | OK | Seção 4 lista Spotify e Google Firebase explicitamente |
| Direitos do titular listados | OK | Seção 6, alinhada à Lei 13.709/2018 |
| Coleta de câmera declarada e minimizada | OK | Processamento local via `mobile_scanner`, sem upload de imagem |
| Política voltada a menores de idade | OK | Seção 7 |
| Consistência entre promessa da política e comportamento real (dados locais) | Parcial | `allowBackup` não desabilitado — ver SEC-003 |
| Revisão jurídica formal da política atual | Pendente | Fora do escopo técnico, declarado como rascunho |

---

## 4. Status do supply chain

- **Ferramenta executada nesta sessão:** `osv-scanner.exe --lockfile=pubspec.lock`.
- **Resultado:** 133 pacotes escaneados, **0 vulnerabilidades conhecidas**.
- **`flutter pub outdated` (executado nesta sessão):** confirma 1 versão transitiva retracted e ~20 dependências diretas com versão mais nova disponível (ver SEC-005).
- **CI:** `gitleaks-action@v2` e o workflow reutilizável oficial do OSV-Scanner (v2.5.1) rodam em todo push/PR, com publicação de SARIF no GitHub Code Scanning — verificação contínua real, não pontual.
- **Não coberto:** dependências nativas Android/Gradle não foram escaneadas por uma ferramenta de supply chain Java/Kotlin — o OSV-Scanner rodado cobriu apenas o ecossistema Dart/pub via `pubspec.lock`.

---

## 5. Itens não verificados nesta sessão

- Visibilidade formal do repositório GitHub (inferida via resposta `404` da API pública, não confirmada nas configurações do GitHub diretamente).
- Restrição da API key do Firebase Android no Google Cloud Console (requer acesso ao console, fora do escopo do repositório).
- Scan de dependências nativas Gradle/Android com ferramenta dedicada.
- Teste dinâmico (DAST) ou captura de tráfego de rede real do app em execução.
- Conteúdo integral de `hosting/termos/index.html` linha a linha.
