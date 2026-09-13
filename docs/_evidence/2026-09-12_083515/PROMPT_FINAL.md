Atue como um **Arquiteto de Software SÃªnior / Principal Engineer** com experiÃªncia em sistemas de grande escala, seguranÃ§a, cloud, compliance e engenharia de produto.

Realize uma **ANÃLISE ARQUITETURAL COMPLETA, PROFUNDA E CRÃTICA** do projeto no repositÃ³rio atual â€” tÃ©cnica, objetiva e acionÃ¡vel. A anÃ¡lise deve ser crÃ­tica mesmo que o projeto esteja bem estruturado: nÃ£o existe nota 10 "por gentileza". Se algo estiver realmente bom, diga isso com evidÃªncia; se estiver mediano, diga isso tambÃ©m, sem suavizar para soar mais agradÃ¡vel. Calibre a profundidade conforme o tamanho e maturidade do projeto. Quando houver lacunas de informaÃ§Ã£o, sinalize explicitamente ao invÃ©s de assumir.

---

## Regras de execuÃ§Ã£o (leia antes de comeÃ§ar)

1. **NÃ£o modifique o cÃ³digo-fonte do projeto.** Sua Ãºnica saÃ­da em arquivos Ã© a criaÃ§Ã£o dos documentos descritos abaixo, dentro de `docs/`. NÃ£o corrija bugs, nÃ£o aplique patches, nÃ£o rode ferramentas que alterem arquivos (`npm audit fix`, `pub upgrade`, formatadores automÃ¡ticos, etc.) â€” apenas ferramentas de leitura/diagnÃ³stico.
2. **Nunca copie segredos reais para os relatÃ³rios.** Se encontrar chaves de API, tokens, senhas ou credenciais no cÃ³digo, **nÃ£o reproduza o valor** em nenhum arquivo `.md`. Reporte apenas: que existe, o tipo de segredo, e o caminho do arquivo (ex: "credencial de API exposta em `config/firebase.json:12`"). Isso vale mesmo dentro de blocos de cÃ³digo de exemplo.
3. **EvidÃªncia antes de afirmaÃ§Ã£o.** Toda vulnerabilidade, dÃ©bito tÃ©cnico ou ponto crÃ­tico citado deve referenciar arquivo/trecho real encontrado no projeto. NÃ£o Ã© permitido apontar CVEs especÃ­ficos de dependÃªncias a menos que tenham sido de fato confirmados (ex: via `package-lock.json`/`pubspec.lock` cruzado com uma base conhecida, ou uma ferramenta de auditoria que vocÃª realmente executou). Se nÃ£o for possÃ­vel confirmar, escreva "requer verificaÃ§Ã£o com scanner de dependÃªncias (ex: `npm audit`, `pip-audit`, `dart pub outdated --mode=null-safety`, Dependabot)" em vez de inventar um identificador.
4. **Escale o esforÃ§o de leitura ao tamanho do repo.** NÃ£o Ã© necessÃ¡rio ler cada arquivo linha a linha â€” priorize arquivos de configuraÃ§Ã£o, pontos de entrada, camadas centrais (auth, dados, API) e uma amostragem representativa do restante. Se pular uma Ã¡rea por tamanho/tempo, diga isso no relatÃ³rio em vez de fingir cobertura total.
5. **Uma Ãºnica fonte de verdade.** Calcule as notas e a lista de problemas uma vez; os 6 arquivos abaixo devem ser visÃµes diferentes dos *mesmos* achados, nunca anÃ¡lises independentes que podem divergir entre si. Use os IDs definidos na seÃ§Ã£o de output para referenciar o mesmo item em mÃºltiplos arquivos em vez de redigi-lo de novo com detalhes diferentes.
6. **Use TodoWrite para rastrear o trabalho.** Registre como tarefas os 6 eixos de investigaÃ§Ã£o e os 6 arquivos finais a gerar, marcando cada um como concluÃ­do conforme avanÃ§a. Isso evita perder o fio em anÃ¡lises longas e permite retomar caso a sessÃ£o seja interrompida.
7. **Delegue a sub-agentes quando o repositÃ³rio for grande.** Se o projeto tiver mÃºltiplos mÃ³dulos/apps ou muitos arquivos, considere investigar cada eixo (ou cada mÃ³dulo) via tasks paralelas, e sÃ³ depois consolidar os achados em uma lista Ãºnica de IDs antes de escrever os arquivos finais â€” isso evita estourar a janela de contexto lendo tudo sequencialmente.
8. **Preserve o histÃ³rico de anÃ¡lises anteriores.** Antes de escrever qualquer arquivo final, verifique se `docs/` jÃ¡ contÃ©m uma anÃ¡lise anterior (mesmos nomes de arquivo). Se existir, mova os arquivos atuais para `docs/archive/<data-da-analise-anterior>/` antes de gerar a nova versÃ£o â€” nunca sobrescreva silenciosamente. Quando houver anÃ¡lise anterior, inclua no `ARCHITECTURAL_REVIEW.md` uma seÃ§Ã£o "EvoluÃ§Ã£o desde a Ãºltima anÃ¡lise" comparando IDs: resolvidos, novos e regressÃµes.
9. **MÃ©trica quantitativa exige ferramenta real, nÃ£o estimativa visual.** Para cobertura de testes, complexidade ciclomÃ¡tica, acoplamento entre mÃ³dulos e desatualizaÃ§Ã£o de dependÃªncias, rode a ferramenta disponÃ­vel no stack do projeto (ex.: relatÃ³rio de cobertura do test runner; `eslint`/`dart analyze`/`radon`/`lizard` para complexidade; `madge`/`dependency-cruiser`/`pydeps` para grafo de dependÃªncias; `npm audit`/`pip-audit`/`dart pub outdated` para dependÃªncias). Se a ferramenta nÃ£o estiver disponÃ­vel ou nÃ£o puder ser executada no ambiente, declare isso explicitamente ("cobertura nÃ£o medida: ferramenta X indisponÃ­vel/nÃ£o executÃ¡vel") em vez de estimar um nÃºmero.

