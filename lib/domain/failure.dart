// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

/// Base de toda falha de domínio. Cada use case declara sua própria sealed
/// subclass (ex.: [MusicaPlaybackFailure]) com as variantes possíveis —
/// evita que códigos numéricos de use cases distintos colidam ou sejam
/// comparados fora do contexto de origem. Handlers em `presentation/`
/// tratam cada hierarquia com `switch` exaustivo em vez de `if (code == N)`.
sealed class Failure {
  String get message;
}

/// Falhas de [GetMusicaUseCase]/`MusicaRepository`.
sealed class MusicaFailure implements Failure {
  const MusicaFailure();
}

class MusicaNaoEncontrada extends MusicaFailure {
  const MusicaNaoEncontrada();

  @override
  String get message => 'Música não encontrada';
}

class MusicaConsultaErro extends MusicaFailure {
  @override
  final String message;

  const MusicaConsultaErro(this.message);
}

/// Falhas de [MusicaPlaybackUseCase].
sealed class MusicaPlaybackFailure implements Failure {
  const MusicaPlaybackFailure();
}

class MusicaPlaybackUriInvalida extends MusicaPlaybackFailure {
  const MusicaPlaybackUriInvalida();

  @override
  String get message => 'URI inválida';
}

class MusicaPlaybackPreviaIndisponivel extends MusicaPlaybackFailure {
  const MusicaPlaybackPreviaIndisponivel();

  @override
  String get message => 'Prévia indisponível';
}

/// Falha real de rede/conectividade (timeout, sem internet, resposta
/// inválida do servidor) — distinto de [MusicaPlaybackSpotifyNaoAutorizado].
class MusicaPlaybackErroConexao extends MusicaPlaybackFailure {
  @override
  final String message;

  const MusicaPlaybackErroConexao(this.message);
}

/// Falha de autorização/configuração do Spotify (app não autorizado, plugin
/// ausente, erro de autenticação do SDK) — não é um problema de internet.
class MusicaPlaybackSpotifyNaoAutorizado extends MusicaPlaybackFailure {
  @override
  final String message;

  const MusicaPlaybackSpotifyNaoAutorizado(this.message);
}

class MusicaPlaybackErroInesperado extends MusicaPlaybackFailure {
  @override
  final String message;

  const MusicaPlaybackErroInesperado(this.message);
}

/// Falhas de [SpotifyPlaybackUseCase].
sealed class SpotifyPlaybackFailure implements Failure {
  const SpotifyPlaybackFailure();
}

class SpotifyPlaybackNaoAutorizado extends SpotifyPlaybackFailure {
  @override
  final String message;

  const SpotifyPlaybackNaoAutorizado(this.message);
}

class SpotifyPlaybackErroInesperado extends SpotifyPlaybackFailure {
  @override
  final String message;

  const SpotifyPlaybackErroInesperado(this.message);
}

/// O plugin nativo `spotify_sdk` não está registrado para este engine/build
/// — distinto de uma falha de autorização, pois nem chega a tentar conectar.
class SpotifyPlaybackPluginAusente extends SpotifyPlaybackFailure {
  @override
  final String message;

  const SpotifyPlaybackPluginAusente(this.message);
}

/// Limite de requisições da Web API do Spotify atingido (HTTP 429), mesmo
/// após o retry automático que já respeita o header `Retry-After`.
class SpotifyPlaybackLimiteRequisicoes extends SpotifyPlaybackFailure {
  @override
  final String message;
  final Duration retryAfter;

  const SpotifyPlaybackLimiteRequisicoes(this.message, this.retryAfter);
}

/// Falhas de [PreviewPlaybackUseCase].
sealed class PreviewPlaybackFailure implements Failure {
  const PreviewPlaybackFailure();
}

class PreviewPlaybackErroInesperado extends PreviewPlaybackFailure {
  @override
  final String message;

  const PreviewPlaybackErroInesperado(this.message);
}

/// Falhas de [FaqsUseCase]/`FaqRepository`.
sealed class FaqFailure implements Failure {
  const FaqFailure();
}

class FaqErroInesperado extends FaqFailure {
  @override
  final String message;

  const FaqErroInesperado(this.message);
}
