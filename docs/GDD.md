# Galope Estelar — Game Design Document

> Nome provisório ("Galope" não combina mais com gatas; ver §1). Versão 0.3 — 2026-11-17.
> Na v0.3 as garotas viraram **garotas gato**, a arte passou a ser **3D low-poly** (§11) e entraram ideias das referências do gênero: legado (§3.6), afobação na corrida (§5.5) e o amuleto Sete Vidas.
> Na v0.2 entrou o [calendário da carreira](calendario.md), com mapa de rotas e amuletos.
> Valores marcados com **(inicial)** são pontos de partida para balanceamento, não decisões finais.

## 1. Visão geral

**Pitch:** simulador de treino e corrida de **garotas gato**. Você conhece as garotas, treina cada uma numa carreira de 2 anos e monta o melhor elenco para vencer copas de estilos diferentes, como os ginásios de um jogo de monstrinhos.

**Pilares**
1. **Relações importam.** Os encontros mexem no humor, e o humor mexe em treinos e corridas.
2. **Treino é dilema.** Cada turno troca energia e humor por atributos.
3. **A corrida é o resultado.** O jogador não controla a corrida, só assiste ao que construiu.
4. **Colecionar sem pagar.** Não há dinheiro real. A pool semanal usa só moeda do jogo.
5. **Cada carreira é diferente.** Entre os objetivos, o caminho é um mapa sorteado, e os amuletos mudam a build.

**Plataforma:** PC (Windows), single-player, offline.
**Motor:** Godot 4, GDScript.
**Idioma:** PT-BR, com os textos fora do código para tradução futura.

**Identidade:** universo, academia/liga, personagens, arte, UI e música são **originais**. Nenhuma personagem é baseada em animais reais famosos nem em personagens de outros jogos. Cada garota tem só o nome de uma **estrela ou constelação**, sem sobrenome (ex.: Lira, Shaula).

**Garotas gato:** são garotas com **orelhas e rabo de gato**, ágeis e curiosas. Cada uma tem uma **pelagem** (laranja rajada, frajola, preta, tricolor…) que define as cores do modelo 3D: cabelo, orelhas e rabo ([elenco](elenco.md)). A pelagem é a identidade visual dela, e os detalhes do visual contam algo da personalidade (lição das referências de design de personagem). O jeito felino aparece nos encontros e nas animações: cochilo no sol, curiosidade, caixas de papelão, orelhas que mostram o humor.

**Nome do jogo:** "Galope Estelar" foi pensado para cavalos. Fica como nome provisório até escolhermos outro (opções: *Patas Estelares*, *Corrida Estelar*, *Felinas Estelares*). O repositório continua `stelar-gallop`.

## 2. Loop principal

```
Pool semanal ──► Elenco ──► Carreira (48 turnos) ──► Garota treinada salva
     ▲                                                   │
     └──── moeda ◄──── Circuito (copas) ◄────────────────┘
```

1. Tirar garotas (ou cópias) na pool usando moeda.
2. Escolher uma garota do elenco e jogar uma carreira.
3. No fim, decidir se a nova versão **substitui** a salva ou se o resultado é **descartado**.
4. Escalar o elenco nas copas do circuito, ganhar moeda e repetir.
5. Cada carreira concluída gira a pool.

## 3. Garotas

### 3.1 Atributos

Escala de **0 a 1200**. O limite base é **1000**, e o vínculo 5 libera **1200**.
O jogador também vê uma **nota geral** (G, F, E, D, C, B, A, S) calculada a partir dos atributos.

| Atributo | Efeito na corrida |
|---|---|
| **Velocidade** | Velocidade máxima |
| **Estamina** | Tamanho da barra de fôlego |
| **Poder** | Aceleração e capacidade de abrir espaço no pelotão |
| **Determinação** | Resistência à queda de velocidade quando cansada e força no sprint final |
| **Inteligência** | Chance de disparar habilidades e qualidade das escolhas de posição/faixa |

