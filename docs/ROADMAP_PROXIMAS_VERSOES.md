# Roadmap de Próximas Versões — Beatspan

> Documento de proposta, não um plano aprovado. Versão base do app na data desta proposta: `1.0.0+1` (pré-lançamento, Android-only). Escopo focado em **expansão de produto**, em quatro eixos: **novos modos de jogo**, **conteúdo e catálogo**, **modo 100% digital em tela única (web/tablet)** e **social/multiplayer remoto**. Monetização foi deliberadamente deixada fora deste roadmap.

## Como ler este documento

- Cada versão é um incremento **shippable** — algo que dá para lançar sozinho, sem depender da próxima versão para fazer sentido.
- "Esforço" é relativo ao próprio projeto (app pequeno, sem backend próprio hoje), não uma estimativa em dias-pessoa.
- "Risco arquitetural" sinaliza quando a versão exige uma decisão estrutural nova (ex: autenticação, backend de sessão) que não existe hoje e que vale desenhar com cuidado antes de começar a implementar.
- Pré-requisitos técnicos listados por versão assumem que a versão anterior já foi entregue.

## Ponto de partida (estado atual, resumido)

- Jogo hoje é **100% local com cartas físicas**: o app só resolve QR code → música via Firestore e toca a faixa (Premium via Spotify App Remote, Free via preview 30s + fallback iTunes). Pontuação, rodadas e linha do tempo são geridas pelos jogadores fisicamente.
- Backend é só **Firestore de leitura pública** (coleção `musicas`, sem autenticação de usuário) — não existe conceito de "sessão de jogo", "sala" ou "jogador" no backend.
- App é **Android-only**, só em português (pt-BR), sem seleção de idioma/país (decisão de produto já tomada).
- Débito técnico crítico (arquitetura, segurança, cobertura de teste, CI/CD, analytics, LGPD) já foi trabalhado nas últimas sessões — a base está sólida o suficiente para investir em produto sem reabrir essas frentes.

## Os quatro eixos deste roadmap

1. **Novos modos de jogo** — variações de regra sobre o formato físico existente (equipes, contra-relógio, desafios temáticos).
2. **Conteúdo e catálogo** — packs temáticos de músicas, curadoria, atualização periódica.
3. **Modo digital em tela única** (nasceu de uma ideia trazida durante esta sessão) — versão web/tablet com cartas 100% digitais: em vez do QR code físico, a pessoa vê a música tocando e **toca na tela** para encaixar a carta no ponto certo da linha do tempo. Jogado num único dispositivo compartilhado entre todos (sem multiplayer remoto) — é essencialmente um novo modo de jogo, não uma substituição do físico.
4. **Social / multiplayer remoto** — jogar com pessoas em aparelhos diferentes, rankings, compartilhamento.

Esses eixos não são independentes: o eixo 3 (digital em tela única) é o que mais se aproxima de reverter a decisão de produto já tomada de "não modelar pontuação/linha do tempo digitalmente" — por isso ele é tratado como sua própria frente, e não como uma variação do eixo 1.

---

## v1.1 — Catálogo dinâmico e expansões de conteúdo

**Eixo:** Conteúdo e catálogo · **Esforço:** Médio · **Risco arquitetural:** Baixo (evolui o que já existe, não introduz conceitos novos)

### Escopo proposto

- **Packs temáticos de cartas**: modelar a coleção `musicas` (ou uma nova `packs`) com metadado de pack (ex: "Anos 2000", "Rock Nacional", "Sertanejo", "Anos 80"). Cada carta física já tem um código impresso — packs futuros são só novos códigos apontando para o mesmo schema.
- **Tela de catálogo no app**: uma tela nova (`catalog_view` ou dentro de "Regras"/"Home") que lista os packs disponíveis e quantas faixas cada um tem, mesmo sem "comprar" nada — serve hoje como transparência e amanhã como vitrine.
- **Import/curadoria assistida**: os scripts já existentes (`scripts/spotify_playlist_sync.py`, `scripts/firestore_musicas_import.py`) evoluem para suportar tag de pack e validação de metadados (ano, artista, gênero) antes do import, reduzindo erro manual de curadoria.
- **Atualização periódica de conteúdo**: processo documentado (não necessariamente automatizado ainda) para adicionar packs novos sem re-deploy do app — como o catálogo já é Firestore, isso já é tecnicamente possível hoje; o que falta é o app *comunicar* isso ao usuário (ex: "novidades no catálogo").

### Por que priorizar isso primeiro

