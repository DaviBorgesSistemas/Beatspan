# Relatório de Segurança — Beatspan

**Projeto:** Beatspan
**Data da análise:** 2026-09-08
**Versão do documento:** 1.0

> Nenhum valor real de credencial é reproduzido neste documento. Onde uma credencial foi encontrada, apenas seu tipo e localização (arquivo/linha) são reportados.

> **Adendo 2026-09-09**: SEC-009 (política de privacidade/termos + consentimento OAuth) e SEC-010 (scanner de dependências) foram resolvidos após a data desta análise — ver detalhes nas seções correspondentes abaixo e em [4-ACTION_PLAN.md](4-ACTION_PLAN.md). A nota do eixo e a justificativa abaixo refletem o estado em 2026-09-08 e não foram recalculadas.

---

## Nota do eixo: 6,5/10

**Justificativa:** o núcleo técnico é sólido — Firestore Rules corretas com deny-by-default (SEC-004), 100% das chamadas de rede em HTTPS sem bypass de certificado (SEC-005), armazenamento local sem dados sensíveis (SEC-006), permissões Android mínimas (SEC-007), e validação de input do QR code adequada antes do uso no Firestore, sem vetor de injection real (SEC-008). A nota é penalizada por: exposição confirmada de credencial no histórico do Git (SEC-001), ausência de política de privacidade/termos de uso funcionais apesar da coleta de dados via OAuth do Spotify (SEC-009), e dependências desatualizadas sem processo de scanning aparente (SEC-010). Nenhum achado de severidade **Crítica** foi confirmado — o item de maior severidade (SEC-001) é classificado **Alta**, não Crítica, porque a credencial exposta é um Client ID OAuth público-cliente, não uma Client Secret ou chave privada.

---

## Vulnerabilidades e achados

### SEC-001 — Credencial versionada: arquivo `.env` no repositório Git
**Severidade:** Alta
**Localização:** [.env](../.env) (raiz do projeto)
**Descrição:** o arquivo `.env` está rastreado pelo Git (confirmado via `git ls-files`) e possui commits no histórico (commit `0d5d678`). O `.gitignore` não contém entrada para `.env`. O próprio arquivo contém um comentário interno: *"Este arquivo contém credenciais sensíveis e NÃO deve ser versionado no Git"* — a equipe reconheceu o risco mas não o corrigiu. Define `SPOTIFY_CLIENT_ID` e `SPOTIFY_REDIRECT_URL`.
**Impacto:** qualquer pessoa com acesso ao repositório (incluindo histórico completo, mesmo que removido do HEAD depois) tem acesso à credencial. Se o repositório for ou vier a ser público, ou houver rotação de colaboradores, a credencial fica exposta permanentemente no histórico.
**Recomendação:**
1. `git rm --cached .env`
2. Adicionar `.env` ao `.gitignore`
3. Reescrever o histórico (BFG Repo-Cleaner ou `git filter-repo`) se o repositório for/vier a ser compartilhado externamente
4. Rotacionar o Client ID/Secret no Spotify Developer Dashboard após a limpeza

---

