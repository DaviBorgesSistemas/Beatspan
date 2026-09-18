# Beatspan

*[Read in English](README.en.md)*

Beatspan é um app em Flutter que acompanha um jogo de cartas de música no estilo **Hitster**: cada carta física traz um QR code apontando para `beatspangame.com/<código>`. Lido pelo app, o código é resolvido no Firestore (coleção `musicas`) para a faixa correspondente no Spotify e tocado; lido por qualquer outro leitor de QR, abre a landing page de download hospedada no Firebase Hosting (`hosting/`). Os jogadores tentam adivinhar música, artista e ano posicionando a carta numa linha do tempo.

## Funcionalidades

- **Splash** e onboarding no primeiro acesso (`first_time`, `privacy_consent`), com persistência local das preferências. App em português (pt-BR) apenas — sem seleção de idioma/país.
- **Permissão de câmera** tratada em uma tela dedicada (`camera_permission`) antes de abrir o scanner.
- **Leitura de QR code** via câmera (`mobile_scanner`), validando links do domínio `beatspangame.com` (e dos domínios do Firebase Hosting usados durante o desenvolvimento).
- **Resolução da faixa via Firestore** — o código extraído da URL é buscado na coleção `musicas`, que retorna o `spotify_uri` da faixa (ver `docs/2-SECURITY_REPORT.md` para o schema e as regras de segurança).
- **Reprodução da faixa via Spotify** — usuários Premium tocam a música completa pelo Spotify App Remote (`spotify_sdk`); usuários do plano Free buscam a prévia de 30s via Spotify Web API, com fallback para iTunes Search API (`spotify_free_transition` cobre a transição entre os dois modos).
- **Tela de regras** do jogo com ilustrações.
- **FAQ** carregado de um JSON local (`assets/json/faq.json`), com repositório e use case dedicados.
- **Configurações**: troca de conta Spotify, upgrade para Premium, contato e compartilhamento do app.
- **Crash reporting e analytics** via `firebase_crashlytics` e `firebase_analytics`.

## Stack técnica

| Categoria | Pacote |
|---|---|
| Injeção de dependência | `get_it` |
| Result/Either | `dartz` |
| Persistência local | `shared_preferences` |
| Configuração por ambiente | `--dart-define-from-file` (compile-time) |
| Backend / catálogo de músicas | `firebase_core`, `cloud_firestore` |
| Observabilidade | `firebase_crashlytics`, `firebase_analytics` |
| Rede / conectividade | `http`, `connectivity_plus` |
| Integração Spotify | `spotify_sdk` (App Remote + Auth), Web API via `http` |
| Leitura de QR code | `mobile_scanner` |
| Permissões | `permission_handler` |
| Sensores (giroscópio / proximidade) | `sensors_plus`, `proximity_sensor` |
| Áudio (preview local) | `just_audio` |
| Imagens em cache | `cached_network_image` |
| Notificações in-app | `fluttertoast` |
| Splash / ícone do app | `flutter_native_splash`, `flutter_launcher_icons` |

## Arquitetura

Clean Architecture simplificada, com `presentation/` organizada por feature e `data/`/`domain/` genéricos:

```
lib/
├── app/            # App widget, AppPreferences (shared_preferences), configuração de DI (get_it)
├── data/
│   ├── data_source/    # ex.: FaqLocalDataSource (lê assets/json/faq.json)
│   ├── network/         # SpotifyService (App Remote), SpotifyWebApi (REST), MusicaFirestoreDataSource,
│   │                     # ContactFirestoreDataSource, ItunesSearchApi, NetworkInfo, Retry
│   └── repository/      # implementações dos repositórios (Faq, Musica, MusicaPlayback,
│                         # PreviewPlaybackControl, SpotifyPlaybackControl, Contact)
├── domain/
│   ├── enum/            # FlowState, PlanType, TurnPhoneMode, GameModeType
│   ├── exception/        # exceções de domínio (contato, música)
│   ├── exceptions/       # exceções de reprodução, rate limit e consentimento Spotify
│   ├── model/            # modelos de domínio (Faqs, Musica, MusicaPlaybackResult, PlaybackState, ContactMessage)
│   ├── repository/       # contratos abstratos
│   └── usecase/          # casos de uso (FaqsUsecase, GetMusicaUseCase, MusicaPlaybackUseCase,
│                         # SpotifyPlaybackUseCase, PreviewPlaybackUseCase, SendContactMessageUseCase)
└── presentation/
    ├── splash, first_time, privacy_consent, camera_permission, home, game, rules,
    │   settings, faqs, contact, change_spotify, spotify_free_transition, share
    └── resource/         # gerenciadores de cor, fonte, estilo, tema, tela e assets
```