### 3.2 Estilos de corrida

Cada garota tem **1 estilo principal** e no máximo **1 secundário** (mais fraco).

| Estilo | Comportamento |
|---|---|
| **Ponteira** | Lidera desde a largada e tenta segurar a ponta |
| **Perseguidora** | Corre logo atrás do grupo da frente |
| **Arrancadora** | Fica no meio do pelotão e acelera na reta |
| **Fechadora** | Larga no fundo e faz um sprint brutal no final |

**Peso dos atributos por estilo (inicial)** (multiplicadores na fórmula de desempenho):

| Estilo | Vel | Est | Pod | Det | Int |
|---|---|---|---|---|---|
| Ponteira | 1.00 | 1.00 | 0.95 | 0.95 | 1.10 |
| Perseguidora | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| Arrancadora | 1.00 | 1.00 | 1.10 | 1.00 | 0.90 |
| Fechadora | 1.00 | 1.00 | 1.05 | 1.10 | 0.85 |

Tabela recalibrada no simulador. O detalhe está em [corrida.md](corrida.md).

### 3.3 Aptidões

Cada garota tem uma aptidão por **distância** (Sprint, Milha, Média, Longa) e por **piso** (Grama, Terra).

| Nível | Multiplicador (inicial) |
|---|---|
| Ruim | 0.90 |
| Ok | 0.95 |
| Boa | 1.00 |
| Ótima | 1.05 |

### 3.4 Habilidades

- **1 habilidade única** por garota, que já vem com ela.
- **Habilidades genéricas** compradas na carreira com **pontos de habilidade**.
- Disparo **automático por condição**: fase da corrida, posição, curva/reta, distância das outras.
- A **Inteligência** aumenta a chance de disparo.
- Limite de **6 habilidades equipadas**.

### 3.5 Vínculo (cópias repetidas)

Cada cópia extra sobe o **nível de vínculo** da garota, até no máximo **5**. Cada nível dá:
- \+ limite máximo de atributos (de 1000 até 1200 no nível 5);
- \+ atributos iniciais na carreira;
- 1 habilidade nova desbloqueada.

Não há raridade nem estrelas de personagem: todas as garotas valem o mesmo.

### 3.6 Legado (madrinha)

Nas referências do gênero, o sistema que mais faz o jogador repetir carreiras é **passar parte de uma garota treinada para a próxima**. Aqui isso vira a **madrinha**:

- No começo da carreira, o jogador pode escolher **1 garota salva** do elenco como madrinha (não pode ser a própria garota).
- A madrinha dá **+5% dos atributos finais dela** como bônus inicial (inicial; teto de +40 por atributo).
- Nos turnos **13 e 37** acontece um encontro de **inspiração** com a madrinha: chance de ganhar atributos e de subir em 1 nível a aptidão de distância ou piso da casa da madrinha (inicial: 20% por aptidão).
- Quanto melhor a nota geral da madrinha (§3.1), maiores as chances.
- Isso dá uso às garotas salvas fora do circuito e soma com o vínculo e os amuletos liberados na progressão entre carreiras.
- **Fica para depois do MVP**, mas o save já deve guardar a nota e a casa de cada garota salva.

## 4. Carreira

### 4.1 Estrutura

