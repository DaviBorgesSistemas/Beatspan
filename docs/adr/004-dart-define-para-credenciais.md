# ADR-004: Injeção de credenciais via `--dart-define`, não `flutter_dotenv`

**Status:** Aceito
**Data:** 2026-09-12

## Contexto

O app precisa do `SPOTIFY_CLIENT_ID` e do `SPOTIFY_REDIRECT_URL` em tempo de
execução para o fluxo OAuth do Spotify. A abordagem original usava
`flutter_dotenv` lendo um arquivo `.env` declarado como asset Flutter em
`pubspec.yaml`. Uma revisão de segurança (`docs/SECURITY_REPORT.md`, achado
SEC-001) constatou que assets Flutter são compilados em texto plano dentro
do pacote de release (`flutter_assets/.env` extraível de um APK/IPA sem
root, via `apktool` ou equivalente), expondo as credenciais a qualquer
pessoa com acesso ao binário publicado.

## Decisão

- `flutter_dotenv` foi removido do `pubspec.yaml` e o `.env` deixou de ser
  asset do app.
- As credenciais passam a ser injetadas em tempo de build via
  `--dart-define-from-file=env.json` (arquivo local, fora do controle de
  versão — ver `env.json.example` como modelo) e lidas em
  `lib/app/di.dart` com `String.fromEnvironment('SPOTIFY_CLIENT_ID')` /
  `String.fromEnvironment('SPOTIFY_REDIRECT_URL')`, validadas por
  `_requiredEnv` (falha explícita se ausentes, em vez de valor vazio
  silencioso).
- O Client ID que esteve embutido nos builds anteriores foi revogado e
  substituído por um novo no Spotify Developer Dashboard, já que o valor
  antigo deve ser considerado comprometido.

## Alternativas consideradas

- **Manter `flutter_dotenv`, mas servir o `.env` de um endpoint autenticado
  em runtime** (opção "aceitável" listada no relatório de segurança): foi
  descartada por exigir infraestrutura de backend adicional, algo que o
  projeto evita por decisão própria (ver [ADR-003](003-sem-backend-proprio.md)).
- **Buscar a credencial de uma fonte remota como Firebase Remote
  Config/Firestore em runtime:** avaliada informalmente e descartada — o
  `SPOTIFY_CLIENT_ID` é um identificador público do fluxo OAuth
  Authorization Code with PKCE (não um `client_secret`), então buscar seu
  valor de um serviço remoto não aumenta a segurança (o valor acaba do
  mesmo jeito na memória do app, visível via proxy/MITM) e adiciona uma
  dependência de rede e lógica de fallback sem benefício real de sigilo. O
  ganho seria puramente operacional (trocar o valor sem novo build), o que
  não justificou a complexidade extra neste momento.

## Consequências

**Facilita:**
- Nenhum segredo/identificador de configuração fica embutido como arquivo
  legível no pacote de release — extrair o binário não expõe
  `SPOTIFY_CLIENT_ID`/`SPOTIFY_REDIRECT_URL` em texto plano.
- Falha rápida e explícita (`_requiredEnv`) se alguém tentar rodar um build
  sem as variáveis definidas, em vez de o app subir silenciosamente
  com credencial vazia.

**Custa:**
- Toda troca de credencial (ex. rotação do Client ID) exige gerar um novo
  build e redistribuí-lo — não há mecanismo de atualização remota dessas
  variáveis (trade-off aceito conscientemente, ver alternativas acima).
- Quem builda localmente precisa manter um `env.json` próprio (fora do
  controle de versão) e lembrar de passá-lo via
  `--dart-define-from-file`; esquecer a flag faz o build falhar em
  `_requiredEnv` em vez de compilar silenciosamente sem as credenciais.
