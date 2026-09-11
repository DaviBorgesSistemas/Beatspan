# Beatspan — Security Report

**Data da análise:** 2026-09-10
**Versão do documento:** 2.0 (reanálise completa)
**Commit analisado:** `8f2ae1e` (branch `beatspan_v2`)

IDs referenciam `docs/1-ARCHITECTURAL_REVIEW.md` quando aplicável.

---

## 1. Vulnerabilidades e achados

| ID | Severidade | Descrição | Localização | Impacto potencial | Recomendação |
|---|---|---|---|---|---|
| SEC-001 | **Média** | `android/app/google-services.json` e `lib/firebase_options.dart` estão versionados no Git e contêm a `api_key`/`project_id` do Firebase. Não é um segredo de servidor por definição do Firebase, mas a mitigação depende de uma configuração fora do repositório. | `android/app/google-services.json`, `lib/firebase_options.dart` (confirmado via `git ls-files`) | Se a API key não estiver restrita por assinatura/pacote no Google Cloud Console, ela pode em tese ser usada para chamar APIs do Google habilitadas no projeto a partir de qualquer app — a mitigação real são as Firestore Rules (ver SEC-S1) e a restrição de key | Confirmar no Google Cloud Console → Credentials que a API key de Android está restrita ao `applicationId` (`br.com.dcbsys.beatspan`) + SHA-1 de release |
| SEC-002 | **Média** | Build de release (`buildTypes.release.signingConfig`) cai para a assinatura de **debug** sem erro/warning se `android/key.properties` não existir. | `android/app/build.gradle.kts:67-73` | Um pipeline de release mal configurado (ex.: variável de ambiente/secret ausente no runner de CD) pode gerar e publicar um APK/AAB assinado com a chave de debug sem que o build falhe | Adicionar um step de release (CI ou manual) que falhe explicitamente se `key.properties` estiver ausente, em vez de depender do fallback silencioso |
| SEC-003 | ~~Média~~ Resolvido | ~~Nenhum scan de vulnerabilidades de dependências roda no CI.~~ Job `osv-scan` adicionado ao CI, usando o workflow reutilizável oficial do OSV-Scanner contra `pubspec.lock` em todo push/PR. | `.github/workflows/ci.yml` | — | Acompanhar a aba "Security > Code Scanning" do repositório após a primeira execução real |
| SEC-004 | **Baixa** | Política de retenção/exclusão de dados do Crashlytics (stack traces, possíveis identificadores de dispositivo) não está documentada na política de privacidade de forma que eu tenha conseguido confirmar por amostragem. | `hosting/privacidade/index.html` (não auditado linha a linha) | Risco de compliance LGPD se dados de crash forem considerados dados pessoais e não houver retenção/finalidade documentada | Revisão jurídica dedicada da política de privacidade cobrindo especificamente os dados coletados pelo Crashlytics |
| SEC-005 | **Baixa** | `FaqsViewModel` e `session_tile.dart` engolem erros com `debugPrint` em vez de `reportNonFatalError` — não é uma vulnerabilidade de segurança per se, mas reduz a visibilidade de falhas em produção que poderiam sinalizar abuso (ex.: falhas repetidas de parsing de link). | `lib/presentation/faqs/faqs_view_model.dart:27`, `lib/presentation/faqs/widgets/session_tile.dart:101` | Baixo — perda de observabilidade, não exposição direta | Substituir por `reportNonFatalError` para consistência com o resto do app (ver OPS-003 em `docs/3-TECH_DEBT_REGISTER.md`) |

### Status do supply chain (dependências)

**Não executei scanner de vulnerabilidades nesta sessão.** Conforme a regra de evidência deste processo, não é permitido apontar CVEs específicos sem confirmação real. Status:

- **Pendente de verificação com OSV-Scanner** (`scripts/scan_dependencies.sh` — requer ambiente Linux/Windows com o binário correto) **ou `dart pub outdated --mode=null-safety`**.
- Dependências diretas e suas versões resolvidas atuais (`pubspec.lock`), para referência de quem for rodar o scan:

| Pacote | Versão resolvida |
|---|---|
| `cloud_firestore` | 5.6.12 |
| `firebase_core` | 3.15.2 |
| `firebase_crashlytics` | 4.3.10 |
| `spotify_sdk` | 3.0.2 |
| `mobile_scanner` | 7.1.3 |
| `just_audio` | 0.10.5 |
| `http` | 1.6.0 |
| `flutter_dotenv` | 5.2.1 |
| `cached_network_image` | 3.4.1 |
| `permission_handler` | 11.4.0 |
| `connectivity_plus` | 6.1.5 |