### SEC-002 — Spotify Client ID hardcoded no código-fonte
**Severidade:** Média
**Localização:** [lib/app/di.dart:58-59](../lib/app/di.dart#L58-L59)
**Descrição:** `clientId`/`redirectUrl` declarados como string literal direto no código, duplicando o que deveria vir do `.env`/build config. Client ID (diferente de Client Secret) não é, por natureza do fluxo OAuth Authorization Code/PKCE usado por apps mobile, um segredo de altíssima criticidade — é enviado ao dispositivo do usuário de qualquer forma. O problema real é a ausência de gestão de configuração por ambiente (dev/staging/prod usam o mesmo valor sem possibilidade de segregação) e a duplicação com o `.env` versionado sem necessidade.
**Impacto:** baixo risco direto adicional; sintoma de falta de disciplina de configuração.
**Recomendação:** usar exclusivamente variáveis de ambiente/build-time (`--dart-define`, `flutter_dotenv` com arquivo não versionado, ou flavors), eliminando a duplicação.

---

### SEC-003 — Chave de API do Firebase (Android) versionada
**Severidade:** Baixa (informativo)
**Localização:** [lib/firebase_options.dart:56](../lib/firebase_options.dart#L56), `android/app/google-services.json`
**Descrição:** a `apiKey` do Firebase para Android está versionada em texto plano — comportamento padrão e esperado do FlutterFire CLI. Não é um segredo no sentido tradicional: não concede acesso automático a dados; o controle real é feito pelas Firestore Security Rules e pela restrição da chave no Google Cloud Console.
**Impacto:** baixo, desde que (a) as Firestore Rules sejam restritivas (confirmado em SEC-004) e (b) a chave esteja restrita por `applicationId`/SHA-1 no Google Cloud Console (não verificável via código-fonte).
**Recomendação:** confirmar no Google Cloud Console que a API Key Android está restrita ao pacote `br.com.dcbsys.beatspan` + SHA-1 de assinatura. Documentar essa decisão para auditores futuros.

---

### SEC-004 — Firestore Security Rules
**Severidade:** Informativo (achado positivo)
**Localização:** [firestore.rules:18-26](../firestore.rules#L18-L26)
**Descrição:** regras restritivas e corretas:
```
match /musicas/{codigo} {
  allow read: if true;
  allow write: if false;
}
match /{document=**} {
  allow read, write: if false;
}
```
Leitura pública é intencional e documentada (o app não autentica usuário para tocar música), escrita totalmente bloqueada, e há deny-all padrão para qualquer coleção não prevista.
**Impacto:** nenhum. A única exposição é leitura pública de `musicas` (catálogo de faixas, dado não sensível), que é o comportamento intencional.
**Recomendação:** nenhuma correção obrigatória. Sugestão: avaliar Firebase App Check para mitigar scraping em massa do catálogo, já que a leitura é totalmente aberta.

---

### SEC-005 — Comunicação de rede
**Severidade:** Informativo (achado positivo)
**Localização:** `lib/data/network/spotify_webapi.dart`, `itunes_search_api.dart`, `musica_firestore_data_source.dart`
**Descrição:** todas as chamadas usam `https://` explícito ou o SDK do Firestore (TLS forçado internamente). Sem `http://`, sem desabilitação de verificação de certificado, sem `usesCleartextTraffic` no manifest.
**Impacto:** nenhum problema identificado.
**Recomendação:** nenhuma ação necessária. Opcionalmente considerar certificate pinning se o app processar dados de maior sensibilidade no futuro.

---

### SEC-006 — Armazenamento local (SharedPreferences)
**Severidade:** Informativo (achado positivo)
**Localização:** [lib/app/app_prefs.dart](../lib/app/app_prefs.dart)
**Descrição:** armazena apenas preferências de UX/jogo (plano, idioma, país, modo de virar telefone, modo de jogo). Nenhum token de acesso ou credencial do Spotify é persistido em `SharedPreferences` pelo código Dart — `SpotifyService.getAccessToken()` obtém o token via SDK nativo a cada uso.
**Impacto:** nenhum problema identificado no código Dart auditado. Não foi investigado se o plugin nativo `spotify_sdk` faz cache de token em keystore/preferências nativas (fora do escopo desta análise de código Dart).
**Recomendação:** confirmar como item adicional de auditoria onde/se o plugin nativo retém tokens.

---

### SEC-007 — Permissões Android
**Severidade:** Informativo (achado positivo)
**Localização:** [android/app/src/main/AndroidManifest.xml:2](../android/app/src/main/AndroidManifest.xml#L2)
**Descrição:** apenas `android.permission.CAMERA` declarada, coerente com a leitura de QR code. Sem localização, contatos, armazenamento externo, microfone ou SMS.
**Impacto:** nenhum problema — princípio do menor privilégio respeitado.
**Recomendação:** nenhuma ação necessária.

---

### SEC-008 — Validação de input do QR code antes de uso no Firestore
**Severidade:** Baixa (informativo, com observação)
**Localização:** [lib/presentation/game/game_viewmodel.dart:14-46](../lib/presentation/game/game_viewmodel.dart#L14-L46), [game_view.dart:41-76](../lib/presentation/game/game_view.dart#L41-L76)
**Descrição:** o conteúdo bruto do QR não vai direto como doc ID no Firestore. Passa por `validate()`/`extractCodigo()`: parse de URI, exige scheme http/https, valida host contra allowlist fixa (`beatspangame.com`, `beatspan.web.app`, `beatspan.firebaseapp.com`), extrai o último path segment como código. Apenas esse valor validado chega a `.doc(codigo).get()`. O SDK do Firestore trata esse argumento como identificador opaco, não como query interpretada — sem superfície de "NoSQL injection" via concatenação.
**Impacto:** nenhum risco de injection identificado. Como a regra de escrita é `allow write: if false`, mesmo um código malicioso não pode escrever dados.
**Recomendação (defesa em profundidade):** adicionar validação de formato explícita do código extraído (ex.: regex alfanumérico de tamanho fixo, já que os exemplos mostram códigos como "0006") antes da consulta ao Firestore.

---

### SEC-009 — Ausência de política de privacidade e termos de uso reais
**Severidade:** Média (compliance, não é vulnerabilidade técnica)
**Localização:** [hosting/index.html:194-195](../hosting/index.html#L194-L195), `docs/beatspan-home.html:1850`
**Descrição:** o site institucional contém links para `/privacidade` e `/termos`, mas o `firebase.json` configura rewrite `"**" → "/index.html"` (SPA fallback) e `hosting/` contém apenas `index.html` — essas rotas não existem, qualquer visita recarrega a home. Em `docs/beatspan-home.html:1850`, o link de política de privacidade é um placeholder inerte (`href="#" onclick="return false;"`).
**Impacto:** o app processa autenticação/autorização OAuth do Spotify com escopos amplos (`user-read-playback-state`, `user-modify-playback-state`, `playlist-read-private`, `user-library-modify`, `user-library-read` — [di.dart:12-13](../lib/app/di.dart#L12-L13)) e armazena preferências de país/idioma localmente, sem política de privacidade real acessível. Lacuna relevante para LGPD (arts. 8º e 9º) e para os próprios Spotify Developer Terms, que exigem política de privacidade pública.
**Recomendação:** criar e publicar páginas reais de Política de Privacidade e Termos de Uso antes de lançamento público, cobrindo dados coletados via Spotify OAuth, finalidade, retenção e direitos do titular. Adicionar tela de consentimento explícito no onboarding antes da conexão com Spotify.

---

### SEC-010 — Dependências desatualizadas
**Severidade:** Baixa (verificado — sem CVE confirmada)
**Localização:** [pubspec.yaml](../pubspec.yaml)
**Descrição:** `flutter pub outdated` mostra majors mais novas disponíveis: `cloud_firestore` 5.6.12→6.9.0, `firebase_core` 3.15.2→4.14.0, `firebase_crashlytics` 4.3.10→5.3.0, `connectivity_plus` 6.1.5→7.3.1, `permission_handler` 11.4.0→13.0.2, `sensors_plus` 6.1.2→7.1.0, `proximity_sensor` 1.4.0→2.0.0, `fluttertoast` 9.0.0→10.0.0, `spotify_sdk` 3.0.2→4.0.0. **Atualização (2026-09-09): rodado OSV-Scanner v2.5.1 contra `pubspec.lock`** (120 pacotes) — **0 vulnerabilidades conhecidas encontradas**. Nenhuma das versões atualmente fixadas está listada na base de dados OSV.
**Impacto:** baixo — ausência de CVE conhecida nas versões atuais. O risco remanescente é ficar cada vez mais distante das versões upstream (majors defasadas), o que aumenta o custo de migração futura, não um risco de segurança imediato.
**Recomendação:** manter scanner de dependências rodando periodicamente (idealmente integrado ao CI — ver `OPS-002` no [ARCHITECTURAL_REVIEW.md](ARCHITECTURAL_REVIEW.md) e `DOC-007` no [ACTION_PLAN.md](4-ACTION_PLAN.md)) e planejar atualização incremental das majors defasadas como trabalho à parte (breaking changes esperadas em `firebase_core`/`cloud_firestore` e `spotify_sdk`), não como correção de segurança urgente.

---

## Checklist de compliance LGPD/GDPR

**Conforme:**
- [x] Firestore Rules bloqueiam escrita e leitura de qualquer coleção não intencional
- [x] Nenhum dado pessoal sensível (CPF, e-mail, telefone) coletado ou armazenado localmente no código Dart auditado
- [x] Permissões de dispositivo mínimas (apenas câmera)
- [x] Comunicação de rede criptografada (HTTPS) em todos os pontos analisados

**Não conforme / pendente:**
- [ ] Política de Privacidade real e acessível (links são placeholders — SEC-009)
- [ ] Termos de Uso reais e acessíveis (idem)
- [ ] Tela de consentimento explícito (opt-in) antes da autorização OAuth do Spotify com escopos amplos
- [ ] Mecanismo documentado de exclusão de dados do usuário (direito ao esquecimento, art. 18 LGPD)
- [ ] Base legal de tratamento de dados documentada nos artefatos do repositório
- [ ] Confirmação de retenção de dados pelo SDK nativo do Spotify (fora do escopo desta auditoria de código)

---

## Status do supply chain

| Dependência | Instalada | Última major disponível | CVE confirmada |
|---|---|---|---|
| `cloud_firestore` | 5.6.12 | 6.9.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `firebase_core` | 3.15.2 | 4.14.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `firebase_crashlytics` | 4.3.10 | 5.3.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `connectivity_plus` | 6.1.5 | 7.3.1 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `permission_handler` | 11.4.0 | 13.0.2 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `sensors_plus` | 6.1.2 | 7.1.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `proximity_sensor` | 1.4.0 | 2.0.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `fluttertoast` | 9.0.0 | 10.0.0 | Nenhuma (OSV-Scanner, 2026-09-09) |
| `spotify_sdk` | 3.0.2 | 4.0.0 | Nenhuma (OSV-Scanner, 2026-09-09) |

**Atualizado em 2026-09-09**: rodado OSV-Scanner v2.5.1 contra `pubspec.lock` (120 pacotes resolvidos, incluindo transitivos) — **0 vulnerabilidades conhecidas encontradas** na base de dados OSV para nenhuma dependência do projeto, nas versões atualmente fixadas. As majors defasadas na tabela acima representam débito de atualização, não risco de segurança confirmado; recomenda-se reavaliar com o scanner a cada atualização relevante de dependências (ver `SEC-010`/`DOC-007` no [ACTION_PLAN.md](4-ACTION_PLAN.md)).

---

## Áreas não investigadas por escopo/tempo
- Configuração de restrição da API Key do Firebase/Google Cloud Console
- Comportamento interno do SDK nativo `spotify_sdk` quanto a persistência de tokens em keystore/preferências nativas
- Build iOS (não configurado)
- CVEs reais confirmadas nas dependências desatualizadas
- Testes de penetração dinâmicos (DAST)
- Ofuscação/proteção de binário (R8/ProGuard além do já configurado, anti-tampering, root/jailbreak detection)
- `firestore.indexes.json` e configuração de custo/rate-limiting no Firebase Console
- Segurança de pipeline CI/CD (inexistente — nada a auditar)