Todos os outros eixos (modos de jogo, modo digital, multiplayer) ficam mais interessantes com catálogo maduro por trás — inclusive o modo digital da v1.3 depende diretamente de ter músicas bem marcadas com ano/artista para validar o acerto do jogador.

---

## v1.2 — Novos modos de jogo (locais, cartas físicas)

**Eixo:** Novos modos de jogo · **Esforço:** Médio-Alto · **Risco arquitetural:** Baixo-Médio (introduz estado de partida no app, que hoje não existe — hoje o app é *stateless* entre uma música e outra)

### Escopo proposto

- **Modo Equipes**: interface para registrar 2+ times, com placar simples mantido no app (hoje o placar é 100% manual/físico). Precisa de uma tela de "configurar partida" antes de começar a escanear.
- **Modo Contra-relógio / Blitz**: cada carta tem um tempo limite para o time acertar música/artista/ano antes de tocar a próxima; usa o cronômetro só como utilidade de apoio, sem mudar a mecânica central de QR→Spotify.
- **Modo Desafio temático**: uma partida restrita a um pack específico (depende de v1.1) — ex: "só anos 2000", jogável como sessão fechada.
- **Persistência de partida em andamento**: como o app hoje não guarda nenhum estado de "jogo atual", isso é a mudança de maior risco desta versão — decidir se o estado vive só em memória (perde ao fechar o app) ou se vale persistir localmente (`shared_preferences` ou um store mais estruturado) para retomar uma partida interrompida.

### Dependências e decisões a tomar antes de implementar

- Definir se os modos ficam **client-side apenas** (cada aparelho mantém seu próprio placar, sem sincronizar entre jogadores com apps diferentes) — abordagem recomendada para esta versão, adiando sincronização real para a v1.5 (multiplayer remoto).
- Confirmar com o usuário/produto se placar dentro do app é desejável ou se foge do design original ("por design, o app só cobre escanear e tocar, sem modelar pontuação digitalmente") — **isto contraria uma decisão de produto já registrada**, então precisa de validação explícita antes de iniciar, não é um follow-up automático deste roadmap.

---

## v1.3 — Modo digital em tela única (web/tablet)

**Eixo:** Modo digital em tela única · **Esforço:** Alto · **Risco arquitetural:** Médio (novo domínio de jogo dentro do app: linha do tempo digital, interação por toque/arraste, e possivelmente uma plataforma nova — web)

### O que muda em relação ao jogo físico

Hoje a linha do tempo é física (cartas sobre a mesa) e o app só toca a música. Neste modo, **a carta deixa de existir fisicamente**: o app mostra a música tocando (sem revelar nome/artista/ano) e o jogador **toca na tela** no ponto onde acredita que ela se encaixa na linha do tempo já formada pelas cartas anteriores — depois revela o acerto/erro. É um modo adicional, o físico continua existindo sem alterações.

### Escopo proposto

- **Motor de linha do tempo digital**: estrutura de dados e UI para representar a sequência de cartas já reveladas (ano + música), permitindo inserir uma nova carta em qualquer posição por toque/arraste. Este é o componente novo mais complexo do roadmap até aqui — não existe hoje nenhuma representação de "linha do tempo" em código, físico ou digital.
- **Fluxo de rodada digital**: sorteia uma música do catálogo (reaproveita packs da v1.1) → toca a prévia/faixa → jogador toca a posição → app revela e valida automaticamente (comparando o ano) → atualiza a linha do tempo e o placar.
- **UI otimizada para tela grande / tablet**: layout responsivo pensado para uma superfície compartilhada (várias pessoas ao redor de um tablet ou tela), diferente do layout atual do app, desenhado para uso individual em smartphone.
- **Decisão de plataforma**: avaliar se este modo roda como parte do mesmo app Flutter (Flutter já compila para web e tem suporte a tablet/Android sem grandes mudanças) ou como um app/target separado. **Recomendação**: manter no mesmo código Flutter e usar `flutter build web` como novo target, em vez de criar um projeto separado — evita duplicar lógica de domínio (catálogo, playback, packs) que já existe e será reaproveitada.
- **Playback no modo digital**: como não há carta física para ditar o momento de tocar, este modo precisa decidir a fonte de áudio por rodada (prévia Free vs. faixa completa Premium) dentro do próprio fluxo — reaproveita `MusicaPlaybackUsecase`/`SpotifyPlaybackUsecase` já existentes, mas exige uma orquestração de "próxima rodada automática" que hoje não existe (hoje cada música é disparada por um scan manual).

### Riscos e perguntas em aberto (recomendado resolver antes de codar)

