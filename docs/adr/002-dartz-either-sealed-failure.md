# ADR-002: `dartz`/`Either` para erros de domínio, com `Failure` como sealed class por use case

**Status:** Aceito
**Data:** 2026-09-11 (decisão já vigente no código; documentada retroativamente
— a forma atual de `Failure`, com sealed class por domínio, veio do commit
`ad8438c`, que substituiu uma versão anterior mais genérica)

## Contexto

Cada use case (`MusicaPlaybackUseCase`, `SpotifyPlaybackUseCase`,
`PreviewPlaybackUseCase`, `GetMusicaUseCase`, `FaqsUseCase`) precisa
comunicar à camada de apresentação não só "deu erro", mas qual erro
especificamente, para a UI decidir a mensagem certa (ex.: "prévia
indisponível" vs. "Spotify não autorizado" vs. "erro de conexão").
Lançar exceções para esse controle de fluxo esperado (erros de negócio,
não bugs) misturaria erro previsto com erro inesperado, e usar códigos
`int` genéricos (a forma anterior do projeto) permitia que o mesmo valor
significasse coisas diferentes em use cases distintos.

## Decisão

- Toda operação de use case que pode falhar retorna
  `Future<Either<F, Out>>` (pacote `dartz`), nunca lança uma exceção de
  domínio esperada.
- `F` é sempre uma subclasse de `Failure` (`lib/domain/failure.dart`),
  que é uma `sealed class`. Cada use case declara sua própria sealed
  subclass (`MusicaFailure`, `MusicaPlaybackFailure`,
  `SpotifyPlaybackFailure`, `PreviewPlaybackFailure`, `FaqFailure`), com
  variantes concretas nomeadas pelo cenário real (ex.
  `MusicaPlaybackUriInvalida`, `SpotifyPlaybackLimiteRequisicoes`).
- A camada de apresentação consome o resultado com `switch` exaustivo
  sobre o tipo da falha (o compilador força tratar toda variante conhecida
  quando a sealed class ganha uma nova subclasse), em vez de comparar um
  código numérico.
- Exceções (`try`/`catch`) continuam existindo para erro *inesperado*
  (bug, falha de rede não classificada) — nesse caso, o use case captura,
  reporta via `reportNonFatalError` (Crashlytics) e converte para uma
  variante `*ErroInesperado`/`*ErroConexao` de `Failure`, mantendo o
  contrato de retorno consistente mesmo no caminho de erro não previsto.

## Alternativas consideradas

- **Exceções para tudo** (inclusive erro de negócio esperado): descartado
  porque não força o chamador a tratar cada caso — um `catch` genérico
  esconde qual falha específica ocorreu, e o compilador não ajuda a
  garantir cobertura de casos.
- **`Failure` genérico com código `int`** (forma anterior do projeto):
  descartado porque o mesmo código podia significar coisas diferentes em
  use cases distintos (ex. `1` era "erro de autorização do Spotify" em um
  lugar e "URI inválida" em outro) — um risco real se um `Failure` fosse
  reaproveitado fora do arquivo onde foi originado.

## Consequências

**Facilita:**
- Mensagens de erro específicas e corretas por cenário na UI, sem
  `if (code == N)` espalhado.
- Segurança em tempo de compilação: adicionar uma nova variante de falha
  e esquecer de tratá-la em um `switch` existente vira erro de análise
  (`flutter analyze`), não um bug silencioso em produção.

**Custa:**
- Mais tipos para declarar por use case (uma sealed class + N variantes)
  comparado a um `Failure` único genérico.
- `dartz` como dependência externa para `Either`/`Unit` em vez do suporte
  nativo do Dart (ex. um `Result` própria ou pattern matching sobre
  exceções) — decisão anterior ao uso de `sealed class`, quando o suporte
  de pattern matching exaustivo do Dart para isso era mais limitado.
