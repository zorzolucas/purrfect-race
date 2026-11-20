# Nekomusume: Corrida Purrfeita (stelar-gallop)

Simulador de treino e corrida de garotas gato. O design está em [docs/GDD.md](docs/GDD.md).

## Protótipo jogável (Godot 4.7)

O projeto Godot fica na raiz do repositório. Para jogar, abra o `project.godot` no Godot 4.7
e aperte F5, ou rode:

```
Godot_v4.7.2-stable_win64.exe --path .
```

**O que dá para fazer:** escolher a primeira garota entre 3 iniciais, conhecer outras na pool
semanal e jogar com qualquer garota do elenco uma carreira de 72 turnos (3 anos, um turno por
meio mês), seguindo o [calendário](docs/calendario.md) e as [campanhas](docs/campanhas.md):

- **Semestre de base:** os turnos 1 a 12 são só treino e encontros. A Estreia é no turno 13.
- **Campanha única:** 8 objetivos (turnos 13, 20, 24, 32, 40, 48, 60 e 72), com os 3 Grandes
  Prêmios no fim de cada ano. As 6 garotas do MVP têm campanha escrita à mão, e as outras 42
  usam um de 12 arquétipos. Capítulos de história aparecem em turnos fixos, e depois do GP do
  ano 2 a carreira segue um de 2 caminhos, cada um com objetivo 7, GP final e final próprios.
  Falhou um objetivo, acabou.
- **Calendário fixo:** 16 corridas Prata e Ouro com nome, nos anos 2 e 3, que dá para correr
  em qualquer nó do mapa.
- **Mapa de rotas:** entre um objetivo e outro você escolhe um caminho num mapa sorteado de
  3 colunas. Cada nó dura 2 turnos: Treino focado, Circuito (corridas geradas), Festival,
  Recuperação, Biblioteca, Desafio (corrida de elite) ou Mistério (6 eventos).
- **Fama e categorias:** Estreia, Aberta, Prata, Ouro e Grande Prêmio. As mais altas pedem fama
  nas opcionais (os objetivos são por convite), e o pelotão fica mais forte a cada ano.
- **Clima do mês** (seis climas, conforme a estação), **férias de verão** com acampamento na
  Serra ou na Praia e **véspera** com a rival antes dos Grandes Prêmios.
- **Amuletos:** cada objetivo cumprido (do 1 ao 7) e o top 3 num Desafio dão a escolha de
  1 entre 3 amuletos (4, com um raro garantido, nos objetivos difíceis). São 15, de 4 tipos
  (simples, troca, estilo e raro), com até 6 equipados. Valem só até o fim da carreira.
- **Habilidades:** corridas dão um pouco de atributos e pontos de habilidade, que compram genéricas na loja da
  carreira (10 no total, até 6 equipadas; a Biblioteca dá 30% de desconto). Ela começa com
  Fôlego Extra e Reta Decisiva, e a versão salva guarda as habilidades.
- **Olheiro e instrução:** antes de toda corrida o olheiro mostra a força média do pelotão, se
  há rival e a etiqueta **Favorita / Disputada / Azarão** pela chance estimada de vencer. A fama
  vale ×0,75 / ×1 / ×1,5, então arriscar rende mais. Antes da largada você escolhe **Poupar,
  Normal ou Forçar**, e o olheiro sugere a que tem mais chance.
- **Séries e títulos:** vencer conjuntos de corridas do calendário fixo dá títulos (Estrela da
  *distância*, Coroa Dupla, Volta ao Céu) com fama, amuleto, aptidão ou +1 espaço de amuleto.
  Os títulos ficam na versão salva.
- **Madrinha:** com garotas salvas no elenco, a carreira começa pela escolha da madrinha, que dá
  um bônus inicial (teto de +25 por atributo com o vínculo) e inspira nos turnos 25 e 49.
- **Semente:** todos os sorteios saem da semente da carreira; recarregar e repetir a mesma
  ação dá o mesmo resultado.

A corrida é assistida em 3D (primitivas placeholder), com
ranking ao vivo, minimapa, avisos de habilidade e botões 1x / 2x / pular.

**Câmeras da corrida:** Automática (troca sozinha conforme a fase, como numa transmissão),
Acompanhar, Lateral, Frente, Aérea e Tribuna. Troque com `C` ou com as teclas `1` a `6`.

