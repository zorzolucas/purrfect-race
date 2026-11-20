# Nekomusume — Fórmula da Corrida

> Versão 0.6 — 2026-11-20 (fôlego do pelotão e correção de estilo por nível). Complementa o [GDD](GDD.md) §5.
> Todos os números são **(inicial)**, calibrados com [`tools/sim_corrida.py`](../tools/sim_corrida.py) e [`tools/ajustar_ritmo.py`](../tools/ajustar_ritmo.py).

## 1. Modelo

A corrida é uma simulação em **passos fixos de 0,1 s**. A cada passo, cada corredora:

1. descobre em que **fase** está (e tenta disparar as habilidades daquela fase);
2. calcula sua **velocidade-alvo**;
3. **acelera ou desacelera** em direção a ela;
4. **gasta fôlego**;
5. **anda** `v × 0,1` metros.

Ganha quem cruzar a distância `D` primeiro. Não há faixas no MVP: a pista é uma linha, e a ordem é a distância percorrida.

A simulação não depende da tela, então roda headless para testes e balanceamento (GDD §10).

## 2. Atributos efetivos

Antes da largada, cada atributo vira um valor **efetivo**:

```
efetivo = atributo × peso_estilo × aptidão_distância × aptidão_piso × humor × correção_estilo
```

- **peso_estilo**: tabela §3.1.
- **correção_estilo**: multiplicador do estilo pelo nível médio do pelotão e pela distância (§8.5). Fica entre 0,93 e 1,05.
- **aptidão**: Ruim 0,90 · Ok 0,95 · Boa 1,00 · Ótima 1,05 (GDD §3.3).
- **humor**: Péssimo 0,95 · Mal 0,975 · Normal 1,00 · Bem 1,025 · Ótimo 1,05. Na v0.1 era ±8%, o que pesava mais que a aptidão (§8.3).
- Se a garota correr no **estilo secundário**, tudo recebe ×0,95.

No resto deste documento, `Vel`, `Est`, `Pod`, `Det` e `Int` são sempre valores **efetivos**.

## 3. Estilo

### 3.1 Pesos dos atributos

| Estilo | Vel | Est | Pod | Det | Int |
|---|---|---|---|---|---|
| Ponteira | 1.00 | 1.00 | 0.95 | 0.95 | 1.10 |
| Perseguidora | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| Arrancadora | 1.00 | 1.00 | 1.10 | 1.00 | 0.90 |
| Fechadora | 1.00 | 1.00 | 1.05 | 1.10 | 0.85 |

**Velocidade e Estamina valem o mesmo para todos.** Na v0.1, a diferença de peso nesses dois atributos dava uma vantagem que **crescia com o nível**: com atributos em 1000, a Ponteira vencia 69%. Agora o estilo só muda os atributos "de personalidade":

- **Ponteira**: Inteligência, para dosar o ritmo na frente.
- **Arrancadora**: Poder, para sair do pelotão.
- **Fechadora**: Determinação, para o sprint.

### 3.2 Ritmo por fase

Multiplicador da velocidade-alvo:

| Estilo | Largada | Meio | Final | Sprint |
|---|---|---|---|---|
| Ponteira | 0.9943 | 0.9694 | 0.9843 | 0.9893 |
| Perseguidora | 0.9877 | 0.9678 | 0.9927 | 0.9977 |
| Arrancadora | 0.9710 | 0.9659 | 1.0060 | 1.0110 |
| Fechadora | 0.9568 | 0.9669 | 1.0122 | 1.0525 |

Os valores foram ajustados automaticamente (§9). O balanço é **muito sensível**: 1% de ritmo muda a taxa de vitória em ~30 pontos. Por isso as 4 casas decimais. Não arredonde.

## 4. Fases

| Fase | Trecho |
|---|---|
| Largada | 0 → D/6 |
| Meio | D/6 → 0,6·D |
| Final | 0,6·D → D − 400 m |
| Sprint | últimos 400 m |

