# Plano: Liga Estelar (corridas semanais entre jogadores e ranking)

> Versão 0.1, 2026-11-26. Continua o [plano do jogo no navegador](jogo-no-navegador.md).
> É um plano para o futuro: nada disto está implementado.

**A ideia do Lucas:** cada jogador inscreve garotas do seu elenco salvo numa corrida
semanal, parecida com o [Circuito do endgame](endgame.md), só que as adversárias
são as garotas de outros jogadores. Os resultados alimentam um ranking.

## Resumo

- **Corrida assíncrona, não ao vivo.** Ninguém precisa estar online na hora. O
  jogador inscreve as garotas durante a semana; no domingo à noite um servidor roda
  todas as corridas de uma vez e publica os resultados. Isso combina com o jogo
  (por turnos, sem ação em tempo real) e é muito mais barato e simples que
  multiplayer ao vivo.
- **O código da corrida já serve.** `SimCorrida` é determinística (mesma semente e
  mesmo pelotão dão a mesma corrida) e o Circuito já monta pelotões a partir de
  versões salvas (`Endgame.corredora_salva`). O servidor roda o **mesmo GDScript**
  num Godot sem tela; o jogo baixa a semente e o pelotão e mostra a corrida em 3D
  como se fosse ao vivo.
- **Backend recomendado:** Supabase (banco Postgres, login e API prontos; plano
  grátis) para guardar contas, inscrições e resultados, e um **GitHub Actions
  agendado** para rodar as corridas toda semana. Sem servidor ligado 24 horas.
- **Bônus:** com contas, o save vai para a nuvem, o que resolve o maior risco do
  plano web (o Safari apagar o save do navegador).
- **O maior problema é trapaça.** Hoje o save fica na mão do jogador e dá para
  editar os atributos. O plano começa com limites de plausibilidade e, numa fase
  depois, valida a carreira inteira refazendo ela no servidor (a carreira também é
  determinística: o teste `teste_carreira` já confere isso).

## 1. Como funciona para o jogador

### 1.1 A semana

| Quando (horário de Brasília) | O quê |
|---|---|
| Segunda 00:00 | Abre a semana: saem as **corridas da Liga** (3 corridas, como uma copa), com distância, piso, clima e traçado. |
| Segunda a domingo 20:00 | O jogador **inscreve** 3 garotas salvas diferentes, uma por corrida, e a instrução de cada uma. Pode trocar quantas vezes quiser até fechar. |
| Domingo 20:00 | Fecham as inscrições. A garota inscrita é uma **foto** da versão salva naquele momento. |
| Domingo ~21:00 | O servidor monta as salas e roda as corridas. |
| Domingo à noite em diante | Resultados no jogo: replay em 3D de cada corrida, pontos, subida/descida de divisão. |

A semana aqui é de **calendário real**, igual para todos. O "Desafio da semana" de
hoje usa a rotação da pool de cada jogador (`Perfil.giro`), que anda quando a
pessoa termina uma carreira; na Liga isso não serve, porque todo mundo precisa
correr na mesma semana.

### 1.2 Salas e pontos

- Cada corrida tem **12 corredoras**, como hoje. O servidor separa os inscritos
  em **salas de 4 jogadores** da mesma divisão; cada jogador põe 1 garota em cada
  uma das 3 corridas, e as 8 vagas que sobram são das casas rivais e avulsas (NPCs
  na força da divisão), como no Circuito. Com poucos jogadores no começo, isso
  garante corrida cheia.
- Pontos por colocação como no Circuito (10, 8, 6, 5, 4, 3, 2, 1). A soma das 3
  corridas decide a sala.
- Uma variante para depois: salas de 12 jogadores, sem NPC, quando houver gente.

### 1.3 Ranking

- **Divisões** (sugestão): Bronze, Prata, Ouro, Platina e Estelar. Começa no
  Bronze. Por semana, o 1º da sala sobe e o 4º desce (ajustável).
- **Temporada** de 6 semanas: no fim, título e moldura pela divisão final, e todo
  mundo desce uma divisão para a próxima temporada.
- **Ranking geral** da temporada (soma de pontos) e **recordes** por garota (a
  Lira mais vitoriosa da temporada etc.).
- Quem não inscrever na semana não perde divisão (só deixa de pontuar).

### 1.4 Recompensas sem criar um meta

A regra do projeto é não ter meta (ver [endgame](endgame.md) §5). A Liga segue
isso assim:

- **Recompensa não deixa garota mais forte.** Moeda limitada (como o prêmio de
  repetição do Circuito), títulos, molduras e estrelas na ficha. Se a Liga desse
  atributo, quem já ganha ganharia cada vez mais.
- **Condições da semana mudam o que rende**: os traçados do Circuito (pista
  pesada, subidas, vento contra, reta final, curvas) e o clima entram também na
  Liga. Cada semana favorece um estilo ou atributo diferente.
- **Regras de semana** opcionais, no estilo do Desafio: "só garotas de terra",
  "nota máxima A", "sem habilidades raras". Dão chance a garotas fora da moda.