**Encontros e afinidade:** em algumas semanas (mais ao Sair) aparece um encontro com 2 ou 3
escolhas. Há 3 eventos únicos por inicial e 6 genéricos com as colegas da academia, todos em
`data/encontros.json`. Os encontros mexem na afinidade, e colegas com afinidade 30+ podem
aparecer num treino para um bônus de dupla (+25%). As rivais Polaris e Algol, ou a campeã
da casa, correm os Grandes Prêmios e os objetivos com meta de rival.

**Pátio da academia:** o botão "Ir ao pátio" (não gasta o turno) abre o pátio em 3D, com
cenário de primitivas e as colegas passeando como sprites das fichas conceituais. A garota da
carreira aparece grande à esquerda, com a expressão do humor. Cada colega tem o seu hábito
(a Lira cochila numa faixa de sol, a Mira fica na fonte, a Capela ensaia na escada...) e as
amigas trocam balões quando se encontram. Clicar numa colega abre uma **conversa curta**,
uma por turno, com efeitos pequenos (afinidade, às vezes humor ou +5 num atributo). Cada
colega tem 2 conversas próprias (a segunda pede afinidade 30+) e há conversas genéricas.
O pátio muda com o **evento do turno**: aniversário de uma colega (bolo na fonte e conversa
especial), aniversário da própria garota (festa surpresa), vitória (comemoração em roda),
derrota (a amiga mais próxima espera por ela), festival (barracas) e clima (chuva embaixo da
marquise, noite de estrelas, calor na fonte, chocolate quente no frio). Tudo fica em
`data/patio.json`. Na academia, o botão "Pátio" mostra as garotas do elenco só com falas.

**Expressões e gestos:** encontros, conversas, cartões e telas usam os rostos das fichas
conceituais (normal, olhos fechados, feliz, surpresa, tonta e piscadinha). Quem fala abre o
encontro com uma expressão e um gesto simples (pulinho, concordar, negar, encolher...) e
reage à escolha com outra expressão e um balão (coração, nota, "!", "..."). As 40 garotas
sem ficha usam o círculo com a inicial e a gata de primitivas com as cores da pelagem.

**Save:** a carreira é salva sozinha a cada turno (`user://carreira.json`). Na tela inicial
aparece o botão para continuar.

**Academia, pool e vínculo:** entre carreiras você fica na academia, com a moeda e o elenco.
A pool semanal mostra 5 garotas (2 com eventos e 3 só com dados), com chances iguais e
visíveis. Cada tiragem custa 100 moedas. Marque uma garota e ela vem garantida em no máximo
10 tiragens. Garota repetida sobe o vínculo (até 5), que dá +4 em cada atributo inicial e
+40 no limite por nível. A rotação gira a cada carreira concluída. No fim da carreira você
recebe moeda (prêmios das corridas e bônus por objetivo) e decide se a nova versão substitui
a salva. O perfil fica em `user://perfil.json`.

**Endgame ([endgame.md](docs/endgame.md)):** vencer o GP final libera a próxima
**Magnitude** daquela garota (0 a 5: NPCs mais fortes, maldições, metas mais altas, +20% de
moeda por nível). O **Circuito** tem 5 copas e o Campeonato Final em Bronze, Prata e Ouro,
corridos com as versões salvas contra 3 casas rivais; clima e traçado de cada corrida mudam a
cada rotação. O **Desafio da semana** é uma carreira com semente, garota e regra fixas por rotação.

**Fica para depois:** liberar amuletos entre carreiras e os amuletos exclusivos de magnitude.
Fora a Lira na pista e os sprites das fichas, a arte é placeholder (formas coloridas).