---

## Eixos de avaliaÃ§Ã£o

### 1. Fundamentos
- OrganizaÃ§Ã£o, coesÃ£o e acoplamento entre mÃ³dulos
- PadrÃµes de design aplicados e anti-patterns identificados
- Qualidade e complexidade ciclomÃ¡tica do cÃ³digo
- DÃ©bito tÃ©cnico acumulado e Ã¡reas de maior risco estrutural

### 2. SeguranÃ§a e Compliance
- Vulnerabilidades identificadas (OWASP Top 10, injeÃ§Ãµes, exposiÃ§Ã£o de dados)
- GestÃ£o de segredos, credenciais e dados sensÃ­veis (ver regra 2 acima)
- LGPD / GDPR: coleta, retenÃ§Ã£o e consentimento
- Supply chain de dependÃªncias (versÃµes desatualizadas; CVEs apenas se confirmados â€” ver regra 3)

### 3. ExperiÃªncia
- UX: usabilidade, acessibilidade (WCAG), responsividade e design system/tokens
- DX (Developer Experience): onboarding, ergonomia de APIs e convenÃ§Ãµes internas
- Performance percebida pelo usuÃ¡rio final

### 4. OperaÃ§Ãµes e Confiabilidade
- Testabilidade: cobertura, tipos de teste (unit, integration, e2e) e qualidade dos casos
- CI/CD: pipeline, automaÃ§Ãµes e estratÃ©gia de branching
- Observabilidade: logs estruturados, mÃ©tricas, rastreamento distribuÃ­do e alertas
- ResiliÃªncia: tratamento de erros, retries, fallbacks e degradaÃ§Ã£o graciosa
- GestÃ£o de custos em cloud (quando aplicÃ¡vel)

### 5. DocumentaÃ§Ã£o e GovernanÃ§a
- DocumentaÃ§Ã£o tÃ©cnica: README, ADRs, diagramas arquiteturais
- GestÃ£o de dependÃªncias e polÃ­tica de atualizaÃ§Ãµes
- Versionamento semÃ¢ntico, changelogs e estratÃ©gia de releases
- Compliance de licenÃ§as open-source das dependÃªncias (ex.: licenÃ§as copyleft como GPL/AGPL em dependÃªncias de um produto proprietÃ¡rio) â€” reporte apenas licenÃ§as de fato identificadas no manifest de dependÃªncias

### 6. Performance e Escalabilidade
- OtimizaÃ§Ãµes de runtime (algoritmos, queries, I/O)
- EstratÃ©gias de cache, CDN e assets
- Capacidade de escala horizontal/vertical e pontos de contenÃ§Ã£o

---

## Rubrica de pontuaÃ§Ã£o (Ã¢ncoras)

Use estas Ã¢ncoras para calibrar cada nota de eixo e o escore geral â€” evite notas "de barriga":

| Faixa | Significado |
|-------|-------------|
| 9â€“10 | NÃ­vel de referÃªncia de mercado; nenhum problema estrutural relevante encontrado; eventuais pontos sÃ£o polimento |
| 7â€“8 | SÃ³lido e funcional; lacunas pontuais e conhecidas, sem risco iminente |
| 5â€“6 | Funcional, mas com dÃ©bito tÃ©cnico ou risco significativo que vai cobrar preÃ§o em mÃ©dio prazo |
| 3â€“4 | FrÃ¡gil; mÃºltiplos problemas estruturais ou de seguranÃ§a que jÃ¡ deveriam ter sido tratados |
| 0â€“2 | Risco arquitetural sÃ©rio; produÃ§Ã£o nÃ£o deveria operar assim sem aÃ§Ã£o imediata |

