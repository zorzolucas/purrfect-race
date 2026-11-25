# Fama, corridas e boosts de treino (v0.2)

> Versão 0.2 — 2026-11-24. **No protótipo.** O Lucas decidiu: a fama age como **multiplicador** (§2) e a meta de fama falhada **acaba a carreira**, com o pelotão escalando para equilibrar com esse mínimo (§3). Os números finais e o resultado do bot estão na §8; os dados ficam em `data/calendario.json` (`crescimento`).
> Versão 0.1 — 2026-11-24. Mapa pedido pelo Lucas: o que o protótipo já fazia e a proposta para os 4 pedidos.
>
> Os 4 pedidos:
> 1. Corridas contribuem com atributos tanto quanto treinos.
> 2. Fama vira um atributo que escala os outros, e o jogador precisa escolher bem quando correr opcionais.
> 3. Objetivos fixos de fama (fama mínima durante a carreira ou até o fim dela).
> 4. Melhorias e boosts de treino, fixos e temporários.
>
> A regra que vale para tudo: **não pode existir um META** (nenhuma rota, estilo ou atributo sempre melhor). Cada pedido abaixo tem uma seção "Como não vira META".

---

## 0. Como está hoje

### 0.1 Treino (`scripts/carreira.gd`, `ganho_previsto` e `treinar`)

Ganho de um treino = base × nível × humor × extras × retorno decrescente.

| Peça | Valor hoje | Onde |
|---|---|---|
| Base | 39 no principal, 14 no secundário | `BAL.ganho_principal/secundario` |
| Nível do treino | +30% por nível acima do 1; sobe a cada 3 usos, até 5 | `nivel_treino` |
| Nível efetivo (+1) | nó Foco/Biblioteca, chuva (Potência), frio (Determinação), férias serra/praia, Mistério da serra, amuleto Sino de Vento | `nivel_efetivo` |
| Humor | ×0,8 a ×1,2 | `HUMOR_TREINO` |
| Natural | +10% (+20% com Constelação) | `BAL.bonus_natural` |
| Dupla com colega | +25% | `BAL.bonus_dupla` |
| Outros | Festival ×0,9; chuva −10% em Velocidade; vento +10% em Inteligência; lesão ×0,5; Treino Pesado +10% em tudo | vários |
| Amuletos de ganho | Ferradura +5% Velocidade | `efeito.ganho` em `data/amuletos.json` |
| Retorno decrescente | ×(1,25 − 0,45 × atributo/limite), mínimo 0,3 | `_retorno` |

Um treino no nível 1, com humor Normal e atributos em 300, rende ~+45 no principal e ~+16 no secundário (**~60 no total**). No nível 5, ~2,2 vezes isso.

**O que já existe de "boost"** está espalhado: cada fonte tem um `if` próprio (`serra`, `clima()`, `tipo_no()`, `acampamento()`, `_efeito("nivel")`). Não há um lugar único com "boosts ativos e quanto tempo faltam".

### 0.2 Corrida (`registrar_corrida`)

| O que dá | Valor hoje |
|---|---|
| Atributos | **o mesmo número em todos os 5**: Estreia +5, Aberta +6, Prata +9, Ouro e GP1 +12, GP2/GP3 +15. Vence ×1, top 3 ×0,8, resto ×0,5 (`BAL.atributos_corrida`) |
| Fama | base da categoria × colocação × olheiro (Favorita ×0,75, Disputada ×1, Azarão ×1,5) × amuletos |
| Pontos de habilidade e moeda | por categoria e colocação |
| Custo | 15 de energia (+10 na 3ª seguida, 30% de chance de baixar o humor) e o turno sem treino |

Uma Aberta vencida dá 6 × 5 = **30 no total**; uma Ouro vencida, 60. Ou seja, **uma corrida rende metade a um quarto de um treino** em atributos. Corre-se pela fama, pelos pontos e pelas séries, não pelo crescimento.

### 0.3 Fama

