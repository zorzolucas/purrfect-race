# Nekomusume — Campanhas e balanceamento

> Versão 0.4 — 2026-11-18. Na v0.4 a diferença entre casas e entre arquétipos caiu para ~11 pontos, as viradas da Durona e da Curiosa mudaram, a Coroa Dupla pede as 2 Ouros no mesmo ano e o bot rodou com 40 sementes (§7).
> Versão 0.3 — 2026-11-17. Na v0.3 entraram o olheiro, a instrução pré-corrida, as séries e a madrinha no protótipo, e o bot rodou de novo (§7).
> Versão 0.2 — 2026-11-17. Na v0.2 entraram os resultados do bot na carreira de 72 turnos (§7) e as regras de virada calibradas.
> Versão 0.1 — 2026-11-17. Complementa o [calendário](calendario.md) §3 (estrutura da campanha) e o [elenco](elenco.md).
> Valores marcados com **(inicial)** são pontos de partida para balanceamento.

Este documento tem 4 partes:
1. **Metas de dificuldade**: quanto o jogo deve ser difícil, e como fica para quem já jogou muito (§1 e §2).
2. **As 6 campanhas do MVP**, escritas à mão (§3).
3. **12 arquétipos** que geram a campanha das outras 42 garotas (§4 e §5).
4. **Plano de balanceamento**: o que o bot mede, o que ajustar e quando está pronto (§6 e §7).

---

## 1. Metas de dificuldade

A régua é o **bot de balanceamento** (`testes/balanco.gd`), que joga de um jeito razoável mas sem planejar rota. Um jogador humano atento deve ir um pouco melhor que ele.

| Medida | Alvo |
|---|---|
| Carreiras completas (8 objetivos) com **conta nova** | **~35%** |
| Carreiras completas com **conta madura** | **~55%** |
| Diferença entre a garota mais fácil e a mais difícil | **no máximo 10 pontos** |
| Queda em um único objetivo | **no máximo 25%** das carreiras que chegam nele |
| Divisão no ponto de virada | cada caminho com **35% a 65%** das carreiras que chegam no turno 48 |
| Vitória no GP final (libera a Magnitude 1) | ~25% com conta nova (inicial) |

Com 8 objetivos, 35% de carreiras completas dá uma média de **~12% de queda por objetivo**. O teto de 25% evita que um objetivo sozinho vire um muro.

**Conta nova:** sem madrinha, vínculo 0 e só os amuletos e Mistérios iniciais.

**Conta madura:** madrinha com nota boa (média final ~700), vínculo 3 e tudo liberado no sorteio de amuletos e Mistérios. É o jogador que já fez umas 15 carreiras.

## 2. Progressão entre carreiras e endgame

O jogo **fica um pouco mais fácil** conforme o jogador junta madrinhas e cópias, mas pouco: de ~35% para ~55%. Quem já domina o jogo ganha desafio de outro jeito.

### 2.1 Bônus de conta, com teto

| Fonte | Bônus (inicial) | Teto |
|---|---|---|
| **Vínculo** (GDD §3.5) | +4 em cada atributo inicial por nível (nível 5 = +20) | — |
| **Madrinha** (GDD §3.6) | +3% dos atributos finais dela | +20 por atributo |
| **Vínculo + madrinha juntos** | — | **+25 por atributo** |
| **Inspiração** da madrinha (turnos 25 e 49) | chance de atributos e de +1 nível de aptidão | 1 aptidão por inspiração |

O bônus parece pequeno, mas cresce durante a carreira: com atributos maiores ela entra e vai bem em mais corridas, que dão fama e atributos. No bot, com teto de +50 a conta madura completava 73% das carreiras e a curva terminava 75 pontos acima. Por isso o teto ficou em +25 (§7).

### 2.2 Liberações "horizontais"

O que se libera depois do começo **dá variedade, não força**:
- **Amuletos e Mistérios novos** no sorteio (calendário §5.3), com o mesmo nível de poder dos iniciais.
- **Finais** e **títulos** de séries na ficha da garota.
- O limite de atributos sobe só com o vínculo (1000 → 1200).

### 2.3 Endgame

| Modo | O que é | Para quem |
|---|---|---|
| **Magnitude** (calendário §10) | Dificuldade 0 a 5 por garota, liberada vencendo o GP final. | Quem quer a mesma garota mais difícil. |
| **Circuito em níveis** | As 5 copas e o Campeonato Final (GDD §7) ganham 3 níveis: **Bronze, Prata e Ouro**. Cada nível sobe a força das NPCs (inicial: 600 / 800 / 950). O Ouro só abre com o Prata vencido. | Quem quer usar o elenco salvo. É onde a garota forte e o vínculo 5 fazem diferença. |
| **Desafio da semana** | A cada rotação da pool, uma carreira com **semente fixa**, garota fixa e uma regra especial (ex.: "só Pratas", "sempre chove"). Mostra o melhor resultado do jogador. Tudo offline. | Quem quer comparar carreiras em condições iguais. |

---

## 3. Campanhas do MVP

