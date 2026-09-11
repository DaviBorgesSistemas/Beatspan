# Beatspan — Tech Debt Register

**Data da análise:** 2026-09-11
**Versão do documento:** 3.0 (reanálise completa do zero, substitui a versão 2.0)
**Commit analisado:** `577dd0c` (branch `beatspan_v2`)

> Catálogo consolidado de débito técnico, referenciando os IDs já definidos em `docs/1-ARCHITECTURAL_REVIEW.md` e `docs/2-SECURITY_REPORT.md`.

---

## Tabela de débitos

| ID | Descrição | Categoria | Severidade | Esforço | Impacto se não resolvido |
|---|---|---|---|---|---|
| EXP-001 | Acessibilidade (`Semantics`/`Tooltip`) ausente na maioria absoluta das telas, incluindo o fluxo bloqueante de permissão de câmera | Código/UX | **Crítico** | G | Usuários com deficiência visual não conseguem operar o app — inclui uma etapa obrigatória (permissão de câmera) sem a qual não é possível jogar |
| EXP-003 | `ContactView` é um placeholder vazio, mas documentado como funcionalidade entregue no README | Código/Produto | **Crítico** | P | Usuário que navega até "Contato" encontra tela em branco; risco reputacional e de compliance (único canal in-app para exercício de direitos LGPD) |
| ARQ-101 | `domain/` acopla diretamente a SDKs de infraestrutura (Crashlytics, Analytics, plugin nativo Spotify) | Arquitetura | Atenção | M | Testar use cases isoladamente exige o Flutter engine; trocar de fornecedor de crash/analytics exige editar `domain/` |
| ARQ-102 | Reporte de erro inesperado inconsistente — alguns repositórios não chamam `reportNonFatalError` no catch genérico | Código | Atenção | P | Erros reais em `musica_repository_impl.dart`, `faq_repository_impl.dart`, `musica_firestore_data_source.dart` ficam invisíveis em produção |
| ARQ-103 | UI de erro duplicada byte a byte entre `player_music_premium_view.dart` e `play_music_free_view.dart` | Código | Atenção | P | Mudança de UX na tela de erro precisa ser replicada manualmente em 2+ lugares, risco de divergência |
| ARQ-104 | Estilo de DI misto dentro de `GameView` (construtor + Service Locator direto) | Arquitetura | Atenção | P | Dificulta rastrear todas as dependências de uma view só pelo construtor |
| ARQ-105 | Boilerplate de registro em `di.dart` ainda alto (~180 linhas para ~15 dependências) | Arquitetura | Atenção (informativo) | M | Ponto de atrito crescente se o número de features dobrar; não é problema hoje |
| ARQ-106 | Granularidade assimétrica entre hierarquias irmãs de `Failure` (`PreviewPlaybackFailure` só tem 1 variante) | Código | Atenção (menor) | P | Inconsistência de nível de detalhe entre domínios de erro parecidos |
| SEC-001 | `SPOTIFY_CLIENT_ID` no histórico git (repositório confirmado privado, risco atenuado) | Segurança | Atenção (Média) | P | Exposição só se o repositório for tornado público sem rotação prévia da credencial |
| SEC-002 | Sem revogação de consentimento Spotify dentro do app | Segurança/Compliance | Atenção | P | Usuário não consegue "desconectar" de fato pelo app; inconsistente com facilidade de revogação exigida pela LGPD |
| SEC-003 | `allowBackup` não desabilitado no `AndroidManifest.xml` | Segurança/Compliance | Atenção | P | Contradiz promessa da política de privacidade sobre dados locais não saírem do dispositivo |
| SEC-005 | 18 dependências desatualizadas, 1 transitiva (`path_provider_foundation`) retracted | Infra/Dependências | Atenção | M | Versão retracted pode ser removida do pub.dev a qualquer momento, quebrando builds futuros |
| SEC-006 | Sem rate limiting/App Check na leitura pública da coleção `musicas` | Segurança | Baixa | M | Scraping completo do catálogo é tecnicamente possível; sem dado sensível envolvido |
| EXP-002 | Botão "voltar" duplicado em 5+ arquivos sem componentização | Código/UX | Atenção | P | Mecanismo raiz do EXP-001 permanecer incompleto — correções não se propagam |
| EXP-004 | Estado de erro do FAQ cai em container vazio, sem mensagem nem retry | Código/UX | Atenção | P | Falha de leitura do FAQ local vira tela em branco sem explicação |
| EXP-005 | Uso inconsistente dos tokens de design (`AppPadding`/`FontSize`) já existentes | Código/UX | Atenção | M | Mudança de escala de espaçamento/tipografia não se propaga uniformemente |
| EXP-006 | Typo `bagroundColor` propagado como nome oficial do token em 17 arquivos | Código/DX | Atenção | M (rename amplo) | Autocomplete não encontra o token esperado; perpetua o erro em novos arquivos |
| EXP-007 | Nomenclatura português/inglês mista (`Musica*` vs. resto do código em inglês) | Código/DX | Atenção | G (rename amplo) | Fricção de DX para quem chega de outras partes do código |
| OPS-001 | `SpotifyPlaybackControlRepositoryImpl` sem tratamento de erro nem teste de falha (33,3% cobertura) | Testes/Resiliência | Atenção | M | Falha real durante partida (Bluetooth cai, app Spotify fecha) sem rede de segurança nem visibilidade |
| OPS-002 | `PreviewPlaybackControlRepositoryImpl` (just_audio) em 0% de cobertura, sem try/catch em `load()` | Testes/Resiliência | Atenção | M | Mesma classe de risco do OPS-001, no fluxo Free |
| OPS-003 | Guard de conectividade (`network_info.dart`, `connectivity_guard.dart`) sem teste | Testes | Atenção | P | Comportamento de bloqueio "sem internet" sem confirmação automatizada |
| OPS-004 | >1000 linhas de telas frequentes (Settings, FAQ, Home, Splash, Rules) sem nenhum teste | Testes | Atenção | G | Regressões nessas telas não são pegas automaticamente pelo CI |
| OPS-005 | CI não gera artefato de build (APK/AAB) nem publica cobertura de forma visível (badge/comentário em PR) | CI/CD | Atenção (informativo) | P–M | Necessário baixar `lcov.info` manualmente para ver detalhe por arquivo |
| PERF-001 | Caches em memória (`_cache`, `_previewCache`) sem TTL/limite, sem telemetria para reavaliar | Performance | Atenção | P (instrumentar) | Decisão de não agir permanece suposição informada, não conclusão medida, mesmo com Analytics já disponível |
| PERF-002 | Token de acesso Spotify sem cache/expiração explícita no lado Dart | Performance | Atenção | P | Overhead pequeno de platform channel por música tocada; depende do comportamento interno não confirmado do SDK nativo |
| DOC-001 | Cabeçalhos dos 5 documentos de análise desatualizados em relação ao corpo | Docs | Atenção | P | Corrigido nesta própria versão 3.0 |
| DOC-002 | `CHANGELOG.md` documenta apenas 1 de ~15 mudanças relevantes desde sua criação | Docs | Atenção | P (processo) | Risco de o changelog virar documento decorativo |
| DOC-003 | Sem tags Git; `pubspec.yaml` congelado em `1.0.0+1` desde o commit inicial | Docs/Processo | Atenção | P (processo) | Impossível rastrear o que mudou entre "versões" sem ler o Git log inteiro |
| DOC-004 | Dependências desatualizadas sem política de cadência de atualização documentada | Docs/Processo | Atenção | P | Decisão de quando atualizar fica ad-hoc, sem critério registrado |
| DOC-006 | ADRs não cobrem decisões de produto/governança relevantes já tomadas (idioma único, gate de cobertura 40%) | Docs | Atenção (menor) | P | Racional dessas decisões só existe como linha de plano de ação, documento por natureza transitório |

