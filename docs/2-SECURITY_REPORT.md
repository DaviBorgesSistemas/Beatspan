# Relatório de Segurança — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-09
**Versão do documento:** 2.0

> Nenhum valor real de credencial é reproduzido neste documento. Onde uma credencial foi encontrada, apenas seu tipo e localização (arquivo/linha) são reportados.

---

## Nota do eixo: 5,5/10

**Justificativa:** o núcleo técnico segue sólido — Firestore Rules deny-by-default (`SEC-004`), 100% HTTPS (`SEC-005`), armazenamento local sem dados sensíveis (`SEC-006`), permissões Android mínimas (`SEC-007`), validação de QR sem vetor de injection (`SEC-008`) — e a postura de compliance LGPD avançou de forma real desde a v1.0 (política de privacidade publicada, termos publicados, diálogo de consentimento implementado e conectado a duas telas). A nota **não sobe** porque:
1. `SEC-001` (credencial versionada) foi corrigido em 2026-09-08 e **revertido silenciosamente** ~15 minutos depois, e segue revertido no HEAD atual — uma regressão ativa, não um problema legado.
2. Achado novo: build de release Android assinado com chave de debug, sem ofuscação (`SEC-011`).
3. Achado novo: o gate de consentimento OAuth não cobre todos os caminhos que disparam autenticação do Spotify (`SEC-012`).

Nenhum achado é classificado **Crítico** — o item de maior severidade (`SEC-001`) permanece **Alta**, porque a credencial exposta é um Client ID OAuth público-cliente (trafega para o dispositivo do usuário em toda autenticação por design), não uma Client Secret ou chave privada.

---

## Vulnerabilidades e achados

### SEC-001 — Credencial versionada: `.env` no Git · ⚠️ Reaberto
**Severidade:** Alta
**Localização:** [.env](../.env) (raiz)
**Descrição:** o commit `9d66a14` ("security: remove .env do controle de versão") removeu `.env` do tracking e adicionou a entrada ao `.gitignore`. ~15 minutos depois, o commit `95ab2b9` **reintroduziu `.env` no Git com um `SPOTIFY_CLIENT_ID` real** e **removeu a linha `.env` do `.gitignore`**. Um commit seguinte (`6433da0`) ainda editou o `SPOTIFY_REDIRECT_URL` dentro desse mesmo `.env` já versionado. Hoje, no HEAD de `beatspan_v2`: `git ls-files | grep .env` retorna o arquivo; `.gitignore` não tem entrada `.env`; o conteúdo commitado é o valor real em uso.
**Por que não é Crítico:** Client ID Spotify em fluxo mobile é público por design (trafega para o Spotify a cada autenticação); o dano de vazamento isolado é limitado (spoofing de app cliente, sem acesso a contas de usuário sem aprovação explícita no app oficial do Spotify).
**Impacto:** exposição permanente no histórico do Git; se o repositório for/vier a ser compartilhado externamente, a credencial já está lá independente de correções futuras no HEAD.
**Recomendação:**
1. `git rm --cached .env` + restaurar a entrada em `.gitignore`
2. Auditar por que a correção anterior foi revertida (falha de processo/review)
3. Rotacionar o Client ID no Spotify Developer Dashboard como precaução
4. Adicionar um step de secret-scanning ao CI (`SEC-013`/`OPS-007`) para que isso não se repita sem ser notado

---

### SEC-002 — Client ID hardcoded no código-fonte · ✅ Resolvido
`di.dart` não contém mais string literal — lê via `flutter_dotenv`. O problema agora é apenas o `.env` em si (`SEC-001`).

---