- **Divisões por força**: quem acabou de começar corre contra quem também
  começou.
- **Medir**: o servidor guarda todos os resultados, então dá para rodar o mesmo
  tipo de análise do `testes/meta_circuito.gd` com dados reais (vitórias por
  estilo, garota e atributo) e ajustar os traçados.

## 2. Arquitetura

```
 Jogo (navegador ou PC)                Supabase                    GitHub Actions
 ──────────────────────               ─────────────               ─────────────────
 login  ───────────────────────────▶  Auth
 save na nuvem  ◀──────────────────▶  tabela saves
 inscrever garotas (foto) ─────────▶  tabela inscricoes
                                       (regras de acesso:
                                        só a própria conta,
                                        só antes de fechar)
                                                      ◀─── domingo 21:00: lê inscrições
                                                           Godot headless roda
                                                           res://servidor/liga.gd
                                                      ───▶ grava salas e resultados
 baixa resultado (semente + pelotão)◀  tabelas salas/resultados
 refaz a corrida localmente e mostra em 3D
```

### 2.1 Por que Supabase

| Opção | Custo | Prós | Contras |
|---|---|---|---|
| **Supabase** (recomendado) | Grátis até 500 MB de banco e 50 mil usuários ativos/mês; Pro US$ 25/mês | Postgres com regras de acesso por linha (RLS), login pronto (e-mail, Google, Discord), API REST que o Godot chama com `HTTPRequest`, funciona no navegador | Projeto grátis **pausa após 1 semana sem uso** (o cron semanal já conta como uso, mas vale conferir) |
| Firebase | Grátis no começo | Login e banco prontos | Sem SDK oficial para Godot; banco de documentos é pior para ranking |
| Nakama (Heroic Labs) | Grátis se você hospedar (precisa de um servidor, ~US$ 5–10/mês) | Feito para jogos: ranking, torneios, amigos | Mais coisa para manter |
| Servidor próprio (Node/Python) | VPS ~US$ 5/mês | Controle total | Tudo na mão: login, segurança, backup |

### 2.2 Onde a corrida roda

**No servidor, com o mesmo código do jogo.** Um workflow agendado
(`.github/workflows/liga.yml`, `cron` de domingo) baixa o Godot 4.7.2 (igual ao
`testes.yml`), lê as inscrições da semana pela API do Supabase com uma chave
secreta guardada nos segredos do GitHub, roda `servidor/liga.gd` e grava os
resultados. Custo zero num repositório público.

O jogo depois **não confia na própria simulação** para o resultado: ele baixa a
ordem de chegada oficial e usa a semente só para animar a corrida em 3D.
Motivo: o navegador (WebAssembly) e o Linux do servidor podem diferir na última
casa decimal em funções como `exp` e `pow`, e numa chegada apertada isso troca
duas posições. O replay mostra a corrida e, se ele divergir, a tela final segue o
resultado oficial.

Cuidados com o GitHub Actions agendado: pode atrasar alguns minutos em horário de
pico, e o GitHub desliga workflows agendados depois de 60 dias sem commits no
repositório. Se isso incomodar, a mesma tarefa roda num Supabase Edge Function
chamando um Godot hospedado, ou num servidor pequeno.

### 2.3 Versão do jogo

Cada inscrição leva a **versão do jogo** e a **versão da simulação**. Se uma
atualização mudar a simulação no meio da semana, o servidor roda a semana com a
versão em que ela abriu (o workflow faz checkout da tag da semana). Mudanças de
balanceamento entram sempre na virada de semana.

## 3. Dados (tabelas)

| Tabela | Campos principais |
|---|---|
| `jogadores` | id (do login), apelido, divisão, criado_em |
| `saves` | jogador, perfil (JSON do `user://perfil`), atualizado_em, versão |
| `semanas` | id (ex. `2026-W49`), semente, corridas (distância, piso, clima, traçado), regra, abre, fecha, estado |
| `inscricoes` | semana, jogador, corrida (0–2), garota, instrução, **foto da versão salva** (JSON), versão do jogo, hash |
| `salas` | semana, divisão, jogadores, semente de cada corrida |
| `resultados` | sala, corrida, ordem de chegada, tempos, pontos |
| `temporadas` / `ranking` | temporada, jogador, pontos, divisão final |

Regras de acesso (RLS no Supabase): cada jogador lê e escreve só o próprio save e
as próprias inscrições, e só enquanto a semana está aberta; `salas` e
`resultados` são de leitura para todos e só o workflow (chave de serviço) grava.

## 4. Trapaça

O jogo roda no computador do jogador, então qualquer número que ele mande pode ter
sido editado (o save é um JSON no IndexedDB). Em ordem de esforço:

