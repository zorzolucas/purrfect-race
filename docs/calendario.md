# Nekomusume — Calendário da Carreira

> Versão 0.4 — 2026-11-17. Complementa o [GDD](GDD.md) §4.
> Na v0.4 a carreira passou para **3 anos (72 turnos)**, com semestre de base só de treino, **campanha única** por garota com ponto de virada e 2 finais (§3), **calendário fixo** de corridas com séries (§7.2 e §7.4) e **olheiro** (§7.3). Os objetivos sorteados da v0.3 saíram.
> Na v0.3 entraram o clima do mês (§4.4), os objetivos sorteados (§3.2) e a magnitude (§10).
> Na v0.2 o calendário virou **roguelike**: entre os objetivos, cada carreira sorteia um mapa de rotas (§4), objetivos cumpridos dão amuletos (§5) e uma semente fixa guarda os sorteios (§6).
> Valores marcados com **(inicial)** são pontos de partida para balanceamento.

## 1. Tempo

- A carreira tem **72 turnos** em **3 anos**.
- **1 turno = meio mês**: cada mês tem 2 turnos, **Início** e **Fim**. Assim 12 meses × 2 = 24 turnos por ano.
- O ano da academia segue o ano letivo: começa em **março** e termina em **fevereiro**. As **férias de verão** caem em **janeiro**.
- A tela mostra a data assim: *Ano 1 · Abril · Fim*.
- **Semestre de base:** os turnos **1 a 12** (março a agosto do ano 1) são **só de treino, encontros e história**. Não há nenhuma corrida, nem Circuito. A primeira corrida é a **Estreia, no turno 13**.

| Mês | Mar | Abr | Mai | Jun | Jul | Ago | Set | Out | Nov | Dez | **Jan** | Fev |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Turnos (ano 1) | 1–2 | 3–4 | 5–6 | 7–8 | 9–10 | 11–12 | 13–14 | 15–16 | 17–18 | 19–20 | **21–22** | 23–24 |
| Turnos (ano 2) | 25–26 | 27–28 | 29–30 | 31–32 | 33–34 | 35–36 | 37–38 | 39–40 | 41–42 | 43–44 | **45–46** | 47–48 |
| Turnos (ano 3) | 49–50 | 51–52 | 53–54 | 55–56 | 57–58 | 59–60 | 61–62 | 63–64 | 65–66 | 67–68 | **69–70** | 71–72 |

**Por que 3 anos:** é a mesma proporção do gênero (cerca de 1/6 da carreira só de treino antes da estreia) e dá espaço para a campanha única de cada garota (§3). O custo é uma carreira de **uns 50 minutos**. Para compensar: botão de **repetir a última ação**, diálogos **já vistos** que podem ser pulados (GDD §4.9) e o amuleto **Sete Vidas** (§5.2).

## 2. Categorias de corrida

Toda corrida tem uma **categoria**. Ela define a força das adversárias, o prêmio e a fama exigida para entrar.

| Categoria | Força das NPCs (média dos atributos) | Fama para entrar (inicial) | Quando aparece |
|---|---|---|---|
| **Estreia** | 209 | — | Só no turno 13 (a primeira corrida dela) |
| **Aberta** | Ano 1: 267 · Ano 2: 345 · Ano 3: 475 | 0 | A partir do turno 14 |
| **Prata** | Ano 2: 372 · Ano 3: 545 | 600 | A partir do turno 25 (ano 2) |
| **Ouro** | Ano 2: 465 · Ano 3: 628 | 1500 | A partir do turno 37 (2º semestre do ano 2) |
| **Grande Prêmio** | Ano 1: 340 · Ano 2: 535 · Ano 3: 715 | Por convite (objetivo) | Turnos 24, 48 e 72 |

