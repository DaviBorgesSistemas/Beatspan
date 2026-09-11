# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Added

- Analytics de produto (Firebase Analytics) instrumentando o funil de escaneamento→reprodução: `qr_scanned`, `qr_invalid`, `musica_lookup_failed`, `playback_started` (com fonte: faixa completa Premium vs. prévia de 30s), `playback_failed` e `itunes_fallback_used` quando a prévia é resolvida via iTunes em vez do Spotify.

### Changed

### Fixed

### Removed
