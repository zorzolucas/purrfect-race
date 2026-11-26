# Web e celular: escala, layouts e o que falta

Como o jogo se ajusta ao tamanho da tela no navegador (desktop e celular), o que foi
medido em cada resolução e o que ainda vale fazer. Código: `scripts/escala.gd`,
`scripts/main.gd` (escala, rolagem e camada), `scripts/toque_rolagem.gd` (toque) e os
ramos `UI.em_pe()` das telas.

## 1. O problema do print (altura cortada)

O projeto usa stretch `canvas_items` + aspect `expand` com base 1280x720. Numa janela mais
larga que 16:9 (o navegador tira a barra de abas e a do Windows), o canvas lógico fica com
720 px de altura e o resto vira largura. A tela de turno pedia **~760 px** de altura (palco
da garota + painel do turno + faixa de atributos), então a faixa de atributos saía da tela.
Isso acontecia em quase todo notebook: 1366x768 no Chrome (viewport ~1366x657), 1920x1080
com escala de 125%/150%, monitores 1600x900.

## 2. Como ficou

**Três modos** (`Escala.calcular`), decididos pelo tamanho em px CSS (janela ÷ devicePixelRatio):

| Modo | Quando | Base lógica | Rolagem |
|---|---|---|---|
| `desktop` | qualquer janela que não seja celular | 1280x720 | só se encolher demais |
| `paisagem` | celular deitado (altura CSS < 600 com toque) | altura ~480-720 | a tela inteira rola |
| `retrato` | em pé (largura < altura e < 1000 px CSS) | largura ~460-720 | a tela inteira rola |

**Caber na tela** (`main._caber`): depois de montar cada tela, mede o mínimo que ela pede e,
se não couber, aumenta a base (tudo encolhe junto). Na largura sempre (não há rolagem para o
lado); na altura até 1,4x no desktop (encolher até ~71%), 1,12x deitado e nada em pé. O que
sobrar vira rolagem: a tela atual fica dentro de um `ScrollContainer` no Main.

**Camada por cima** (`main.camada`, `UI.camada(no)`): guia e janela de detalhes vão para uma
camada do tamanho da tela visível, fora da rolagem.

**Celular girou**: se o modo muda, a tela atual é refeita no layout novo (o guia aberto fica).

**Toque** (`ToqueRolagem`): o `ScrollContainer` do Godot só rola pelo dedo se o toque começa
num espaço vazio; com botões embaixo não rolava. Agora arrastar rola a lista sob o dedo
(com inércia), e o botão desiste do clique. Segurar o dedo ~0,5 s num controle mostra a dica
dele (os `tooltip_text`, que no toque não apareciam). As plaquinhas de tecla (1, D, F1, Esc)
somem no celular.

**Página web** (`export_presets.cfg`): PWA ligado (dá para "Adicionar à tela inicial" e jogar
sem a barra do navegador, o que ganha ~100 px de altura no iPhone), `theme-color`, sem
seleção de texto, sem "puxar para recarregar" e sem o menu de toque longo do iOS.

## 3. Medido em cada resolução (desktop)

Viewport real do navegador (descontando abas, barra de endereço e barra de tarefas):

| Tela / escala | Viewport CSS | Antes | Depois |
|---|---|---|---|
| 1366x768, 100% | 1366x657 | atributos cortados na tela de turno | cabe, encolhe ~5% |
| 1600x900, 100% (print) | 1600x770 | atributos cortados | cabe |
| 1920x1080, 100% | 1920x969 | atributos cortados | cabe |
| 1920x1080, 125% | 1536x739 | atributos cortados | cabe |
| 1920x1080, 150% | 1280x595 | atributos cortados | cabe |
| 1440x900 (Mac) | 1440x789 | atributos cortados | cabe |

Capturas antes/depois de cada uma na pasta do projeto `web-celular/`.

### Melhorias de UI/UX no desktop (mapa)

Feitas neste PR:
- Altura cabendo em qualquer proporção (seção 2).
- Treino um pouco mais baixo (150 → 136 px) e "Outras ações" 86 → 72 px: o Descansar aparece
  sem rolar o painel em 16:9 quando não há corridas no turno.

Sugeridas (não feitas):
1. **Descansar sempre à vista**: com corridas no turno, o painel da direita ainda rola e o
   Descansar fica embaixo. Dá para pôr "Outras ações" numa coluna fina à direita do treino
   ou fixar a linha de ações embaixo do painel.