- Só sobe, nunca desce.
- Usos hoje: **entrar** em Prata (600) e Ouro (1500) nas opcionais (objetivo é por convite); **virada** das campanhas no turno 48 (algumas com fama ≥ 4800, ex.: Capela e Estrela); moeda no fim (+1 a cada 100); desempate no placar do Desafio da semana; condição `fama_min` já existe em `scripts/campanha.gd`.
- Fontes: corridas (tabela acima), séries (Tríplice +500, Coroa +300), alguns encontros (`efeito.fama`), Fita Azul (+10%).
- **Fama não mexe em atributo nenhum.** Depois que ela passa de 1500, fama extra quase não muda o jogo (só a virada).

### 0.4 Objetivos

- 8 objetivos de corrida por campanha (`data/campanhas.json`), falhou = a carreira acaba.
- Não existe objetivo de fama. A fama só aparece como condição da virada.

---

## 1. Corridas contribuem com atributos tanto quanto treinos

### 1.1 Proposta

Trocar o "+N em todos os atributos" por um ganho que **vale um treino** e tem **a cara da corrida**:

- **Total**: o ganho total de uma corrida vencida passa a ser ≈ um treino no **nível médio atual** dos treinos dela (média de `nivel_treino` dos 5), com o retorno decrescente de cada atributo. Assim a corrida acompanha a curva do treino e não trava no ano 3.
- **Distribuição pelo tipo de corrida** (inicial):

| Distância | Vel | Est | Pod | Det | Int |
|---|---|---|---|---|---|
| Sprint | 35% | 5% | 30% | 15% | 15% |
| Milha | 30% | 10% | 25% | 15% | 20% |
| Média | 20% | 25% | 20% | 15% | 20% |
| Longa | 10% | 40% | 10% | 25% | 15% |

  Piso: **Terra** passa 5 pontos de Velocidade para Potência; **Grama**, nada.
- **Colocação** (inicial): vence ×1,0 · top 3 ×0,75 · top 5 ×0,55 · resto ×0,35. Hoje o resto ganha 50%; com o ganho maior, perder precisa doer mais.
- **Categoria**: Estreia ×0,8 · Aberta ×0,9 · Prata ×1,0 · Ouro ×1,15 · GP ×1,3. Corrida mais difícil rende mais, mas o risco de cair para ×0,35 também cresce.
- **Experiência de corrida** (opcional, para pensar): cada corrida concluída numa distância nova dá +1 nível de treino "virtual" na Inteligência por 1 turno. Fica de fora da v1.

Exemplo: treinos médios no nível 3 (×1,6), atributos em 500. Um treino rende ~85 no total. Uma Milha Prata vencida rende ~85 também, espalhado (25 Vel, 9 Est, 21 Pod, 13 Det, 17 Int). Em 4º lugar, ~47.

### 1.2 Como não vira META

O risco é a corrida ficar **sempre melhor** que o treino (dá o mesmo atributo + fama + pontos + moeda, e gasta menos energia). Os contrapesos:

1. **Atributo espalhado**: o treino concentra onde ela precisa; a corrida espalha pelo perfil da corrida. Para uma Fechadora de Longa que precisa de Velocidade, uma Longa rende pouco do que importa.
2. **Colocação**: em corrida difícil, o valor esperado cai para perto de metade de um treino.
3. **Energia**: a corrida passa a custar **20** (era 15), quase o mesmo que o treino (22). No protótipo. A 3ª seguida continua com +10 e o risco de humor.
4. **Nível do treino não sobe**: o treino dá uso (sobe o nível a cada 3); a corrida não. Quem corre demais no ano 1 chega ao ano 2 com treinos de nível baixo.
5. **O bot mede**: meta de equilíbrio = a carreira que **só treina** e a que **corre tudo o que pode** ficam a menos de 5 pontos de conclusão uma da outra, e a melhor rota fica no meio.

---

## 2. Fama escala os outros atributos

### 2.1 Proposta: **Prestígio**

A fama vira um medidor com **níveis de Prestígio**. Cada nível dá um multiplicador de **ganho** (treino e corrida), como patrocínio, treinadoras melhores e torcida.