Distâncias de referência: Sprint 1200 m · Milha 1600 m · Média 2000–2400 m · Longa 3000 m ou mais.

## 5. Velocidade

```
E  = 0,66                 escala de unidades (ver abaixo)
V0 = 20 × E = 13,2 m/s

alvo = (20 + 1,2 × Vel/1000) × E × ritmo_fase × (1 + sorte)

Final:   alvo += E × (2,0 × Det + 1,5 × Int) / 1000
Sprint:  alvo += bônus × min(1, fôlego / fôlego_necessário)
         bônus = E × (7,0 × Det/1000 + 3,0 × fôlego/fôlego_máx)

sem fôlego (≤ 0):  alvo = V0 × (0,80 + 0,15 × Det/1000)
habilidade ativa:  alvo += valor da habilidade × E

teto:  alvo = min(alvo, teto)
       teto = 60 + 5 × min(Vel, 1200)/1200   km/h  (÷ 3,6 para m/s)
```

- **Teto de velocidade (v0.5):** cada garota tem velocidade máxima entre **60 km/h** (Vel 0) e **65 km/h** (Vel 1200), aplicada depois de habilidades e bloqueio. É a "velocidade máxima" do atributo Velocidade (GDD §3).
- **Escala E:** antes da v0.5, os picos iam de 88 a 107 km/h. `E` multiplica todas as velocidades, as acelerações por E², as durações (habilidades, bloqueio) por 1/E e o gasto de fôlego por segundo por E. Sem o teto, a corrida seria exatamente a mesma, só mais lenta. Com E = 0,66, os picos ficam em **~58–63 km/h** e o teto corta o topo do sprint. Tempo da vencedora: ~86 s em 1200 m e ~228 s em 3200 m.

- **sorte**: sorteada uma vez por corrida, normal com σ = 2,5% × (1 − Int/2400). É o principal controle de "estratégico × caótico".
- **Final:** é a última curva. A Determinação dá a briga e a Inteligência a escolha de faixa.
- **Sprint dosado (novo):** a corredora calcula quanto fôlego precisa para chegar no bônus total e **só acelera o quanto aguenta**. Na v0.1, quem acelerava demais morria antes da linha, e a Estamina virava tudo ou nada.
- **Fôlego guardado vira sprint:** quanto mais sobrar, maior o bônus.

### 5.1 Aceleração

```
acel = 0,35 × E² × (0,8 + Pod/1000)    m/s²
na Largada: acel × 5                   (sai de 3 × E m/s)
desaceleração: 0,8 × E² m/s²
```

### 5.2 Bloqueio

Se, no Meio ou depois, houver alguém **menos de 2 m à frente** e mais lento, a cada passo há esta chance de ficar presa por 1/E s (~1,5 s), com a velocidade limitada à de quem está na frente:

```
chance = E × 1,5% × (1 − Pod/1500) × (1 − Int/2000)
```

## 6. Fôlego

```
fôlego_máx = 0,6 × D + 1,5 × max(Est − desconto, 0)
desconto   = max(0, nível do pelotão − 350)      ← nível = média dos atributos de todas

gasto por segundo = 20 × E × (v / V0)²
  no Meio:   × (1,2 − Int/1500)      ← ritmo bem dosado
  no Sprint: × (1,1 − Det/2000)
```

**Fôlego do pelotão (v0.6):** um pelotão forte corre num ritmo que cansa mais. Acima do nível 350, cada ponto que a média do pelotão sobe tira 1 ponto da Estamina que conta no fôlego de todas. Uma garota com a Estamina igual à média do pelotão tem o mesmo fôlego em qualquer nível, e quem tem Estamina acima das outras leva a vantagem de antes.

Antes disso, a partir do nível ~550 o fôlego nunca acabava: com atributos em 800, +10% de Estamina não mudava nenhuma colocação, nem em 3200 m, e a Velocidade valia mais que tudo ([endgame](endgame.md) §5.2). Agora a Estamina decide as corridas longas em todo nível e a Velocidade e o Poder decidem as curtas (§8.6).

