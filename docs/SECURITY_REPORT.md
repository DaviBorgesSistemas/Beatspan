# Beatspan — Relatório de Segurança
**Projeto:** Beatspan
**Data da análise:** 2026-09-12
**Versão do documento:** 3.0
**Fonte primária de IDs:** `docs/ARCHITECTURAL_REVIEW.md`

---

## Resumo Executivo de Segurança

| ID | Severidade | Título | Status |
|----|-----------|--------|--------|
| SEC-002 | Alta | `.env` com credenciais Spotify embutido no APK | Resolvido em 2026-09-12 |
| SEC-001 | Média | Firebase API key no código-fonte | Aberto |
| SEC-003 | Média | Dependência `path_provider_foundation` 2.5.0 retracted | Aberto |
| SEC-004 | Baixa | Código QR sem validação de tamanho antes do Firestore | Aberto |

---

## Vulnerabilidades Identificadas

### SEC-002 — `.env` Embutido no APK como Asset Flutter
**Severidade:** Alta

**Status:** Resolvido em 2026-09-12. `.env` removido dos assets do `pubspec.yaml` e da dependência `flutter_dotenv`; credenciais agora injetadas em tempo de compilação via `--dart-define-from-file=env.json` e lidas com `String.fromEnvironment` em `lib/app/di.dart` (ver recomendação #2 abaixo, agora implementada). O Client ID Spotify que esteve embutido em builds anteriores foi revogado e substituído por um novo no Spotify Developer Dashboard.

**Descrição (achado original):** O arquivo `.env` está declarado em `pubspec.yaml:55` como asset Flutter:
```
assets:
  - .env
```
Assets Flutter são compilados diretamente no APK (`build/app/intermediates/flutter/release/flutter_assets/.env` confirmado na árvore de build). Qualquer pessoa com acesso ao APK pode extrair o arquivo via `apktool d app.apk` sem root, sem ofuscação, sem bypass de verificação.

**Conteúdo exposto:** `SPOTIFY_CLIENT_ID` e `SPOTIFY_REDIRECT_URL`. Com essas credenciais, um atacante pode:
1. Criar um app não-autorizado que se autentica na API Spotify como se fosse o Beatspan.
2. Usar o Client ID para phishing via fluxo OAuth Spotify.
3. Esgotar quotas de rate-limit do app legítimo.

**Localização:** `pubspec.yaml:55`, `.env`, `build/.../flutter_assets/.env`

**Impacto potencial:** Alto — exposição de credenciais de terceiro com consequências operacionais e de reputação.

**Recomendação:**
1. **Imediato:** Remover `.env` da lista de assets em `pubspec.yaml`. Revogar e re-criar o Spotify Client ID atual.
2. **Curto prazo:** Usar build-time injection via `--dart-define` ou `--dart-define-from-file` (não empacota como asset legível):
   ```
   flutter build apk --dart-define=SPOTIFY_CLIENT_ID=xxx --dart-define=SPOTIFY_REDIRECT_URL=yyy
   ```
   E no código: `const String.fromEnvironment('SPOTIFY_CLIENT_ID')`.
3. **Alternativa aceitável:** Manter `flutter_dotenv` mas servir o `.env` de um endpoint autenticado em runtime, não como asset estático.
4. Adicionar `.env` ao `.gitignore` (já está) e ao `.aaptignore`/`.gitattributes` para garantir que não seja incluído em builds de release inadvertidamente.

---

### SEC-001 — Firebase API Key no Código-Fonte
**Severidade:** Média

**Descrição:** O arquivo `lib/firebase_options.dart:46` contém a `apiKey` Firebase hardcodada. O valor é visível em qualquer clone/fork do repositório.

**Localização:** `lib/firebase_options.dart:46` (valor não reproduzido neste relatório — ver regra de segredos)

**Contexto:** Chaves Firebase client-side são semi-públicas por design: o Google protege o acesso via SHA-1 fingerprint do certificado de assinatura (Android) e via Firebase Security Rules no Firestore. Entretanto:
- A chave permite consultas ao Firestore sem autenticação se as regras estiverem abertas.
- Recomenda-se validar que as **Firebase Security Rules** estão restringindo leitura/escrita corretamente (não verificável nesta sessão — requer acesso ao console Firebase).
- A chave estar no VCS facilita reconhecimento automatizado por scanners de segredos.

**Recomendação:**
1. Validar no console Firebase que as Firestore Security Rules exigem autenticação ou ao menos limitam leitura ao catálogo público.
2. Configurar API key restrictions no Google Cloud Console (restrição por SHA fingerprint já é padrão no Firebase para Android, mas vale confirmar).
3. Considerar usar o arquivo `google-services.json` (não versionado) em vez de `firebase_options.dart` codificado — o FlutterFire CLI suporta ambos.

**Nota:** O CI já tem `gitleaks` que detectaria novos segredos; este foi introduzido antes do scanner ser adicionado ou é considerado aceitável pelo padrão Firebase.

---

### SEC-003 — Dependência `path_provider_foundation` 2.5.0 Retracted
**Severidade:** Média

**Descrição:** `path_provider_foundation` 2.5.0 aparece com `"isCurrentRetracted": true` no relatório `pub-outdated.json` (evidência coletada em 2026-09-12). Versão retracted significa que o autor do pacote removeu-a do pub.dev, tipicamente por bug crítico, incompatibilidade ou problema de segurança.

**Localização:** `pubspec.lock` (versão transitiva, não direta)

**Impacto potencial:** Depende da razão do retracted (não declarada publicamente nesta sessão). Riscos típicos: comportamento incorreto no iOS, crash em versões específicas do sistema operacional.

**Recomendação:**
1. Executar `flutter pub upgrade path_provider_foundation` para atualizar para 2.6.0 (versão resolvível conforme `pub-outdated.json`).
2. Se a versão travada por conflito de dependência, identificar qual dependência direta trava e resolver o upgrade maior correspondente.
3. Verificar o changelog do pacote para entender a razão do retracted.

**CVEs:** Nenhum CVE confirmado nesta sessão. OSV scanner no CI verificará automaticamente.

---

### SEC-004 — Código QR Sem Validação de Tamanho Antes do Firestore
**Severidade:** Baixa

**Descrição:** `GameViewModel.extractCodigo()` em `game_viewmodel.dart:48-61` valida o host da URL e extrai o último segmento de path, mas não valida tamanho ou formato do código resultante antes de passá-lo para `MusicaFirestoreDataSource.getByCodigo()`. Um QR code adversarial com um path de grande extensão resulta em uma consulta ao Firestore com documento ID de comprimento arbitrário.

O Firestore rejeita `documentId` acima de 1500 bytes com `INVALID_ARGUMENT`, que é capturado e mapeado para `MusicaConsultaException` (não é uma falha silenciosa do ponto de vista do usuário — o app mostra "Erro de Conexão"). O risco real é baixo, mas o comportamento poderia ser refinado.

**Localização:** `game_viewmodel.dart:48-61`, `musica_firestore_data_source.dart:32-43`

**Recomendação:** Adicionar validação de tamanho máximo (ex.: ≤100 chars) e formato (ex.: alfanumérico) no `extractCodigo()` antes de consultar o Firestore. Retornar `null` para códigos fora do padrão.

---

## Checklist LGPD/GDPR

| Item | Status | Observação |
|------|--------|-----------|
| Crashlytics desabilitado em debug | ✅ Atendido | `!kDebugMode` em `main.dart:37` |
| Dados de crash não contêm PII evidente | ✅ Provável | Eventos reportam `runtimeType`, não dados de usuário |
| Analytics coleta apenas eventos de uso | ⚠️ Requer verificação | Firebase Analytics coleta Device ID e pode coletar localização por padrão — validar configuração no console |
| Consentimento para Analytics | ❌ Não identificado | Nenhuma tela de consentimento de coleta de dados |
| Consentimento Spotify | ✅ Atendido | `SpotifyConsentRequiredException` + dialog de consentimento antes de qualquer chamada Spotify |
| Política de privacidade acessível no app | ❌ Não identificado | Nenhuma tela de política de privacidade encontrada |
| Direito ao esquecimento / deleção de dados | ❌ Sem mecanismo | Sem backend próprio para dados de usuário; verificar Firebase |
| Dados de menores | ⚠️ Requer verificação | App sem restrição de idade; Spotify requer 13+ |

**Ação recomendada antes do lançamento público:** Adicionar tela de aceite de política de privacidade e termos de uso; configurar Firebase Analytics para coleta mínima (desativar coleta de interesse e dados demográficos se não necessários); adicionar link para política de privacidade na Play Store.

---

## Supply Chain — Dependências

**Ferramenta utilizada:** `flutter pub outdated` (resultado em `docs/_evidence/2026-09-12_084947/pub-outdated.json`)

### Dependências Diretas com Quebra de Versão Maior

| Pacote | Atual | Resolvível | Última | Notas |
|--------|-------|-----------|--------|-------|
| `cloud_firestore` | 5.6.12 | 6.9.0 | 6.9.0 | Major break; FirebaseSDK v6 |
| `firebase_analytics` | 11.6.0 | 12.5.0 | 12.5.0 | Major break; FirebaseSDK v12 |
| `firebase_core` | 3.15.2 | 4.14.0 | 4.14.0 | Major break; precondição para outros Firebase |
| `firebase_crashlytics` | 4.3.10 | 5.3.0 | 5.3.0 | Major break |
| `connectivity_plus` | 6.1.5 | 7.3.1 | 7.3.1 | Major break |
| `permission_handler` | 11.4.0 | 13.0.2 | 13.0.2 | Dois major breaks |
| `sensors_plus` | 6.1.2 | 7.1.0 | 7.1.0 | Major break |
| `spotify_sdk` | 3.0.2 | 3.0.2 | 4.0.0 | Último major travado por conflito |
| `cached_network_image` | 3.4.1 | 3.4.1 | 4.0.0 | Último major travado por conflito |

**CVEs:** Nenhum CVE confirmado nesta sessão. OSV scanner (job `osv-scan` no CI) verifica `pubspec.lock` a cada push/PR via Google OSV Database — resultado mais confiável do que cruzamento manual.

**Dependência retracted:** `path_provider_foundation` 2.5.0 (ver SEC-003 acima).

### Recomendação de Atualização
Executar atualização em cascata dos pacotes Firebase primeiro (`firebase_core` → `firebase_analytics` → `firebase_crashlytics` → `cloud_firestore`) pois compartilham a mesma versão major do Firebase SDK. Após Firebase, atualizar `connectivity_plus`, `permission_handler` e `sensors_plus` em sprints separadas, com testes de regressão em device físico.