- Os valores subiram 5% a 12% em 2026-11-17, quando o olheiro e a instrução pré-corrida deixaram o bot mais esperto. Em 2026-11-18 (v0.5) subiram de novo, acompanhando a curva nova da jogadora, e o **ano 3 ficou bem mais forte** (Ouro de 487 para 575): antes, a garota do bot chegava ao ano 3 com folga e só o GP final era desafio ([campanhas](campanhas.md) §7).
- Em 2026-11-20 (v0.7) os anos 2 e 3 subiram de 3% a 11%: com o fôlego do pelotão ([corrida.md](corrida.md) §6), a garota que treina Estamina ganhou vantagem sobre o pelotão a partir do ano 2, e o GP do ano 2 derrubava só 2% de quem chegava nele ([campanhas](campanhas.md) §7.4).
- As **corridas do calendário fixo** (§7.2) correm com força ×1,08 no ano 2 e ×1,1 no ano 3 (`forca_fixa`): juntam as melhores do ano, e é isso que faz as séries pedirem rota planejada.
- O pelotão **fica mais forte a cada ano**, como a jogadora. Assim a mesma categoria pede mais no ano 3 do que no ano 2.
- **Por distância**, a força é multiplicada por: Sprint ×0,99 · Milha ×0,98 · Média ×1,01 · Longa ×1,04. Corrida curta tem mais sorte, e sem isso as garotas de Sprint completavam bem menos carreiras que as de Longa. Com a instrução Forçar (GDD §5.7) a Sprint ficou mais fácil, e o multiplicador subiu de ×0,95 para ×0,99. A Média desceu de ×1,01 para ×0,99 na v0.6 e voltou a ×1,01 na v0.7, quando as casas de Média passaram a completar 55% a 57% com a simulação nova.
- **Por categoria e distância** (`forca_distancia_cat`, v0.7), por cima do multiplicador de distância: Estreia na Longa ×0,92, Aberta do ano 1 na Longa ×0,95, GP do ano 1 na Sprint ×0,95 e na Milha ×0,98, Prata do ano 2 na Sprint ×0,97, Ouro do ano 3 na Longa ×0,98 e GP final na Longa ×0,97. Cada um tira um muro de uma casa: o GP do ano 1 derrubava 25% das garotas de Sprint Grama, e a Estreia, 16% das de Longa (a média é 5%).
- A força das NPCs varia ±10% de uma corredora para outra, para o pelotão não ser uniforme.
- Nas corridas de objetivo com meta de rival e em todo Grande Prêmio, a **rival** (com nome ou campeã da casa) corre com +15% sobre a força da categoria, sempre com aptidão Ótima. A **Algol** corre com mais 8% (`forca_rival_extra`), porque a habilidade única dela rende menos que a da Polaris e as casas dela ficavam 9 pontos mais fáceis.
- Os números saíram do bot de balanceamento na carreira de 72 turnos ([campanhas](campanhas.md) §7).

### 2.1 Curva esperada da jogadora

Este é o **alvo** para calibrar os ganhos de treino em 72 turnos:

| Turno | 13 (Estreia) | 24 | 36 | 48 | 60 | 72 |
|---|---|---|---|---|---|---|
| Média dos atributos (alvo) | ~200 | ~330 | ~460 | ~590 | ~700 | ~800 |
| Média do bot (v0.5 do protótipo) | 228 | 338 | 450 | 587 | 708 | 819 |

O treino rende mais com atributos baixos e menos com atributos altos (retorno de ×1,25 − 0,45 × atributo/limite): a garota cresce mais nos anos 1 e 2 e menos no ano 3. Uma jogadora que treina bem chega acima disso, e uma que descansa demais ou se lesiona chega abaixo. Amuletos e rotas boas também empurram a curva para cima, então a força das NPCs deve ser calibrada com uma carreira "média" sem amuletos raros.

## 3. Objetivos e campanha única

Cada garota tem **sua própria campanha**: 8 objetivos obrigatórios, um arco de história e **2 finais**. Os 3 Grandes Prêmios são comuns a todas (na versão da casa de cada uma). Os outros 5 objetivos são escritos para ela: distância, piso, rival e até metas que não são de colocação ("chegar à frente da Polaris", "vencer na chuva"). Falhou um, a carreira acaba ali, mas a garota pode ser salva como estava (GDD §4.8).

| # | Turno | Data | Quem define | O quê |
|---|---|---|---|---|
| 1 | 13 | Ano 1 · Set · Início | Garota | **Estreia** dela |
| 2 | 20 | Ano 1 · Dez · Fim | Garota | Objetivo da história |
| 3 | 24 | Ano 1 · Fev · Fim | Comum | **Grande Prêmio do ano 1** |
| 4 | 32 | Ano 2 · Jun · Fim | Garota | Objetivo da história |
| 5 | 40 | Ano 2 · Out · Fim | Garota | Objetivo da história |
| 6 | 48 | Ano 2 · Fev · Fim | Comum | **Grande Prêmio do ano 2** |
| — | — | — | — | **Ponto de virada** (§3.3) |
| 7 | 60 | Ano 3 · Ago · Fim | Garota (por caminho) | Objetivo da história |
| 8 | 72 | Ano 3 · Fev · Fim | Comum (meta por caminho) | **Grande Prêmio final** e o final dela |

- Os turnos de objetivo são iguais para todas, para o calendário e o mapa funcionarem do mesmo jeito. O que muda é a corrida e a meta.
- Um objetivo pode **ser** uma corrida do calendário fixo (§7.2). Por exemplo, o objetivo 5 da Lira é o Prêmio Cometa.
- Nesses turnos a única ação disponível é **Correr**. Se ela estiver lesionada, corre assim mesmo, porque a lesão só corta ganho de treino (GDD §4.5).
- **Aviso antes do objetivo:** a partir de 6 turnos antes, a tela de objetivos mostra a etiqueta do olheiro (§7.3) com os atributos atuais e qual atributo mais aumentaria a chance. O jogador nunca chega num objetivo sem saber se está pronto.

### 3.1 Grande Prêmio

No turno do Grande Prêmio acontecem **8 corridas ao mesmo tempo**, uma por casa (4 distâncias × 2 pisos). Normalmente o objetivo usa a da casa da garota, mas um caminho da campanha pode levar a outra versão (ex.: a Lira no caminho "Revanche" corre o GP final na Média). As rivais com nome ficam onde combinam:

| Casa | Rival do Grande Prêmio |
|---|---|
| Média Grama, Longa Grama | **Polaris** |
| Sprint Terra, Milha Terra | **Algol** |
| Outras | A **campeã da casa**: a garota do elenco da mesma casa com maior soma de atributos, sem contar a jogadora (sem encontros no MVP, [campanhas](campanhas.md) §4.3) |

Distâncias do Grande Prêmio (inicial): Sprint 1200 m · Milha 1600 m · Média 2400 m · Longa 3200 m.

### 3.2 Como escrever uma campanha

Cada campanha tem:
- **Objetivos 1, 2, 4 e 5**, com corrida (ou categoria + casa) e meta. As metas vêm da lista abaixo, para manter a dificuldade sob controle.
- **Meta dos GPs 1 e 2** (em geral top 5 no ano 1 e top 3 no ano 2).
- **Capítulos de história:** 1 no semestre de base, 1 entre cada par de objetivos e 1 final para cada caminho. São os eventos únicos da garota ([elenco](elenco.md)).
- **Condição do ponto de virada** e os dois caminhos (§3.3).

**Tipos de meta** (a dificuldade vale para o amuleto do objetivo: os Difíceis dão escolha entre 4, com 1 incomum ou raro garantido)

| Meta | Exemplo | Dificuldade |
|---|---|---|
| Colocação na casa | Top 3 numa Aberta de Milha Grama | Normal |
| Fora de casa | Top 5 na distância vizinha | Normal |
| Outro piso | Top 5 na casa, no outro piso | Normal (não usar se o outro piso for Ruim) |
| Maratona | Duas corridas com top 5 desde o objetivo anterior | Normal |
| Rival | Chegar à frente de uma rival com nome | Normal |
| Condição | Vencer na chuva, liderar na Largada, vencer de virada | Difícil |
| Vitória | Vencer a corrida | Difícil |
| Série | Vencer 2 corridas de uma série (§7.4) | Difícil |