| Arquivo | O que faz |
|---|---|
| `scripts/sim_corrida.gd` | Simulação da corrida, port fiel de [corrida.md](docs/corrida.md) e `tools/sim_corrida.py`. Não depende de tela. |
| `scripts/calendario.gd` | Datas, trechos, mapa de rotas, clima, calendário fixo e corridas geradas, tudo pela semente. |
| `scripts/campanha.gd` | Monta a campanha de cada garota (`data/campanhas.json`) e avalia o ponto de virada. |
| `scripts/carreira.gd` | Regras da carreira. Os números de balanceamento ficam em `BAL`. |
| `scripts/perfil.gd` | Moeda, elenco, vínculo, versão salva de cada garota, a pool e o progresso do endgame. |
| `scripts/endgame.gd`, `scripts/tela_circuito.gd` | Magnitude, Circuito (pelotão, casas rivais, traçados, pontos) e Desafio da semana, com os números em `data/endgame.json`; tela do circuito com escalação e resultado. |
| `scripts/dados.gd` | Autoload que carrega os arquivos de `data/` (elenco, iniciais, rivais, encontros). |
| `scripts/corrida_3d.gd`, `scripts/pista_geo.gd` | Vista 3D da corrida (pista, corredoras, câmeras) e a geometria da pista em metros. |
| `scripts/patio_3d.gd`, `scripts/tela_patio.gd` | Pátio da academia: cenário de primitivas, colegas passeando com hábitos, clima e evento do turno, e a tela com as conversas. |
| `scripts/sprites_garota.gd`, `scripts/retrato_garota.gd` | Sprites das fichas conceituais (corpo e 6 expressões) e o retrato com expressão, gesto e balão. |
| `tools/recortar_fichas.py` | Recorta as fichas de `arte/animações/` em `sprites/garotas/` (corpo de frente e atlas das 6 expressões, fundo transparente). |
| `scripts/tela_*.gd`, `scripts/main.gd` | Telas montadas em código (escolha, madrinha, carreira com olheiro, corrida, fim). |
| `testes/balanco.gd` | Joga carreiras completas com um bot (conta nova ou madura) e mede objetivos, virada, curva de atributos e fama. |
| `testes/teste_campanhas.gd` | Monta as 48 campanhas e confere turnos, rivais, aptidões e o save depois da virada. |
| `testes/teste_amuletos.gd` | Testa oferta, limite e efeitos dos amuletos e a loja de habilidades. |
| `testes/teste_mapa.gd` | Gera 1400 mapas e confere as regras do sorteio. |
| `testes/teste_perfil.gd` | Testa a pool, a garantia, o vínculo, a moeda do fim de carreira e o save do perfil. |
| `testes/teste_save.gd` | Salva uma carreira, carrega de volta e confere se o estado é o mesmo. |
| `testes/teste_series.gd` | Testa o olheiro, a instrução, as séries e títulos, o teto da madrinha e o visual do elenco. |
| `testes/teste_sim.gd` | Testa a simulação da corrida: mesma semente dá o mesmo resultado, a mais forte vence mais, chuva e modo estimativa. |
| `testes/teste_dados.gd` | Confere os JSON de `data/`: campos, ids únicos e referências entre arquivos (colegas, rivais, habilidades, efeitos). |
| `testes/teste_carreira.gd` | Joga carreiras inteiras com um bot aleatório, confere o estado a cada passo e que salvar e carregar no meio não muda nada. |
| `testes/teste_telas.gd` | Abre o jogo e aperta botões ao acaso por 1200 passos. Falha em qualquer erro de script. |
| `testes/teste_endgame.gd` | Testa a magnitude (metas, maldições, força, mapa, moeda, save), as regras do desafio, a liberação de magnitude, as tentativas e os prêmios do circuito. |
| `testes/meta_circuito.gd` | Procura meta no circuito: pontos por estilo, por garota e por +10% em cada atributo em cada corrida e traçado, e a chance de vencer cada nível ([endgame](docs/endgame.md) §5). |
| `testes/capturas_endgame.gd` | Capturas da academia com o desafio e a magnitude, do circuito, da escalação, do resultado e do fim de um desafio. |
| `testes/rodar_testes.gd` | Roda todos os `teste_*.gd` e mostra o resumo. O GitHub roda o mesmo a cada PR (`.github/workflows/testes.yml`). |
| `testes/instrucao.gd` | Compara as 3 instruções em corridas equilibradas e mede o erro do olheiro contra corridas reais. |
| `testes/teste_patio.gd` | Testa aniversários, eventos do pátio, conversas (uma por turno, afinidade 30+), reações, save e monta a cena 3D em todos os eventos. |
| `testes/capturas_patio.gd` | Capturas do pátio, das conversas e dos encontros com expressões. |
| `testes/capturas.gd` | Passa pelas telas sozinho e salva capturas em `testes/capturas/`. |
| `testes/capturas_novas.gd` | Capturas da madrinha, do olheiro, dos cartões de corrida e dos títulos. |
| `tools/importar_visual.py` | Lê as fichas de [visual-elenco.md](docs/visual-elenco.md) e grava signo, aniversário e visual em `data/garotas.json` e `data/rivais.json`. |
| `tools/resumo_balanco.py` | Junta as saídas JSON do `testes/balanco.gd` e mostra a taxa geral, a queda por objetivo, as taxas por casa e por arquétipo, a divisão no ponto de virada e os títulos ([campanhas](docs/campanhas.md) §7). |