Nenhuma dessas versões foi cruzada contra uma base de CVEs nesta análise — a tabela serve apenas de ponto de partida para quem rodar o scan.

---

## 2. Gestão de segredos e credenciais

| Item | Status | Evidência |
|---|---|---|
| `.env` (credenciais Spotify) | ✅ Não versionado | `.gitignore:51`, confirmado ausente em `git ls-files` |
| `android/key.properties` (keystore release) | ✅ Não versionado | `.gitignore:54` |
| `*.jks` / `*.keystore` | ✅ Não versionado | `.gitignore:55-56` |
| `android/key.properties.example` | ✅ Versionado (template, sem credenciais reais) | `git ls-files` |
| `.env.example` | ✅ Versionado (placeholders vazios) | conteúdo lido: `SPOTIFY_CLIENT_ID=`, `SPOTIFY_REDIRECT_URL=` |
| `android/app/google-services.json` | ⚠️ Versionado com dado real de projeto Firebase | ver SEC-001 |
| `lib/firebase_options.dart` | ⚠️ Versionado com dado real de projeto Firebase | ver SEC-001 |
| Verificação automática de segredos vazados | ✅ `gitleaks` roda em todo push/PR | `.github/workflows/ci.yml` |

Nenhum valor de segredo real foi reproduzido neste relatório, conforme a regra de execução do processo de análise — apenas o tipo de dado e a localização do arquivo.

---

## 3. Checklist de compliance LGPD/GDPR

| Item | Status | Observação |
|---|---|---|
| Política de privacidade publicada e acessível | ✅ | `hosting/privacidade/index.html`, linkada no diálogo de consentimento |
| Termos de uso publicados | ✅ | `hosting/termos/index.html` |
| Consentimento explícito antes de acessar dados do usuário (Spotify) | ✅ | `SpotifyConsentDialog` + `SpotifyService._ensureConsent()` bloqueia a chamada no nível de serviço, não só na UI |
| Coleta mínima de dados (minimização) | ✅ | App não tem conta própria; Firestore armazena só catálogo de músicas (`spotify_id`, `spotify_uri`), sem dado pessoal do jogador |
| Dados do Spotify (OAuth) nunca transitam/persistem no app | ✅ (por design) | Token obtido e gerenciado pelo `spotify_sdk`/Spotify; app não persiste o token em `shared_preferences` (confirmado por ausência de chave de token em `app_prefs.dart`) |
| Retenção/finalidade dos dados de crash (Crashlytics) documentada | ⚠️ Não confirmado | Ver SEC-004 — requer revisão jurídica dedicada |
| Canal de contato para exercício de direitos do titular | ⚠️ Não auditado em detalhe | Existe `ContactView` no app (`lib/presentation/contact/contact_view.dart`) — não verifiquei se a política de privacidade referencia esse canal explicitamente para pedidos LGPD |
| Mecanismo de revogação de consentimento já dado | ⚠️ Parcial | `AppPreferences.setSpotifyConsentAccepted(false)` existe como capacidade técnica, mas não confirmei se há uma ação de UI exposta ao usuário para revogar o consentimento após aceitar (ex.: em Configurações) |

**Nota:** este checklist cobre o que é verificável a partir do código e da estrutura do repositório. Não substitui uma análise jurídica formal de compliance LGPD/GDPR, especialmente quanto à completude da política de privacidade.

---

## 4. Pontos fortes de segurança (para registro)

- **SEC-S1** — Firestore Rules restritivas por padrão: leitura pública apenas na coleção necessária, escrita sempre bloqueada, deny-all explícito para qualquer outra coleção (`firestore.rules:18-26`).
- **SEC-S3** — Gate de consentimento aplicado na camada de serviço (`SpotifyService._ensureConsent()`), não contornável pulando uma tela.
- **SEC-S4** — `gitleaks` no CI como rede de segurança contra vazamento acidental de segredos em qualquer PR.
- **SEC-S5** — Build de release com assinatura de produção configurável, `isMinifyEnabled`/`isShrinkResources`/ProGuard habilitados.

(IDs completos e evidência de cada um em `docs/1-ARCHITECTURAL_REVIEW.md`, seção 4.)