Os números ficam em `SimCorrida.FOLEGO_PELOTAO` (`nivel` 350, `fracao` 1,0).

## 7. Habilidades

Cada habilidade tem **condição**, **efeito** (+alvo, +fôlego, −gasto, −alvo de outra), **valor** e **duração**.

**Chance de disparar**, sorteada uma vez quando a condição é cumprida:

```
genérica: Int / 1000          (máx. 0,90)
única:    genérica + 0,20     (máx. 0,95)
```

O simulador dá a todas as corredoras 5 habilidades genéricas de referência:

| Fase | Efeito |
|---|---|
| Meio | +6% fôlego |
| Meio | +0,8 × E m/s (~1,9 km/h) por 4/E s (~6 s) |
| Final | +0,8 × E m/s por 4/E s |
| Final | +4% fôlego |
| Sprint | +1,0 × E m/s (~2,4 km/h) por 4/E s |

**Esta é a escala de referência das habilidades do jogo.** Habilidades únicas podem ser ~1,5× mais fortes.

## 8. Resultados (v0.5)

As tabelas abaixo vêm de `python tools/sim_corrida.py 400`. Com 400 corridas, cada número oscila uns ±3 pontos.

**v0.5, teto de velocidade:** o teto corta o bônus de sprint, então a **Determinação vale menos nas distâncias curtas** (+200 de Det em 1200 m: de 16% para 10%). O ritmo (§3.2) foi recalibrado com o `ajustar_ritmo`, e o perfil das Fechadoras trocou Det por Vel (§8.4).

**v0.3, corrida mais estratégica:** a sorte por corrida subiu de σ 1,5% para **2,5%**, e a aptidão Ruim foi de ×0,85 para **×0,90**. Antes, ~5% de vantagem dava 74% de vitória e o resto ficava em 0%. Agora a favorita clara vence ~45% e as outras boas ~20–25%.

### 8.1 Vitórias por estilo

12 corredoras (3 de cada estilo), todos os atributos iguais. O ideal é 25%.

| Nível | 1200 | 1600 | 2000 | 3200 |
|---|---|---|---|---|
| **400** | 18 / 22 / 23 / 37 | 23 / 21 / 23 / 33 | 35 / 26 / 15 / 24 | 38 / 27 / 20 / 16 |
| **700** | 27 / 27 / 25 / 22 | 25 / 23 / 26 / 26 | 25 / 24 / 26 / 25 | 23 / 26 / 25 / 25 |
| **1000** | 25 / 24 / 28 / 22 | 25 / 24 / 27 / 24 | 24 / 24 / 27 / 26 | 23 / 24 / 25 / 28 |

*Ordem dentro de cada célula: Ponteira / Perseguidora / Arrancadora / Fechadora (%).*

- Nos níveis 700 e 1000, todos os estilos ficam entre **22% e 28%** (v0.4: 20–32%).
- No nível 400 ainda há desvios: a Fechadora é forte em 1200–1600 m (33–37%) e a Ponteira, na Longa (38%).

### 8.2 Quanto vale +200 num atributo

1 garota com 800 contra 11 com 600. Sem efeito nenhum, seriam ~8%.

| Distância | Vel | Est | Pod | Det | Int |
|---|---|---|---|---|---|
| 1200 | 25% | 10% | 26% | 10% | 8% |
| 2000 | 23% | 12% | 16% | 15% | 12% |
| 3200 | 22% | 22% | 16% | 19% | 26% |

Cada atributo continua tendo uma distância onde vale mais. Com o teto, a Determinação perdeu valor na Sprint e na Média.

### 8.3 Aptidão e humor

1 garota com o multiplicador indicado contra 11 normais, em 2000 m. Normal seria ~8%.

| Multiplicador | Equivale a | Vitórias |
|---|---|---|
| ×0,85 | Ruim × piso Ok | 2% |
| ×0,95 | aptidão Ok / humor Péssimo | 7% |
| ×0,975 | humor Mal | 9% |
| ×1,025 | humor Bem | 12% |
| ×1,05 | aptidão Ótima / humor Ótimo | 13% |