### Testes

Todos os testes automáticos de uma vez (uns 2 minutos; com `-- carreira` roda só os que têm "carreira" no nome):

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/rodar_testes.gd
```

Um por um, e as ferramentas de balanceamento e capturas:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/balanco.gd -- 20 mvp nova
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_campanhas.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_save.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_perfil.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_mapa.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_amuletos.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_series.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/instrucao.gd -- 40
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://testes/teste_patio.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://testes/capturas.gd
```

Para rodar as 48 garotas em 4 processos e juntar o resultado:

```
for i in 0 1 2 3; do Godot --headless --path . --script res://testes/balanco.gd -- 20 parte:$i/4 nova nova_$i.json & done; wait
python tools/resumo_balanco.py nova_*.json
```

Os resultados da última rodada do bot estão em [campanhas](docs/campanhas.md) §7. O bot é simples; quem planeja a rota e cuida do humor vai melhor.

A primeira garota em 3D low-poly, a Lira, já corre na pista no lugar da cápsula
(ver [modelo da Lira](docs/modelo-lira.md)).

![Lira em 3D low-poly](docs/prototipo/21_lira_modelo.png)
![Expressões da Lira](docs/prototipo/22_lira_expressoes.png)
![Lira na pista](docs/prototipo/23_lira_na_pista.png)
![Ficha conceitual x modelo da Lira](docs/prototipo/24_lira_ficha_vs_modelo.png)
![Pátio no aniversário da Mira](docs/prototipo/29_patio_aniversario.png)
![Conversa no pátio](docs/prototipo/34_patio_capela.png)
![Pátio num dia comum](docs/prototipo/33_patio_habitos.png)
![Noite de estrelas no pátio](docs/prototipo/38_patio_estrelas.png)
![Comemoração depois da vitória](docs/prototipo/40_patio_vitoria.png)
![Encontro com expressão](docs/prototipo/35_encontro_expressao.png)
![Reação depois da escolha](docs/prototipo/36_encontro_reacao.png)
![Escolha](docs/prototipo/1_escolha.png)
![Madrinha](docs/prototipo/17_madrinha.png)
![Olheiro e instrução](docs/prototipo/18_olheiro_objetivo.png)
![Cartões com olheiro e séries](docs/prototipo/19_cartoes_olheiro.png)
![Olheiro com série](docs/prototipo/20_olheiro_serie.png)
![Academia](docs/prototipo/9_academia.png)
![Pool](docs/prototipo/10_pool.png)
![Fim de carreira](docs/prototipo/11_fim_de_carreira.png)
![Mapa de rotas](docs/prototipo/12_mapa.png)
![Circuito](docs/prototipo/13_circuito.png)
![Férias](docs/prototipo/14_ferias.png)
![Amuleto](docs/prototipo/15_amuleto.png)
![Loja de habilidades](docs/prototipo/16_loja_habilidades.png)
![Carreira](docs/prototipo/6_depois_da_corrida.png)
![Encontro](docs/prototipo/7_encontro.png)
![Treino em dupla](docs/prototipo/8_treino_em_dupla.png)
![Câmera acompanhar](docs/prototipo/4b_camera_acompanhar.png)
![Câmera frente](docs/prototipo/4d_camera_frente.png)
![Câmera aérea](docs/prototipo/4e_camera_aerea.png)
![Chegada](docs/prototipo/5_chegada.png)

## Outras ferramentas

- `tools/`: simulador de corrida e gerador do elenco em Python (ver [corrida.md](docs/corrida.md) §9).
- `visualizador/`: visualizador da corrida no navegador.
- MCPs do [Godot](docs/mcp-godot.md) e do [Blender](docs/mcp-blender.md) para o Claude Code.