> A reprodução de faixas (Spotify App Remote, Web API e fallback iTunes) já passa por repository + usecase (`MusicaPlaybackUseCase`), assim como contato e FAQ — `GameViewModel` não fala mais diretamente com os services de rede.
>
> Observação: existem duas pastas de exceções (`domain/exception/` e `domain/exceptions/`) por herança histórica; ao adicionar novas exceções de domínio, prefira consolidar em uma só.

## Fluxo principal do jogo

1. No primeiro acesso, o app passa por `first_time`/`privacy_consent` e, ao abrir a câmera pela primeira vez, por `camera_permission`.
2. Na `HomeView`, o jogador toca em "Começar um jogo".
3. A `GameView` abre a câmera para escanear o QR code da carta.
4. O app valida se a URL escaneada é do domínio `beatspangame.com` e extrai o código curto (ex.: `0006`).
5. O código é resolvido pelo `GetMusicaUseCase`, que busca na coleção `musicas` do Firestore e retorna o `spotify_uri` da faixa.
6. O `MusicaPlaybackUseCase` decide a reprodução conforme o plano salvo (`PlanType`):
   - **Premium**: conecta ao Spotify App Remote e reproduz a faixa completa.
   - **Free**: busca a URL de prévia (30s) via Spotify Web API, com fallback para iTunes Search API se a prévia não estiver disponível.

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.9.2`
- Conta de desenvolvedor no [Spotify for Developers](https://developer.spotify.com/) para obter `Client ID` e `Redirect URI`
- Aplicativo Spotify instalado no dispositivo de teste (necessário para o App Remote)
- Projeto no [Firebase Console](https://console.firebase.google.com/) com Firestore e Hosting habilitados
- Android Studio / Xcode configurados para rodar em emulador ou dispositivo físico

## Configuração do Spotify

O app precisa de credenciais do Spotify (Client ID e Redirect URI) para autenticar e tocar as faixas.

- Copie `env.json.example` para `env.json` e preencha `SPOTIFY_CLIENT_ID` e `SPOTIFY_REDIRECT_URL` com suas credenciais. O app lê essas variáveis em tempo de compilação via `String.fromEnvironment` em [lib/app/di.dart](lib/app/di.dart) — sem elas definidas, o app lança um erro claro ao iniciar. Rode/compile passando o arquivo: `flutter run --dart-define-from-file=env.json` (o VS Code já faz isso nas configurações em `.vscode/launch.json`). `env.json` está no `.gitignore` e nunca deve ser versionado nem empacotado como asset — diferente da abordagem anterior com `.env`, os valores de `--dart-define` não são incluídos como arquivo extraível no APK/IPA.

## Configuração do Firebase

O app usa Firestore para resolver o código do QR code na faixa do Spotify (coleção `musicas`) e Firebase Hosting para a landing page servida a quem escaneia a carta fora do app.

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Isso gera `lib/firebase_options.dart` e os arquivos de configuração nativos. Consulte `firestore.rules` para as regras de segurança já versionadas.

## Como rodar

```bash
# instalar dependências
flutter pub get

# rodar em um dispositivo/emulador conectado
flutter run
```

### Gerar ícone e splash screen

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Convenção de commits

O projeto adota [Conventional Commits](https://www.conventionalcommits.org/pt-br/): `<tipo>: <descrição>`, com tipos `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `security`, `style`, `perf`. Mensagens genéricas (`...`, `..`, nomes de tela soltos) não devem mais ser usadas — commits anteriores a essa convenção não foram reescritos (ver `docs/1-ARCHITECTURAL_REVIEW.md`, achado `DOC-004`).