1. **Limites de plausibilidade (fase 1):** o servidor recusa a inscrição se os
   atributos passam do máximo alcançável naquela magnitude, se a aptidão não bate
   com a da garota (ou com o que o Prestígio/equipamento permite), se a habilidade
   não existe ou se a garota não pertence ao elenco salvo na nuvem. Pega a trapaça
   grosseira com pouco código. Os máximos saem do bot de balanceamento (o melhor
   resultado em milhares de carreiras, com folga).
2. **Save só na nuvem para a Liga:** a versão salva usada na Liga vem do save da
   nuvem, que o jogo só atualiza no fim de uma carreira. Dificulta, mas não
   impede (dá para mandar um save editado pela API).
3. **Refazer a carreira no servidor (fase 4):** a carreira já é determinística a
   partir da semente e das escolhas. O jogo passa a guardar a **lista de escolhas**
   de cada carreira (nó do mapa, treino, corrida, resposta de encontro: algumas
   centenas de números) junto com a versão salva. Na inscrição, o workflow refaz
   a carreira no Godot sem tela e só aceita se a versão salva sair igual. Isso
   fecha a trapaça quase toda. Custo: guardar as escolhas em `carreira.gd`, manter
   as versões antigas do jogo para refazer carreiras feitas nelas, e ~5 s de CPU
   por carreira (medido pelo bot), o que cabe no Actions para algumas centenas de
   inscrições por semana.
4. **Moderação:** apelidos com filtro de palavras e botão de denúncia; banir conta
   pelo painel do Supabase.

Vale lembrar que, como a recompensa não dá força (§1.4), trapacear só estraga o
ranking, não o jogo dos outros.

## 5. Etapas

| Fase | Entrega | Depende de | Tamanho |
|---|---|---|---|
| 0 | Jogo no site (etapas 1 a 3 do [plano web](jogo-no-navegador.md)) e número de versão no jogo | nada | 1 PR |
| 1 | **Contas e save na nuvem**: projeto Supabase, tela de login (com "jogar sem conta"), envio do perfil no fim de cada carreira e baixar o save em outro aparelho | Fase 0 | 2 PRs |
| 2 | **Liga MVP**: tabela de semanas, tela de inscrição (reaproveita a escalação do Circuito), workflow de domingo, tela de resultado com replay em 3D, limites de plausibilidade | Fase 1 | 3–4 PRs |
| 3 | **Ranking**: divisões, temporadas, recompensas, ranking geral e por garota, histórico de semanas | Fase 2 | 2 PRs |
| 4 | **Carreira verificada**: lista de escolhas na carreira e refazer no servidor | Fase 2 | 2 PRs |
| 5 | Extras: liga entre amigos com código de sala, **corrida contra fantasma** (correr agora contra a garota inscrita de outro jogador, sem esperar domingo, sem valer ranking), notificação de resultado | Fase 3 | à parte |

As fases 1 e 2 já dão a experiência principal. A fase 4 pode vir antes da 3 se
aparecer trapaça logo.

Testes: `servidor/liga.gd` ganha um `testes/teste_liga.gd` que roda uma semana
falsa com inscrições geradas pelo bot e confere salas, pontos e determinismo
(mesma semente, mesmo resultado), no mesmo formato da suíte atual.

## 6. Custos

| Item | Custo |
|---|---|
| Supabase | Grátis no começo; US$ 25/mês se passar de 500 MB de banco ou precisar que o projeto nunca pause |
| GitHub Actions (cron semanal) | Grátis em repositório público |
| Hospedagem do jogo | Grátis (GitHub Pages ou Vercel, ver plano web) |
| Domínio próprio (opcional) | ~R$ 40–80 por ano |
| Login com Google/Discord | Grátis |

## 7. Riscos

| Risco | O que fazer |
|---|---|
| Trapaça por save editado | §4: limites na fase 2, carreira verificada na fase 4 |
| Poucos jogadores no começo | Salas de 4 com NPCs completando; a Liga funciona até com 1 jogador por divisão |
| Um estilo ou garota domina a Liga | Traçados e regras da semana; medir com os resultados reais e ajustar |
| Atualização muda a simulação no meio da semana | Versão da simulação por semana (§2.3) |
| Replay no navegador diferente do resultado oficial | O resultado oficial vem do servidor; o replay é só visual (§2.2) |
| Dados pessoais (LGPD) | Guardar só apelido e o login; política de privacidade simples; botão de apagar conta |
| Workflow agendado atrasado ou desligado | Alerta se a semana não fechou; rodar à mão pelo `workflow_dispatch` |
| Chave do Supabase exposta no jogo | A chave pública é feita para isso; a segurança está nas regras RLS. A chave de serviço fica só nos segredos do GitHub |

## 8. Decisões em aberto (para o Lucas)

1. **Backend:** Supabase (recomendado) ou outro.
2. **Recompensa:** só cosmética e moeda limitada (recomendado) ou algo que dê força.
3. **Formato:** 3 corridas com 3 garotas (como uma copa) ou 1 corrida com 1 garota
   (mais simples de começar).
4. **Conta obrigatória?** Recomendação: o jogo continua jogável sem conta; a conta
   só é pedida para a Liga e para o save na nuvem.