- **Web + Spotify App Remote**: o `spotify_sdk` (App Remote) depende do app nativo do Spotify instalado no aparelho — isso **não funciona em web**. Se o modo digital rodar em navegador, faixas completas via Spotify Premium precisam de outra estratégia (Web Playback SDK do próprio Spotify, que roda em navegador mas exige uma integração diferente da atual) ou o modo web fica limitado a prévias de 30s. Se rodar como app Android/tablet nativo (não web), o App Remote atual já funciona sem mudança. **Esta decisão determina boa parte do esforço técnico da versão** e vale validar antes de estimar com mais precisão.
- **Fonte da imagem/nome do artista para conferência visual**: hoje o app não exibe capa/nome da faixa em nenhum fluxo (o jogador descobre pela própria música/carta física). O modo digital provavelmente precisa exibir isso na revelação — dado que já vem do Spotify/iTunes nas respostas de busca atuais, é mais dado a expor na UI do que uma integração nova.
- **Validação de "acerto"**: definir a régua de pontuação (acertar o ano exato? uma faixa de anos? posição relativa na linha do tempo, como no Hitster original?) — decisão de regra de jogo, não técnica, mas que muda a lógica do motor de linha do tempo.

### Por que isso antes do multiplayer remoto

Mesmo sendo a versão de maior esforço até aqui, ela é **local e sem backend novo** — o risco fica concentrado em UI/UX e decisões de plataforma (web vs. nativo, fonte de áudio), não em infraestrutura de sala/sessão. Validar a mecânica de linha do tempo digital aqui também deixa o terreno mais claro para, futuramente, oferecer esse mesmo modo em multiplayer remoto (v1.5+), caso faça sentido depois de testado localmente.

---

## v1.4 — Conteúdo social e compartilhamento pós-jogo

**Eixo:** Conteúdo e catálogo + Social (ponte leve) · **Esforço:** Baixo-Médio · **Risco arquitetural:** Baixo

### Escopo proposto

- **Cartão de resultado compartilhável**: ao fim de uma partida (modos da v1.2 ou v1.3), gerar uma imagem/resumo ("Time A venceu por 8x5 jogando o pack Anos 2000") pronta para compartilhar via `share` (o app já tem uma feature `share/` com widgets reaproveitáveis).
- **Estatísticas locais simples**: histórico de partidas jogadas naquele aparelho (quantas partidas, packs mais jogados, desempenho no modo digital) — dado 100% local, sem backend novo.
- **Deep link de convite**: link tipo `beatspangame.com/pack/<id>` que abre o app direto num pack específico, reaproveitando a infraestrutura de link que já existe para os QR codes das cartas.

### Por que isso antes do multiplayer remoto completo

Entrega valor social real (compartilhar, comparar, convidar) com esforço e risco muito menores que sincronização em tempo real — e testa apetite do usuário por "social" antes de pagar o custo de introduzir autenticação e backend de sessão.

---

## v1.5 — Multiplayer remoto (fundação)

**Eixo:** Social / multiplayer remoto · **Esforço:** Alto · **Risco arquitetural:** Alto (novo domínio de backend, autenticação, meio de comunicação em tempo real)

### Por que isto é diferente de tudo antes

Hoje o Firestore do projeto é só um catálogo de leitura pública, sem autenticação de usuário e sem modelagem de "jogador" ou "partida". Multiplayer remoto exige:

1. **Autenticação de usuário** (mínimo: Firebase Auth anônimo, para identificar jogadores numa sala sem exigir cadastro completo).
2. **Modelo de dados novo**: coleções `salas`/`sessoes` com jogadores, estado da partida (quem já jogou, placar, pack escolhido), regras de segurança do Firestore que hoje são simples (`allow read: if true`) e precisarão de regras por sala/participante.
3. **Sincronização em tempo real**: Firestore já suporta listeners em tempo real (`snapshots()`), então tecnicamente não exige um serviço novo de infraestrutura — mas exige desenho cuidadoso de estado (otimista vs. servidor, reconexão, jogador que sai no meio).
4. **UX de sala**: criar sala, entrar por código/link, lobby de espera, sincronizar "próxima carta" entre aparelhos remotos.

### Escopo proposto para esta versão (fundação, não o produto completo)

- Autenticação anônima via Firebase Auth.
- Criar/entrar em sala com código curto (reaproveita o padrão de "código curto" já usado nas cartas).
- Sincronizar apenas o essencial: quem está na sala e de quem é a vez — **sem** ainda sincronizar automaticamente qual carta foi escaneada (isso pode continuar sendo "cada jogador com sua carta física, o app só sincroniza o turno e o placar") ou, alternativamente, reaproveitar o motor de linha do tempo digital da v1.3 já sincronizado (opção mais ambiciosa, avaliar depois de validar a fundação).
- Regras de segurança do Firestore revisadas com o mesmo rigor que já foi aplicado à coleção `musicas` (ver histórico de segurança do projeto).