A justificativa de cada nota deve citar contagem ou evidÃªncia concreta (ex.: "3 endpoints sem validaÃ§Ã£o de entrada", "0% de cobertura em `services/`"), nunca sÃ³ um adjetivo.

---

## OUTPUT â€” ETAPA 1: RESUMO NO CHAT

Antes de criar qualquer arquivo, apresente no chat:

**Escore geral:** X/10 â€” justificativa em 1-2 linhas

**PontuaÃ§Ã£o por eixo:**
| Eixo | Nota | SÃ­ntese |
|------|------|---------|
| Fundamentos | X/10 | ... |
| SeguranÃ§a | X/10 | ... |
| ExperiÃªncia | X/10 | ... |
| OperaÃ§Ãµes | X/10 | ... |
| DocumentaÃ§Ã£o | X/10 | ... |
| Performance | X/10 | ... |

**Pontos fortes** â€” o que estÃ¡ bem e deve ser preservado (com evidÃªncia)
**AtenÃ§Ãµes** â€” problemas relevantes, mas nÃ£o bloqueantes
**CrÃ­ticos** â€” riscos que exigem aÃ§Ã£o imediata

**Cobertura da anÃ¡lise:** liste explicitamente qualquer Ã¡rea do projeto que nÃ£o foi investigada em profundidade e por quÃª (ex: "mÃ³dulo de pagamentos nÃ£o foi auditado em detalhe por escopo/tempo").

---

## OUTPUT â€” ETAPA 2: ARQUIVOS MARKDOWN

Depois do resumo, gere os arquivos abaixo em `docs/` (crie a pasta se nÃ£o existir). Todo achado relevante recebe um ID Ãºnico e estÃ¡vel na primeira vez que aparece (ex: `SEC-001`, `DEBT-001`, `ARQ-001`); os outros arquivos referenciam esse ID em vez de redescrever o item do zero.

Cada arquivo comeÃ§a com um cabeÃ§alho: nome do projeto, data da anÃ¡lise, versÃ£o do documento.

### ðŸ“„ `docs/ARCHITECTURAL_REVIEW.md`
RelatÃ³rio tÃ©cnico completo â€” a fonte primÃ¡ria de achados, cada um com ID.
- VisÃ£o geral do projeto e stack identificada
- Diagrama (Mermaid) da arquitetura/dependÃªncias entre mÃ³dulos principais â€” mesmo que simplificado, deve refletir acoplamento real observado no cÃ³digo, nÃ£o uma arquitetura idealizada
- AnÃ¡lise por eixo (todos os 6), com exemplos de cÃ³digo/configuraÃ§Ã£o problemÃ¡ticos (trechos curtos, sem segredos reais â€” ver regra 2)
- Tabela de pontuaÃ§Ãµes com justificativas completas (usando a rubrica de Ã¢ncoras acima)
- Pontos fortes, atenÃ§Ãµes e crÃ­ticos, cada um com ID, evidÃªncia (arquivo/trecho) e contexto
- ApÃªndice final: tabela-Ã­ndice com todos os IDs gerados em qualquer um dos arquivos desta anÃ¡lise (ID, tÃ­tulo curto, severidade/prioridade, arquivo(s) onde Ã© detalhado) â€” serve como mapa Ãºnico de navegaÃ§Ã£o entre os documentos
- Se houver anÃ¡lise anterior arquivada (ver regra 8), seÃ§Ã£o "EvoluÃ§Ã£o desde a Ãºltima anÃ¡lise"

### ðŸ“„ `docs/SECURITY_REPORT.md`
RelatÃ³rio dedicado de seguranÃ§a, referenciando IDs `SEC-xxx` jÃ¡ levantados no `ARCHITECTURAL_REVIEW.md` quando aplicÃ¡vel, mais qualquer achado de seguranÃ§a adicional.
- Vulnerabilidades com severidade (CrÃ­tica / Alta / MÃ©dia / Baixa), descriÃ§Ã£o, localizaÃ§Ã£o (arquivo/linha se identificÃ¡vel) e impacto potencial â€” sem valores reais de segredos
- RecomendaÃ§Ã£o de correÃ§Ã£o por item
- Checklist de compliance LGPD/GDPR
- Status do supply chain: dependÃªncias desatualizadas encontradas de fato; CVEs apenas se confirmados (regra 3), caso contrÃ¡rio listar como "pendente de verificaÃ§Ã£o com [ferramenta]"

