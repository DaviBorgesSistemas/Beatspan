## O que mudou e por quê

<!-- Resumo objetivo. Se resolve um item do plano de ação, cite o ID (ex. SEC-001, OPS-008). -->

## Este PR marca algum item de `docs/4-ACTION_PLAN.md` como concluído (`[x]`)?

- [ ] Não — pular a seção abaixo.
- [ ] Sim — preencher a seção abaixo **antes de pedir revisão**.

### Se sim: evidência reproduzível por item marcado

> Regra (ver `docs/4-ACTION_PLAN.md`, lição da v1.4 → v2.0): nenhum item é marcado `[x]`
> só porque "lembro que fiz isso". Cole abaixo, para cada item marcado neste PR, o comando
> e a saída (ou o link) que comprova o estado atual do código — não a intenção.

- **`[ID-000]`**: `comando rodado` → resultado colado aqui

## Checklist do revisor

- [ ] Para cada item de `docs/4-ACTION_PLAN.md` marcado `[x]` neste PR, a evidência acima
      foi conferida rodando o mesmo comando (ou abrindo o mesmo link) — não apenas lida.
- [ ] Nenhum segredo (`.env`, chaves, tokens) está no diff (`git diff --stat` limpo de
      arquivos sensíveis; o gate `gitleaks` do CI também cobre isso).
- [ ] `flutter analyze` e `flutter test` passam no CI deste PR.