- **48 turnos**: 2 anos de jogo, 1 turno = meio mês (Início e Fim de cada mês). O ano vai de março a fevereiro.
- **Férias de verão** em janeiro (turnos 21–22 e 45–46): acampamento sem corridas, com treino reforçado.
- Um **Grande Prêmio** no fim de cada ano (turnos 24 e 48).
- **5 objetivos**, nos mesmos turnos em toda carreira, quase sempre na casa da garota (melhor distância e piso). Os objetivos 2 e 4 são **sorteados** de uma lista de candidatos. Se falhar um, **a carreira acaba ali**, mas a garota ainda pode ser salva como estava.
- **Calendário roguelike:** entre um objetivo e outro, o jogador escolhe uma rota num **mapa sorteado**. Cada nó dura 1 mês e muda o contexto (treino focado, circuito de corridas, festival, recuperação, biblioteca, desafio, mistério). Corridas opcionais só aparecem nos nós de circuito.
- **Amuletos:** cada objetivo cumprido dá 1 amuleto (escolha entre 3), um modificador que vale até o fim da carreira. Não passam para a garota salva. Proposta nova: o amuleto raro **Sete Vidas**, que deixa refazer uma vez um objetivo falhado ([calendário](calendario.md) §5.2).
- **Clima do mês** (tempo bom, chuva, calor, frio, vento, noite de estrelas), seguindo as estações. Ele mexe no treino e, na chuva e no calor, na corrida.
- **Magnitude** (0 a 5): dificuldade por garota, liberada vencendo o Grande Prêmio final. Fica para depois do MVP.
- Uma **semente** por carreira guarda todos os sorteios: recarregar o save e repetir a ação dá o mesmo resultado.
- Corridas têm **categorias** (Estreia, Aberta, Prata, Ouro, Grande Prêmio). As mais altas pedem **fama** para entrar.
- O detalhe está no [calendário](calendario.md).

### 4.2 Ações por turno

| Ação | Efeito |
|---|---|
| **Treinar** | Escolhe um dos 5 treinos, ganha atributos e gasta energia |
| **Descansar** | Recupera energia |
| **Sair** | Recupera humor e pode gerar encontro |
| **Correr** | Corrida opcional (só em nós de circuito): dá moeda, pontos de habilidade e fama ([calendário](calendario.md) §7) |
| **Enfermaria** | Cura lesão (só aparece quando ela está lesionada) |

### 4.3 Treinos

- Cada treino sobe muito o atributo principal e um pouco 1 secundário:

| Treino | Principal | Secundário |
|---|---|---|
| Velocidade | Vel | Pod |
| Estamina | Est | Det |
| Poder | Pod | Est |
| Determinação | Det | Vel |
| Inteligência | Int | Vel |

- Repetir o mesmo treino sobe o **nível daquele treino** (1 a 5) dentro da carreira, e os ganhos aumentam.
- O treino de **Inteligência** gasta pouca ou nenhuma energia: é a opção "segura".
- Cada garota tem **2 treinos naturais** que rendem mais (inicial: +10% de ganho).
- Garotas com **afinidade alta** podem aparecer num treino e dar **bônus de dupla**.

### 4.4 Energia e falha

- Energia vai de **0 a 100**.
- Abaixo de um limite (inicial: 40), a chance de **falha** cresce conforme a energia cai.
- Uma falha faz perder atributo e humor, com chance de **lesão leve**.
- Correr gasta energia (inicial: 15).

### 4.5 Lesão

- Só acontece por falha de treino.
- Status negativo que corta o ganho de treino até **descansar** ou ir à **enfermaria** (1 turno).
- Nunca tira a garota da carreira de vez.

### 4.6 Humor

| Nível | Corrida (inicial) | Ganho de treino (inicial) |
|---|---|---|
| Péssimo | −5% | −20% |
| Mal | −2,5% | −10% |
| Normal | 0 | 0 |
| Bem | +2,5% | +10% |
| Ótimo | +5% | +20% |

O efeito na corrida foi reduzido de ±8% para ±5% depois dos testes ([corrida.md](corrida.md) §8.3).

Muda com encontros, descanso, saídas, vitórias, derrotas e falhas.

### 4.7 Encontros e afinidade

