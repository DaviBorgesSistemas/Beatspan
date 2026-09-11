# Beatspan

*[Read in English](README.en.md)*

Beatspan é um app em Flutter que acompanha um jogo de cartas de música no estilo **Hitster**: cada carta física traz um QR code apontando para `beatspangame.com/<código>`. Lido pelo app, o código é resolvido no Firestore (coleção `musicas`) para a faixa correspondente no Spotify e tocado; lido por qualquer outro leitor de QR, abre a landing page de download hospedada no Firebase Hosting (`hosting/`). Os jogadores tentam adivinhar música, artista e ano posicionando a carta numa linha do tempo.

## Funcionalidades

- **Splash** no primeiro acesso, com persistência local das preferências. App em português (pt-BR) apenas — sem seleção de idioma/país.
- **Leitura de QR code** via câmera (`mobile_scanner`), validando links do domínio `beatspangame.com` (e dos domínios do Firebase Hosting usados durante o desenvolvimento).
- **Resolução da faixa via Firestore** — o código extraído da URL é buscado na coleção `musicas`, que retorna o `spotify_uri` da faixa (ver `docs/2-SECURITY_REPORT.md` para o schema e as regras de segurança).
- **Reprodução da faixa via Spotify** — usuários Premium tocam a música completa pelo Spotify App Remote (`spotify_sdk`); usuários do plano Free buscam a prévia de 30s via Spotify Web API, com fallback para iTunes Search API.
- **Tela de regras** do jogo com ilustrações.
- **FAQ** carregado de um JSON local (`assets/json/faq.json`), com repositório e use case dedicados.
- **Configurações**: troca de conta Spotify, upgrade para Premium, contato e compartilhamento do app.

## Stack técnica

| Categoria | Pacote |
|---|---|
| Injeção de dependência | `get_it` |
| Result/Either | `dartz` |
| Persistência local | `shared_preferences` |
| Configuração por ambiente | `flutter_dotenv` |
| Backend / catálogo de músicas | `firebase_core`, `cloud_firestore` |
| Rede / conectividade | `http`, `connectivity_plus` |
| Integração Spotify | `spotify_sdk` (App Remote + Auth), Web API via `http` |
| Leitura de QR code | `mobile_scanner` |
| Áudio (preview local) | `just_audio` |
| Splash / ícone do app | `flutter_native_splash`, `flutter_launcher_icons` |

## Arquitetura

Clean Architecture simplificada, com `presentation/` organizada por feature e `data/`/`domain/` genéricos:

```
lib/
├── app/            # App widget, AppPreferences (shared_preferences), configuração de DI (get_it)
├── data/
│   ├── data_source/    # ex.: FaqLocalDataSource (lê assets/json/faq.json)
│   ├── network/         # SpotifyService (App Remote), SpotifyWebApi (REST), MusicaFirestoreDataSource, ItunesSearchApi, NetworkInfo
│   └── repository/      # implementações dos repositórios (FaqRepositoryImpl, MusicaRepositoryImpl)
├── domain/
│   ├── enum/            # FlowState, PlanType, TurnPhoneMode, GameModeType
│   ├── exception/        # exceções de domínio (ex.: MusicaNaoEncontradaException)
│   ├── model/            # modelos de domínio (ex.: Faqs, Musica)
│   ├── repository/       # contratos abstratos (FaqRepository, MusicaRepository)
│   └── usecase/          # casos de uso (ex.: FaqsUsecase, GetMusicaUseCase)
└── presentation/
    ├── splash, home, game, rules, settings, faqs, contact,
    │   change_spotify, connect_spotify_premium, share
    └── resource/         # gerenciadores de cor, fonte, estilo, tema, tela e assets
```

> Observação: as features de FAQ e de busca de música por código (Firestore) implementam a stack completa (repository + usecase + datasource). O fluxo de reprodução Spotify/iTunes dentro de `GameView` ainda conversa diretamente com `SpotifyService`/`SpotifyWebApi`/`ItunesSearchApi`, sem repository/usecase — ver `docs/1-ARCHITECTURAL_REVIEW.md`, achado `ARQ-001`.

## Fluxo principal do jogo

1. Na `HomeView`, o jogador toca em "Começar um jogo".
2. A `GameView` abre a câmera para escanear o QR code da carta.
3. O app valida se a URL escaneada é do domínio `beatspangame.com` e extrai o código curto (ex.: `0006`).
4. O código é buscado na coleção `musicas` do Firestore, que retorna o `spotify_uri` da faixa.
5. Conforme o plano salvo (`PlanType`):
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

- Copie `.env.example` para `.env` e preencha `SPOTIFY_CLIENT_ID` e `SPOTIFY_REDIRECT_URL` com suas credenciais. O app carrega esse arquivo via `flutter_dotenv` na inicialização ([lib/main.dart](lib/main.dart)) e lê as variáveis em [lib/app/di.dart](lib/app/di.dart) — sem elas definidas, o app lança um erro claro ao iniciar.

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

**Verificação automática:** o CI rejeita PRs com commits fora do padrão (step "Verificar Conventional Commits" em `.github/workflows/ci.yml`). Para receber o mesmo aviso já no `git commit`, local, ative o hook versionado uma vez por clone:

```bash
git config core.hooksPath .githooks
```

## Estrutura de documentação

A pasta [docs/](docs/) contém uma análise arquitetural completa (fundamentos, segurança, experiência, operações, documentação, performance), gerada a partir de `guides/prompts/PROMPT_ANALISE_ARQUITETURAL.md`:

- [1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) — relatório técnico completo, todos os achados com ID
- [2-SECURITY_REPORT.md](docs/2-SECURITY_REPORT.md) — achados de segurança, checklist LGPD/GDPR, status do supply chain
- [3-TECH_DEBT_REGISTER.md](docs/3-TECH_DEBT_REGISTER.md) — catálogo de débito técnico priorizado
- [4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) — plano de ação por prazo, com checklist de progresso
- [5-IMPROVEMENT_ROADMAP.md](docs/5-IMPROVEMENT_ROADMAP.md) — roadmap de melhoria por fase

## Status do projeto

Projeto em desenvolvimento ativo, pré-lançamento (ainda não publicado nas lojas). Pontos conhecidos em aberto:

- Ainda não há modelo de jogo (rodadas, pontuação, timeline, vitória) implementado — o app cobre hoje o fluxo de escanear e tocar a música.
- Sem suporte a multiplayer ou estado sincronizado entre dispositivos.
- Cobertura de testes ainda inicial (ver `test/`) — falta cobrir `GameView`/players.
- Build iOS não configurado — apenas Android está funcional hoje.

Consulte [docs/1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) para o levantamento técnico completo e [docs/4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) para o plano de correção priorizado, com checklist de progresso.