As 6 campanhas seguem o modelo do calendário §3.2: objetivos 1, 2, 4 e 5 próprios, metas dos GPs 1 e 2, capítulos de história, ponto de virada e 2 finais. A da **Lira** está no [elenco](elenco.md#campanha-da-lira). As outras 5 estão abaixo.

**Regra dos dois caminhos:** um caminho é o de **triunfo**, com objetivo 7 Difícil (vencer) e GP final top 3. O outro é o de **desvio**, com objetivo 7 Normal e GP final com uma condição extra (rival ou outra versão do GP). Os dois devem ter dificuldade parecida.

**Correção de dado:** a casa da **Antares** é **Sprint Terra** (como em `data/garotas.json`). A visão geral do elenco dizia Grama.

### 3.1 Nashira — "a estrategista"

*Uma garota que planeja tudo descobre que a melhor corrida dela foi a que saiu do roteiro.* Casa: Média Grama. Rival: **Polaris**.

| # | Turno | Corrida | Meta | Dificuldade |
|---|---|---|---|---|
| — | 1–12 | *Capítulo 1: "O caderno"*. Ela chega com um caderno cheio de anotações sobre todas as corredoras da academia. O evento *Caderno perdido* acontece aqui. | — | — |
| 1 | 13 | Estreia, Média Grama | Top 5 | Normal |
| — | 14–19 | *Capítulo 2: "Dados insuficientes"*. A estreia não sai como ela previu, e ela começa a anotar a si mesma. | — | — |
| 2 | 20 | Aberta gerada, Média Grama | Top 3 | Normal |
| 3 | 24 | GP do ano 1, Média Grama | Top 5 | Normal |
| — | 25–31 | *Capítulo 3: "A página da Polaris"*. Ela enche um caderno só com a Polaris e decide testar um plano B numa distância menor. | — | — |
| 4 | 32 | Prata gerada, **Milha Grama** | Top 5 | Normal (fora de casa) |
| — | 33–39 | *Capítulo 4: "O plano perfeito"*. O evento *Plano perfeito* acontece aqui. | — | — |
| 5 | 40 | Ouro gerada, Média Grama | Chegar **à frente da Polaris** | Normal (rival) |
| — | 41–47 | *Capítulo 5: "Quando o plano falha"*. O evento de mesmo nome acontece aqui. | — | — |
| 6 | 48 | GP do ano 2, Média Grama | Top 3 | Normal |

**Ponto de virada:** se o jogador escolheu "seguir o plano à risca" no capítulo *O plano perfeito* e ela ficou **top 2** no GP do ano 2, segue o caminho **O plano perfeito**. Senão, segue **Improviso**.

| Caminho | Objetivo 7 (turno 60) | GP final (turno 72) | Final |
|---|---|---|---|
| **O plano perfeito** | **Vencer** uma Ouro gerada de Média Grama (Difícil) | Média Grama, top 3 | *"Caderno fechado"*: o plano dá certo do começo ao fim, e ela dá o caderno para uma novata. |
| **Improviso** | Ouro gerada de **Longa Grama**, top 3 (fora de casa) | Média Grama, top 3 e **à frente da Polaris** | *"Página em branco"*: ela corre sem anotar nada e descobre que gosta. |

**Série natural:** *Estrela da Média* (Taça Horizonte e Prêmio Equinócio, anos 2 e 3).

### 3.2 Mira — "a última a sair, a primeira a chegar"

*Uma sonhadora que todos acham distraída descobre que corre melhor quando para de tentar ser outra pessoa.* Casa: Longa Grama. Rival: **Polaris**.

As corridas do ano 1 são na **Média**: no nível baixo a Fechadora sofre na Longa (calendário §11). A história usa isso: a treinadora "não deixa" ela correr a Longa ainda.

| # | Turno | Corrida | Meta | Dificuldade |
|---|---|---|---|---|
| — | 1–12 | *Capítulo 1: "Perdida"*. Ela chega atrasada no primeiro dia porque seguiu um gato de verdade. O evento *Perdida no caminho* acontece aqui. | — | — |
| 1 | 13 | Estreia, **Média Grama** | Top 5 | Normal |
| — | 14–19 | *Capítulo 2: "Longe demais"*. Ela acha que não deixam ela correr a Longa porque ninguém acredita nela. | — | — |
| 2 | 20 | Aberta gerada, **Média Grama** | Top 3 | Normal |
| 3 | 24 | GP do ano 1, **versão Média Grama** | Top 5 | Normal |
| — | 25–31 | *Capítulo 3: "Três mil e duzentos"*. Finalmente a Longa. | — | — |
| 4 | 32 | Prata gerada, Longa Grama | Top 5 | Normal |
| — | 33–39 | *Capítulo 4: "Nuvem em forma de peixe"*. O evento de mesmo nome acontece aqui. | — | — |
| 5 | 40 | Ouro gerada, Longa Grama | Top 3 | Normal |
| — | 41–47 | *Capítulo 5: "Quem é a outra Mira?"*. Ela descobre que gosta de correr no fundo. | — | — |
| 6 | 48 | GP do ano 2, Longa Grama | Top 3 | Normal |

**Ponto de virada:** se o jogador escolheu "então corra do seu jeito" no capítulo *Quem é a outra Mira?* e ela já venceu **pelo menos 1 corrida de virada** (fora do top 5 na metade da corrida), segue o caminho **A outra Mira**. Senão, segue **Nuvens**.

| Caminho | Objetivo 7 (turno 60) | GP final (turno 72) | Final |
|---|---|---|---|
| **A outra Mira** | **Vencer** uma Ouro gerada de Longa Grama (Difícil) | Longa Grama, top 3 | *"Primeira a chegar"*: ela larga em último e cruza em primeiro, como sempre sonhou. |
| **Nuvens** | Ouro gerada de **Média Grama**, top 3 (fora de casa) | Longa Grama, top 3 e **à frente da Polaris** | *"Corre porque gosta"*: ela para de se comparar e passa a correr pelo céu do caminho. |

**Série natural:** *Estrela da Longa* (Taça Maré e Prêmio Via Láctea, anos 2 e 3).

### 3.3 Capela — "a estrela do palco"

*Uma garota que só brilha com plateia descobre se corre pelos aplausos ou pela pista.* Casa: Milha Grama. Rival: a **campeã da casa** (§4.3).

| # | Turno | Corrida | Meta | Dificuldade |
|---|---|---|---|---|
| — | 1–12 | *Capítulo 1: "Primeira fila"*. Ela ensaia escondida uma dança de vitória antes de correr a primeira vez. O evento *Ensaio secreto* acontece aqui. | — | — |
| 1 | 13 | Estreia, Milha Grama | Top 5 | Normal |
| — | 14–19 | *Capítulo 2: "Fã número 1"*. Aparece a primeira fã, e ela quer correr em todo lugar. | — | — |
| 2 | 20 | **Maratona**: 2 corridas com top 5 desde a Estreia | — | Normal |
| 3 | 24 | GP do ano 1, Milha Grama | Top 5 | Normal |
| — | 25–31 | *Capítulo 3: "Palco pequeno"*. Uma corrida curta, sem holofote, para ela aprender a largar rápido. | — | — |
| 4 | 32 | Prata gerada, **Sprint Grama** | Top 5 | Normal (fora de casa) |
| — | 33–39 | *Capítulo 4: "Fã-clube"*. O evento de mesmo nome acontece aqui. | — | — |
| 5 | 40 | **Prêmio Cometa** (Ouro do calendário), Milha Grama | Top 3 | Normal |
| — | 41–47 | *Capítulo 5: "Sem plateia"*. O evento de mesmo nome acontece aqui. | — | — |
| 6 | 48 | GP do ano 2, Milha Grama | Top 3 | Normal |

**Ponto de virada:** se ela tem **fama de 5500 ou mais** no turno 48, segue o caminho **Ídolo**. Senão, segue **Corredora**. Liberar o evento no capítulo *Fã-clube* dá fama extra.

| Caminho | Objetivo 7 (turno 60) | GP final (turno 72) | Final |
|---|---|---|---|
| **Ídolo** | **Maratona**: 2 corridas com top 3 desde o GP do ano 2, pelo menos 1 delas Ouro | Milha Grama, top 3 e **à frente da campeã da casa** | *"Palco e pista"*: ela faz o show depois da corrida, e a arquibancada canta junto. |
| **Corredora** | **Vencer** uma Ouro gerada de Milha Grama (Difícil) | Milha Grama, top 3 | *"Sem plateia"*: ela vence de madrugada num treino vazio e percebe que não precisa de ninguém olhando. |

**Série natural:** *Estrela da Milha* (a mesma da Lira).

### 3.4 Antares — "a pancada"

*Uma garota que só sabe ir com tudo aprende que o corpo também tem voz.* Casa: Sprint Terra. Rival: **Algol**.

| # | Turno | Corrida | Meta | Dificuldade |
|---|---|---|---|---|
| — | 1–12 | *Capítulo 1: "Cinco da manhã"*. Ela já está na pista quando todo mundo acorda. O evento *Treino às 5h* acontece aqui. | — | — |
| 1 | 13 | Estreia, Sprint Terra | Top 5 | Normal |
| — | 14–19 | *Capítulo 2: "A provocadora"*. A Algol aparece na arquibancada e ri da estreia dela. | — | — |
| 2 | 20 | Aberta gerada, Sprint Terra | Top 3 | Normal |
| 3 | 24 | GP do ano 1, Sprint Terra | Top 5 | Normal |
| — | 25–31 | *Capítulo 3: "No terreno dela"*. A Algol a desafia na Milha. | — | — |
| 4 | 32 | Prata gerada, **Milha Terra** | Chegar **à frente da Algol** | Normal (rival) |
| — | 33–39 | *Capítulo 4: "Lanche proibido"*. O evento de mesmo nome acontece aqui. | — | — |
| 5 | 40 | Ouro gerada, Sprint Terra | Top 3 | Normal |
| — | 41–47 | *Capítulo 5: "Distância demais"*. O evento de mesmo nome acontece aqui. | — | — |
| 6 | 48 | GP do ano 2, Sprint Terra | Top 3 | Normal |

**Ponto de virada:** se ela **venceu o GP do ano 2**, ficou **top 2 no objetivo 5** e **não se lesionou desde o turno 25**, segue o caminho **Sem freio**. Senão, segue **Fôlego novo**.

| Caminho | Objetivo 7 (turno 60) | GP final (turno 72) | Final |
|---|---|---|---|
| **Sem freio** | **Vencer** uma Ouro gerada de Sprint Terra (Difícil) | Sprint Terra, top 3 | *"Ninguém segura"*: ela vence a Algol na largada e as duas apostam corrida até o refeitório. |
| **Fôlego novo** | Ouro gerada de **Milha Terra**, top 3 (fora de casa) | **Versão Milha Terra** do GP, top 3 e **à frente da Algol** | *"Saber parar"*: ela aprende a respirar no meio da corrida e ganha uma distância nova. |

**Série natural:** *Estrela da Sprint* na Terra (Taça Relâmpago e Prêmio Trovão, anos 2 e 3).

### 3.5 Shaula — "a sombra"

*Uma garota que diz não ligar para nada carrega uma cidade inteira nas costas.* Casa: Longa Terra. Rival: a **campeã da casa** (§4.3).

Como a Mira, ela é Fechadora de Longa, então o ano 1 é na **Média Terra**.

| # | Turno | Corrida | Meta | Dificuldade |
|---|---|---|---|---|
| — | 1–12 | *Capítulo 1: "Terra batida"*. Ela é a última a sair da pista toda noite. O evento *Última na pista* acontece aqui. | — | — |
| 1 | 13 | Estreia, **Média Terra** | Top 5 | Normal |
| — | 14–19 | *Capítulo 2: "Cidade pequena"*. Ela conta, sem querer, que corria na terra da cidade natal. | — | — |
| 2 | 20 | Aberta gerada, **Média Terra** | Top 3 | Normal |
| 3 | 24 | GP do ano 1, **versão Média Terra** | Top 5 | Normal |
| — | 25–31 | *Capítulo 3: "Grama alheia"*. A academia quer ver se ela corre na grama. | — | — |
| 4 | 32 | Prata gerada, **Longa Grama** | Top 5 | Normal (outro piso) |
| — | 33–39 | *Capítulo 4: "Carta de casa"*. O evento de mesmo nome acontece aqui. | — | — |
| 5 | 40 | Ouro gerada, Longa Terra | Top 3 | Normal |
| — | 41–47 | *Capítulo 5: "Lira de novo"*. O evento de mesmo nome acontece aqui. | — | — |
| 6 | 48 | GP do ano 2, Longa Terra | Top 3 | Normal |

**Ponto de virada:** se o jogador escolheu "perguntar" no capítulo *Carta de casa* e **saiu com ela pelo menos 1 vez** (ação Sair), segue o caminho **Raízes**. Senão, segue **Sombra**.

| Caminho | Objetivo 7 (turno 60) | GP final (turno 72) | Final |
|---|---|---|---|
| **Raízes** | Ouro gerada de **Média Terra**, top 3 (fora de casa) | Longa Terra, top 3 e **à frente da campeã da casa** | *"Volta para casa"*: a cidade natal assiste ao GP pelo rádio, e ela acena para a câmera pela primeira vez. |
| **Sombra** | **Vencer** uma Ouro gerada de Longa Terra (Difícil) | Longa Terra, top 3 | *"Última na pista"*: ela vence e continua sendo a última a sair, agora com a Lira do lado. |

**Série natural:** *Estrela da Longa* na Terra (Taça Travessia e Prêmio Eclipse, anos 2 e 3).

### 3.6 Resumo das 6

| Garota | Obj. 2 | Obj. 4 | Obj. 5 | Virada decidida por | Caminhos |
|---|---|---|---|---|---|
| Lira | Top 3 casa | Rival (Polaris, na Milha) | Prêmio Cometa top 3 | Resultado + escolha | Coroa da Milha / Revanche |
| Nashira | Top 3 casa | Fora de casa (Milha) | Rival (Polaris) | Resultado + escolha | O plano perfeito / Improviso |
| Mira | Top 3 Média | Top 5 casa | Top 3 casa | Escolha (evento) | A outra Mira / Nuvens |
| Capela | Maratona | Fora de casa (Sprint) | Prêmio Cometa top 3 | Fama | Ídolo / Corredora |
| Antares | Top 3 casa | Rival (Algol, Milha) | Top 3 casa | Resultado + saúde | Sem freio / Fôlego novo |
| Shaula | Top 3 Média | Outro piso (Grama) | Top 3 casa | Escolha + saídas | Raízes / Sombra |

Cada campanha usa um tipo diferente de virada. É de propósito: o bot mede se cada tipo dá a divisão de 35% a 65% (§1).

---

## 4. Campanhas por modelo

As outras **42 garotas** ganham a campanha a partir de **1 dos 12 arquétipos** (§5) e da **casa** delas. O arquétipo dá o tom, a meta de alguns objetivos, a regra da virada e os textos. A casa dá as corridas.

### 4.1 Regras fixas

| # | Turno | Corrida | Meta |
|---|---|---|---|
| 1 | 13 | Estreia na casa | Top 5 |
| 2 | 20 | Aberta gerada na casa | Do arquétipo |
| 3 | 24 | GP do ano 1, versão da casa | Top 5 |
| 4 | 32 | Prata gerada (casa, distância vizinha ou outro piso, conforme o arquétipo) | Do arquétipo |
| 5 | 40 | Ouro na casa (se a casa for Milha Grama, é o Prêmio Cometa) | Top 3 |
| 6 | 48 | GP do ano 2, versão da casa | Top 3 |
| 7 | 60 | Do caminho | Do caminho |
| 8 | 72 | GP final, versão da casa ou do caminho | Top 3 + condição do caminho |

- **Distância vizinha:** Sprint ↔ Milha ↔ Média ↔ Longa. Quem é de Sprint vai para a Milha, e quem é de Longa vai para a Média. Nos outros casos, o arquétipo diz se vai para cima ou para baixo (padrão: a mais longa).
- **Outro piso** só vale quando a aptidão no outro piso é Ok ou melhor. Se for Ruim, a meta vira "fora de casa".

### 4.2 Exceções do nível baixo

Até o ritmo ser recalibrado nos níveis 150–300 (calendário §11):
- **Fechadora de Longa:** objetivos 1 e 2 e o GP do ano 1 na **Média** do mesmo piso (como a Mira e a Shaula).
- **Fechadora de Sprint:** a Estreia pede **top 3** em vez de top 5, porque ela tem vantagem no começo.
- *A **Ponteira de Longa** saiu desta exceção na v0.4: com top 3, a Estreia derrubava 29% delas (§7).*

Quando a recalibração sair, o bot roda de novo e as exceções que não forem mais necessárias saem.

### 4.3 Rival da campanha

- Se a casa tem rival com nome (calendário §3.1), é ela: **Polaris** em Média e Longa Grama, **Algol** em Sprint e Milha Terra.
- Senão, é a **campeã da casa**: a garota do elenco da mesma casa com a maior soma de atributos que não seja a jogadora. Ela corre com +15% sobre a força da categoria nas corridas de objetivo e no GP, como as rivais com nome, mas sem encontros no MVP.
- A rival da campanha **corre sempre com aptidão Ótima** na distância e no piso da corrida (`aptidao_rival` no `data/calendario.json`). Antes da v0.4, Polaris na Longa e Algol na Milha tinham aptidão Boa e eram mais fracas que as campeãs da casa, o que deixava as casas com campeã até 7 pontos mais difíceis.
- Na **primeira Prata** (objetivo 4, turno 32) dos arquétipos Competitiva, Estrategista e Leal, a rival corre **sem os +15%** (`forca_rival: 1.0` no objetivo): ela ainda está pegando ritmo. Esse objetivo derrubava de 33% a 42% das carreiras desses arquétipos.

Isso **muda o calendário §3.1**: a "campeã da casa" deixa de ser uma NPC gerada e passa a ser uma garota do elenco. Assim ela tem nome e cara, e o jogador vai conhecendo as 48 aos poucos.

### 4.4 Textos por arquétipo

Cada arquétipo tem **7 textos**, escritos uma vez e preenchidos com o nome da garota, a casa e a rival:

| Texto | Quando |
|---|---|
| Capítulo 1 | Semestre de base (turnos 1–12) |
| Capítulo 2 | Da Estreia ao GP do ano 1 (turnos 14–23) |
| Capítulo 3 | Ano 2 até o GP (turnos 25–47) |
| Capítulo 4A e 4B | Ano 3, um por caminho (turnos 49–71) |
| Final A e Final B | Depois do GP final |

São **84 textos** no total (12 × 7). As campanhas do MVP têm mais capítulos (um entre cada par de objetivos) porque têm eventos únicos.

---

## 5. Os 12 arquétipos

3 por estilo de corrida. Em cada estilo, um arquétipo é parecido com uma garota do MVP (a referência), para o tom ficar coerente, mas as campanhas do modelo são mais simples que as do MVP.

`{nome}` é a garota, `{rival}` é a rival da campanha e `{casa}` é a casa dela.

### 5.1 Ponteiras

**Competitiva** (referência: Lira). *Quer vencer tudo agora e aprende que vencer também é esperar.*
- Objetivo 2: top 3. Objetivo 4: Prata na casa, **à frente de {rival}**.
- Virada: venceu o GP do ano 2 **e** ficou top 2 no objetivo 5 → **Coroa**. Senão → **Revanche**.
- Coroa: vencer Ouro na casa (Difícil); GP final top 3. Revanche: Ouro na casa à frente de {rival}; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Ainda não?!"*: {nome} descobre que vai passar seis meses sem correr. 2 *"Primeira chegada"*: {rival} se apresenta depois da estreia. 3 *"Quem é ela?"*: {rival} vence {nome} numa opcional e ela treina sem parar. 4A *"Esperar também é correr"*. 4B *"Ajuste de contas"*.
- Finais: A *"Paciência de campeã"*: ela vira a referência das novatas. B *"Rival de respeito"*: as duas combinam correr juntas no ano seguinte.

**Capitã**. *Cuida de todo mundo e precisa aprender a correr por si.*
- Objetivo 2: Maratona (2 corridas com top 5). Objetivo 4: Prata **fora de casa**, top 5 ("cobrir a vaga de uma colega").
- Virada: escolheu "cuidar do grupo" no capítulo 3 **e** ficou top 3 no GP do ano 2 → **Capitã da academia**. Senão → **Voo solo**.
- Capitã da academia: Ouro na casa, top 3; GP final top 3 e à frente de {rival}. Voo solo: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"Monitora"*: {nome} vira responsável pelas novatas no primeiro dia. 2 *"Todas juntas"*: ela leva as novatas para correr nas Abertas. 3 *"Escolha"*: uma novata pede ajuda na véspera de uma corrida dela (escolha: cuidar do grupo ou focar em si). 4A *"Faixa de capitã"*. 4B *"Só eu e a pista"*.
- Finais: A *"Todas na foto"*: a academia inteira na foto do pódio. B *"A estrada é minha"*: ela corre o GP sem olhar para trás.

**Durona** (referência: Antares). *Só sabe ir com tudo e aprende a ouvir o corpo.*
- Objetivo 2: top 3. Objetivo 4: Prata no **outro piso**, top 5 ("provar que corre em qualquer chão").
- Virada: venceu o GP do ano 2, ficou **top 3 no objetivo 4** e está **sem lesão desde o turno 25** → **Sem limites**. Senão → **Corpo e cabeça**.
- Sem limites: vencer Ouro na casa (Difícil); GP final top 3. Corpo e cabeça: Ouro na distância vizinha, top 3; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Antes do sol"*: {nome} treina antes de todo mundo acordar. 2 *"Mais um"*: ela esconde uma dor para não perder treino. 3 *"Chão diferente"*: corrida no outro piso. 4A *"Sem freio"*. 4B *"Respirar"*.
- Finais: A *"Ninguém segura"*. B *"Saber parar"*: ela ganha uma distância nova.

### 5.2 Perseguidoras

**Estrategista** (referência: Nashira). *Planeja tudo e descobre o valor do improviso.*
- Objetivo 2: top 3. Objetivo 4: Prata na casa, **à frente de {rival}**.
- Virada: escolheu "seguir o plano" no capítulo 3 **e** ficou top 2 no GP do ano 2 → **Tudo previsto**. Senão → **Fora do roteiro**.
- Tudo previsto: vencer Ouro na casa (Difícil); GP final top 3. Fora do roteiro: Ouro na distância vizinha, top 3; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Planilha"*: {nome} já sabe o tempo de todas as veteranas. 2 *"Variável nova"*: {rival} não faz o que ela previu. 3 *"O plano"*: ela mostra um plano para o GP (escolha: seguir à risca ou deixar margem). 4A *"Execução"*. 4B *"Sem mapa"*.
- Finais: A *"Tudo como previsto"*. B *"Fora do roteiro"*: a melhor corrida dela foi a que ela não planejou.

**Leal**. *Corre por uma promessa e descobre o que quer para si.*
- Objetivo 2: Maratona (2 corridas com top 5). Objetivo 4: Prata na casa, **à frente de {rival}** ("a amiga de infância virou rival").
- Virada: **saiu com ela 2 vezes ou mais** até o turno 48 → **Promessa**. Senão → **Por mim**.
- Promessa: Ouro na casa, top 3; GP final top 3 e à frente de {rival}. Por mim: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"A promessa"*: {nome} prometeu a alguém de casa que correria o GP. 2 *"Carta"*: a resposta chega depois da estreia. 3 *"Do outro lado"*: {rival} é alguém que ela conhece desde pequena. 4A *"Cumprir"*. 4B *"Minha corrida"*.
- Finais: A *"Promessa cumprida"*. B *"Correr por mim"*.

**Perfeccionista**. *Nunca está satisfeita e aprende que bom também é bom.*
- Objetivo 2: top 3. Objetivo 4: Prata **fora de casa**, top 5 ("a corrida errada").
- Virada: venceu **10 corridas ou mais** até o turno 48 → **Recorde**. Senão → **Bom o bastante**.
- Recorde: vencer Ouro na casa (Difícil); GP final top 3. Bom o bastante: Ouro na casa, top 3; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Cronômetro"*: {nome} refaz o mesmo treino até sair perfeito. 2 *"Segundo lugar"*: um 2º lugar que ela trata como derrota. 3 *"Fora do lugar"*: uma distância que ela não domina. 4A *"Décimo de segundo"*. 4B *"Respirar fundo"*.
- Finais: A *"Recorde"*: o tempo dela vai para o quadro da academia. B *"Bom o bastante"*: ela sorri no pódio pela primeira vez.

### 5.3 Arrancadoras

**Estrela** (referência: Capela). *Brilha com plateia e descobre se corre pelos aplausos ou pela pista.*
- Objetivo 2: Maratona (2 corridas com top 5). Objetivo 4: Prata **fora de casa**, top 5.
- Virada: fama de **6000 ou mais** no turno 48 → **Holofote**. Senão → **Pista vazia**.
- Holofote: Maratona, 2 corridas com top 3 desde o GP do ano 2 (1 Ouro); GP final top 3 e à frente de {rival}. Pista vazia: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"Primeira foto"*: {nome} quer ser famosa antes de correr. 2 *"Fã"*: a primeira fã aparece. 3 *"Turnê"*: ela quer correr em todo lugar. 4A *"Palco"*. 4B *"Madrugada"*.
- Finais: A *"Palco e pista"*. B *"Sem plateia"*.

**Festeira**. *Faz amizade com todas, atrapalha o treino e aprende a hora de focar.*
- Objetivo 2: top 3. Objetivo 4: Prata no **outro piso**, top 5.
- Virada: passou por **pelo menos 1 nó de Festival** até o turno 48 → **Rainha da festa**. Senão → **Hora de focar**.
- Rainha da festa: Ouro na casa, top 3; GP final top 3 e à frente de {rival}. Hora de focar: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"Boas-vindas"*: {nome} organiza uma festa no primeiro dia. 2 *"Depois da festa"*: ela chega cansada num treino importante. 3 *"Todo mundo convidado"*: até {rival} vai à festa dela. 4A *"A festa continua"*. 4B *"Luzes apagadas"*.
- Finais: A *"Rainha da festa"*: a comemoração do GP é a maior que a academia já viu. B *"Hora de focar"*: ela comemora sozinha, com um sorvete.

**Curiosa**. *Quer testar tudo e descobre onde é a casa dela.*
- Objetivo 2: Aberta **fora de casa**, top 5. Objetivo 4: Prata no **outro piso**, top 5.
- Virada: **correu nas 4 distâncias** e ficou **top 3 em pelo menos 3** delas até o turno 48 → **Exploradora**. Senão → **Volta para casa**.
- Exploradora: Ouro na distância vizinha, top 3; GP final, versão da distância vizinha, top 3. Volta para casa: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"E se?"*: {nome} pergunta tudo sobre todas as pistas. 2 *"Outra distância"*: ela quer correr fora de casa logo depois da estreia. 3 *"Chão novo"*. 4A *"Mapa completo"*. 4B *"O caminho de volta"*.
- Finais: A *"Exploradora"*: ela coleciona as 4 distâncias no caderno. B *"Volta para casa"*.

### 5.4 Fechadoras

**Sonhadora** (referência: Mira). *Distraída o ano todo, acorda na reta final.*
- Objetivo 2: top 3. Objetivo 4: Prata na casa, **à frente de {rival}**.
- Virada: venceu **4 corridas de virada** (estava fora do top 5 na metade da corrida) até o turno 48 → **Acordada**. Senão → **Céu aberto**.
- Acordada: vencer Ouro na casa (Difícil); GP final top 3. Céu aberto: Ouro na distância vizinha, top 3; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Nas nuvens"*: {nome} esquece o horário do treino olhando o céu. 2 *"Lá atrás"*: ela larga em último na estreia e ninguém entende. 3 *"Reta final"*. 4A *"Desperta"*. 4B *"Nuvens"*.
- Finais: A *"Do fundo"*: ela larga em último e cruza em primeiro. B *"Corre porque gosta"*.

**Misteriosa** (referência: Shaula). *Esconde um passado e decide se mostra quem é.*
- Objetivo 2: top 3. Objetivo 4: Prata no **outro piso**, top 5 ("a pista de onde ela veio").
- Virada: escolheu "perguntar" no capítulo 3 → **Raízes**. Senão → **Sombra**.
- Raízes: Ouro na distância vizinha, top 3; GP final top 3 e à frente de {rival}. Sombra: vencer Ouro na casa (Difícil); GP final top 3.
- Capítulos: 1 *"Ninguém sabe"*: {nome} não fala de onde veio. 2 *"Foto antiga"*: cai uma foto da mochila dela. 3 *"Pergunta"*: escolha entre perguntar e respeitar o silêncio. 4A *"De onde eu vim"*. 4B *"Sombra"*.
- Finais: A *"Volta para casa"*. B *"Última na pista"*.

**Teimosa**. *Faz tudo do jeito dela e aprende a ouvir, ou prova que estava certa.*
- Objetivo 2: top 3. Objetivo 4: Prata na casa, **à frente de {rival}**.
- Virada: escolheu "deixar do jeito dela" no capítulo 3 **e** ficou top 2 no GP do ano 2 → **Do meu jeito**. Senão → **Ouvir**.
- Do meu jeito: vencer Ouro na casa (Difícil); GP final top 3. Ouvir: Ouro na distância vizinha, top 3; GP final top 3 e à frente de {rival}.
- Capítulos: 1 *"Não"*: {nome} recusa o plano de treino no primeiro dia. 2 *"Eu avisei"*: ela ignora a instrução e se dá mal, ou bem. 3 *"Briga"*: escolha entre impor o plano e deixar do jeito dela. 4A *"Do meu jeito"*. 4B *"Escutar"*.
- Finais: A *"Eu avisei"*: ela vence do jeito que sempre disse. B *"A treinadora tinha razão"*: e ela admite isso em público.

### 5.5 Tipos de virada

| Tipo | Arquétipos | Dado que o jogo guarda |
|---|---|---|
| Resultado | Competitiva | Colocação nos objetivos |
| Resultado + escolha | Capitã, Estrategista, Teimosa | Colocação + escolha do capítulo 3 |
| Resultado + saúde | Durona | Colocação nos objetivos 4 e 6 + turno da última lesão |
| Saídas | Leal | Quantas vezes ela saiu (ação Sair) |
| Escolha | Misteriosa | Escolha do capítulo 3 |
| Contador | Perfeccionista (vitórias), Estrela (fama), Festeira (Festivais), Curiosa (distâncias corridas e com top 3), Sonhadora (vitórias de virada) | Contadores da carreira |

*Na v0.2, "afinidade com ela" virou "saídas": o protótipo só tem afinidade com as colegas, e sair com a garota é o jeito que o jogador tem de passar tempo com ela.*

### 5.6 Quem tem cada arquétipo

10 Ponteiras, 11 Perseguidoras, 11 Arrancadoras e 10 Fechadoras (as outras 6 de cada estilo são do MVP). Cada arquétipo fica com 3 ou 4 garotas, e evitei repetir arquétipo na mesma casa.

| Garota | Casa | Estilo | Arquétipo | Rival da campanha | Exceção (§4.2) |
|---|---|---|---|---|---|
| Altair | Sprint Grama | Ponteira | Competitiva | Campeã da casa | — |
| Electra | Sprint Grama | Ponteira | Durona | Campeã da casa | — |
| Spica | Sprint Grama | Perseguidora | Leal | Campeã da casa | — |
| Adara | Sprint Grama | Arrancadora | Estrela | Campeã da casa | — |
| Maia | Sprint Grama | Arrancadora | Festeira | Campeã da casa | — |
| Alcione | Sprint Grama | Fechadora | Teimosa | Campeã da casa | Estreia top 3 |
| Cassiopeia | Milha Grama | Perseguidora | Estrategista | Campeã da casa | — |
| Vela | Milha Grama | Perseguidora | Leal | Campeã da casa | — |
| Auriga | Milha Grama | Arrancadora | Curiosa | Campeã da casa | — |
| Carina | Milha Grama | Fechadora | Sonhadora | Campeã da casa | — |
| Alya | Média Grama | Ponteira | Capitã | Polaris | — |
| Alcor | Média Grama | Perseguidora | Estrategista | Polaris | — |
| Alhena | Média Grama | Arrancadora | Festeira | Polaris | — |
| Mizar | Média Grama | Fechadora | Teimosa | Polaris | — |
| Dubhe | Média Grama | Fechadora | Sonhadora | Polaris | — |
| Almach | Longa Grama | Ponteira | Capitã | Polaris | — |
| Elnath | Longa Grama | Ponteira | Competitiva | Polaris | — |
| Nunki | Longa Grama | Perseguidora | Perfeccionista | Polaris | — |
| Ankaa | Longa Grama | Arrancadora | Curiosa | Polaris | — |
| Zosma | Longa Grama | Fechadora | Misteriosa | Polaris | Ano 1 na Média |
| Mintaka | Sprint Terra | Ponteira | Durona | Algol | — |
| Mérope | Sprint Terra | Perseguidora | Perfeccionista | Algol | — |
| Celeno | Sprint Terra | Arrancadora | Estrela | Algol | — |
| Andrômeda | Sprint Terra | Arrancadora | Festeira | Algol | — |
| Bellatrix | Sprint Terra | Fechadora | Misteriosa | Algol | Estreia top 3 |
| Columba | Milha Terra | Ponteira | Competitiva | Algol | — |
| Fênix | Milha Terra | Perseguidora | Leal | Algol | — |
| Corona | Milha Terra | Perseguidora | Perfeccionista | Algol | — |
| Hidra | Milha Terra | Arrancadora | Estrela | Algol | — |
| Zaniah | Milha Terra | Arrancadora | Festeira | Algol | — |
| Tucana | Milha Terra | Fechadora | Teimosa | Algol | — |
| Deneb | Média Terra | Ponteira | Capitã | Campeã da casa | — |
| Albireo | Média Terra | Perseguidora | Estrategista | Campeã da casa | — |
| Hamal | Média Terra | Perseguidora | Leal | Campeã da casa | — |
| Achernar | Média Terra | Arrancadora | Estrela | Campeã da casa | — |
| Mimosa | Média Terra | Fechadora | Sonhadora | Campeã da casa | — |
| Mirach | Média Terra | Fechadora | Misteriosa | Campeã da casa | — |
| Saiph | Longa Terra | Ponteira | Capitã | Campeã da casa | — |
| Alnair | Longa Terra | Ponteira | Durona | Campeã da casa | — |
| Naos | Longa Terra | Perseguidora | Estrategista | Campeã da casa | — |
| Avior | Longa Terra | Arrancadora | Curiosa | Campeã da casa | — |
| Atria | Longa Terra | Fechadora | Misteriosa | Campeã da casa | Ano 1 na Média |

Contagem: Competitiva 3, Capitã 4, Durona 3, Estrategista 4, Leal 4, Perfeccionista 3, Estrela 4, Festeira 4, Curiosa 3, Sonhadora 3, Misteriosa 4, Teimosa 3.

---

## 6. Plano de balanceamento

### 6.1 Ponto de partida

O protótipo ainda roda a carreira antiga de **48 turnos**, com objetivos 2 e 4 sorteados. Resultado do bot hoje (20 carreiras por garota, conta nova):

| Garota | Obj. 1 | Obj. 2 | Obj. 3 | Obj. 4 | Obj. 5 |
|---|---|---|---|---|---|
| Lira | 90% | 70% | 50% | 40% | 25% |
| Nashira | 90% | 70% | 65% | 50% | 35% |
| Mira | 75% | 45% | 35% | 30% | 20% |
| Capela | 70% | 55% | 40% | 40% | 25% |
| Antares | 70% | 45% | 35% | 25% | 20% |
| Shaula | 75% | 50% | 40% | 35% | 20% |

*% de carreiras que passaram de cada objetivo.* A diferença entre a melhor e a pior é de 15 pontos, e o objetivo 2 derruba até 40% de quem chega nele. Esses números não valem para a carreira nova, mas mostram onde estão os buracos: o começo é duro demais para Fechadoras e para a Antares.

### 6.2 Mudanças no protótipo (feitas)

1. **72 turnos** em `data/calendario.json`: semestre de base, 7 trechos com 24 nós, férias nos turnos 21–22, 45–46 e 69–70, vésperas e o calendário fixo de 16 corridas.
2. **`data/campanhas.json`** com as 6 campanhas do MVP, os 12 arquétipos e o arquétipo de cada garota. `scripts/campanha.gd` monta a campanha das outras 42 a partir do arquétipo e da casa (§4.1), sem guardar 42 cópias.
3. **Metas novas** na avaliação de objetivo: rival, maratona, fora de casa, outro piso e vitória. A simulação guarda a ordem na metade da corrida para contar as vitórias de virada.
4. **Ponto de virada** com as regras da §5.5, decidido ao cumprir o GP do ano 2. O caminho entra no save.
5. **Capítulos de história** como diálogos nos turnos 1, 14, 25, 33 e 41, mais o do caminho no turno 49. O final aparece na tela de fim.
6. **Rival da campanha** e **campeã da casa** (uma garota do elenco) nas corridas de objetivo com meta de rival e em todo GP.
7. **Madrinha** e inspirações no código da carreira, ainda sem tela (só o bot usa).
8. **Bot** com conta nova e madura, e o teste `teste_campanhas` para as 48 campanhas.

O olheiro, as séries e a instrução pré-corrida ainda não estão no protótipo.

**Formato do `data/campanhas.json`:**

```json
{
  "mvp": {
    "Nashira": {
      "objetivos": [
        {"turno": 13, "cat": "estreia", "dist": "media", "piso": "grama", "meta": {"max": 5}},
        {"turno": 40, "cat": "ouro", "dist": "media", "piso": "grama", "meta": {"rival": "Polaris"}}
      ],
      "capitulos": [{"turno": 33, "titulo": "O plano perfeito", "texto": "...", "escolhas": [...]}],
      "virada": {"e": [{"flag": "plano_a_risca"}, {"top": [48, 2]}]},
      "caminhos": {"A": {"nome": "...", "objetivos": [...], "capitulo": {...}, "final": {...}}, "B": {...}}
    }
  },
  "arquetipos": {
    "competitiva": {"obj2": {"turno": 20, "cat": "aberta", "onde": "casa", "meta": {"max": 3}}, "obj4": {...}, "virada": {...}, "capitulos": [...], "caminhos": {...}}
  },
  "arquetipo_por_garota": {"Altair": "competitiva"}
}
```

Uma meta pode ter `max` (colocação), `rival` (nome ou `true` para a rival da campanha) e `maratona` (quantas corridas com aquela colocação desde o objetivo anterior). O `onde` dos arquétipos é `casa`, `vizinha` ou `outro_piso`.

### 6.3 O que o bot faz

- Treina o atributo mais atrasado em relação ao perfil da casa e descansa com energia abaixo de 45 (ou sai, se o humor estiver Normal ou pior). Escolhe o nó do mapa pelo tipo, preferindo Treino focado e Circuito.
- **Opcionais:** corre quando a média dos atributos, com a aptidão, chega a 95% da força da corrida (o olheiro diria Favorita ou Disputada) e a energia está em 50 ou mais. Entre as possíveis, escolhe a que dá mais fama.
- **Escolhas de história:** sorteia 50/50, para medir os dois caminhos.
- **Instrução pré-corrida:** sempre Normal.
- **Amuletos:** pega o primeiro oferecido (como hoje).
- **Conta madura:** soma o bônus de vínculo 3 e de uma madrinha de nota ~700 (com o teto de §2.1) e roda as inspirações dos turnos 25 e 49.

### 6.4 O que medir

**20 carreiras** com conta nova e 20 com conta madura para cada uma das 48 garotas (1.920 carreiras, uns 15 minutos em 4 núcleos). Com 20 carreiras, a taxa de uma garota sozinha varia uns ±11 pontos só por sorte, então a regra dos 10 pontos é conferida **por casa e por arquétipo** (60 a 120 carreiras cada).

Comando: `Godot --headless --path . --script res://testes/balanco.gd -- 20 <garota|mvp|modelo|todas> <nova|madura> [saida.json]`.

| Medida | Por quê |
|---|---|
| % que passa de cada objetivo | Taxa final (35%/55%) e o teto de 25% por objetivo |
| Queda condicional por objetivo | Acha o objetivo que vira muro |
| Média dos atributos nos turnos 13, 24, 36, 48, 60 e 72 | Compara com a curva alvo (calendário §2.1) |
| Fama nos turnos 32 e 40 | Confere se dá para entrar em Prata e Ouro a tempo |
| Corridas por carreira | Alvo de 14 a 20 (calendário §7.1) |
| Divisão no ponto de virada | Alvo de 35% a 65% por caminho |
| Taxa por caminho depois da virada | Os dois caminhos devem ter dificuldade parecida (até 10 pontos) |
| Vitórias no GP final | Ritmo de liberar a Magnitude |
| Taxa por arquétipo e por casa | Acha arquétipo ou casa fora da curva |

### 6.5 Ordem de ajuste

Mexer sempre na ordem abaixo, um botão por vez, e rodar de novo:

1. **Ganho de treino**, até a curva de atributos bater com o calendário §2.1.
2. **Força das NPCs por categoria**, até a taxa geral chegar perto de 35% (conta nova).
3. **Teto e valor dos bônus de conta** (§2.1), até a conta madura chegar perto de 55%.
4. **Fama por corrida** e fama para entrar, se o bot não alcança Prata ou Ouro a tempo.
5. **Meta de objetivos específicos**, só para uma garota ou arquétipo fora da faixa de 10 pontos.
6. **Regras de virada** (os números de fama, vitórias e saídas), até a divisão ficar entre 35% e 65%.

### 6.6 Pronto quando

- Taxa geral entre **30% e 40%** (conta nova) e entre **50% e 60%** (conta madura).
- Todas as casas e todos os arquétipos a **até 10 pontos** um do outro (com 20 carreiras por garota, a taxa de uma garota sozinha é ruidosa demais).
- Nenhum objetivo derruba **mais de 25%** de quem chega nele.
- Todos os pontos de virada entre **35% e 65%**.
- Os resultados ficam registrados na §7 deste documento, com a semente e o número de carreiras.

## 7. Resultados

Rodada de 2026-11-18 (v0.4), depois dos ajustes de casa, arquétipo, virada e Coroa Dupla (§7.4): **40 carreiras por garota na conta nova** (sementes 1 a 40, 1.920 carreiras) e **20 na conta madura** (sementes 1 a 20, 960 carreiras), as 48 garotas. O bot é o mesmo da v0.3 (olheiro e instrução sugerida), com uma correção: a escolha de história agora sorteia por garota (§7.4). Resumo com `python tools/resumo_balanco.py saida_*.json`.

A rodada anterior (v0.3, 20 carreiras) deu 32,8% na conta nova e 55,4% na madura, com 16 pontos entre casas e 19 entre arquétipos.

### 7.1 Conta nova

| Objetivo | 1 (t13) | 2 (t20) | 3 (t24) | 4 (t32) | 5 (t40) | 6 (t48) | 7 (t60) | 8 (t72) |
|---|---|---|---|---|---|---|---|---|
| Passa | 94% | 85% | 66% | 57% | 51% | 46% | 40% | **35%** |
| Queda de quem chega | 6% | 10% | 22% | 14% | 11% | 10% | 12% | 13% |

- **Carreiras completas: 34,9%** (alvo ~35%, faixa de 30% a 40%). Nenhum objetivo derruba mais de 22% de quem chega nele (teto 25%).
- **Por casa:** de 27,9% (Longa Terra) a 39,6% (Média Terra). **Diferença de 11,7 pontos** (era 16). Com 240 carreiras por casa, a sorte sozinha já explica uns ±3 pontos em cada casa.
- **Por arquétipo:** de 28,3% (Durona) a 39,4% (Estrela). **Diferença de 11 pontos** (era 19). Com 120 a 160 carreiras por arquétipo, a sorte explica uns ±4 pontos em cada um, então a diferença que sobra está perto do que o sorteio permite medir.
- **Curva de atributos:** 209 / 311 / 414 / 547 / 674 / 804 nos turnos 13, 24, 36, 48, 60 e 72 (alvo 200 / 330 / 460 / 590 / 700 / 800).
- **16,4 corridas** por carreira (alvo 14 a 20). Fama média de 1.700 no turno 32 e 2.840 no turno 40.
- **GP final vencido** em 31% das carreiras. Depois da virada, o caminho A completa 76% e o B 77%.
- **Olheiro:** 66% Favorita, 33% Disputada e 1% Azarão nas corridas do bot. **Instrução sugerida:** Forçar 43%, Poupar 41%, Normal 16%.
- **Títulos:** 28% das carreiras fecham pelo menos 1 Coroa Dupla (0,39 por carreira; era 0,42), 17% a Volta ao Céu e 10% uma Tríplice. Veja a §7.6.

**A semente pesa mais do que parecia.** As garotas de uma mesma semente correm com o mesmo clima e o mesmo pelotão sorteado. Nas sementes 1 a 20 o GP do ano 1 (objetivo 3) derruba 14% de quem chega; nas sementes 21 a 40, 29%. Por isso esta rodada usa 40 sementes: com 20, a taxa de cada casa e de cada arquétipo varia junto, e as diferenças pareciam maiores (ou menores) do que são.

**Onde ainda há muro, olhando por casa e por arquétipo** (queda de quem chega, acima de 25%):
- **GP do ano 1 na Sprint:** derruba 35% na Sprint Grama e 30% na Sprint Terra (as outras casas, de 12% a 23%). A corrida curta tem mais sorte e o top 5 de 12 fica apertado.
- **Objetivo 4 da Sonhadora e da Teimosa** (Prata à frente da rival): 37% e 30%. As duas são só de Fechadoras, que vencem a rival com folga quando ela corre sem os +15%. Com a rival mais leve elas iam a 53%; com a rival normal ficam em 37% e 38% no total, dentro da faixa, mas com o muro no objetivo 4.

### 7.2 Conta madura

| Objetivo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Passa | 99% | 95% | 89% | 83% | 77% | 73% | 65% | **60%** |
| Queda de quem chega | 1% | 4% | 6% | 8% | 7% | 5% | 11% | 9% |

- **Carreiras completas: 59,6%** (alvo ~55%, faixa de 50% a 60%), com a madrinha de nota ~700, vínculo 3 e o teto de +25 por atributo. Subiu junto com a conta nova (era 55,4%).
- Por casa, de 53,6% a 66,7%. Curva 233 / 338 / 443 / 579 / 709 / 856, 23,5 corridas por carreira e GP final vencido em 52%.
- Títulos: 46% das carreiras fecham uma Coroa Dupla, 33% a Volta ao Céu e 23% uma Tríplice.

### 7.3 Ponto de virada (conta nova)

| Divisão no caminho A | Campanhas |
|---|---|
| 35% a 65% (dentro da meta) | Todas as 12 de arquétipo e 5 das 6 do MVP: Perfeccionista 38%, Estrela 41%, Misteriosa 41%, Teimosa 44%, Estrategista 47%, Leal 49%, Curiosa 49%, Nashira 50%, Shaula 50%, Festeira 52%, Capitã 52%, Antares 54%, Sonhadora 55%, Capela 56%, Mira 56%, Durona 58%, Competitiva 62% |
| Fora | Lira (69%), mas com só 13 carreiras chegando no turno 48 |

- **Durona** (era 76%): o bot nunca se lesiona, porque descansa antes de a energia ficar baixa, então "sem lesão" não pesava e a regra virava "venceu o GP do ano 2" (77% de quem chega). Agora pede também **top 3 no objetivo 4** (a Prata no outro piso), além de vencer o GP do ano 2 sem lesão desde o turno 25.
- **Curiosa**: "top 3 nas 4 distâncias" oscilava de 15% a 48% entre rodadas. Agora é **correr nas 4 distâncias e ficar top 3 em pelo menos 3**, que fica perto de 50% nas três rodadas.
- **Leal** e **Misteriosa** (eram 31% e 30%) voltaram para a faixa só com a correção do bot: antes, todas as garotas da carreira *i* faziam a mesma escolha no mesmo turno, e a virada por escolha media só 20 sorteios.
- Na conta madura, Competitiva (67%), Perfeccionista (70%) e Leal (70%) passam um pouco do limite. A meta vale para a conta nova; quem tem a conta madura vence mais e vai mais para o caminho de quem vence.

### 7.4 O que mudou nesta rodada

1. **A rival corre sempre com aptidão Ótima** (§4.3). As 4 casas com campeã da casa completavam em média 29%, e as 4 com rival com nome, 37%: Polaris na Longa e Algol na Milha têm aptidão Boa, mais fracas que qualquer campeã. Só isso levou a diferença entre casas de 16 para 7,5 pontos na primeira rodada com 20 sementes.
2. **Primeira Prata com a rival sem os +15%** para Competitiva, Estrategista e Leal. Esse objetivo derrubava de 33% a 42% delas. A Sonhadora e a Teimosa testaram a mesma mudança, foram a 53% e voltaram para a rival normal.
3. **Ponteira de Longa sai da exceção** da Estreia com top 3 (§4.2): derrubava 29% delas na Estreia.
4. **Viradas da Durona e da Curiosa** (§7.3), escolhidas com as posições e os contadores que o bot agora guarda no turno 48.
5. **Coroa Dupla no mesmo ano** (calendário §7.4).
6. **Bot:** a escolha de história sorteia por garota e por carreira; o bot guarda as posições nos objetivos e quantas carreiras fecham cada título; a variável de ambiente `SEMENTE0` desloca as sementes (para rodar as sementes 21 a 40 em separado).

### 7.5 O que mudou para chegar aqui

| Botão | Antes (48 turnos) | Agora |
|---|---|---|
| Ganho do treino principal / secundário | 75 / 28 | 39 / 14 |
| Retorno decrescente | 1,15 − 0,45 × atributo/limite | Sem queda (1,0) |
| Bônus por nível de treino | +10% por nível | +30% por nível |
| Atributos por corrida | — | +5 a +15 em cada atributo (calendário §7.1) |
| Força das NPCs | Fixa por categoria | Por categoria e por ano, × distância (calendário §2) |
| Vínculo por nível | +8 | +4 |
| Madrinha | +5%, teto 40 | +3%, teto 20; com o vínculo, teto 25 |
| Força das NPCs (v0.3) | Estreia 170, Aberta 215/300/380, Prata 315/420, Ouro 380/455, GP 290/405/620 | Estreia 191, Aberta 241/321/407, Prata 337/449, Ouro 407/487, GP 320/421/663 (calendário §2) |
| Multiplicador da Sprint (v0.3) | ×0,95 | ×0,99 |
| Rival da campanha (v0.4) | Aptidão própria (Polaris e Algol Boa em 2 casas) | Sempre Ótima na corrida (`aptidao_rival`) |
| Rival no objetivo 4 de Competitiva, Estrategista e Leal (v0.4) | +15% | Sem bônus (`forca_rival: 1.0`) |
| Estreia da Ponteira de Longa (v0.4) | Top 3 | Top 5 |
| Coroa Dupla (v0.4) | Ouros da distância nos 2 pisos | Nos 2 pisos **no mesmo ano** |

O ganho do treino caiu porque o semestre de base sozinho levava a garota a ~320 na Estreia. O bônus por nível e os atributos por corrida devolvem o crescimento nos anos 2 e 3, quando ela corre mais e treina menos.

### 7.6 Próximos passos

- **Coroa Dupla:** pedir as 2 Ouros no mesmo ano tirou pouco (0,42 → 0,39 por carreira). A causa é o ano 3: a Ouro tem força 487 e a garota do bot está perto de 674 no turno 60, então ela é Favorita em quase toda Ouro do ano 3 e fecha a Coroa sem planejar. Para a Coroa pedir rota de verdade, o calendário fixo do ano 3 precisa ficar mais forte (por exemplo ×1,2 nas corridas fixas do ano 3), o que também mexe na Tríplice, na Volta ao Céu e na fama do ano 3. Fica para uma rodada própria.
- **GP do ano 1 na Sprint** (queda de 30% a 35%): testar top 5 com a força do GP da Sprint um pouco menor, ou deixar a Sprint mais forte no começo.
- **Objetivo 4 da Sonhadora e da Teimosa**: testar a rival com +8%, no meio do caminho.
- Testar com jogadores de verdade: o bot não planeja rota nem usa o calendário fixo de propósito.
- Mostrar o encontro de inspiração da madrinha (hoje o bônus dos turnos 25 e 49 acontece em silêncio).

## 8. Decisões pequenas tomadas aqui

- **Objetivo dá entrada:** a corrida de um objetivo é por convite, mesmo sem a fama da categoria. Sem isso, uma carreira poderia acabar por falta de fama num objetivo que a garota venceria. A fama continua limitando as **opcionais**. (O calendário §3.2 dizia que os objetivos 4 e 5 "pressupõem fama".)
- **Campeã da casa** vira uma garota do elenco (§4.3).
- **Fechadoras de Longa** correm o ano 1 na Média (§4.2), como a Mira e a Shaula.
- **Correr dá atributos** (calendário §7.1) e o **pelotão fica mais forte a cada ano** (calendário §2). As duas mudanças saíram do balanceamento (§7.5).
- A **Lira** corre o objetivo 4 na Milha, com a Polaris de visitante, em vez de ir à Média. O antigo derrubava 2 de cada 3 carreiras dela.
- Os nomes de capítulos e finais são provisórios.