- Podem acontecer em qualquer turno (mais chance ao **Sair**).
- São um diálogo curto com outra garota do elenco ou com uma rival, com **2 ou 3 escolhas**. Cada escolha tem efeitos (humor, atributos, energia, habilidade).
- Repetir encontros sobe a **afinidade** entre o par. Afinidade alta libera o **treino em dupla**.
- A afinidade vai de **0 a 100**. Alguns pares começam com **afinidade inicial**: amizade (inicial: +20) ou atrito (inicial: −10). Esses pares estão definidos no [elenco](elenco.md).
- Isso substitui qualquer sistema de "cartas de suporte".
- No MVP: **encontros genéricos** (servem para qualquer par) + **2 ou 3 eventos únicos por garota**.

### 4.8 Fim da carreira

- Ela recebe **moeda** com bônus por desempenho.
- O jogador escolhe: **substituir** a versão salva da garota ou **descartar** o resultado.
- Fica **1 versão salva por garota**.
- A pool gira.

## 5. Corrida

### 5.1 Simulação

- O jogador só assiste. As habilidades disparam sozinhas.
- O resultado vem de atributos × pesos do estilo × aptidões × humor × habilidades × aleatoriedade.
- Até **12 corredoras** por corrida.

### 5.2 Fases

| Fase | Trecho | O que pesa mais |
|---|---|---|
| **Largada** | Início | Poder (posicionamento) e Inteligência |
| **Meio** | Corpo da corrida | Velocidade e gasto de fôlego (Estamina) |
| **Final** | Última curva | Poder (sair do pelotão) e Inteligência |
| **Sprint** | Últimos ~400 m | Velocidade, Determinação e fôlego restante |

Cada estilo tem uma **posição-alvo** e um **ritmo de gasto de fôlego** por fase. É isso que faz uma Ponteira e uma Fechadora parecerem diferentes na tela.

### 5.3 Adversárias

- NPCs gerados, com atributos que sobem conforme a **categoria da corrida**.
- Algumas **rivais com nome** aparecem várias vezes e têm encontros próprios.

### 5.4 Apresentação (MVP)

- Corrida em **3D** com câmeras de transmissão (automática, acompanhar, lateral, frente, aérea, tribuna). O protótipo usa primitivas, e os modelos low-poly entram depois (§11).
- Ranking ao vivo, minimapa e aviso quando uma habilidade dispara.
- Botões **1x / 2x / pular**.

### 5.5 Afobação (proposta)

Ideia vinda das referências: às vezes a corredora **perde a calma** e corre fora do plano.

- No começo do Meio, cada corredora tem uma chance de ficar **afobada** (inicial: 15% com Inteligência 0, caindo até 3% com Inteligência 1200).
- Afobada, ela tenta ir para a frente do pelotão por alguns segundos, ignorando a posição-alvo do estilo, e gasta **+50% de fôlego** nesse tempo.
- Aparece na tela (orelhas para trás e rabo eriçado) e no ranking ao vivo.
- Dá uma função clara para a Inteligência nas corridas longas e cria momentos de drama sem controle do jogador.
- Precisa ser testada no simulador antes de entrar (§12).

## 6. Pool semanal

- A "semana" gira **a cada carreira concluída** (não usa o relógio real, então não dá para burlar).
- A pool mostra **4 ou 5 garotas** por rotação.
- Cada tiragem custa moeda e **sempre** entrega uma delas, com **chances visíveis**.
- **Garantia:** depois de N tiragens sem vir a garota escolhida, ela vem garantida (N inicial: 10).
- Garota nova entra no elenco. Garota repetida sobe o vínculo (§3.5).

### 6.1 Moeda

Existe **uma única moeda**, sem moeda premium. Fontes:
1. Vitórias durante a carreira.
2. Conclusão de carreira (bônus por desempenho).
3. Prêmios do circuito.

## 7. Circuito

- **5 copas**: Sprint, Milha, Média, Longa e Terra.
- Cada copa tem **3 corridas**. O jogador escala **3 garotas diferentes**, uma por corrida, e vence por **pontos**.
- As copas de distância têm as 3 corridas na mesma faixa. A **Copa Terra** varia: **1200 / 1600 / 2400 m**, para pedir especialistas de terra diferentes.
- Vencer as 5 copas abre o **Campeonato Final**: 5 corridas variadas, que pedem **5 garotas diferentes**.
- Tudo é PvE, sem PvP.