---

## Débitos críticos vs. aceitáveis

### Críticos (ação recomendada no curto prazo)
- **EXP-001** e **EXP-003** são os únicos itens desta reanálise classificados como críticos — ambos no eixo Experiência, ambos com impacto direto e imediato no usuário final (um bloqueia o uso do app por pessoas com deficiência visual em uma etapa obrigatória; o outro é uma feature documentada como pronta que não existe de fato).

### Aceitos conscientemente (com justificativa)
- **PERF-001** (caches sem TTL) — decisão já tomada e reafirmada nesta reanálise: o volume esperado (sessão de jogo física) não justifica ação preventiva. Recomendação é instrumentar antes de agir, não agir diretamente.
- **DOC-003** (sem tags/versionamento semântico) — aceitável em pré-lançamento; passa a ser um problema real só quando houver a primeira release pública de fato.
- **SEC-006** (sem rate limiting no Firestore) — aceitável dado que o catálogo é público por design e não contém dado sensível.
- **OPS-005** (CI sem geração de artefato/deploy) — aceitável para o estágio de pré-lançamento atual; é um gate de qualidade, não um pipeline de entrega, e essa é uma escolha deliberada e razoável para o momento.

---

## Recomendação de priorização

1. **EXP-003** (Contato vazio) — esforço P, resolve uma inconsistência crítica de produto/compliance rapidamente.
2. **EXP-001** (acessibilidade) — esforço G, mas o bloco em `camera_permission_view.dart` (fluxo obrigatório) deveria ser tratado com prioridade isolada antes do restante das telas.
3. **OPS-001/OPS-002** (resiliência do controle de playback) — esforço M cada, fecham a maior lacuna de confiabilidade identificada nesta sessão.
4. **SEC-002/SEC-003** (revogação de consentimento, `allowBackup`) — esforço P cada, fecham lacunas de compliance de baixo custo de implementação.
5. Demais itens de Documentação/Performance seguem como fluxo contínuo de manutenção, sem urgência isolada.