Exemplo: `fix: valida corretamente links de faixa sem prefixo de locale`.

O CI rejeita PRs com commits fora do padrão (ver seção abaixo). Para receber o mesmo aviso já no `git commit` local, ative o hook versionado uma vez por clone:

```bash
git config core.hooksPath .githooks
```

## Integração contínua (CI)

O workflow `.github/workflows/ci.yml` roda em todo PR e push para `master`/`beatspan_v2`:

- **gitleaks** — verifica segredos vazados no histórico do PR.
- Conventional Commits (ver acima), `flutter analyze --fatal-infos` e `dart format --set-exit-if-changed`.
- `flutter test --coverage`, com **gate de cobertura mínima de 60%** das linhas (`coverage/lcov.info`).
- **osv-scanner** — varre `pubspec.lock` em busca de vulnerabilidades conhecidas nas dependências, publicando o SARIF no Code Scanning.

## Release (CD)

O workflow `.github/workflows/cd.yml` gera o APK de release e publica automaticamente no Firebase App Distribution sempre que uma tag no formato `vX.Y.Z` (semver) é enviada ao repositório:

```bash
git tag v1.0.0
git push origin v1.0.0
```

O job roda `flutter analyze`/`flutter test` antes de compilar, reconstrói `android/key.properties`, a keystore e o `env.json` a partir de secrets do repositório (nenhum desses arquivos é versionado) e depois remove esses arquivos do runner. Secrets necessários em **Settings  Secrets and variables  Actions**:

| Secret | Conteúdo |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `upload-keystore.jks` codificado em base64 (`base64 -w0 upload-keystore.jks`) |
| `ANDROID_STORE_PASSWORD` | senha da keystore (`storePassword` do `key.properties`) |
| `ANDROID_KEY_PASSWORD` | senha da chave (`keyPassword`) |
| `ANDROID_KEY_ALIAS` | alias da chave (`keyAlias`) |
| `SPOTIFY_CLIENT_ID` / `SPOTIFY_REDIRECT_URL` | mesmas credenciais do `env.json` local |
| `FIREBASE_APP_ID` | App ID do Firebase (Project settings  General  seção Android) |
| `FIREBASE_SERVICE_ACCOUNT` | JSON da service account com permissão de Firebase App Distribution |

O grupo de testers do Firebase App Distribution usado é `testers` (configurável em `.github/workflows/cd.yml`).

## Estrutura de documentação

A pasta [docs/](docs/) contém uma análise arquitetural completa (fundamentos, segurança, experiência, operações, documentação, performance), gerada a partir de `guides/prompts/PROMPT_ANALISE_ARQUITETURAL.md`:

- [1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) — relatório técnico completo, todos os achados com ID
- [2-SECURITY_REPORT.md](docs/2-SECURITY_REPORT.md) — achados de segurança, checklist LGPD/GDPR, status do supply chain
- [3-TECH_DEBT_REGISTER.md](docs/3-TECH_DEBT_REGISTER.md) — catálogo de débito técnico priorizado
- [4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) — plano de ação por prazo, com checklist de progresso
- [5-IMPROVEMENT_ROADMAP.md](docs/5-IMPROVEMENT_ROADMAP.md) — roadmap de melhoria por fase

## Status do projeto

Projeto em desenvolvimento ativo, pré-lançamento (ainda não publicado nas lojas). Pontos conhecidos em aberto:

- Rodadas, pontuação e linha do tempo são geridas pelos próprios jogadores com as cartas físicas (o ano vem impresso na carta) — por design, o app só cobre o fluxo de escanear e tocar a música, sem precisar modelar isso digitalmente.
- Sem suporte a multiplayer ou estado sincronizado entre dispositivos.
- Cobertura de testes já cobre `GameView`/viewmodel/players (ver `test/presentation/game/`), mas ainda não é completa em todas as features.
- Build iOS não configurado — apenas Android está funcional hoje.

Consulte [docs/1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) para o levantamento técnico completo e [docs/4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) para o plano de correção priorizado, com checklist de progresso.