## 8. Início do jogo

1. O jogador escolhe **1 entre 3 garotas iniciais**.
2. Ganha moeda para algumas tiragens na primeira pool.
3. Faz a primeira carreira guiada como tutorial.

## 9. Escopo do MVP

**Entra**
- 6 garotas completas (3 iniciais + 3 na pool), com personalidade e eventos.
- Mais 42 garotas **só com dados** (estilo, atributos, aptidões) para encher a pool e equilibrar: 6 especialistas por distância × piso ([elenco](elenco.md#elenco-completo-48)).
- 1 carreira completa de 48 turnos.
- 5 atributos, 5 treinos, energia, humor, falha e lesão.
- Encontros genéricos + 2 ou 3 únicos por garota.
- Calendário completo com mapa de rotas, 7 tipos de nó, 6 eventos de Mistério e ~15 amuletos. Estreia e 2 Grandes Prêmios escritos à mão, opcionais geradas por modelo ([calendário](calendario.md) §12). Clima do mês e objetivos 2 e 4 sorteados. Simulação em 4 fases, visão top-down.
- Pool semanal com garantia e vínculo.
- Arte provisória (primitivas 3D) e **1 garota low-poly de referência** para validar o pipeline Blender → Godot (§11.4).

**Fica para depois**
- Mais garotas, mais corridas, circuito completo.
- Magnitude (dificuldade crescente), ver [calendário](calendario.md) §10.
- Modelos low-poly finais das 6 garotas do MVP, rivais e NPCs (§11).
- Cenários low-poly além da pista e do pátio da academia.
- Legado/madrinha (§3.6).
- História principal.
- Mobile.

## 10. Técnico

- **Godot 4 + GDScript**. Cenas e recursos em texto (`.tscn` / `.tres`).
- Dados das garotas, habilidades, eventos e corridas ficam em **arquivos de dados** (`.tres` ou JSON), não espalhados pelo código.
- Textos em arquivos de tradução do Godot (CSV/PO), em PT-BR.
- **Save automático a cada turno**, em um único slot.
- Todo sorteio da carreira sai de `hash(semente, turno, contexto)`, com fluxos separados para mapa, treino, encontros e corrida ([calendário](calendario.md) §6).
- A simulação da corrida não depende da tela, para poder rodar headless em testes e balanceamento.
- Modelos 3D feitos no **Blender** e exportados em **glTF (`.glb`)** para o Godot (§11.4).

## 11. Direção de arte: 3D low-poly

### 11.1 Ideia

Personagens e cenários em **3D low-poly** com cara de anime: poucos polígonos, formas limpas e cor chapada. É mais barato de produzir do que retratos 2D com várias expressões, combina com a corrida 3D que o protótipo já tem e dá uma cara própria ao jogo dentro do gênero.

Referências que o Lucas mandou: modelagem de personagem low-poly anime no Blender a partir de desenhos de frente e perfil, com rig Rigify, e um personagem estilo PS1 (blockout, UV e textura). As duas seguem o mesmo pipeline (§11.4).

**Estilo escolhido (inicial):** low-poly **limpo**, com cores de paleta e sombreamento toon simples. O visual "PS1" (textura serrilhada, vértices tremendo) fica como **filtro opcional** de tela, não como base, porque dificulta ler as expressões.

### 11.2 Personagens

- **Base única** de corpo para todas as garotas (~2.500 a 4.000 triângulos), com variações de cabelo, roupa, orelhas e rabo. Assim 48 garotas não viram 48 modelos do zero.
- **Orelhas e rabo** têm ossos próprios. O rabo é uma corrente de ossos com balanço físico simples, e as orelhas giram para mostrar emoção (em pé, de lado, para trás).
- **Cor por paleta:** o modelo usa uma textura pequena de paleta (um quadrado por cor). Trocar a pelagem é trocar a paleta, sem refazer o modelo.
- **Rosto:** olhos e boca como **textura trocável** (atlas de expressões), não como malha. Expressões do MVP: normal, feliz, determinada, cansada, triste, surpresa.
- **Animações:** parada, andar, correr (2 ritmos), sprint, comemorar, perder, treinar (1 por treino) e cochilar.
- **Uniformes:** roupa de treino e roupa de corrida. A roupa de corrida tem a cor e um símbolo da estrela de cada garota.
- **NPCs:** a base com paleta e cabelo sorteados.

### 11.3 Cenários

| Cenário | Uso | Prioridade |
|---|---|---|
| Pista (grama e terra) com arquibancada | Corridas | MVP |
| Pátio da academia | Tela principal: a garota escolhida aparece grande, parada, e outras garotas passeiam no fundo. Clicar numa delas abre um encontro curto. | MVP |
| Campo de treino | Animação dos treinos | Depois |
| Cidade, praia e serra | Saídas, festival e férias | Depois |

Os cenários usam a mesma paleta compartilhada e luz de céu simples. O clima do mês (chuva, neblina, noite de estrelas) aparece no cenário.

### 11.4 Pipeline

1. **Referência:** desenho de frente e de perfil da garota (pode ser rascunho).
2. **Blockout e modelagem** no Blender, na base compartilhada.
3. **UV e paleta:** UV de cada parte em cima da cor certa da textura de paleta.
4. **Rig** com Rigify, mais os ossos de orelha e rabo.
5. **Exportar** em glTF (`.glb`) para `modelos/` no projeto Godot.
6. **Godot:** material toon com a paleta, troca de expressão por textura, e a cena da corrida troca as cápsulas pelos modelos.

O MCP do Blender ([mcp-blender.md](mcp-blender.md)) permite que o Claude crie e confira modelos, e o MCP do Godot ([mcp-godot.md](mcp-godot.md)) permite montar as cenas. A primeira tarefa de arte é **1 garota de referência** passando pelo pipeline inteiro, antes de produzir as outras.

### 11.5 Interface

Da análise de UI das referências: personagem grande no centro e informação em cima, botões principais embaixo, cores neutras com destaque de grama e terra, e o mesmo sistema visual em todas as telas. No PC isso vira painel de ações na parte de baixo da tela e atalhos de teclado.

## 12. Pendências de balanceamento

- Corrida: Ponteira forte no nível 400 em Média/Longa (ver [corrida.md](corrida.md) §8).
- Ganho por treino e por nível de treino.
- Custo da tiragem, valor de N da garantia e moeda por fonte.
- Limite de energia para falha e chance de lesão.
- Lista de habilidades genéricas e seus gatilhos.
- Corrida em nível baixo (150–300): Fechadora forte na Sprint e Ponteira na Longa ([calendário](calendario.md) §11).
- Calor na Longa favorece a Ponteira e a Estamina; vento ainda sem efeito na corrida ([calendário](calendario.md) §4.4).
- Maldições e força das NPCs por magnitude.
- Afobação (§5.5): chance, duração e custo de fôlego, testados no simulador.
- Pesos do sorteio do mapa, força dos amuletos e do Desafio.
- Força das NPCs por categoria, fama por corrida e curva esperada de atributos ([calendário](calendario.md) §2 e §5).

## 13. Documentos relacionados

- [Elenco](elenco.md): as 6 garotas do MVP com eventos, 2 rivais e o elenco completo de 48.
- [Calendário da carreira](calendario.md): turnos, objetivos, mapa de rotas, clima, amuletos, semente, magnitude, fama e férias.
- [MCP do Blender](mcp-blender.md) e [MCP do Godot](mcp-godot.md): ferramentas para modelar e montar o jogo.
- [Fórmula da corrida](corrida.md): fases, velocidade, fôlego, bloqueio, habilidades e calibração.