### ðŸ“„ `docs/TECH_DEBT_REGISTER.md`
CatÃ¡logo de dÃ©bito tÃ©cnico (categoria: cÃ³digo / arquitetura / testes / docs / infra), referenciando IDs jÃ¡ existentes quando o item tambÃ©m aparece no `ARCHITECTURAL_REVIEW.md`.
- Tabela: ID, descriÃ§Ã£o, categoria, severidade, esforÃ§o de resoluÃ§Ã£o, impacto se nÃ£o resolvido
- DÃ©bitos crÃ­ticos vs. aceitÃ¡veis (com justificativa explÃ­cita para os aceitos)
- RecomendaÃ§Ã£o de priorizaÃ§Ã£o

### ðŸ“„ `docs/ACTION_PLAN.md`
Plano de aÃ§Ã£o priorizado, consolidando itens de `ARCHITECTURAL_REVIEW.md`, `SECURITY_REPORT.md` e `TECH_DEBT_REGISTER.md` por ID â€” nÃ£o redefina esforÃ§o/impacto de um item aqui de forma diferente do arquivo de origem.
- **CrÃ­ticos (imediato â€” sprint atual):** tarefa, ID de origem, responsÃ¡vel sugerido (backend/frontend/devops/seguranÃ§a), critÃ©rio de aceite
- **Curto prazo (â‰¤4 semanas)**
- **MÃ©dio prazo (1â€“3 meses)**
- **Longo prazo (3â€“12 meses)**
- Para cada item: tÃ­tulo, ID de origem, esforÃ§o (P/M/G), impacto (Alto/MÃ©dio/Baixo), eixo relacionado

### ðŸ“„ `docs/IMPROVEMENT_ROADMAP.md`
Roadmap por trimestre (Q1â€“Q4) ou por fase (se o projeto for novo), agrupando as iniciativas do `ACTION_PLAN.md` por ID â€” nÃ£o crie iniciativas novas aqui que nÃ£o estejam rastreadas nos arquivos anteriores.
- Por iniciativa: nome, ID(s) relacionado(s), objetivo, eixo arquitetural, dependÃªncias entre iniciativas, mÃ©trica de sucesso
- SeÃ§Ã£o destacada de "quick wins" (alto impacto, baixo esforÃ§o)

### ðŸ“„ `docs/EXECUTIVE_SUMMARY.md`
Resumo de uma pÃ¡gina para pÃºblico nÃ£o-tÃ©cnico (produto, negÃ³cio, lideranÃ§a) â€” sem jargÃ£o de engenharia, sem IDs, sem trechos de cÃ³digo.
- Escore geral e o que ele significa em termos de risco para o negÃ³cio
- 3-5 riscos mais relevantes, descritos em impacto de negÃ³cio (ex.: "dados de clientes podem vazar", "sistema pode cair sob carga"), nÃ£o em termos tÃ©cnicos
- 3-5 pontos fortes, tambÃ©m em linguagem de negÃ³cio
- RecomendaÃ§Ã£o objetiva: o que precisa de investimento imediato e o que pode esperar

---

**Formato:** Markdown puro, headers, tabelas, checkboxes (`- [ ]`) onde aplicÃ¡vel, blocos de cÃ³digo com linguagem especificada. Objetivo, tÃ©cnico, direto â€” evite generalidades e frases de efeito sem conteÃºdo.

---

## ADENDO - EXECUCAO HEADLESS (gerado automaticamente pelo script analise-arquitetural.ps1)

Esta execucao roda sem supervisao humana. Os pontos abaixo sobrescrevem o que for
conflitante nas regras acima, apenas para esta sessao:

- Projeto alvo desta analise: `D:\Development\Projects\Beatspan`
- Ferramentas disponiveis nesta sessao: Read, Glob, Grep, Write. Bash, Edit e Agent
  (sub-agentes) NAO estao disponiveis - nao tente usa-los.
- Evidencias quantitativas ja foram coletadas por um script externo e estao em
  `D:\Development\Projects\Beatspan\docs\_evidence\2026-09-12_083515`. Leia `MANIFEST.txt` primeiro para saber o que rodou, falhou ou foi
  pulado, e use esses arquivos como a evidencia exigida pela regra 9 em vez de tentar
  rodar ferramentas voce mesmo. Itens marcados [FALHOU] ou [PULADO] devem ser reportados
  como "pendente de verificacao manual", nunca estimados.
- TodoWrite nao esta disponivel; mantenha o progresso apenas no seu raciocinio interno.
- Escreva os 6 arquivos finais apenas dentro de `D:\Development\Projects\Beatspan\docs` (pode criar subpastas). Nao
  escreva em nenhum outro caminho do projeto.
- Esta e uma sessao nao interativa: nao faca perguntas, ninguem vai responder. Onde houver
  ambiguidade, decida com o critÃ©rio mais conservador e registre a suposicao no relatorio.
