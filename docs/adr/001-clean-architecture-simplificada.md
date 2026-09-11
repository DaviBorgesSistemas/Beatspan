# ADR-001: Clean Architecture simplificada (presentation/domain/data)

**Status:** Aceito
**Data:** 2026-09-11 (decisão já vigente no código; documentada retroativamente)

## Contexto

O app precisa resolver um código de carta em um catálogo (Firestore) e
reproduzir uma faixa (Spotify App Remote ou prévia via iTunes), com regras de
negócio (qual plano/modo usar, como tratar falha de autorização, fallback
para prévia) que não deveriam ficar acopladas a widgets do Flutter nem à
implementação concreta do Firestore/Spotify SDK.

## Decisão

O código é organizado em três camadas por toda a aplicação:

- `lib/domain/`: contratos (`repository/*.dart` como `abstract class`),
  `usecase/*.dart` (orquestram regra de negócio), modelos e `Failure`
  (ver ADR-002). Não depende de Flutter nem de nenhum pacote de
  infraestrutura (Firestore, Spotify SDK, `dio`/`http`).
- `lib/data/`: implementações concretas dos contratos de `domain/`
  (`repository/*_impl.dart`), datasources que falam com Firestore/Spotify
  Web API/iTunes Search API, e tratamento de erro de rede (`network/`).
- `lib/presentation/`: uma pasta por feature (`game/`, `faqs/`,
  `change_spotify/`...), cada uma com sua View e, quando há lógica de
  apresentação não-trivial, um ViewModel simples (não é um MVVM completo
  com binding automático — é um objeto que expõe estado via `ValueNotifier`
  e métodos, consumido manualmente pela View).

Os fluxos de Música e FAQ implementam a stack completa (repository abstrato
→ impl → usecase → datasource), todos com teste de unidade via `mocktail`.
`get_it` resolve as dependências entre camadas (`lib/app/di.dart`).

## Alternativas consideradas

Não há registro de que outras arquiteturas (ex. MVC simples, BLoC completo
com `flutter_bloc`, Riverpod) tenham sido avaliadas formalmente antes desta
decisão — ela já estava em vigor desde o início do histórico de commits
disponível. Este ADR documenta o estado já adotado, não uma escolha entre
alternativas concorrentes que foram de fato comparadas.

## Consequências

**Facilita:**
- Testar regra de negócio (`usecase`) sem precisar de Firestore/Spotify
  reais — só um mock do contrato de `domain/repository`.
- Trocar a fonte de dados (ex. outro backend de catálogo) sem tocar em
  `presentation/`, desde que o contrato de `domain/repository` seja mantido.

**Custa:**
- Mais arquivos/indireção do que uma solução direta para um app deste
  porte (~89 arquivos Dart em `lib/` para um fluxo central relativamente
  simples: escanear → resolver → tocar).
- Boilerplate de registro repetitivo em `lib/app/di.dart` (ver débito
  técnico ARQ-004, aceito como baixo risco).
- A separação não é absoluta: `presentation/` ainda importa tipos de
  `domain/` diretamente (ex. `Failure` e suas subclasses, ver ADR-002) —
  não há uma camada de mapeamento presentation-only para erros.