- A corrida de um objetivo é **por convite**: a garota entra mesmo sem a fama da categoria. A fama limita só as opcionais ([campanhas](campanhas.md) §8).
- **Exemplo completo:** a campanha da **Lira** está no [elenco](elenco.md#campanha-da-lira). As outras 5 do MVP, os 12 arquétipos das outras 42 garotas e o plano de balanceamento estão em [campanhas.md](campanhas.md).

### 3.3 Ponto de virada

Depois do **Grande Prêmio do ano 2** (turno 48), a história se divide em **2 caminhos**. Cada caminho tem seu próprio **objetivo 7**, sua **meta para o GP final** e seu **final** (epílogo).

- **O que decide:** o resultado de corridas marcadas na campanha (ex.: "terminou à frente da Polaris nos objetivos 4 e 6") e as escolhas feitas nos eventos únicos dela. Cada campanha diz a regra.
- O jogo **não mostra** a regra exata, mas os capítulos de história dão pistas.
- Os 2 finais ficam registrados na ficha da garota. Ver os dois é o principal motivo para jogar uma 2ª carreira com ela, além do mapa, do clima, dos amuletos e da magnitude.

## 4. Mapa de rotas

Os objetivos são os "chefes" da carreira e ficam sempre no mesmo turno. **Entre um objetivo e outro**, o caminho é um mapa sorteado para cada carreira.

### 4.1 Trechos e nós

A carreira é dividida em **trechos**, um antes de cada objetivo. Cada trecho tem um mapa de **nós**. **Cada nó dura 2 turnos.**

| Trecho | Turnos | Nós a escolher | Fixos | Chefe |
|---|---|---|---|---|
| Base | 1–12 | **4** (turnos 3–10) | Chegada (1–2), Preparação (11–12) | Objetivo 1, Estreia (13) |
| 1 | 14–19 | **3** | — | Objetivo 2 (20) |
| 2 | 21–23 | — | Férias (21–22), Véspera (23) | GP do ano 1 (24) |
| 3 | 25–31 | **3** | Véspera (31) | Objetivo 4 (32) |
| 4 | 33–39 | **3** | Véspera (39) | Objetivo 5 (40) |
| 5 | 41–47 | **2** | Férias (45–46), Véspera (47) | GP do ano 2 (48) |
| 6 | 49–59 | **5** | Véspera (59) | Objetivo 7 (60) |
| 7 | 61–71 | **4** | Férias (69–70), Véspera (71) | GP final (72) |

São **24 nós escolhidos** por carreira.

- **Chegada** (turnos 1–2): tutorial de treino e capítulo 1 da história.
- **Preparação** (turnos 11–12): 2 turnos normais, sem bônus de nó, antes da estreia. O capítulo da história fecha o semestre de base.
- **Semestre de base:** os nós desse trecho **nunca são Circuito nem Desafio**, porque não há corrida antes do turno 13.
- **Formato do mapa:** 3 colunas, uma linha por nó. Cada nó liga ao nó logo abaixo e aos vizinhos de diagonal, então de um nó saem 2 ou 3 caminhos. O jogador vê o **trecho inteiro** antes de começar, e é isso que permite planejar a rota.
- **Véspera:** turno normal, sem opcionais, com encontro com a rival do próximo objetivo (quando houver).
- **Dentro do nó** o jogador continua escolhendo a ação de cada turno (Treinar, Descansar, Sair, Correr, Enfermaria). O nó só muda o **contexto**: quais corridas geradas existem, quais bônus valem, que eventos podem aparecer. O pilar "treino é dilema" fica intacto.

### 4.2 Tipos de nó

| Nó | Efeito durante o mês (inicial) | Peso no sorteio |
|---|---|---|
| **Treino focado** (atributo X) | O treino de X conta **1 nível acima** (máximo 5). O mapa mostra qual atributo. | Alto |
| **Circuito** | Cada turno oferece **2 corridas geradas** (§7.1). O mapa mostra a categoria e a casa de cada uma. As corridas do calendário fixo existem em qualquer nó. | Alto (nunca no semestre de base) |
| **Festival** | **Sair** sempre gera encontro, e encontros dão o dobro de afinidade. Treinos rendem −10%. | Médio |
| **Recuperação** | Descanso rende +50%, a Enfermaria não gasta o turno e o humor não cai por falha. | Médio |
| **Biblioteca** | Habilidades genéricas custam −30% de pontos. O treino de Inteligência conta 1 nível acima. | Baixo |
| **Desafio** | No 2º turno há uma corrida contra uma **NPC de elite** (força da categoria +20%). Top 3 dá **1 amuleto** (§5). Fora do top 3, o humor cai 1 nível. Correr é opcional. | No máximo 1 por trecho, a partir do trecho 3 |
| **Mistério** | No 1º turno, sorteia um evento especial de risco e recompensa (§4.3). | Baixo |

Regras do sorteio:
- Cada linha do mapa tem pelo menos 2 tipos diferentes de nó.
- Do trecho 1 em diante, **todo caminho possível** do trecho passa por pelo menos **1 Circuito**, para ninguém ficar sem corrida gerada por azar.
- Os Circuitos oferecem mais corridas da categoria que a campanha vai pedir no próximo objetivo.

### 4.3 Eventos de Mistério (exemplos)

- **Treino na serra:** +1 nível no próximo treino de Estamina ou Determinação, mas a chance de falha dobra nesse treino.
- **Treinadora visitante:** escolher 1 entre 2 habilidades genéricas de graça.
- **Aposta no refeitório:** uma corrida-relâmpago contra uma garota do elenco. Vencer dá humor e afinidade, perder tira humor.
- **Noite sem dormir:** −20 de energia, mas o próximo encontro é um evento único garantido.
- **Mercado de pulgas:** trocar 50 pontos de habilidade por um amuleto sorteado.
- **Nada demais:** um passeio tranquilo, +1 humor.

No MVP: **6 eventos de Mistério**.

### 4.4 Clima do mês

Cada mês tem um **clima**, sorteado pela semente junto com o mapa. O ícone aparece em cada linha do mapa, então o clima também entra no planejamento da rota.

O ano segue as estações do hemisfério sul: **outono** (mar–mai), **inverno** (jun–ago), **primavera** (set–nov) e **verão** (dez–fev).

| Clima | Treino (inicial) | Corrida (inicial) | Outono | Inverno | Primavera | Verão |
|---|---|---|---|---|---|---|
| **Tempo bom** | — | — | 50% | 45% | 50% | 40% |
| **Chuva** | Treinos de Velocidade rendem −10%. Treino de Poder conta 1 nível acima. | Aceleração −15% e bloqueio +50% para todas. O Poder vale mais. | 20% | 10% | 25% | 30% |
| **Calor** | Todo treino gasta +5 de energia. | Fôlego −2% para todas. A Estamina vale mais. | 5% | — | 10% | 25% |
| **Frio** | Descanso recupera −10%. Treino de Determinação conta 1 nível acima. | — | 10% | 30% | — | — |
| **Vento** | Treino de Inteligência rende +10%. | — (efeito na corrida fica para depois, ver abaixo) | 15% | 10% | 10% | — |
| **Noite de estrelas** | Encontros dão +50% de afinidade e o humor sobe 1 nível no início do mês. | — | — | 5% | 5% | 5% |

- O clima vale para **as corridas daquele mês** e para os dois turnos de treino.
- Os objetivos também pegam o clima do mês. O clima dos Grandes Prêmios (fevereiro, verão) é sorteado como os outros.
- **Férias** sempre têm Tempo bom ou Calor.
- Amuletos podem mexer no clima (ex.: *Capa de Chuva*: a chuva não tira ganho de treino).

**Teste no simulador** (300 corridas por célula, nível 600). Chuva e calor afetam todas as corredoras igual, então não favorecem ninguém diretamente. O que muda é **quanto vale cada atributo**:

| Clima | Efeito medido |
|---|---|
| Chuva | +200 de Poder em 1200 m: de 26% para 29% de vitória. Fora isso, quase igual ao tempo bom. É um efeito sutil, como planejado. |
| Calor (fôlego −8%) | Na Longa (3200 m), +200 de Estamina foi de 22% para **56%** e a Ponteira venceu 47%. Forte demais. |
| Calor (fôlego −2%) | Na Longa, +200 de Estamina vai para 28% e a Ponteira fica em 46% (no tempo bom são 41%). Nas outras distâncias não muda nada. |

Por isso o calor ficou em **−2%** de fôlego. Ainda assim, ele empurra a Ponteira na Longa, que já é o ponto fraco do balanço (§11 e [corrida.md](corrida.md) §8). O **vento** ficaria com um efeito de estilo (quem vai na frente gasta mais fôlego, quem vem atrás pega vácuo), mas isso precisa de uma regra nova no simulador e fica para depois do MVP.

## 5. Amuletos

Amuletos são modificadores que valem **até o fim da carreira**. Eles criam "builds" diferentes a cada carreira.

- **Como ganhar:** ao cumprir os objetivos 1 a 7, o jogador escolhe **1 entre 3** amuletos sorteados. O nó Desafio e alguns eventos de Mistério também dão amuletos.
- **Limite:** 6 amuletos equipados (7 com o título *Volta ao Céu*, §7.4). Ao ganhar o 7º, troca um ou descarta o novo.
- Uma carreira típica termina com **5 a 6 amuletos**, trocando alguns no caminho.
- **Não passam para a garota salva.** A versão salva leva só atributos, habilidades e aptidões.

### 5.1 Tipos

| Tipo | Ideia | Frequência |
|---|---|---|
| **Simples** | Bônus pequeno, sem custo | Comum |
| **Troca** | Bônus grande com um custo | Comum |
| **Estilo** | Só funciona com um estilo de corrida | Incomum |
| **Raro** | Muda uma regra do jogo | Raro |

### 5.2 Exemplos (inicial)

| Amuleto | Tipo | Efeito |
|---|---|---|
| Guizo de Bronze | Simples | Ganho de Velocidade +5% |
| Fita Azul | Simples | +10% de fama em toda corrida |
| Garrafinha | Simples | Descanso recupera +10 de energia |
| Sino de Vento | Troca | Treino de Poder conta 1 nível acima, mas Descansar recupera −20% |
| Coração de Fogo | Troca | Vitória sobe o humor 2 níveis, derrota (fora do top 3) derruba 2 |
| Mapa Velho | Troca | Vê o mapa do trecho seguinte, mas cada trecho tem 1 Circuito a menos |
| Lenço da Ponta | Estilo (Ponteira) | Na Largada, +5% de velocidade se estiver no top 3 |
| Garra de Prata | Estilo (Fechadora) | No Sprint, gasta 10% menos fôlego |
| Bússola | Estilo (Perseguidora) | Chance de bloqueio −30% |
| Trevo Torto | Estilo (Arrancadora) | Habilidades do Final disparam com +15% de chance |
| Estrela Cadente | Raro | Uma vez por carreira, uma falha de treino vira sucesso |
| Constelação | Raro | Os 2 treinos naturais da garota rendem +20% em vez de +10% |
| Sete Vidas *(proposta)* | Raro | Uma vez por carreira, se ela falhar um objetivo, pode correr de novo no turno seguinte em vez de encerrar a carreira. O amuleto some depois do uso. |

No MVP: **~15 amuletos**.

### 5.3 Progressão entre carreiras

Cada carreira concluída (chegando ao objetivo 8, vencendo ou não) **libera novos amuletos e eventos de Mistério** no sorteio. É uma progressão lenta, que soma com o vínculo e a pool (GDD §3.5 e §6).

## 6. Semente

- Cada carreira tem uma **semente** sorteada no turno 1.
- O mapa de todos os trechos sai da semente logo no início (o jogador só vê o trecho atual).
- Os sorteios usam fluxos separados, cada um calculado por `hash(semente, turno, contexto)`:
  - **mapa**, **clima**, **corridas geradas** e **amuletos oferecidos**;
  - **treino** (falha, lesão), com a ação escolhida no contexto;
  - **encontros** e **Mistério**;
  - **corrida**, com o id da corrida no contexto.
- Assim, **recarregar o save e repetir a mesma ação dá o mesmo resultado**. Trocar a ação pode mudar o resultado daquele turno, mas nunca reembaralha o mapa nem os turnos seguintes.
- A semente aparece na tela de fim de carreira, para quem quiser compartilhar uma carreira boa.

## 7. Fama e corridas opcionais

A fama mede quantas pessoas acompanham a garota. Ela nunca diminui durante a carreira.

**Para que serve**
1. **Entrar em corridas** de categoria mais alta (tabela da §2).
2. **Bônus de moeda** no fim da carreira (inicial: +1 moeda a cada 100 de fama; o valor da moeda fica para a etapa de economia).
3. **Encontros com torcedoras**: alguns encontros genéricos só aparecem com fama alta (conteúdo futuro).

**Quanto dá** (inicial)

| Categoria | 1º lugar |
|---|---|
| Estreia | 100 |
| Aberta | 200 |
| Prata | 400 |
| Ouro | 800 |
| Grande Prêmio | 1500 |

Por colocação: 2º = 50% · 3º = 30% · 4º e 5º = 15% · 6º em diante = 5%. O multiplicador do olheiro (§7.3) vale por cima disso.

### 7.1 Duas camadas de corridas opcionais

As opcionais vêm de duas fontes. As duas juntas deixam o jogador **planejar uma rota** (o calendário fixo é igual em toda carreira) sem perder a variedade do roguelike (os Circuitos são sorteados).

| Camada | O que é | Onde aparece |
|---|---|---|
| **Calendário fixo** (§7.2) | Corridas Prata e Ouro com nome, sempre no mesmo turno do ano. Algumas formam **séries** (§7.4). | Visível desde o turno 1. Dá para correr a partir de **qualquer nó**, no turno dela. |
| **Circuito** | Corridas **geradas** (categoria × distância × piso, com nome sorteado de uma lista). Cada turno de um nó Circuito oferece **2**. | Só nos nós Circuito (§4.2) e no Desafio. |

Regras que valem para as duas:
- Correr gasta **15 de energia** (inicial) e não dá ganho de treino naquele turno, mas **dá atributos**: em cada atributo, Estreia +5, Aberta +6, Prata +9, Ouro e GP do ano 1 +12, GPs dos anos 2 e 3 +15 (inicial). Quem vence ganha tudo, top 3 ganha 80% e o resto 50%. Sem isso, a curva de atributos travava no ano 3, quando a garota corre mais.
- **Corridas seguidas:** a 3ª corrida em 3 turnos seguidos gasta +10 de energia e tem 30% de chance de baixar o humor 1 nível (inicial).
- Uma carreira típica deve ter **14 a 20 corridas** contando os objetivos.

### 7.2 Calendário fixo

As corridas abaixo acontecem nos **anos 2 e 3**, no mesmo turno do ano. A Prata começa no turno 25 e a Ouro no turno 37 (2º semestre do ano 2). A coluna "Turno do ano" vai de 1 a 24, então no ano 2 some 24 e no ano 3 some 48.

**Prata**

| Turno do ano | Mês | Corrida | Casa |
|---|---|---|---|
| 3 | Abr · Início | Taça Faísca | Sprint Grama |
| 4 | Abr · Fim | Taça Poeira Alta | Milha Terra |
| 5 | Mai · Início | Taça Horizonte | Média Grama |
| 6 | Mai · Fim | Taça Travessia | Longa Terra |
| 7 | Jun · Início | Taça Brisa | Milha Grama |
| 9 | Jul · Início | Taça Relâmpago | Sprint Terra |
| 10 | Jul · Fim | Taça Maré | Longa Grama |
| 11 | Ago · Início | Taça Cânion | Média Terra |

**Ouro**

| Turno do ano | Mês | Corrida | Casa |
|---|---|---|---|
| 13 | Set · Início | Prêmio Equinócio | Média Grama |
| 14 | Set · Fim | Prêmio Trovão | Sprint Terra |
| 15 | Out · Início | Prêmio Via Láctea | Longa Grama |
| 16 | Out · Fim | Prêmio Cometa | Milha Grama |
| 17 | Nov · Início | Prêmio Duna | Milha Terra |
| 18 | Nov · Fim | Prêmio Meteoro | Sprint Grama |
| 19 | Dez · Início | Prêmio Eclipse | Longa Terra |
| 20 | Dez · Fim | Prêmio Nebulosa | Média Terra |

- Os turnos 8, 12 e 16 do ano coincidem com objetivos (turnos 32, 60 e 40). O Prêmio Cometa (turno 40) é de propósito: uma campanha pode usar uma corrida do calendário como objetivo.
- Os nomes são provisórios.
- No ano 1 não há calendário fixo. As opcionais do ano 1 são só as Abertas dos Circuitos.

### 7.3 Olheiro

Antes de toda corrida (opcional ou objetivo), a tela mostra:
- a **força média do pelotão** e se há **rival com nome**;
- uma **etiqueta de chance**, calculada rodando ~50 simulações rápidas da corrida (a simulação não depende da tela, GDD §10):

| Etiqueta | Chance estimada de vencer | Multiplicador de fama |
|---|---|---|
| **Favorita** | 40% ou mais | ×0,75 |
| **Disputada** | 15% a 40% | ×1,0 |
| **Azarão** | menos de 15% | ×1,5 |

Assim existe uma **rota segura** (correr só onde ela é Favorita), mas ela rende menos fama. Quem arrisca corridas de Azarão junta fama mais rápido.

**No protótipo** (`Carreira.olheiro`): 50 simulações completas levariam ~3 s por corrida, então o olheiro roda **1 simulação em modo estimativa** por instrução (sem sorte, sem bloqueio, cada habilidade pelo valor esperado, passo de 0,25 s) e sorteia a sorte de cada corredora por cima do tempo esperado (400 sorteios). Leva ~50 a 120 ms para as 3 instruções, e contra 40 corridas reais por caso erra em média 3 a 5 pontos de chance (`testes/instrucao.gd`). A etiqueta usa a chance da instrução sugerida, vale também para os objetivos e é determinística: o mesmo estado dá sempre a mesma etiqueta. Os números ficam em `data/calendario.json` (`olheiro`).

### 7.4 Séries e títulos

Vencer conjuntos de corridas do calendário fixo dá um **título**, que aparece na ficha da garota salva, mais uma recompensa na hora.

| Série | Como completar | Recompensa (inicial) |
|---|---|---|
| **Tríplice da casa** (ex.: *Estrela da Milha*) | Vencer a Prata e as 2 Ouros (anos 2 e 3) da mesma casa | +500 de fama e 1 amuleto (escolha entre 4, 1 raro garantido) |
| **Coroa Dupla** | Vencer as Ouros da mesma distância nos 2 pisos **no mesmo ano** | +300 de fama e +1 nível de aptidão no piso mais fraco |
| **Volta ao Céu** | Vencer uma Ouro em cada uma das 4 distâncias | Título raro e +1 limite de amuleto (7) até o fim da carreira |

As séries são o principal motivo para **planejar a rota** com antecedência: a Tríplice exige estar em forma em 3 turnos conhecidos, espalhados por 2 anos.

**No protótipo** (`Carreira._checar_series`): vale vencer a corrida do calendário fixo também quando ela é objetivo (o Prêmio Cometa da Capela). Cada série sai 1 vez por carreira: a Tríplice e a Coroa Dupla, 1 vez por casa ou distância. A Coroa Dupla conta só as Ouros do mesmo ano (as duas de cada distância ficam a 1 a 7 turnos uma da outra): sem isso, o bot fechava a Coroa em 42% das carreiras sem planejar a rota. Os títulos vão para a versão salva. Nomes (provisórios): Tríplice de Grama = **Estrela da *distância*** (ex.: *Estrela da Milha*), de Terra = **Poeira da *distância***; **Coroa Dupla da *distância***; **Volta ao Céu**. O cartão da corrida e o olheiro mostram o progresso de cada série que ela conta (ex.: *Estrela da Milha 1/3*).

## 8. Férias de verão

Turnos **21–22** (ano 1), **45–46** (ano 2) e **69–70** (ano 3), em janeiro.

- **Sem corridas.**
- O jogador escolhe 1 entre 2 acampamentos:
  - **Serra:** treinos de Estamina e Determinação contam 1 nível acima.
  - **Praia:** treinos de Velocidade e Poder contam 1 nível acima.
- **Sair** sempre gera um encontro.
- O descanso recupera mais energia (inicial: +50% sobre o normal).
- As férias do ano 3 ficam logo antes do GP final. É o último "fôlego" para a reta final.

## 9. Linha do tempo resumida

| Turnos | Fase | O que acontece |
|---|---|---|
| 1–2 | Chegada | Tutorial de treino. Capítulo 1 da história. |
| 3–10 | Semestre de base | Mapa com 4 nós, sem Circuito. Só treino, encontros e história. |
| 11–12 | Preparação | Turnos normais. Fecha o capítulo do semestre. |
| **13** | Objetivo 1 | **Estreia** da garota. Primeiro amuleto. |
| 14–19 | Trecho 1 | 3 nós. Abertas nos Circuitos. |
| **20** | Objetivo 2 | Objetivo da história. |
| 21–23 | Férias e véspera | Serra ou Praia. Encontro com a rival. |
| **24** | Objetivo 3 | **GP do ano 1**. |
| 25–31 | Trecho 3 | 3 nós. Começa o calendário fixo de Pratas. |
| **32** | Objetivo 4 | Objetivo da história. |
| 33–39 | Trecho 4 | 3 nós. Começam as Ouros (turno 37). |
| **40** | Objetivo 5 | Objetivo da história. |
| 41–47 | Trecho 5 | 2 nós, férias e véspera. |
| **48** | Objetivo 6 | **GP do ano 2**. Depois vem o **ponto de virada**. |
| 49–59 | Trecho 6 | 5 nós. Calendário fixo do ano 3, séries em jogo. |
| **60** | Objetivo 7 | Objetivo do caminho escolhido. |
| 61–71 | Trecho 7 | 4 nós, férias e véspera. |
| **72** | Objetivo 8 | **GP final** e o final do caminho. Fim da carreira. |

## 10. Magnitude (dificuldade crescente)

Na astronomia, a **magnitude** mede o brilho de uma estrela. Aqui ela é o nível de dificuldade de uma carreira, de **0 a 5**.

> No protótipo desde 2026-11-19 ([endgame](endgame.md) §1). A Má Fama virou **Bolso Furado** (prêmios em moeda das corridas −30%); os amuletos e Mistérios exclusivos ainda faltam.

- A magnitude é **por garota**. No começo da carreira, o jogador escolhe qualquer magnitude até a **maior liberada** para aquela garota.
- **Liberar:** terminar uma carreira **vencendo o GP final** na magnitude M libera a magnitude M+1 para aquela garota.
- Os efeitos se **acumulam**: a Magnitude 3 tem tudo da 1 e da 2.

| Magnitude | O que muda (inicial) |
|---|---|
| **0** | Normal. |
| **1** | NPCs +5% de força. |
| **2** | A carreira começa com **1 maldição** sorteada (amuleto negativo, que não ocupa vaga). |
| **3** | As metas dos objetivos sobem um degrau: top 5 vira top 3, top 3 vira vitória (§3.2). |
| **4** | NPCs +10% no total e rivais com nome +25% (em vez de +15%). |
| **5** | **2 maldições**, e cada trecho tem 1 nó de Recuperação a menos no sorteio. |

**Maldições** (exemplos, inicial)

| Maldição | Efeito |
|---|---|
| Coleira Frouxa | 5% de chance de falha em todo treino, mesmo com energia cheia |
| Torcida Exigente | Fama −20% em toda corrida |
| Insônia | Descanso recupera −15% |
| Nuvem Carregada | Chuva sai com o dobro da chance |
| Má Fama | O primeiro encontro de cada trecho é sempre o pior resultado possível |

**Recompensas**
- **Moeda** no fim da carreira: +20% por nível de magnitude.
- **Amuletos e eventos de Mistério** exclusivos, liberados ao vencer a primeira carreira em cada magnitude.
- Uma **estrela na ficha** da garota salva mostra a maior magnitude vencida com ela. É só visual.
- A magnitude **não deixa a garota salva mais forte**. O limite de atributos continua vindo só do vínculo (GDD §3.5). Assim o circuito não vira obrigação de jogar no difícil.

## 11. Corrida em nível baixo

As primeiras corridas (Estreia e Abertas do ano 1) acontecem com atributos entre 200 e 330. O simulador só tinha sido calibrado de 400 para cima ([corrida.md](corrida.md) §8.1). Um teste rápido (300 corridas, 3 de cada estilo, atributos iguais) mostra que os desvios do nível baixo continuam:

| Nível | 1200 | 1600 | 2000 | 3200 |
|---|---|---|---|---|
| **150** | 22 / 18 / 24 / **35** | 27 / 23 / 24 / 26 | 29 / 25 / 23 / 23 | **37** / 27 / 20 / 15 |
| **250** | 21 / 20 / 19 / **40** | 23 / 23 / 21 / **33** | 29 / 25 / 22 / 24 | **33** / 28 / 22 / 17 |

*Ponteira / Perseguidora / Arrancadora / Fechadora (%). Ideal 25%.*

No começo da carreira, a **Fechadora** é forte na Sprint e a **Ponteira** é forte na Longa. Isso pesa nos objetivos 1 e 2, então as campanhas devem evitar Sprint para Fechadoras e Longa para Ponteiras nesses objetivos até a recalibração. Duas saídas possíveis:
- Recalibrar o ritmo também nos níveis 150–300 (o `ajustar_ritmo` hoje usa 500 e 800).
- Aceitar como "sabor" do começo de carreira e compensar com a meta (top 5 em vez de top 3).

Enquanto isso, as campanhas usam uma exceção: a Fechadora de Sprint precisa de top 3 na Estreia ([campanhas](campanhas.md) §4.2).

**Resolvido na v0.7 (2026-11-20):** a simulação ganhou uma correção de estilo por nível e distância, calibrada de 200 a 1000 ([corrida.md](corrida.md) §8.5). Com ela, os 4 estilos ficam entre 21% e 29% em cada nível e distância da grade. A exceção da Fechadora de Sprint ficou, porque não pesa (campanhas §4.2).

## 12. Escopo do MVP

**Entra**
- O calendário de **72 turnos** (3 anos), com semestre de base, 8 objetivos e ponto de virada.
- **Campanha completa das 6 garotas do MVP**: 5 objetivos próprios, 2 caminhos e 2 finais cada. A primeira a ser escrita é a da Lira ([elenco](elenco.md#campanha-da-lira)).
- **Calendário fixo** com as 16 corridas com nome e as 3 séries (§7.2 e §7.4).
- **Olheiro** com etiqueta de chance (§7.3).
- **Clima do mês** com 6 climas (§4.4). Só chuva e calor mexem na corrida.
- Mapa de rotas com os **7 tipos de nó** e as regras de sorteio da §4.2.
- **6 eventos de Mistério** e **~15 amuletos**.
- Semente por carreira com fluxos separados (§6).
- Rivais com nome só nas casas da tabela §3.1.

**Fica para depois**
- **Magnitude** (§10).
- Efeito do **vento** na corrida (§4.4).

**Estado do protótipo:** o projeto Godot roda a carreira de **72 turnos** com as campanhas de `data/campanhas.json`, o calendário fixo, o ponto de virada e os finais. Ainda faltam o olheiro, as séries e a instrução pré-corrida.