| Prestígio | Fama (inicial) | Ganho de treino e corrida | O que destrava |
|---|---|---|---|
| 0 · Novata | 0 | ×1,00 | — |
| 1 · Conhecida | 600 | ×1,04 | Prata nas opcionais |
| 2 · Promessa | 1500 | ×1,08 | Ouro nas opcionais |
| 3 · Destaque | 3000 | ×1,12 | 1ª melhoria fixa de treino (§4.2) |
| 4 · Estrela | 4800 | ×1,15 | Torcida no treino (§4.3) |
| 5 · Ídolo | 7000 | ×1,18 | 2ª melhoria fixa |
| 6 · Lenda | 10000 | ×1,20 | título "Lenda" na ficha |

- Por que **ganho** e não atributo direto: o multiplicador age **daqui para frente**. Fama cedo rende o resto da carreira; fama no fim do ano 3 rende quase nada. É isso que transforma "quando correr a opcional" numa decisão: correr no ano 1 tira treino agora para ganhar mais em todos os treinos depois.
- Os degraus diminuem (+4, +4, +4, +3, +3, +2): depois do Prestígio 4 a fama vale cada vez menos em atributo, e passa a valer pelas metas (§3) e pela virada.
- A tela mostra a barra de fama com o próximo degrau e o multiplicador atual (o UI gamificado do PR #27 já tem o número de fama no topo; vira uma barra com selo).

### 2.2 O preço da fama: **Expectativa**

Fama alta também cobra. A partir do Prestígio 3, a torcida espera vitória:

- Ficar fora do top 5 numa corrida (opcional ou objetivo) com Prestígio ≥ 3 tem **25% de chance de baixar o humor** (inicial), 40% no Prestígio ≥ 5.
- O olheiro passa a mostrar "a torcida espera vitória" nesse caso.

Assim correr de Azarão para juntar fama rápido fica mais arriscado justamente quando a fama já está alta.

### 2.3 Como não vira META

- **Rota da fama vs. rota do treino**: o bot roda as duas pontas (correr cedo e muito × só treinar e correr no fim) e a meta é que nenhuma vença sempre. O ponto de equilíbrio esperado é "algumas opcionais no ano 1, mais no ano 2".
- **Olheiro** continua: Azarão dá ×1,5 de fama, mas a chance de cair para ×0,35 em atributo (§1) e de baixar o humor (§2.2) também.
- **Teto suave**: os degraus diminuem, então quem só caça fama para de ganhar atributo extra.
- **Casas**: toda casa tem 1 Prata e 1 Ouro por ano no calendário fixo, mas as casas que vencem opcionais com mais facilidade (as de corrida curta, com mais sorte) juntam fama mais rápido e o Prestígio compõe essa vantagem. O bot confere a fama média por casa e, se uma casa sobrar, a fama base das corridas dessa casa muda (mesmo esquema de `forca_distancia_cat`).
- **Endgame**: o Prestígio só existe na carreira; a simulação não muda, então os traçados do circuito (`testes/meta_circuito.gd`) não precisam ser recalibrados. O que muda é o atributo final das garotas salvas, que o bot mede de novo.

---

## 3. Objetivos fixos de fama

### 3.1 Proposta: **Metas de fama**, iguais em toda campanha

Além dos 8 objetivos de corrida, toda carreira tem **3 metas de fama** fixas, visíveis desde o turno 1, conferidas no fim de cada ano:

| Meta | Turno | Fama mínima (inicial) | Falhou |
|---|---|---|---|
| Ano 1 · "Primeiros fãs" | 24 | 500 | a carreira **acaba** |
| Ano 2 · "Nome no jornal" | 48 | 3500 | a carreira **acaba** |
| Ano 3 · "Lenda das pistas" | 72 | 8000 | a carreira **acaba** (o GP final vencido não conta como carreira completa) |

- A meta é conferida **depois** do objetivo do mesmo turno (a fama dele conta).
- **O pelotão escala junto** (decisão do Lucas): `forca_npc_ano` multiplica a força das NPCs por ano (1,00 · 1,05 · 1,08), calibrado para que quem chega no mínimo de fama, com o Prestígio que ele dá, tenha a mesma dificuldade da v0.7.

- Regra usada para calibrar: com a rota do bot (que corre opcionais quando é Favorita ou Disputada), **~90% das carreiras passam** da meta do ano 1 e **~80%** da do ano 2 na conta nova. Uma carreira que nunca corre opcional precisa falhar a meta do ano 2.
- Os objetivos de corrida já dão fama (são por convite e valem a fama da categoria), então a meta mede só o **excesso** que ela foi buscar nas opcionais e nas séries.
- **Objetivos de campanha com fama**: o campo `fama_min` já existe em `scripts/campanha.gd`. Dá para usar em objetivos específicos de uma campanha (ex.: a Capela, que é sobre fama, ter o objetivo 5 como "ter 2500 de fama até o turno 40" em vez de uma corrida). Proposta: 2 das 8 campanhas ganham 1 objetivo de fama no lugar de um de corrida. Quais, fica para o Lucas.
- A **virada** das campanhas que usam fama (4800 no turno 48) passa a bater com o Prestígio 4 (já bate).

### 3.2 Interface

- No painel de objetivos da tela de turno, uma linha fixa "Meta de fama do ano: 1240 / 3000 · faltam 9 turnos".
- No turno da conferência, uma tela de resultado no mesmo estilo do objetivo cumprido (com o banner do PR #27).
- O olheiro mostra quanto a corrida aproxima da meta ("+400 de fama: meta do ano 85%").

### 3.3 Como não vira META

A meta força **pelo menos** uma quantidade de opcionais, mas não diz quais. Junto com o Prestígio (§2) e a corrida que dá atributo (§1), o jogador escolhe entre: correr cedo e garantir a meta (menos treino agora, mais ganho depois) ou deixar para o fim do ano (mais treino agora, risco de chegar sem fama e precisar correr de Azarão).

---

## 4. Melhorias e boosts de treino

### 4.1 Base: um lugar só para boosts

Criar `var boosts: Array` na `Carreira`, com cada item:

```
{"id": "embalo", "fonte": "vitoria", "efeito": {"ganho_todos": 0.10}, "turnos": 2, "treinos": []}
```

- `turnos` = turnos restantes (−1 = até o fim da carreira). `_fim_turno` desconta e remove os zerados.
- `treinos` = em quais treinos vale (vazio = todos).
- `efeito` usa as mesmas chaves dos amuletos (`ganho`, `ganho_todos`, `nivel`, `natural`, `custo_treino`, `falha_min`...), então `ganho_previsto`, `nivel_efetivo`, `custo` e `chance_falha` leem dos dois do mesmo jeito (`_soma` e `_efeito` passam a somar amuletos + boosts).
- O Mistério da serra (`serra`) vira um boost (`{"nivel": ["est","det"], "falha_mult": 2, "treinos": 1}`), e os do nó e do clima podem virar boosts de 1 turno criados no começo do turno. Assim a tela mostra **tudo que está valendo** numa fila de ícones com o contador de turnos, e o save guarda só a lista.

### 4.2 Melhorias fixas (até o fim da carreira)

**Equipamento da academia**: cada treino tem uma melhoria com 3 graus. Grau comprado vale até o fim da carreira.

| Grau | Efeito no treino | Como consegue |
|---|---|---|
| 1 | +6% de ganho nele | Prestígio 3 (escolhe 1 treino) |
| 2 | +12% e −2 de energia nele | Prestígio 5 (escolhe 1 treino, pode ser o mesmo) |
| 3 | +18%, −3 de energia e falha −20% nele | Tríplice da casa (escolhe 1 treino) |

- Cada grau ganho é escolhido numa tela própria (pendência `equipamento`), e o mesmo treino pode subir até o grau 3.
- **Ainda não feito:** comprar graus com pontos de habilidade (proposta: 120 / 200 / 300).
- Os amuletos continuam sendo o outro tipo de melhoria fixa (já existem: Ferradura, Treino Pesado, Constelação).

### 4.3 Boosts temporários

| Boost | Fonte | Efeito (inicial) | Duração |
|---|---|---|---|
| **Embalo** | vencer uma corrida | +10% em todos os treinos | 2 turnos |
| **Lição da derrota** | ficar em 2º–3º contra a rival | +1 nível no treino do atributo em que a rival era maior | 1 treino |
| **Treinadora convidada** | encontros e conversas do pátio (efeito novo `boost`) | +1 nível num treino sorteado | 2 turnos |
| **Torcida no treino** | Prestígio ≥ 4, 1 vez por trecho | +20% no próximo treino | 1 treino |
| **Cansaço acumulado** | 3 corridas em 4 turnos | −10% em todos os treinos | 2 turnos |
| **Foco total** | descansar com humor Ótimo | falha −50% | 1 treino |

- Os existentes continuam: nó Foco/Biblioteca, clima, férias, dupla com colega, humor.
- O Embalo é a recompensa de correr que conversa com §1 e §2: vencer dá atributo, fama e um treino melhor em seguida; o Cansaço é o freio de correr demais.

### 4.4 Como não vira META

- Os boosts temporários **não acumulam do mesmo tipo** (renovam a duração).
- O teto de nível efetivo continua 5.
- O equipamento grau 3 só vem de uma Tríplice, que já é rara (o bot fecha poucas), então ninguém tem 3 treinos no grau 3.
- O bot mede a **conclusão por estilo e por casa** antes e depois. Se o equipamento puxar todo mundo para o mesmo treino (ex.: todo mundo equipa Velocidade), o grau 1 de Velocidade custa mais.

---

## 5. Como os 4 se encaixam

```
correr opcional ─┬─> atributo (≈ 1 treino, pelo perfil da corrida)       §1
                 ├─> fama ─> Prestígio ─> ×ganho de todo treino depois    §2
                 │                   └─> equipamento fixo                 §4.2
                 ├─> vitória ─> Embalo (treino melhor em seguida)         §4.3
                 └─> conta para a meta de fama do ano                     §3
custo: energia 20, turno sem treino (nível não sobe), risco de humor,
       Cansaço acumulado, Expectativa da torcida (§2.2)
```

A pergunta que o jogador faz a cada opcional deixa de ser "dá fama?" e vira "**vale trocar este treino por esta corrida agora?**", e a resposta muda com o ano, a meta, o Prestígio e quanto ela precisa de cada atributo.

## 6. Ordem de implementação sugerida

1. **Boosts** (§4.1): só refatora, sem mudar número. Os testes atuais precisam continuar passando.
2. **Corrida dá atributo pelo perfil** (§1) + energia 20. Rodar o bot.
3. **Prestígio** (§2.1) e **Expectativa** (§2.2). Rodar o bot nas duas pontas (só treino × corre tudo).
4. **Metas de fama** (§3), calibradas pela fama do bot nos turnos 24, 48 e 72 (o bot precisa passar a registrar a fama por turno).
5. **Equipamento** e **boosts temporários** (§4.2 e §4.3). Rodar o bot de validação com sementes novas.
6. UI: barra de Prestígio, fila de boosts, linha da meta de fama.

O endgame não muda (a simulação não muda), mas as garotas salvas ficam com atributos diferentes, então o bot valida a conta madura e o circuito no fim.

## 7. Decisões

Tomadas pelo Lucas em 2026-11-24:
1. A fama age como **multiplicador** do ganho (§2.1).
2. **Meta de fama falhada acaba a carreira**, e o pelotão escala para equilibrar com o mínimo (§3.1).

Em aberto:
3. **Equipamento** com pontos de habilidade também, ou só pelo Prestígio e pela Tríplice?
4. Quais **campanhas** trocam um objetivo de corrida por um de fama (proposta: 2 das 8, começando pela Capela).
5. A **Treinadora convidada** sai por enquanto só do encontro genérico "Treinadora visitante" (`gen_treinadora`). Dá para pôr `"boost": "treinadora"` em mais encontros.

## 8. Resultado do bot (2026-11-24)

Bot de balanceamento (`testes/balanco.gd`), 48 garotas. O bot agora escolhe o equipamento pelo treino que o estilo mais usa e, quando está atrás do ritmo da próxima meta de fama, aceita correr de Azarão.

**Calibração** (sementes da v0.7, 8 a 10 carreiras por garota):

| Rodada | Oponentes por ano | Metas de fama | Completas |
|---|---|---|---|
| main (v0.7) | — | — | 33% |
| novo, sem ajuste | 1,00 · 1,00 · 1,00 | — | 61% |
| novo | 1,04 · 1,12 · 1,12 | — | 35% |
| novo | 1,03 · 1,10 · 1,10 | 800 · 4000 · 8500 | 17% (a meta do ano 1 derrubava 23%) |
| novo | 1,00 · 1,05 · 1,08 | 500 · 3500 · 8000 | 37% |
| **final** | **1,00 · 1,09 · 1,10** | **500 · 3500 · 8000** | 34% |

**Validação com sementes novas** (`SEMENTE0=1000`, 24 carreiras por garota, 1152 carreiras, conta nova):

| Medida | v0.7 | Agora | Alvo |
|---|---|---|---|
| Completas | 35,6% | **31,8%** | ~35% |
| Maior queda num objetivo | 18% (main, sementes da calibração) | 21,8% (turno 72, com a meta de fama) | ≤ 25% |
| Diferença entre casas | 9,8 | 11,8 | ≤ 10 (com 24 por garota a sorte sozinha abre ~11) |
| Diferença entre estilos | 1,8 | 6,2 (Perseguidora 35,4%, Arrancadora 29,2%) | pequena |
| Curva média (turnos 13 a 72) | 227 / 338 / 449 / 575 / 697 / 807 | 229 / 355 / 490 / 651 / 803 / 892 | — |
| Corridas por carreira | 16,1 | 16,2 | 14 a 20 |
| Completas na **conta madura** (10 por garota) | 58,2% | 62,5% | ~55% |

- **Metas de fama**: derrubam ~3% das que chegam no turno 24, ~6% no 48 e ~5% no 72. Quem quase não corre opcional falha a do ano 2 (fama do bot no turno 48: 10% abaixo de 3786, mediana 5343).
- **Viradas**: as que dependem de vencer o GP do turno 48 (Durona 77%, Lira e Antares ~80%, com poucas carreiras nas do MVP) e a Sonhadora (71%) passaram de 65%. As viradas por fama foram para 5200 (Estrela 49%; a Capela teve só 6 carreiras no turno 48).
- **A garota termina ~10% mais forte** (892 contra 807 no turno 72). As garotas salvas que vão para o **circuito do endgame** ficam mais fortes, e a força das NPCs do circuito (`data/endgame.json`) ainda não acompanhou.

**Feito em 2026-11-25:**
- **Circuito do endgame** +10% (Bronze 660, Prata 880, Ouro 1045), com a tabela de dificuldade medida de novo ([endgame](endgame.md) §5.7). Estilos no circuito a 4,4% um do outro (eram 2,7%), nenhum o melhor em mais de 39% das corridas.
- **Viradas sem depender de vencer o GP do turno 48:** Durona (vencer o objetivo 4 e top 2 no 5 e no GP), Lira e Antares (top 2 no GP e 9 vitórias), Sonhadora (3 viradas e 9 vitórias). Com 40 carreiras por garota: Antares 45%, Lira 38%, Durona 48%, Sonhadora 46%, Competitiva 47%.

**Próximos ajustes:** rodar 80 carreiras por garota para separar sorte de diferença real (casas, estilos e arquétipos) e revisar a Perseguidora +1,5% (`forca_estilo`), que pode ter ficado sobrando.
