# Architecture Decision Records (ADR)

Registro de decisões de arquitetura do Beatspan. Cada ADR documenta uma
decisão, o contexto que a motivou e as consequências — não é um relatório de
progresso nem um changelog (ver `CHANGELOG.md` na raiz do projeto para isso).

Novas decisões relevantes devem ganhar um ADR novo a partir de agora — não é
necessário reconstruir retroativamente decisões menores já tomadas no
passado sem contexto claro do motivo.

Use `template.md` como ponto de partida.

## Índice

| ADR | Título | Status |
|---|---|---|
| [001](001-clean-architecture-simplificada.md) | Clean Architecture simplificada (presentation/domain/data) | Aceito |
| [002](002-dartz-either-sealed-failure.md) | `dartz`/`Either` para erros de domínio, com `Failure` como sealed class por use case | Aceito |
| [003](003-sem-backend-proprio.md) | Sem backend próprio — Firestore como catálogo, Spotify SDK direto no cliente | Aceito |
