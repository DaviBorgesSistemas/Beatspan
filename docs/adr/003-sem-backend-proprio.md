# ADR-003: Sem backend próprio — Firestore como catálogo, Spotify SDK direto no cliente

**Status:** Aceito
**Data:** 2026-09-11 (decisão já vigente no código; documentada retroativamente)

## Contexto

O app precisa: (1) resolver um código de carta para os metadados de uma
música (`spotify_uri`, nome, artista, capa), e (2) autenticar e controlar a
reprodução no Spotify do jogador. Nenhum dos dois fluxos exige lógica de
servidor que não possa ser feita com segurança direto no cliente.

## Decisão

- O catálogo de músicas vive inteiramente no Firestore (coleção `musicas`),
  lido diretamente pelo app (`lib/data/network/musica_firestore_data_source.dart`)
  sem nenhuma API intermediária própria.
- `firestore.rules` restringe a coleção a leitura pública e escrita sempre
  negada (`allow write: if false`), com deny-all explícito para qualquer
  outra coleção — a superfície de escrita do catálogo é gerenciada fora do
  app (ex. console/script administrativo, não documentado neste ADR por
  não fazer parte do código do app).
- A autenticação e o controle de reprodução do Spotify usam o SDK oficial
  (`spotify_sdk`, App Remote) e a Web API do Spotify diretamente do
  dispositivo do jogador — o token OAuth é obtido e gerenciado pelo próprio
  SDK, nunca passa pelo app em texto persistido (`app_prefs.dart` não tem
  chave de token) nem por um servidor do projeto.
- Não há Cloud Functions, API própria, nem qualquer processo de backend sob
  controle do time — `firestore.indexes.json` está vazio (coerente com uma
  leitura por chave de documento, não por query) e não existe diretório
  `functions/` no repositório.

## Alternativas consideradas

Um backend próprio (ex. Cloud Functions validando/transformando o catálogo,
ou um proxy para a Web API do Spotify) permitiria esconder lógica adicional
do cliente, mas não há registro de que isso tenha sido avaliado e descartado
formalmente — a ausência de backend parece ter sido a escolha natural dado
o escopo do produto (catálogo somente-leitura, sem dado sensível de servidor
a proteger) mais do que uma alternativa descartada após comparação.

## Consequências

**Facilita:**
- Custo de infraestrutura limitado aos limites de uso do Firebase (sem
  servidor próprio para provisionar, escalar ou manter no ar).
- Superfície de ataque menor: não há API própria para autenticar, ratelimitar
  ou proteger contra abuso — a fronteira de segurança real são as Firestore
  Rules (ver `docs/2-SECURITY_REPORT.md`, SEC-S1) e as regras nativas do
  Spotify OAuth.

**Custa:**
- Qualquer lógica de servidor futura (ex. moderar o catálogo, agregar
  analytics de uso do lado do servidor, aplicar rate limit próprio acima do
  que o Spotify já impõe) exigiria introduzir infraestrutura nova do zero —
  não há Cloud Functions nem API própria para estender incrementalmente.
- A administração do catálogo (adicionar/editar músicas) depende de um
  processo fora do código do app, não documentado nem versionado neste
  repositório — um ponto cego de governança se a forma de editar o
  catálogo mudar de mãos.
