# Changelog

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto adota [Versionamento Semântico](https://semver.org/lang/pt-BR/) (`MAJOR.MINOR.PATCH`, com o `+N` do `pubspec.yaml` como build number do Android).

## Processo de release

1. Atualize a versão em `pubspec.yaml` (`version: X.Y.Z+N`) seguindo semver: `MAJOR` para mudanças incompatíveis, `MINOR` para funcionalidades novas compatíveis, `PATCH` para correções; incremente sempre o build number `+N`.
2. Mova as entradas de `[Não lançado]` para uma nova seção `## [X.Y.Z] - AAAA-MM-DD` neste arquivo.
3. Commit dessas mudanças e crie a tag correspondente:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
4. A tag dispara `.github/workflows/cd.yml`, que builda o APK de release e publica no Firebase App Distribution (ver seção "Release (CD)" no README).

## [Não lançado]

### Adicionado

- Analytics de produto (Firebase Analytics) instrumentando o funil de escaneamento→reprodução: `qr_scanned`, `qr_invalid`, `musica_lookup_failed`, `playback_started` (com fonte: faixa completa Premium vs. prévia de 30s), `playback_failed` e `itunes_fallback_used` quando a prévia é resolvida via iTunes em vez do Spotify.
- CD (`.github/workflows/cd.yml`): build de APK assinado e publicação no Firebase App Distribution disparados por tag `vX.Y.Z`.
- Tela de privacidade/LGPD (`PrivacyConsentView`), exibida antes do primeiro uso, com links para a Política de Privacidade e os Termos de Uso e consentimento opcional (opt-in) para o Firebase Analytics; consentimento revogável a qualquer momento em Configurações → Privacidade.

### Alterado

### Corrigido

### Removido