2. **Telas muito largas (21:9, 1920x969 já é ~2:1)**: sobra largura; o palco da garota poderia
   crescer junto, ou os cartões de treino ganharem o ícone grande.
3. **Tela cheia na tela de turno**: o botão existe só na academia (F11 funciona em qualquer tela).
4. **Hover nos cartões de corrida**: mostrar o relatório do olheiro resumido sem precisar
   entrar na corrida.
5. **Zoom do navegador (Ctrl +/-)**: já funciona (o Godot recebe o novo tamanho), mas o texto
   não cresce, só o espaço. Uma opção "Tamanho do texto" nas configurações ajudaria quem joga
   em monitor grande longe da tela.

## 4. Celular

Foco nos aparelhos de 2023 em diante. Viewport CSS útil com o navegador aberto:

| Aparelho | Em pé | Deitado | Texto do corpo (16 px lógicos) em pé |
|---|---|---|---|
| iPhone 15 / 16 | 393x659 | 760x340 | ~13 px CSS |
| iPhone 16/17 Pro Max | 440x760 | 850x370 | ~13 px |
| Galaxy S23/S24/S25 | 360x660 | 740x300 | ~12,5 px |
| Pixel 8/9/10 | 412x780 | 830x340 | ~13 px |
| Galaxy A54/A55 | 412x760 | 830x330 | ~13 px |

**Em pé é o jeito principal de jogar no celular** (como nos jogos do gênero). Cada tela tem
um ramo `UI.em_pe()`: uma coluna só, a tela inteira rola, botões com pelo menos 44 px de altura.
- Turno: topo em duas linhas (data e turno; trilha, clima, Guia e Academia), a garota num
  cartão deitado com energia, humor e aptidões, os 5 atributos compactos logo abaixo e a
  decisão do turno. Treinos em 5 colunas com nome curto.
- Corrida: pista 3D em cima, classificação embaixo (rola sozinha), botão único de câmera.
- Academia, pool, madrinha, circuito: cartões em uma coluna, botões do topo numa grade.
- Fim, guia (capítulos numa lista de escolha), pátio (conversa embaixo, garota grande some).

**Deitado** funciona com o layout do desktop rolando inteiro (atributos sobem para o topo),
mas o texto fica pequeno (~9-10 px CSS). Aparece uma dica, uma vez, sugerindo girar o celular.

**Safe areas**: a página não usa `viewport-fit=cover`, então o Safari já deixa o canvas fora do
entalhe e da barra do iPhone; nada do jogo fica embaixo deles. No modo PWA a barra de status
fica por cima do fundo da página (cor do tema).

### Ainda vale fazer no celular

1. **Testar num aparelho de verdade** (iPhone e um Android médio): desempenho da corrida 3D
   (no celular a corrida já usa MSAA 2x em vez de 4x), memória do Safari
   com os modelos 3D e a inércia da rolagem.
2. **Treino em pé com detalhe ao tocar**: hoje o cartão mostra tudo em 13 px. Um toque poderia
   selecionar e mostrar o detalhe grande embaixo, e o segundo toque confirma.
3. **Deitado de verdade**: um layout próprio (palco menor, atributos na lateral) para caber sem
   rolar, ou travar em pé na PWA (`progressive_web_app/orientation=2`).
4. **Teclado virtual**: não há campo de texto hoje; se entrar nome de jogadora, ligar
   `html/experimental_virtual_keyboard`.
5. **Fonte maior opcional** (acessibilidade): uma escala extra sobre a base do modo.

## 5. Testes e capturas

- `testes/teste_escala.gd`: modos e bases para cada aparelho/navegador da tabela, limites do
  "caber" e se as telas em pé cabem na largura.
- `teste_telas` também roda com `ESCALA_MODO=retrato` ou `paisagem` (e `ESCALA_TOQUE=1`).
- Capturas em qualquer tamanho: `CAPTURA_PASTA=res://testes/capturas/x ESCALA_DPR=2
  ESCALA_TOQUE=1 xvfb-run ... --resolution 786x1320 --script res://testes/capturas.gd`
  (786x1320 com DPR 2 = iPhone 15 em pé). Telas que rolam também salvam `*_inteira.png`.
- `testes/estouro.gd` ganhou `largos()`: lista o que obriga a tela em pé a encolher.