### 8.4 Especialistas por combinação

Cada combinação de distância × piso tem 6 especialistas (todas **Ótima** ali; ver [elenco](elenco.md#elenco-completo-48)). As 6 correm juntas com o perfil de cada uma escalado para média 600, em 800 corridas. O ideal é **~17% cada** (1 em 6).

| Casa | Garotas (estilo) e vitórias |
|---|---|
| Sprint Grama | Altair (Pon) 17% · Spica (Per) 17% · Adara (Arr) 16% · Alcione (Fec) 13% · Electra (Pon) 19% · Maia (Arr) 18% |
| Sprint Terra | **Antares** (Pon) 21% · Mérope (Per) 16% · Celeno (Arr) 17% · Bellatrix (Fec) 15% · Mintaka (Pon) 16% · Andrômeda (Arr) 14% |
| Milha Grama | **Lira** (Pon) 16% · **Capela** (Arr) 19% · Cassiopeia (Per) 16% · Carina (Fec) 17% · Vela (Per) 16% · Auriga (Arr) 15% |
| Milha Terra | Columba (Pon) 16% · Fênix (Per) 17% · Hidra (Arr) 18% · Tucana (Fec) 16% · Corona (Per) 18% · Zaniah (Arr) 15% |
| Média Grama | **Nashira** (Per) 19% · Alya (Pon) 16% · Alhena (Arr) 13% · Mizar (Fec) 18% · Alcor (Per) 15% · Dubhe (Fec) 19% |
| Média Terra | Deneb (Pon) 18% · Albireo (Per) 18% · Achernar (Arr) 15% · Mimosa (Fec) 17% · Hamal (Per) 14% · Mirach (Fec) 18% |
| Longa Grama | **Mira** (Fec) 18% · Almach (Pon) 15% · Nunki (Per) 20% · Ankaa (Arr) 16% · Zosma (Fec) 18% · Elnath (Pon) 14% |
| Longa Terra | **Shaula** (Fec) 17% · Saiph (Pon) 15% · Naos (Per) 17% · Avior (Arr) 16% · Atria (Fec) 20% · Alnair (Pon) 15% |

*Em negrito: as 6 do MVP. Com 800 corridas, cada número oscila ~±1,5 ponto.*

**Faixa geral: 13% a 21%** (v0.4: 14–19%).

**Ajustes da v0.5 (teto de velocidade):** sem mexer nos perfis, as Fechadoras caíam para 10–14%, porque o teto corta o bônus de sprint, que vem da Det. O modelo de perfil da Fechadora passou de `vel −5, det +10` para `vel +5, det 0`, e a Determinação dela agora vem só do peso de estilo (×1,10). **Antares** (MVP) estava em 23% e passou para (107, 78, 106, 86, 73). O ajuste manual da **Mintaka** caiu pela metade.

**Ajustes da v0.4:**
- **Modelos de perfil por estilo** (gerador): a Arrancadora perdeu o Poder extra, porque ele somava com o peso de estilo (Pod ×1,10) e ela ficava acima. A Perseguidora ganhou um pouco de Velocidade e Determinação no lugar de Inteligência. Isso corrigiu a tendência da v0.4 (Perseguidora 13–16%, Arrancadora 17–21%). **O ritmo dos estilos (§3.2) não mudou**, porque com atributos iguais eles já estavam em 25% (§8.1). O problema estava nos perfis.
- A variação aleatória dos perfis caiu de ±6 para ±4 por atributo.
- **Ajustes manuais** (`AJUSTES` no gerador): Mintaka, Electra, Corona, Hidra e Tucana. Quase sempre eram pontos em atributos que não servem na distância da casa.
- **Capela** e **Antares** (MVP) estavam fortes e perderam ~4 pontos de Poder/Velocidade, redistribuídos.

**O que sobrou:** as Fechadoras de Sprint ainda estão um pouco baixas (13–15%) e a Antares, um pouco alta (21%). As outras diferenças são do tamanho da oscilação do teste somada à personalidade de cada perfil.

### 8.5 Correção de estilo por nível (v0.6)

O ritmo (§3.2) foi calibrado nos níveis 500 a 1000, mas a carreira passa os 2 primeiros anos entre 200 e 600. Ali os estilos se desviavam bastante (12 corredoras, 3 de cada estilo, atributos iguais, vitória em %):

| Nível | 1200 | 1600 | 2400 | 3200 |
|---|---|---|---|---|
| **350** | 17 / 21 / 20 / **42** | 27 / 22 / 20 / 31 | 30 / 30 / 21 / 19 | **37** / 29 / 19 / 16 |
| **450** | 20 / 24 / 23 / 33 | 15 / 20 / 25 / **41** | **37** / 28 / 18 / 17 | **40** / 28 / 16 / 17 |

*Ponteira / Perseguidora / Arrancadora / Fechadora. Ideal 25%.*

Na Sprint e na Milha, o teto de velocidade quase não corta o sprint da Fechadora em nível baixo. Na Média e na Longa, todas ficam sem fôlego e quem está na frente segura. Era o "Fechadora forte na Sprint, Ponteira forte na Longa" do calendário §11.

A correção é um multiplicador nos atributos de cada estilo, numa grade de **9 níveis** (200 a 1000) × **5 distâncias** (1200, 1600, 2000, 2400 e 3200 m), interpolada entre os pontos: `SimCorrida.CORRECAO_ESTILO`. `testes/ajustar_estilo.gd` ajusta cada célula até a média entre a vitória e o top 3 de cada estilo ficar em 25% (12 iterações com sementes novas e passo decrescente, média das últimas). Na conferência, com 400 corridas de sementes que o ajuste não viu, as 45 células ficam entre **21% e 29%** (±2,5 de sorte). Fora da grade (`testes/estilos_nivel.gd`, níveis 250, 375, 525 e 700) fica entre 16% e 34% na vitória e 21% e 31% no top 3.

**Na carreira, o perfil de treino pesa mais que a correção.** `testes/estilo_jogadora.gd` põe a jogadora contra 11 garotas do elenco com o mesmo pelotão e a mesma sorte para os 4 estilos (top 3 em %, média dos níveis 300 e 550 e das 5 distâncias):

| Perfil da jogadora | Ponteira | Perseguidora | Arrancadora | Fechadora |
|---|---|---|---|---|
| Todos os atributos iguais | 31 | 31 | 30 | 30 |
| O do bot (Vel 1,2, Est 1,0 ou 1,3, Pod 0,9, Det 0,8, Int 0,7) | 40 | 42 | 42 | **47** |
| O do bot × os pesos do estilo (§3.1) | 43 | 42 | 39 | 43 |

Com o treino igual para todos, a Fechadora sobra, porque o sprint dela converte melhor a Estamina que sobra e ela usa pouco a Inteligência que fica para trás. Treinando o que o estilo usa (a Ponteira puxa Inteligência), os 4 empatam. O bot de balanceamento passou a treinar assim ([campanhas](campanhas.md) §6.3).

**Extra da carreira (`SimCorrida.EXTRA_ESTILO`):** por cima da grade, a Perseguidora corre com **×1,02**. A grade empata os estilos num pelotão de atributos iguais, mas na carreira, contra o pelotão do elenco, as 12 Perseguidoras completavam 32,2% das carreiras, de 3 a 6 pontos abaixo dos outros estilos, e puxavam para baixo a Estrategista e a Leal. Com o extra, foram a 36,6% ([campanhas](campanhas.md) §7.4). Numa corrida com atributos iguais, isso dá à Perseguidora uns 3 pontos a mais de vitória. O `ajustar_estilo.gd` zera o extra antes de calibrar, para a grade continuar sendo só a do pelotão de atributos iguais.

### 8.6 Quanto vale +10% em cada atributo (v0.6)

`testes/valor_atributo.gd`: 12 corredoras com atributos iguais (3 de cada estilo), uma delas com +10% num atributo, mesma semente nas variantes. Posições ganhas na média (40 corridas × 4 estilos por célula):

| Nível | Distância | Vel | Est | Pod | Det | Int |
|---|---|---|---|---|---|---|
| 550 | 1200 | +0,62 | +0,12 | **+0,68** | +0,38 | +0,06 |
| 550 | 1600 | +0,38 | **+0,48** | +0,34 | +0,44 | +0,24 |
| 550 | 2000 | +0,81 | **+1,86** | +0,58 | +0,67 | +0,96 |
| 550 | 2400 | +0,19 | **+2,06** | +0,38 | +0,39 | +1,14 |
| 550 | 3200 | +0,42 | **+1,21** | −0,05 | +0,41 | +0,92 |
| 800 | 1200 | **+0,97** | +0,00 | +0,77 | +0,00 | +0,02 |
| 800 | 1600 | **+0,92** | +0,01 | +0,43 | +0,21 | +0,18 |
| 800 | 2000 | **+0,77** | +0,14 | +0,16 | +0,32 | +0,36 |
| 800 | 2400 | +0,81 | **+1,28** | +0,66 | +0,57 | +1,14 |
| 800 | 3200 | +0,50 | **+2,43** | +0,01 | +0,60 | +1,94 |

Na média das 5 distâncias, no nível 800: Vel +0,79, **Est +0,77**, Int +0,73, Pod +0,40, Det +0,34. Antes do fôlego do pelotão era Vel +0,79, **Est 0,00**, Pod +0,39, Int +0,20, Det +0,19. No nível 550 a Estamina ia de +0,07 para +1,15.

- **Sprint e Milha:** Velocidade e Poder. **Média:** Velocidade e Estamina. **Longa:** Estamina e Inteligência.
- A Determinação é a que menos vale sozinha: ela pesa no sprint, que o teto de velocidade corta. É o atributo da Fechadora (peso ×1,10).
- No nível 300 o fôlego já acabava antes da mudança, e nada mudou ali: a Estamina já era o melhor atributo de 1600 m para cima.

## 9. Como recalibrar

```bash
python tools/sim_corrida.py
```

Imprime as quatro tabelas da §8 (~2 min). Também aceita o número de corridas por teste e quais testes rodar. Por exemplo, `python tools/sim_corrida.py 800 D` roda só o teste das especialistas.

```bash
python tools/gerar_elenco.py
```

Regera `data/garotas.json` a partir dos modelos e imprime a tabela do elenco completo. Rode antes do teste D sempre que mudar uma garota.

```bash
python tools/ajustar_ritmo.py
```

Ajusta automaticamente a tabela de ritmo (§3.2) para que cada estilo vença ~25% na média dos níveis 500 e 800, e imprime a tabela nova para colar em `sim_corrida.py`. Rode depois de mudar qualquer outra constante.

Depois de mudar o ritmo, o fôlego ou os pesos, recalibre a correção de estilo (§8.5) e confira:

```bash
Godot --headless --path . --script res://testes/ajustar_estilo.gd -- 12 200 0/4   # 4 processos: 0/4 a 3/4
Godot --headless --path . --script res://testes/estilos_nivel.gd -- 300 250,375    # conferência fora da grade
Godot --headless --path . --script res://testes/valor_atributo.gd -- 40 550,800    # valor de cada atributo
Godot --headless --path . --script res://testes/estilo_jogadora.gd -- 200 estilo   # estilos na carreira
```

O `ajustar_estilo` imprime uma linha por célula; os valores vão para `CORRECAO_ESTILO` em `scripts/sim_corrida.gd`, `tools/sim_corrida.py` e `visualizador/sim.js`. O `EXTRA_ESTILO` fica de fora da calibração e só muda com o bot da carreira.

A versão em Godot deve usar **as mesmas fórmulas**. Este documento é a referência.

## 10. Fora do MVP

- Faixas na pista e posicionamento lateral.
- Curvas com efeitos próprios.
- Clima e estado da pista.