### Recomendação

Tratar esta versão como um **spike/protótipo validado com um grupo pequeno de usuários reais** antes de generalizar — é a maior aposta técnica do roadmap e a mais fácil de superengenheirar sem validação de que o modo remoto é o que os jogadores querem.

---

## v1.6 — Multiplayer remoto (produto completo) + Rankings

**Eixo:** Social / multiplayer remoto · **Esforço:** Alto · **Risco arquitetural:** Médio (evolui a fundação já validada, não introduz conceitos novos)

### Escopo proposto

- **Sincronização completa de partida remota**: placar, pack escolhido e progresso (quantas cartas já foram jogadas) sincronizados entre todos os aparelhos da sala em tempo real.
- **Modo digital em sala remota** (opcional, se validado na v1.3/v1.5): a linha do tempo digital passa a ser compartilhada entre jogadores remotos, não só local em um dispositivo — a extensão natural do eixo 3 depois que ele provar valor localmente.
- **Reconexão e resiliência**: jogador que perde conexão ou fecha o app consegue voltar à sala sem perder o estado da partida (Firestore facilita isso, mas a UX de "jogador desconectado" precisa ser desenhada).
- **Rankings**: locais (por aparelho, "seu recorde") e, se fizer sentido de produto, agregados (leaderboard entre salas/grupos de amigos) — depende de decisão sobre se o app quer coletar esse dado agregado (implicação de LGPD/privacidade a revisar, dado que o projeto já tem uma tela de consentimento dedicada).
- **Notificações leves** (opcional): avisar quando é a vez do jogador, via `firebase_messaging` — dependência nova, avaliar custo/benefício antes de adicionar.

---

## Resumo visual do roadmap

| Versão | Eixo | Tema central | Esforço | Risco arquitetural | Depende de |
|---|---|---|---|---|---|
| v1.1 | Conteúdo | Catálogo dinâmico e packs temáticos | Médio | Baixo | — |
| v1.2 | Modos de jogo | Novos modos locais (equipes, blitz, temático) | Médio-Alto | Baixo-Médio | v1.1 (modo temático) |
| v1.3 | Modo digital | Linha do tempo digital em tela única (web/tablet) | Alto | Médio | v1.1 (catálogo p/ sortear músicas) |
| v1.4 | Conteúdo + Social | Compartilhamento e estatísticas locais | Baixo-Médio | Baixo | v1.2 e/ou v1.3 (placar a compartilhar) |
| v1.5 | Social/multiplayer | Multiplayer remoto (fundação) | Alto | **Alto** | v1.2 (conceito de partida) |
| v1.6 | Social/multiplayer | Multiplayer remoto (completo) + Rankings | Alto | Médio | v1.5, opcionalmente v1.3 |

## Riscos e decisões transversais (valem para todo o roadmap)

- **Conflito com decisão de produto existente**: o projeto já decidiu, deliberadamente, que "rodadas, pontuação e linha do tempo são geridas pelos próprios jogadores com as cartas físicas". Os modos de jogo (v1.2), o modo digital (v1.3) e o multiplayer (v1.5/v1.6) revertem essa decisão parcialmente ou totalmente ao introduzir placar e/ou linha do tempo digital — isso deve ser validado explicitamente com o time antes de iniciar v1.2, não tratado como consequência automática deste documento.
- **iOS continua fora de escopo** neste roadmap orientado a produto — se popular, tanto o modo digital (v1.3, se for web isso é multiplataforma "de graça") quanto o multiplayer remoto (jogadores de plataformas diferentes na mesma sala) podem antecipar essa necessidade.
- **Spotify Web Playback vs. App Remote**: a decisão de plataforma da v1.3 (web vs. nativo) tem implicação direta em como o Spotify Premium é reproduzido — resolver isso cedo evita retrabalho.
- **Custo de backend**: Firestore com leitura pública e sem autenticação tem custo previsível; salas remotas com sincronização em tempo real mudam o perfil de custo (mais leituras/escritas, listeners ativos) — vale orçar antes de v1.5.
- **LGPD/privacidade**: qualquer dado de jogador (mesmo anônimo) em sala remota ou ranking agregado precisa passar pela mesma régua já aplicada à tela de consentimento existente — não introduzir coleta de dados nova sem revisar isso primeiro.