### SEC-003 — Chave de API do Firebase (Android) versionada
**Severidade:** Baixa (informativo) · Sem mudança desde v1.0.
**Localização:** [lib/firebase_options.dart:46](../lib/firebase_options.dart#L46), `android/app/google-services.json`.
**Descrição:** comportamento padrão do FlutterFire CLI; controle real feito pelas Rules (`SEC-004`, corretas).
**Recomendação:** confirmar no Google Cloud Console que a chave está restrita a `br.com.dcbsys.beatspan` + SHA-1 de release — especialmente relevante depois de corrigir `SEC-011`, quando uma keystore de produção real existir.

---

### SEC-004 — Firestore Security Rules · Ponto forte, confirmado
**Localização:** [firestore.rules:18-26](../firestore.rules#L18-L26). Leitura pública intencional de `musicas` (catálogo não sensível), escrita bloqueada, deny-all padrão para o resto. Sem mudança para pior desde v1.0.
**Recomendação:** considerar Firebase App Check se scraping em massa do catálogo se tornar preocupação.

---

### SEC-005 — Comunicação de rede · Ponto forte, confirmado
Nenhuma ocorrência de `http://` em `lib/`; todas as chamadas usam HTTPS/TLS.

---

### SEC-006 — Armazenamento local (SharedPreferences) · Ponto forte, confirmado
[lib/app/app_prefs.dart](../lib/app/app_prefs.dart) — apenas preferências de UX/jogo e a flag de consentimento Spotify. Nenhum token/credencial persistido pelo código Dart.

---

### SEC-007 — Permissões Android · Ponto forte, confirmado
Apenas `android.permission.CAMERA`.

---

### SEC-008 — Validação de input do QR code · Baixa, confirmado
[lib/presentation/game/game_viewmodel.dart:18-31](../lib/presentation/game/game_viewmodel.dart#L18-L31) — allowlist de host fixa, último segmento de path como ID opaco do Firestore. Sem vetor de injection.
**Recomendação (defesa em profundidade):** regex de formato (ex. `^[0-9]{4}$`) antes da consulta.

---

### SEC-009 — Política de privacidade/consentimento OAuth · ✅ Resolvido (com ressalva — ver SEC-012)
`hosting/privacidade/index.html` e `hosting/termos/index.html` publicados e reais; `SpotifyConsentDialog` implementado e conectado a `ChangeSpotifyView`/`SettingsView`, persistido via `AppPreferences`.

---

### SEC-010 — Dependências desatualizadas
**Severidade:** Baixa (sem CVE confirmada). Sem mudança de fundo desde v1.0 — mesma lista de majors defasadas (`cloud_firestore`, `firebase_core`, `firebase_crashlytics`, `connectivity_plus`, `permission_handler`, `sensors_plus`, `proximity_sensor`, `fluttertoast`, `spotify_sdk`, `flutter_dotenv`).
**Novo:** `flutter pub outdated` sinaliza `path_provider_foundation *2.5.0` como **retirado (retracted)** do pub.dev — não é CVE, mas vale revisão.
**CVEs:** não rerodei scanner de vulnerabilidades nesta sessão; `docs` registra uma execução de OSV-Scanner v2.5.1 em 2026-09-09 contra `pubspec.lock` com resultado "0 vulnerabilidades conhecidas" — tratado como não reverificado por mim nesta rodada, recomenda-se repetir periodicamente.

---

### SEC-011 — Release Android assinado com chave de debug, sem ofuscação · **Novo**
**Severidade:** Alta
**Localização:** [android/app/build.gradle.kts:41-51](../android/app/build.gradle.kts#L41-L51) — `release { signingConfig = signingConfigs.getByName("debug") ... }`, comentário `// TODO: Add your own signing config for the release build.`. Nenhum `buildType` define `isMinifyEnabled`/`isShrinkResources`.
**Descrição:** o projeto nunca configurou keystore de produção — builds "release" hoje saem assinadas com a chave de debug padrão do Flutter, o que impede publicação real na Play Store. `android/app/proguard-rules.pro` existe (regras para Spotify SDK/Jackson) mas é código morto: sem `isMinifyEnabled = true`, R8/ProGuard não roda, e o APK de release não é ofuscado.
**Impacto:** combinado com `SEC-001`/o `.env` embutido como asset, a ausência de ofuscação torna a engenharia reversa do binário de release trivial (validação de QR, chamadas de rede, `.env` — tudo legível).
**Recomendação:** configurar `key.properties`/keystore de produção antes de qualquer publicação; habilitar `isMinifyEnabled = true` e `isShrinkResources = true` no `buildType("release")`, validando que as regras do ProGuard continuam suficientes.

---

### SEC-012 — Gate de consentimento Spotify não é aplicado em todos os caminhos de OAuth · **Novo**
**Severidade:** Média
**Localização:** `hasAcceptedSpotifyConsent()` só é checado em [change_spotify_view.dart:121](../lib/presentation/change_spotify/change_spotify_view.dart#L121) e [settings_view.dart:53](../lib/presentation/settings/settings_view.dart#L53). Porém [player_music_premium_view.dart:62](../lib/presentation/game/player_music/player_music_premium_view.dart#L62) chama `authorizeAndConnect()` direto em `initState()`, e [play_music_free_view.dart:72](../lib/presentation/game/player_music/play_music_free_view.dart#L72) chama `getAccessToken()` ao salvar faixa — nenhum dos dois verifica consentimento.
**Descrição:** se o fluxo de jogo permitir chegar a `PlayerMusicPremiumView` sem passar antes pela tela de conexão (não confirmado com certeza via leitura estática — é um gap de design, não uma falha comprovada de navegação), a autorização OAuth do Spotify é disparada sem o disclosure próprio do Beatspan.
**Recomendação:** centralizar a checagem dentro de `SpotifyService.authorizeAndConnect()`/`getAccessToken()`, para que nenhum caminho de código consiga acionar o SDK sem consentimento já registrado. **Requer verificação funcional** da árvore de navegação para confirmar se o gap é real ou só teórico.

---

## Checklist de compliance LGPD/GDPR

**Conforme:**
- [x] Política de Privacidade real e publicada (`hosting/privacidade/index.html`), com dados coletados, retenção, compartilhamento com Spotify/Firebase, direitos do titular (art. 18 LGPD), menores de idade
- [x] Termos de Uso publicados (`hosting/termos/index.html`)
- [x] Diálogo de consentimento explícito antes da conexão Spotify, com link à política e opção de cancelar
- [x] Consentimento persistido via flag dedicada
- [x] Canal de contato para exercício de direitos (e-mail)
- [x] Menção a revogação via `spotify.com/account/apps`
- [x] Firestore Rules bloqueiam qualquer coleção não intencional
- [x] Permissões mínimas (só câmera)

**Não conforme / pendente:**
- [ ] Gate de consentimento não centralizado — caminhos de gameplay podem disparar OAuth sem checagem (`SEC-012`)
- [ ] Exclusão de dados apenas via e-mail (sem autoatendimento in-app — aceitável como mínimo legal)
- [ ] `.env` versionado com credencial real, sem `.gitignore` (`SEC-001`) — problema de governança de segredos, mesmo não sendo dado pessoal
- [ ] Sem artefato interno de base legal de tratamento (RIPD/ROPA)

---

## Status do supply chain

| Dependência | Instalada | Última major disponível |
|---|---|---|
| `cloud_firestore` | 5.6.12 | 6.9.0 |
| `firebase_core` | 3.15.2 | 4.14.0 |
| `firebase_crashlytics` | 4.3.10 | 5.3.0 |
| `connectivity_plus` | 6.1.5 | 7.3.1 |
| `permission_handler` | 11.4.0 | 13.0.2 |
| `sensors_plus` | 6.1.2 | 7.1.0 |
| `proximity_sensor` | 1.4.0 | 2.0.0 |
| `fluttertoast` | 9.0.0 | 10.0.0 |
| `spotify_sdk` | 3.0.2 | 4.0.0 |
| `flutter_dotenv` | 5.2.1 | 6.0.1 |

`path_provider_foundation *2.5.0`: sinalizado como **retracted** pelo próprio `flutter pub outdated`. Nenhuma CVE confirmada nesta rodada (não rerodei scanner — ver acima); requer verificação com scanner de dependências (OSV-Scanner/Snyk) antes de cada release.

---

## Áreas não investigadas por escopo/tempo
- Comportamento nativo do `spotify_sdk` (cache de token em Keystore/preferências nativas fora do Dart)
- Restrições reais da API Key do Firebase e do Redirect URI do Spotify nos respectivos consoles
- Build iOS (inexistente)
- Confirmação viva de CVEs (scanner não rerodado nesta sessão)
- Fluxo de navegação completo do app (para confirmar `SEC-012` como bug real vs. gap teórico)
- Conteúdo completo de `google-services.json` além do padrão já verificado
