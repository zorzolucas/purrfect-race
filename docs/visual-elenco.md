# Nekomusume — Visual e personalidade do elenco

> Versão 0.1 — 2026-11-17. Complementa o [elenco](elenco.md), as [campanhas](campanhas.md) e a direção de arte do [GDD](GDD.md) §11.
> Aqui cada uma das **48 garotas** e das **2 rivais** ganha signo, aniversário, pelagem, corpo, orelhas, rabo, cabelo e uma personalidade própria. As 6 do MVP e as rivais têm ficha completa. As outras 42 têm ficha curta, presa ao arquétipo de campanha delas ([campanhas](campanhas.md) §5.6).

---

## 1. Regras

Decididas com o Lucas em 2026-11-17.

| Tema | Regra |
|---|---|
| **Signo** | Exatamente **4 garotas por signo** (12 × 4 = 48), escolhido pela personalidade. As rivais têm signo fora da conta. Dentro de um mesmo arquétipo, nenhum signo se repete. |
| **Pelagem** | **23 pelagens** de gatos de verdade (§2). Cada uma aparece **no máximo 3 vezes**, nunca duas vezes na mesma casa, e cada garota tem **uma marca própria** que a separa das outras da mesma pelagem. A personalidade puxa o temperamento popular daquela pelagem. |
| **Orelhas e rabo** | **Formato próprio por garota**: tamanho, ponta, tufo, dobra, comprimento, volume e postura. Os ossos são os mesmos (GDD §11.2), só a malha muda. |
| **Corpo** | **3 alturas** (baixa, média, alta) × **2 portes** (esguia, atlética), só com escala de ossos na base única. A silhueta ajuda a ler o estilo: velocistas tendem a atléticas, fundistas a esguias, mas há exceções de propósito. |
| **Efeito do signo** | **Aniversário** e **afinidade leve** (§3). Não mexe em atributos, então o balanceamento das campanhas continua valendo. |

**O que torna cada garota única:** nenhuma outra tem a mesma combinação de pelagem + marca, e cada uma tem pelo menos 3 destes itens diferentes de qualquer outra: cabelo, orelhas, rabo, olhos e corpo. A tabela do §6 serve para conferir.

**Fama popular, não ciência:** o temperamento das pelagens vem do que os donos de gato dizem ("gato laranja é bagunceiro", "tricolor tem gênio"). É folclore e funciona como tempero de personagem, não como regra.

---

## 2. As 23 pelagens

As cores são da **textura de paleta** (GDD §11.2): base, secundária e detalhe. Os olhos ficam na ficha de cada garota.

| # | Pelagem | Fama popular | Paleta (base · secundária · detalhe) | Garotas |
|---|---|---|---|---|
| 1 | **Laranja rajada** | Sociável, gulosa, corajosa, "um neurônio só", dorme em qualquer lugar | `#E8833A` · `#B8541E` · `#F6D2A8` | Lira, Maia, Columba |
| 2 | **Cinza-azulada** (tipo azul-russo) | Quieta com estranhos, leal a poucos, gosta de rotina | `#7D8A99` · `#5E6976` · `#B9C4CF` | Nashira, Vela, Naos |
| 3 | **Frajola** (preto e branco) | Parece de smoking, mas é a palhaça da casa; esperta e imprevisível | `#1E1E24` · `#F4F4F0` · `#3A3A44` | Mira, Tucana |
| 4 | **Siamesa** (corpo claro, pontas escuras) | Tagarela, dramática, exige atenção, muito apegada | `#EFE2C8` · `#4A3426` · `#C9B08A` | Capela, Adara |
| 5 | **Tricolor** (branco, laranja e preto) | Geniosa, independente, "dá sorte" | `#F7F3EC` · `#E07A2F` · `#26201E` | Antares, Electra |
| 6 | **Preta** | Misteriosa e "de azar" para os supersticiosos; na verdade a mais carinhosa | `#17151A` · `#2E2A33` · `#4B4552` | Shaula, Bellatrix |
| 7 | **Branca** | Calma, elegante, distante; a de olho azul tem fama de "não ouvir" | `#F8F8F6` · `#DADBDF` · `#B7B9C0` | Polaris, Saiph, Albireo |
| 8 | **Tigrada cinza** (listras finas) | Gato de rua: esperta, desconfiada, sobrevivente | `#8E8C88` · `#3F3D3B` · `#C8C4BC` | Algol, Mintaka |
| 9 | **Escaminha** (preto e ruivo mesclados) | "Atitude de escaminha": temperamental, intensa, imprevisível | `#2A1D18` · `#B5521F` · `#6E3A22` | Hidra, Mizar |
| 10 | **Rajada marrom clássica** (espirais) | O gato comum mais gente boa: amigável, confiável | `#8A6A4A` · `#3E2C1F` · `#C9AD8A` | Deneb, Fênix |
| 11 | **Bicolor van** (branca, cor só na cabeça e no rabo) | Brincalhona e, rara entre gatos, gosta de água | `#F6F4EF` · *cor da marca* · `#D8D2C8` | Zaniah, Carina |
| 12 | **Abissínia** (pelo "salpicado" cor de areia) | Atleta hiperativa, curiosa, nunca fica no colo | `#B98A55` · `#6E4B2A` · `#E2C9A0` | Altair, Auriga, Avior |
| 13 | **Pintada** (rosetas de leopardo) | Energia selvagem, adora água e escalar | `#C99A55` · `#3B2817` · `#F0DDB5` | Elnath, Andrômeda |
| 14 | **Fumaça** (escura por fora, prata na raiz) | Parece uma coisa e é outra; surpreende quando se mexe | `#26252B` · `#A9A9B1` · `#4A4950` | Zosma, Mirach |
| 15 | **Prata rajada** | Elegante e vaidosa | `#C9CBCF` · `#2F3033` · `#ECEDEF` | Cassiopeia, Achernar |
| 16 | **Creme** (laranja diluído) | Doce, preguiçosa, apegada ao conforto | `#F0D9B5` · `#D9B98A` · `#FBF0DE` | Dubhe, Mimosa |
| 17 | **Chocolate** (marrom sólido) | Grudenta, brincalhona, falante | `#5A3826` · `#3B2418` · `#8A5E44` | Alhena, Celeno |
| 18 | **Tricolor diluída** (cinza, creme e branco) | Mais doce que a tricolor, mas com opinião firme | `#F4F1EC` · `#9AA3B0` · `#E9CFA6` | Alya, Hamal, Alcione |
| 19 | **Ponta de chama** (creme com pontas ruivas) | Carinhosa e falante, como a siamesa, mas mais calma | `#F5E9D6` · `#D9772E` · `#E9B985` | Spica, Ankaa |
| 20 | **Chinchila dourada** (pelo longo, pontas escuras) | Majestosa, mimada, não gosta de bagunça | `#E8C98A` · `#6A4E2A` · `#F7E8C4` | Almach, Corona |
| 21 | **Pontas rajadas** (corpo claro, pontas listradas) | Curiosa como a siamesa e independente como a rajada | `#EDE4D6` · `#7A6A5A` · `#B3A390` | Alcor, Nunki |
| 22 | **Escaminha rajada** (escaminha com listras) | Gênio da escaminha com a paciência da rajada | `#7A5236` · `#C4672B` · `#3A281C` | Mérope, Alnair |
| 23 | **Arlequim** (quase toda branca, poucas manchas grandes) | Reservada e formal, de "boa família" | `#F7F6F2` · `#1C1B1F` · `#CFCBC3` | Atria |

---

## 3. Signos no jogo

### 3.1 Distribuição

| Signo | Elemento | Traço usado | Garotas |
|---|---|---|---|
| ♈ Áries | Fogo | Impulso, coragem, pressa | **Antares**, Altair, Hamal, Mizar |
| ♉ Touro | Terra | Constância, teimosia, conforto | Elnath, Alnair, Mimosa, Alcione |
| ♊ Gêmeos | Ar | Conversa, duas caras, curiosidade | Albireo, Celeno, Alhena, Avior |
| ♋ Câncer | Água | Cuidado, saudade, casa | Alya, Vela, Dubhe, Ankaa |
| ♌ Leão | Fogo | Palco, orgulho, generosidade | **Capela**, Columba, Corona, Tucana |
| ♍ Virgem | Terra | Método, detalhe, servir | **Nashira**, Saiph, Spica, Mérope |
| ♎ Libra | Ar | Charme, harmonia, indecisão | Deneb, Cassiopeia, Adara, Zaniah |
| ♏ Escorpião | Água | Intensidade, segredo, lealdade | **Shaula**, Electra, Hidra, Bellatrix |
| ♐ Sagitário | Fogo | Otimismo, aventura, franqueza | **Lira**, Nunki, Achernar, Maia |
| ♑ Capricórnio | Terra | Disciplina, ambição, frieza | Almach, Mintaka, Naos, Atria |
| ♒ Aquário | Ar | Excentricidade, ideias, distância | Alcor, Andrômeda, Auriga, Mirach |
| ♓ Peixes | Água | Sonho, empatia, fuga | **Mira**, Fênix, Carina, Zosma |

Rivais: **Polaris** é ♑ Capricórnio e **Algol** é ♊ Gêmeos.

Algumas escolhas vêm do céu de verdade: **Shaula** e **Antares** são estrelas da constelação de Escorpião (a Shaula ficou com o signo, a Antares é a ariana que "rouba" o coração do escorpião), **Spica** fica em Virgem, **Elnath** em Touro, **Nunki** em Sagitário, **Zosma** em Leão (ela é pisciana de propósito: a leoa que preferiu o mar) e **Hamal** em Áries.

### 3.2 Aniversário

- Cada garota tem uma **data de aniversário** dentro do signo. O turno é o meio mês da data (dia 1–15 = Início, 16–31 = Fim).
- Se cair durante a carreira dela, no começo daquele turno acontece o encontro **"Feliz aniversário"**: +1 nível de humor e uma escolha de presente com 2 opções (inicial: +afinidade grande ou um item pequeno). Acontece 1 vez por ano, até 3 vezes na carreira.
- Se for o aniversário de **outra garota do elenco**, ela aparece no pátio com um balão. Clicar abre um encontro curto (inicial: +5 de afinidade com ela).
- A **Nashira** "lembra o aniversário de todo mundo" (elenco): quando ela é a garota da carreira, o jogador recebe aviso 1 turno antes de cada aniversário.

### 3.3 Afinidade por elemento

- Garotas do **mesmo elemento** começam com **+5 de afinidade** (inicial).
- Soma com as afinidades especiais do elenco (+20 de amizade, −10 de atrito). Exemplo: Lira e Antares são de fogo e amigas, então começam com +25. Lira e Shaula começam com −10 (fogo e água não somam nada).
- Fogo: Áries, Leão, Sagitário. Terra: Touro, Virgem, Capricórnio. Ar: Gêmeos, Libra, Aquário. Água: Câncer, Escorpião, Peixes.

---

## 4. Fichas do MVP e das rivais

Formato: signo e aniversário, pelagem e marca, corpo, cabelo, olhos, orelhas, rabo, roupa e detalhe, linguagem do corpo, personalidade, como a pelagem e o signo aparecem, e uma fala.

### 4.1 Lira — "a chama da largada"

| | |
|---|---|
| **Signo** | ♐ Sagitário · aniversário 2/dez (Dezembro · Início) |
| **Pelagem** | Laranja rajada. **Marca:** o "M" das rajadas desenhado na franja, com listras mais escuras |
| **Corpo** | Média, atlética |
| **Cabelo** | Curto e repicado, espetado atrás como se ela tivesse acabado de correr. Listras laranja-escuras nas mechas |
| **Olhos** | Verde-claro, grandes, sempre bem abertos |
| **Orelhas** | Médias, pontudas, quase sempre viradas para frente. A esquerda tem um **pequeno entalhe** na ponta, de uma corrida de infância em que ela caiu na cerca |
| **Rabo** | Grosso, com anéis laranja-escuros e ponta clara. Fica em pé, curvado em ponto de interrogação |
| **Roupa e detalhe** | Munhequeira laranja e a jaqueta do treino sempre amarrada na cintura. Um curativo no joelho que nunca sai |
| **Linguagem do corpo** | Rabo em pé tremendo quando está animada. Orelhas para trás quando tem que esperar |

**Personalidade:** a energia do "gato laranja" em forma de gente. Barulhenta, gulosa, corajosa até a burrice e simpática com todo mundo. Desafia qualquer uma para uma corrida até o refeitório, come o dobro de todas e dorme em qualquer lugar depois do almoço, de preferência numa faixa de sol. Como sagitariana, é otimista, sincera demais e não aguenta rotina: fala antes de pensar e pede desculpa depois, com a mesma energia.

**Defeito:** impaciência. Odeia esperar e larga rápido demais quando está nervosa (combina com a afobação, GDD §5.5).

**Gostos:** peixe frito, apostas, o céu de dezembro.

> "Seis meses só treinando? Tá, mas e se eu correr só um pouquinho hoje?"

### 4.2 Nashira — "a estrategista"

| | |
|---|---|
| **Signo** | ♍ Virgem · aniversário 7/set (Setembro · Início) |
| **Pelagem** | Cinza-azulada. **Marca:** pontas do cabelo com **brilho prateado**, como o pelo do azul-russo na luz |
| **Corpo** | Alta, esguia |
| **Cabelo** | Chanel reto e liso, risca impecável de lado, uma presilha prateada |
| **Olhos** | Verde-esmeralda. Óculos redondos que ela usa só para ler o caderno |
| **Orelhas** | Grandes, finas e bem eretas, levemente abertas para os lados, como dois radares |
| **Rabo** | Longo, fino e liso. Quando ela escreve, ele se enrola no braço dela |
| **Roupa e detalhe** | O caderno de capa azul, com abas coloridas, e uma caneta presa na orelha de gato |
| **Linguagem do corpo** | Orelhas giram na direção de quem fala. Quando o plano muda, o rabo fica eriçado por um segundo e volta ao normal |

**Personalidade:** como um azul-russo, é reservada com quem não conhece e muito leal a poucas pessoas. Gosta de rotina e sente falta dela quando quebra. Como virginiana, é detalhista, crítica e quer ser útil: anota o tempo de todas as corredoras e o aniversário de todo mundo, e deixa bilhetes com dicas nos armários. Parece fria, mas é a primeira a perceber quando alguém está triste.

**Defeito:** trava quando o plano falha. Prefere refazer o plano a improvisar.

**Gostos:** chá, cadernos novos, silêncio na biblioteca.

> "Você largou 0,3 segundo atrasada. Não é crítica. É um dado. ...Tá bom, é um pouco crítica."

### 4.3 Mira — "a última a sair, a primeira a chegar"

| | |
|---|---|
| **Signo** | ♓ Peixes · aniversário 3/mar (Março · Início, o **primeiro turno** da carreira) |
| **Pelagem** | Frajola. **Marca:** a franja é **branca só do lado direito**, como a mancha assimétrica de muitos frajolas |
| **Corpo** | Baixa, esguia |
| **Cabelo** | Longo, preto, ondulado e meio bagunçado, com um fio arrepiado no topo que nunca abaixa |
| **Olhos** | Amarelo-dourado, enormes, quase sempre olhando para cima |
| **Orelhas** | Arredondadas e macias, pretas. Caem um pouco para os lados quando ela se distrai |
| **Rabo** | Longo e peludo, preto com a **ponta branca**. Arrasta no chão quando ela anda devagar |
| **Roupa e detalhe** | Casaco do uniforme grande demais, com as mangas cobrindo as mãos (parecem as "luvas" brancas do frajola). Uma presilha de peixinho |
| **Linguagem do corpo** | Orelhas caídas quando está nas nuvens. Na reta final, as duas orelhas viram para frente de uma vez e o rabo fica reto: é a "outra Mira" |

**Personalidade:** o frajola tem fama de parecer elegante de smoking e ser o mais avoado da casa. A Mira é isso: parece séria e fofa ao mesmo tempo, e se perde no caminho do treino seguindo um gato de verdade. Como pisciana, é sonhadora, sensível e foge da pressão para dentro da própria cabeça. Fala pouco e baixo, mas presta atenção em tudo que é bonito: nuvens, poças, o vento na grama. Quando a corrida aperta, a parte "esperta e imprevisível" do frajola aparece.

**Defeito:** distração. Esquece horários, esquece o lanche, esquece que é aniversário dela.

**Gostos:** nuvens com forma de bicho, peixe-dourado da fonte do pátio, deitar na grama.

> "Desculpa o atraso. Tinha um gato... e depois tinha uma nuvem igual ao gato."

**Gancho:** o aniversário dela é no turno 1 e ninguém sabe. Se o jogador sair com ela nesse turno, ela conta no fim do dia.

### 4.4 Capela — "a estrela do palco"

| | |
|---|---|
| **Signo** | ♌ Leão · aniversário 8/ago (Agosto · Início) |
| **Pelagem** | Siamesa (pontas castanho-escuras). **Marca:** o degradê do cabelo vai do creme ao **castanho quase preto** nas pontas, bem marcado |
| **Corpo** | Média, esguia |
| **Cabelo** | Longo, em duas mechas altas e volumosas presas com laços. O degradê aparece nas pontas |
| **Olhos** | Azul-safira, com cílios longos |
| **Orelhas** | Muito grandes e triangulares, de base larga, castanho-escuras |
| **Rabo** | Fino e longo como um chicote, ponta escura. Balança no ritmo de qualquer música |
| **Roupa e detalhe** | Uma presilha de estrela e um microfone de brinquedo no bolso. A roupa de corrida tem brilho nas mangas |
| **Linguagem do corpo** | Rabo dança com a música. Com plateia, as orelhas ficam em pé e o queixo sobe. Sem plateia, as orelhas caem |

**Personalidade:** a siamesa é a gata que mais "fala" e que exige atenção, e a Capela é exatamente isso: comenta tudo em voz alta, faz drama com uma unha quebrada e se apega muito às amigas. Como leonina, nasceu para o palco, é generosa com quem a admira e vaidosa sem pedir desculpa. Treina pouco sozinha e muito com plateia, porque precisa ser vista para acreditar em si.

**Defeito:** depende de aplauso para se sentir boa.

**Gostos:** dançar, fotos, fãs, sobremesas bonitas (que ela fotografa e não come).

> "Se ninguém viu, valeu? Valeu, né? ...Alguém viu?"

### 4.5 Antares — "a pancada"

| | |
|---|---|
| **Signo** | ♈ Áries · aniversário 10/abr (Abril · Início) |
| **Pelagem** | Tricolor. **Marca:** mechas em **blocos grandes**: laranja do lado esquerdo, preta do direito, branco no meio |
| **Corpo** | Baixa, atlética (a velocista compacta) |
| **Cabelo** | Curto e bagunçado, preso num coque pequeno atrás |
| **Olhos** | Âmbar |
| **Orelhas** | Pequenas e grossas, **uma laranja e uma preta** |
| **Rabo** | Curto e grosso, quase de gato de rabo curto, com a ponta preta |
| **Roupa e detalhe** | Esparadrapo no nariz, fita esportiva no tornozelo, garrafinha de água amassada |
| **Linguagem do corpo** | Rabo curto abana rápido quando ela ri. Antes da largada, as orelhas colam para trás e ela se agacha |

**Personalidade:** a tricolor tem fama de "gênio" e de independência, e também de trazer sorte (o gatinho da sorte que acena é tricolor). A Antares fala pouco, não pede ajuda e não aceita ordem que não entende. Como ariana, é impulsiva, direta e competitiva, e sempre a primeira a acordar e a primeira a largar. Ri alto quando ganha e some quando perde, para voltar no dia seguinte às 5h.

**Defeito:** não respeita o próprio limite (é a história da campanha dela).

**Gostos:** treino de madrugada, lanche escondido, corridas curtas.

> "Fala menos. Corre mais."

### 4.6 Shaula — "a sombra"

| | |
|---|---|
| **Signo** | ♏ Escorpião · aniversário 6/nov (Novembro · Início) |
| **Pelagem** | Preta. **Marca:** um **tufo branco escondido na nuca**, como o "botão" branco que muitos gatos pretos têm no peito. Ela esconde com o capuz |
| **Corpo** | Alta, esguia |
| **Cabelo** | Longo, liso e preto, com franja cobrindo o olho esquerdo |
| **Olhos** | Amarelo-ouro, intensos |
| **Orelhas** | Médias, quase sempre abertas para os lados ("orelha de avião", sinal de desconfiança). Argola prateada na orelha direita |
| **Rabo** | Muito longo e fino, com a **ponta curvada para cima**, como o ferrão do escorpião (o nome Shaula quer dizer "o ferrão") |
| **Roupa e detalhe** | Moletom velho de capuz da equipe de terra da cidade natal, com o número apagado |
| **Linguagem do corpo** | Orelhas de lado com estranhos. Com a Lira por perto, o rabo bate no chão de irritação. Sozinha na pista, o rabo relaxa |

**Personalidade:** o gato preto carrega fama de azar e de mistério, mas quem tem um sabe que é o mais carinhoso da casa. A Shaula é isso por dentro: sarcástica e fechada por fora, leal e cuidadosa por dentro. Como escorpiana, é intensa, guarda segredos e não esquece uma ofensa, nem um favor. É a última a sair da pista toda noite.

**Defeito:** orgulho. Prefere se machucar a admitir que precisa de alguém.

**Gostos:** pista vazia, rádio velho, cartas de casa (que ela lê escondida).

> "Não tô esperando ninguém. Só tô... aqui."

### 4.7 Polaris — "a campeã" (rival)

| | |
|---|---|
| **Signo** | ♑ Capricórnio · aniversário 3/jan (Janeiro · Início, nas férias) |
| **Pelagem** | Branca. **Marca:** pelo **sem nenhuma mancha** e olhos azul-gelo |
| **Corpo** | Alta, esguia |
| **Cabelo** | Longo e liso, preso num coque baixo elegante com dois fios soltos na frente |
| **Olhos** | Azul-gelo, calmos |
| **Orelhas** | Médias, perfeitamente eretas e **imóveis**. Ela controla as orelhas, então ninguém lê o humor dela |
| **Rabo** | Longo, sedoso, que se move devagar, sempre na mesma cadência |
| **Roupa e detalhe** | Uniforme da campeã com a estrela polar bordada no peito. Luvas brancas |
| **Linguagem do corpo** | Quase nenhuma. Quando ela perde, a ponta do rabo treme uma vez. É o único sinal |

**Personalidade:** a gata branca de olho azul tem fama de "não ouvir", e a Polaris não ouve provocação nenhuma. Como capricorniana, é disciplinada, ambiciosa e paciente. É educada com todas, elogia as novatas e vence sem levantar a voz. Por trás disso, carrega o medo de ser lembrada só como "a campeã do ano passado".

> "Boa corrida. Até a próxima."

### 4.8 Algol — "a provocadora" (rival)

| | |
|---|---|
| **Signo** | ♊ Gêmeos · aniversário 30/mai (Maio · Fim) |
| **Pelagem** | Tigrada cinza, de listras finas. **Marca:** a **ponta da orelha esquerda cortada reta**, como a marca dos gatos de rua castrados |
| **Corpo** | Baixa, esguia |
| **Cabelo** | Curto e desfiado, listrado, com presilhas tortas de tampinha de garrafa |
| **Olhos** | Verde-amarelado, semicerrados |
| **Orelhas** | Médias, viradas para frente quando ela provoca. A esquerda tem a ponta cortada |
| **Rabo** | Médio e listrado, sempre balançando de um lado para o outro, como quem desdenha |
| **Roupa e detalhe** | Jaqueta jeans por cima do uniforme, poeira de terra nas botas |
| **Linguagem do corpo** | Sorriso de canto com os caninos à mostra. Rabo para cima quando passa alguém |

**Personalidade:** a tigrada cinza é o gato de rua clássico: esperta, desconfiada e sobrevivente. A Algol cresceu no circuito de terra correndo contra quem fosse. Como geminiana, tem a língua rápida e duas caras: deboche em público, conselho honesto em particular (só para quem a vence).

> "Ih, a novata veio. Trouxe lencinho pra poeira?"

---

## 5. Fichas da pool (42)

Ficha curta: casa, estilo, arquétipo, signo e aniversário, visual em uma linha por parte, e personalidade. A personalidade segue o arquétipo da campanha ([campanhas](campanhas.md) §5) e se diferencia pelas outras do mesmo arquétipo com o signo e a pelagem.

### 5.1 Sprint Grama

**Altair** · Ponteira · Competitiva · ♈ Áries, 28/mar (Março · Fim)
- *Visual:* abissínia, **marca:** raiz do cabelo bem mais escura que as pontas. Alta, atlética. Cabelo curto jogado para trás pelo vento. Olhos verde-água. Orelhas grandes e altas, puxadas para trás como asas. Rabo longo e afilado, reto como uma flecha quando corre.
- *Personalidade:* a abissínia que nunca para quieta, com a pressa de Áries. Ao contrário da Lira, não faz barulho: compete contra o cronômetro e contra si mesma, fria e veloz. Sobe nos lugares mais altos da academia para olhar a pista. Quando perde, some por um dia inteiro. O nome é de uma estrela da Águia, e ela tem um chaveiro de pena.

**Electra** · Ponteira · Durona · ♏ Escorpião, 13/nov (Novembro · Início)
- *Visual:* tricolor, **marca:** mais preto que branco, com um raio laranja que desce pela franja. Média, atlética. Cabelo curto, raspado de um lado. Olhos verdes. Orelhas grandes e pontudas, com os pelos das pontas arrepiados. Rabo médio, sempre meio eriçado.
- *Personalidade:* o gênio da tricolor sem o riso da Antares. Tensa, silenciosa, esconde dor para não perder treino, e guarda o nome de quem a subestimou. Leal até o fim a quem conquista a confiança dela. Estala os dedos antes de largar.

**Spica** · Perseguidora · Leal · ♍ Virgem, 1/set (Setembro · Início)
- *Visual:* ponta de chama, **marca:** pontas do cabelo cor de trigo maduro. Baixa, esguia. Trança lateral em espiga com uma presilha de ramo de trigo. Olhos azuis. Orelhas médias com pontas ruivas. Rabo longo com a ponta ruiva.
- *Personalidade:* veio do interior e prometeu à avó que correria o Grande Prêmio. Trabalhadeira, educada, arruma o quarto de todo mundo. Falante e carinhosa como as ponta de chama, mas cobra demais de si por causa da promessa. O nome quer dizer "espiga".

**Adara** · Arrancadora · Estrela · ♎ Libra, 28/set (Setembro · Fim)
- *Visual:* siamesa de **pontas cinza-azuladas** (a Capela tem pontas castanhas). Alta, esguia. Cabelo curto e moderno, em degradê do creme ao cinza. Olhos azul-claro. Orelhas enormes. Rabo fino e muito longo.
- *Personalidade:* a Capela quer palco e canto, a Adara quer capa de revista. Tagarela como siamesa, mas com a elegância calculada de Libra: cada pose é pensada. Sonha em ser modelo. Tem medo de sair feia nas fotos de chegada.

**Maia** · Arrancadora · Festeira · ♐ Sagitário, 16/dez (Dezembro · Fim)
- *Visual:* laranja rajada, **marca:** a metade de baixo do cabelo é branca (laranja e branca). Média, esguia. Duas mechas baixas bagunçadas. Olhos amarelos. Orelhas grandes, viradas para frente. Rabo médio, em pé, com a ponta dobrada.
- *Personalidade:* o "gato laranja" da festa. A Lira compete, a Maia celebra. Chama todo mundo para tudo, come o bolo antes de cantar parabéns e chega atrasada em tudo. Sagitariana, otimista e sem filtro. É a "irmã mais velha" do dormitório das Plêiades (Maia, Alcione, Electra, Celeno e Mérope).

**Alcione** · Fechadora · Teimosa · ♉ Touro, 1/mai (Maio · Início)
- *Visual:* tricolor diluída, **marca:** quase toda creme, com só uma mecha cinza atrás da orelha. Média, atlética. Cabelo curto com franja reta. Olhos verdes. Orelhas médias, de pontas arredondadas. Rabo longo e liso.
- *Personalidade:* uma Fechadora numa casa de Sprint, porque decidiu que é assim e pronto. Taurina: calma, firme, impossível de convencer. Não discute, só não faz. Ama cochilo e não abre mão de dormir 9 horas.

### 5.2 Milha Grama

**Cassiopeia** · Perseguidora · Estrategista · ♎ Libra, 12/out (Outubro · Início)
- *Visual:* prata rajada, **marca:** listras escuras desenhando uma "coroa" no topo da cabeça. Alta, esguia. Cabelo longo, ondulado e sempre arrumado. Olhos verdes. Orelhas grandes e elegantes. Rabo longo com anéis prata e pretos.
- *Personalidade:* a Nashira lê dados, a Cassiopeia lê pessoas. Planeja a corrida pela psicologia das adversárias, com o charme de Libra. Vaidosa como a rainha do mito que deu nome a ela: se recusa a sujar o uniforme e quer vencer "com classe".

**Carina** · Fechadora · Sonhadora · ♓ Peixes, 10/mar (Março · Início)
- *Visual:* bicolor van, **marca:** a cor da cabeça e do rabo é **cinza-azulada**. Média, esguia. Cabelo longo e branco, com as mechas do topo cinza, presas com uma presilha de concha. Olhos azuis. Orelhas cinza, um pouco caídas. Rabo cinza, longo e anelado.
- *Personalidade:* a Mira se distrai, a Carina se apaixona. Romântica, escreve poemas sobre o mar e fala deles para quem quiser ouvir. Como as van, ama água e nada no lago da academia. Pisciana, melancólica em dias de chuva. O nome é a quilha de um navio.

**Vela** · Perseguidora · Leal · ♋ Câncer, 14/jul (Julho · Início)
- *Visual:* cinza-azulada, **marca:** uma mecha branca na franja (o "medalhão" branco no peito de alguns gatos cinza). Baixa, esguia. Cabelo curto com franja reta. Olhos verde-claro. Orelhas médias que caem para trás quando ela fica triste. Rabo médio e fino.
- *Personalidade:* tímida e apegada como uma azul-russo. Escreve cartas toda semana para a amiga de infância que virou rival. Canceriana: sentimental, ciumenta, guarda tudo (até a embalagem do primeiro chocolate que ganhou na academia).

**Auriga** · Arrancadora · Curiosa · ♒ Aquário, 28/jan (Janeiro · Fim)
- *Visual:* abissínia **canela** (avermelhada). Média, esguia. Cabelo curto e bagunçado, com óculos de aviador na cabeça. Olhos verdes. Orelhas enormes. Rabo longo e fino.
- *Personalidade:* inventora. Desmonta cronômetros, desenha mapas das pistas e testa teorias em si mesma. Abissínia curiosa com a cabeça de Aquário: tem uma ideia nova a cada 5 minutos e não termina nenhuma. O nome é o "cocheiro" do céu, e ela quer pilotar tudo.

### 5.3 Média Grama

**Alya** · Ponteira · Capitã · ♋ Câncer, 28/jun (Junho · Fim)
- *Visual:* tricolor diluída, **marca:** metade do rosto emoldurada por cinza e a outra por creme. Média, atlética. Cabelo médio, meio preso com um laço. Olhos castanho-mel. Orelhas médias e macias, uma creme e uma cinza. Rabo médio, que ela enrola nas novatas como um abraço.
- *Personalidade:* a "mãe" da casa. Carrega lanche extra na mochila, sabe quem está doente e quem brigou com quem. Doce como a tricolor diluída, mas firme quando precisa. Canceriana, protege todo mundo e esquece de si.

**Alcor** · Perseguidora · Estrategista · ♒ Aquário, 3/fev (Fevereiro · Início)
- *Visual:* pontas rajadas, **marca:** tufos de lince nas pontas das orelhas. Baixa, esguia. Cabelo creme com pontas cinza listradas, corte assimétrico. Olhos azul-claro. Orelhas médias com tufos. Rabo curto e anelado.
- *Personalidade:* a gênia esquisita. Calcula a corrida com física, ângulo de curva e vento. Esquece de comer. Aquariana distante, só se abre com a **Mizar**, a melhor amiga: as duas são uma estrela dupla de verdade e andam sempre juntas.

**Alhena** · Arrancadora · Festeira · ♊ Gêmeos, 25/mai (Maio · Fim)
- *Visual:* chocolate, **marca:** mãos e pés brancos, como luvas e meias. Alta, esguia. Cabelo longo e ondulado com um laço grande. Olhos dourados. Orelhas médias e arredondadas. Rabo longo e fofo.
- *Personalidade:* conhece todo mundo da academia e todas as fofocas. Grudenta e falante como os gatos chocolate. Geminiana: troca de assunto no meio da frase e não guarda segredo nenhum, mas sem maldade.

**Mizar** · Fechadora · Teimosa · ♈ Áries, 15/abr (Abril · Início)
- *Visual:* escaminha de **rosto dividido**: metade preta e metade ruiva, bem no meio. Média, atlética. Cabelo curto, metade preto e metade ruivo. Olhos laranja. Orelhas pontudas, uma preta e uma ruiva. Rabo médio mesclado.
- *Personalidade:* a resposta padrão é "não". A "atitude de escaminha" com o pavio curto de Áries. Briga com a treinadora, briga com a pista, mas defende a **Alcor** de qualquer um. As duas são a dupla Mizar e Alcor.

**Dubhe** · Fechadora · Sonhadora · ♋ Câncer, 20/jul (Julho · Fim)
- *Visual:* creme de pelo longo, **marca:** cabelo sempre amassado de um lado, como quem acabou de acordar. Alta, atlética (a "grandona fofa"). Cabelo longo e fofo, presilha de ursinho. Olhos cobre. Orelhas pequenas e arredondadas. Rabo grande e felpudo, que ela usa de travesseiro.
- *Personalidade:* dorminhoca, sonha acordada com comida. A Mira sonha com o céu, a Dubhe sonha com bolo. Creme preguiçosa e canceriana carinhosa: abraça forte demais. O nome é de uma estrela da Ursa Maior.

### 5.4 Longa Grama

**Almach** · Ponteira · Capitã · ♑ Capricórnio, 10/jan (Janeiro · Início)
- *Visual:* chinchila dourada, **marca:** contorno escuro nos olhos, como delineador natural. Alta, esguia. Cabelo longo, liso, dourado de pontas escuras, preso num coque alto e rígido. Olhos verde-azulados. Orelhas pequenas com tufos, viradas para frente. Rabo longo e muito peludo.
- *Personalidade:* presidente do grêmio. Majestosa e responsável, não gosta de bagunça nem de atraso. A Alya cuida, a Almach organiza. Capricorniana: cobra demais dos outros e mais ainda de si, e nunca pede ajuda.

**Elnath** · Ponteira · Competitiva · ♉ Touro, 5/mai (Maio · Início)
- *Visual:* pintada (rosetas), **marca:** as rosetas só aparecem nos ombros e nas pontas do cabelo. Alta, atlética. Cabelo longo e grosso numa trança única e pesada. Olhos verde-dourado. Orelhas pequenas de base larga. Rabo grosso e cilíndrico, ponta preta.
- *Personalidade:* competitiva de resistência: vence por insistência, não por explosão. Como as pintadas, adora água e bebe direto da torneira com as mãos. Taurina: constante, teimosa e rancorosa com quem a passou na última corrida. O nome é o "chifre" do Touro.

**Nunki** · Perseguidora · Perfeccionista · ♐ Sagitário, 10/dez (Dezembro · Início)
- *Visual:* pontas rajadas, **marca:** linhas escuras saindo dos olhos, como rímel. Alta, esguia. Cabelo longo preso alto com uma fita, sem um fio fora. Olhos azul-escuros. Orelhas altas com tufos curtos. Rabo longo, reto e anelado.
- *Personalidade:* arqueira nas horas vagas. Mira no recorde como mira no alvo. A franqueza de Sagitário vira autocrítica: "errei por 2 centímetros" é o pior dia da vida dela. Ri alto quando acerta, o que é raro.

**Ankaa** · Arrancadora · Curiosa · ♋ Câncer, 5/jul (Julho · Início)
- *Visual:* ponta de chama, **marca:** pontas ruivo-vivas, quase vermelhas. Média, esguia. Cabelo longo e solto, com pontas que parecem chamas. Olhos azuis. Orelhas pequenas. Rabo longo, de ponta ruiva em pluma.
- *Personalidade:* mudou de cidade 7 vezes e coleciona um chaveiro de cada lugar. Quer conhecer todas as pistas, mas, como canceriana, no fundo procura um lugar para chamar de casa (é a campanha da Curiosa). O nome é a fênix do céu.

**Zosma** · Fechadora · Misteriosa · ♓ Peixes, 25/fev (Fevereiro · Fim)
- *Visual:* fumaça, **marca:** a raiz prateada aparece quando o cabelo se mexe. Alta, esguia. Cabelo longo e preto, solto. Olhos cobre. Orelhas grandes. Rabo longo e esfumado.
- *Personalidade:* fala por enigmas e lê cartas de tarô no corredor. Como a fumaça, parece uma coisa e é outra. Pisciana intuitiva, acerta palpites demais e muda de assunto quando perguntam de onde veio. O nome é uma estrela de Leão, e ela diz que "a leoa preferiu o mar".

### 5.5 Sprint Terra

**Mintaka** · Ponteira · Durona · ♑ Capricórnio, 28/dez (Dezembro · Fim)
- *Visual:* tigrada cinza, **marca:** listras grossas e uma pinta branca no queixo. Baixa, atlética. Cabelo num rabo baixo, bem preso. Olhos amarelos. Orelhas pequenas e firmes. Rabo médio e listrado.
- *Personalidade:* treina como quem bate ponto. Veio de uma família de entregadores e acha que descanso é luxo. Capricorniana disciplinada, a Antares acorda às 5h, a Mintaka às 4h50. Usa um cinto de treino com 3 fivelas (Mintaka é uma das Três Marias).

**Mérope** · Perseguidora · Perfeccionista · ♍ Virgem, 28/ago (Agosto · Fim)
- *Visual:* escaminha rajada, **marca:** listras ruivas finas sobre o marrom. Baixa, atlética. Cabelo chanel curto, sem um fio fora. Olhos verde-amarelados. Orelhas médias. Rabo médio, sempre enrolado na mesma posição.
- *Personalidade:* cronômetro no pescoço, conta os passos. Virginiana ansiosa. No mito, Mérope é a irmã das Plêiades que "brilha menos", e ela sente que é a sombra das outras do dormitório. Melhora quando alguém repara no esforço dela.

**Celeno** · Arrancadora · Estrela · ♊ Gêmeos, 2/jun (Junho · Início)
- *Visual:* chocolate, **marca:** ponta do rabo e do cabelo mais clara, cor de café com leite. Baixa, esguia. Cabelo médio com duas tranças laterais e franja. Olhos verde-vivo. Orelhas médias, sempre se mexendo. Rabo médio.
- *Personalidade:* faz transmissão ao vivo de tudo, até do café da manhã. A Capela quer o palco, a Adara quer a capa, a Celeno quer os comentários. Grudenta e falante como os gatos chocolate, geminiana dispersa.

**Andrômeda** · Arrancadora · Festeira · ♒ Aquário, 10/fev (Fevereiro · Início)
- *Visual:* pintada **clara** (fundo marfim, rosetas castanhas). Alta, atlética. Cabelo curto e armado, com correntinhas de bijuteria (a princesa acorrentada do mito, que ela transformou em estilo). Olhos azuis. Orelhas pequenas de pontas pretas. Rabo longo e grosso.
- *Personalidade:* a DJ das festas, com playlists estranhas que todo mundo acaba amando. Aquariana excêntrica e rebelde: festa é também protesto contra o toque de recolher.

**Bellatrix** · Fechadora · Misteriosa · ♏ Escorpião, 20/nov (Novembro · Fim)
- *Visual:* preta, **marca:** uma cicatriz pequena na sobrancelha e olhos verdes (os da Shaula são amarelos). Média, atlética. Cabelo curto, raspado na nuca. Orelhas pequenas, quase sempre para trás. Rabo com uma **dobra** no meio, como os gatos de rabo quebrado.
- *Personalidade:* o nome quer dizer "guerreira". Silenciosa e intimidadora, ninguém sabe de onde veio a cicatriz. Escorpiana, desconfia de todo mundo, mas alimenta os gatos de rua atrás do refeitório toda noite.

### 5.6 Milha Terra

**Columba** · Ponteira · Competitiva · ♌ Leão, 27/jul (Julho · Fim)
- *Visual:* laranja rajada de **pelo longo**, com uma "gola" branca na nuca. Média, atlética. Cabelo cacheado e volumoso, como uma juba. Olhos cobre. Orelhas médias com tufos saindo de dentro. Rabo em pluma.
- *Personalidade:* a Lira corre para se divertir, a Columba corre pela família, dona de uma pista de terra no interior. Orgulhosa como leonina, sociável e gulosa como o "gato laranja". Não aceita ajuda. O nome é "pomba", e ela vive brigando, o que todo mundo acha engraçado.

**Fênix** · Perseguidora · Leal · ♓ Peixes, 17/mar (Março · Fim)
- *Visual:* rajada marrom clássica, **marca:** pontas avermelhadas, como brasa. Média, esguia. Cabelo longo e desfiado. Olhos âmbar. Orelhas médias com tufos internos. Rabo longo e peludo, ponta ruiva.
- *Personalidade:* voltou de uma lesão antes de entrar na academia e corre pela irmã mais nova, que ainda não pode correr. Amigável e confiável como a rajada clássica, pisciana que se sacrifica pelos outros e esquece de si.

**Corona** · Perseguidora · Perfeccionista · ♌ Leão, 15/ago (Agosto · Início)
- *Visual:* chinchila dourada **clara**, quase champanhe. Média, esguia. Cabelo longo e cacheado, com uma tiara. Olhos verdes. Orelhas pequenas com tufos dourados. Rabo peludo e dourado.
- *Personalidade:* filha de uma campeã famosa. Leonina orgulhosa e mimada, mas perfeccionista porque tem medo de não merecer o sobrenome que não usa. A Almach é rígida, a Corona é frágil por baixo da tiara.

**Hidra** · Arrancadora · Estrela · ♏ Escorpião, 30/out (Outubro · Fim)
- *Visual:* escaminha **mesclada fina** (a da Mizar é dividida ao meio). Alta, atlética. Cabelo longo e volumoso, com muitas camadas de preto e ruivo. Olhos laranja. Orelhas grandes. Rabo longo e grosso.
- *Personalidade:* a diva intensa, magnética e temida. "Atitude de escaminha" no volume máximo. Escorpiana, não perdoa crítica e lembra de cada uma. Tem uma persona diferente para cada câmera (a hidra de muitas cabeças).

**Zaniah** · Arrancadora · Festeira · ♎ Libra, 20/out (Outubro · Fim)
- *Visual:* bicolor van, **marca:** a cor da cabeça e do rabo é **ruiva**. Baixa, atlética. Cabelo branco com o topo ruivo, em dois coques. Olhos âmbar. Orelhas médias e ruivas. Rabo todo ruivo e anelado.
- *Personalidade:* a anfitriã das festas na piscina (como as van, ama água). Libriana: quer todo mundo feliz e foge de briga. A Andrômeda faz festa contra as regras, a Zaniah faz festa para todo mundo se dar bem.

**Tucana** · Fechadora · Teimosa · ♌ Leão, 5/ago (Agosto · Início)
- *Visual:* frajola, **marca:** "bigode" preto logo abaixo do nariz. Baixa, atlética. Cabelo preto com laterais brancas e um topete grande. Olhos verdes. Orelhas grandes e pretas. Rabo todo branco.
- *Personalidade:* a "palhaça esperta" do frajola com a voz alta de Leão. Faz tudo do jeito dela e diz "eu avisei" mesmo quando não avisou. A Mira é a frajola que sonha, a Tucana é a que grita. O nome é o tucano, e ela fala tanto quanto um.

### 5.7 Média Terra

**Deneb** · Ponteira · Capitã · ♎ Libra, 4/out (Outubro · Início)
- *Visual:* rajada marrom clássica, **marca:** a espiral de "borboleta" das rajadas clássicas desenhada no cabelo, atrás. Média, esguia. Cabelo médio e ondulado. Olhos verde-musgo. Orelhas médias de pontas arredondadas. Rabo longo e elegante com anéis largos (o nome quer dizer "cauda", do Cisne).
- *Personalidade:* a mediadora da turma. Amigável como a rajada, justa como Libra. Resolve as brigas dos outros e demora 10 minutos para escolher o sabor do sorvete.

**Albireo** · Perseguidora · Estrategista · ♊ Gêmeos, 8/jun (Junho · Início)
- *Visual:* branca com **heterocromia**: olho direito dourado e esquerdo azul, como a estrela dupla Albireo. Média, esguia. Cabelo médio repartido no meio, com duas presilhas de cores diferentes. Orelhas médias. Rabo longo e fino.
- *Personalidade:* sempre tem dois planos e discute com ela mesma em voz alta. Calma por fora como as brancas, geminiana por dentro. O risco dela é ficar presa entre o plano A e o plano B.

**Hamal** · Perseguidora · Leal · ♈ Áries, 5/abr (Abril · Início)
- *Visual:* tricolor diluída, **marca:** "máscara" cinza só sobre um olho. Baixa, atlética. Cabelo curto, cacheado e fofo. Olhos laranja. Orelhas pequenas, curvadas para trás como chifres de carneiro. Rabo curto e fofo.
- *Personalidade:* defensora impulsiva dos amigos. Leal ao extremo e cabeça quente como ariana: compra briga por quem ama. O nome é "a cabeça do carneiro", a estrela mais brilhante de Áries.

**Achernar** · Arrancadora · Estrela · ♐ Sagitário, 25/nov (Novembro · Fim)
- *Visual:* prata **pintada** (pintas em vez de listras). Média, atlética. Cabelo curto e espetado com gel. Olhos verde-água. Orelhas médias e pontudas. Rabo longo com a ponta preta.
- *Personalidade:* quer ser famosa no país inteiro, não só na academia. Faz "turnê" por todas as pistas e manda cartão-postal de cada uma. Sagitariana aventureira, vaidosa como a prata rajada, mas não se apega a lugar nenhum. O nome quer dizer "o fim do rio".

**Mimosa** · Fechadora · Sonhadora · ♉ Touro, 25/abr (Abril · Fim)
- *Visual:* creme, **marca:** rajado clarinho e nariz rosado. Baixa, esguia. Cabelo curto e ondulado com flores amarelas presas. Olhos verde-claro. Orelhas médias e macias. Rabo médio e enrolado.
- *Personalidade:* cuida da horta da academia e sonha com flores. Lenta para começar qualquer coisa, inclusive a corrida, e impossível de parar quando embala. Taurina sensorial: ama cheiro de terra molhada e comida caseira.

**Mirach** · Fechadora · Misteriosa · ♒ Aquário, 18/fev (Fevereiro · Fim)
- *Visual:* fumaça **azul** (cinza-azulado escuro com raiz prateada). Baixa, esguia. Cabelo médio e repicado, com uma mecha prateada aparecendo. Olhos laranja. Orelhas **dobradas para frente**. Rabo médio.
- *Personalidade:* vive no computador da biblioteca e sabe de coisas que não deveria. Aquariana distante, misteriosa por escolha: não confia em ninguém até a pessoa provar o contrário. A Zosma esconde o passado com mistério, a Mirach com senha.

### 5.8 Longa Terra

**Saiph** · Ponteira · Capitã · ♍ Virgem, 15/set (Setembro · Início)
- *Visual:* branca, **marca:** uma mancha cinza no topo da cabeça, o "boné" que alguns filhotes brancos têm. Alta, atlética. Cabelo curto e prático. Olhos dourados. Orelhas grandes, uma com mancha cinza. Rabo médio e reto.
- *Personalidade:* escoteira. Mochila com kit de primeiros socorros, mapa e lanterna. Calma como as brancas e útil como uma virginiana. A Nashira analisa, a Saiph resolve. Dá dicas que ninguém pediu.

**Alnair** · Ponteira · Durona · ♉ Touro, 14/mai (Maio · Início)
- *Visual:* escaminha rajada, **marca:** listras ruivas largas. Alta, atlética. Cabelo longo em duas tranças grossas. Olhos cobre. Orelhas médias e largas. Rabo médio, peludo e listrado.
- *Personalidade:* um "trator gentil". Força tranquila, fala pouco e ri baixo. Taurina, resiste a tudo e demora para mudar, inclusive quando o corpo pede descanso. A Antares é explosão, a Mintaka é disciplina, a Alnair é resistência.

**Naos** · Perseguidora · Estrategista · ♑ Capricórnio, 15/jan (Janeiro · Início)
- *Visual:* cinza-azulada de **pelo semi-longo**, **marca:** pontas mais claras, quase prata. Alta, esguia. Cabelo longo, preso num rabo baixo com uma fita. Olhos verdes. Orelhas grandes. Rabo muito peludo, como uma pluma.
- *Personalidade:* joga xadrez e pensa a carreira em 3 anos, não em 3 corridas. Capricorniana paciente e um pouco pessimista ("realista", ela diz). O nome quer dizer "navio", e ela fala como capitã de um.

**Avior** · Arrancadora · Curiosa · ♊ Gêmeos, 15/jun (Junho · Início)
- *Visual:* abissínia **azul** (cinza-bege). Baixa, atlética. Cabelo médio, preso alto com um lenço. Olhos dourados. Orelhas grandes com tufo curto. Rabo médio.
- *Personalidade:* mochileira. Pergunta "por quê?" para tudo e faz amizade com qualquer bicho. A Auriga explora com ferramentas, a Avior com conversa. Geminiana impaciente com explicação longa.

**Atria** · Fechadora · Misteriosa · ♑ Capricórnio, 18/jan (Janeiro · Fim)
- *Visual:* arlequim: quase toda branca, com **duas mechas pretas em bloco** no cabelo. Alta, esguia. Cabelo longo e liso. Olhos verdes. Orelhas uma branca e uma preta. Rabo todo preto.
- *Personalidade:* herdeira de uma família rica que fugiu para correr na terra. Formal, educada, fala como em jantar de gala. Capricorniana fria por fora. Esconde o sobrenome e cada carta de casa que recebe volta fechada.

---

## 6. Conferência de unicidade

| Garota | Signo | Pelagem · marca | Corpo | Cabelo | Orelhas | Rabo |
|---|---|---|---|---|---|---|
| Lira | Sagitário | Laranja rajada · "M" na franja | Média atlética | Curto repicado | Médias, entalhe | Grosso, anelado, em interrogação |
| Nashira | Virgem | Cinza-azulada · pontas prateadas | Alta esguia | Chanel reto | Grandes, radar | Longo fino liso |
| Mira | Peixes | Frajola · franja branca de um lado | Baixa esguia | Longo ondulado, fio arrepiado | Arredondadas, caídas | Longo peludo, ponta branca |
| Capela | Leão | Siamesa · pontas castanhas | Média esguia | Duas mechas altas | Muito grandes, base larga | Chicote, ponta escura |
| Antares | Áries | Tricolor · blocos grandes | Baixa atlética | Curto, coque pequeno | Pequenas grossas, 2 cores | Curto e grosso |
| Shaula | Escorpião | Preta · tufo branco na nuca | Alta esguia | Longo, franja no olho | Médias, de lado, argola | Muito longo, ponta em ferrão |
| Polaris | Capricórnio | Branca · sem manchas | Alta esguia | Coque baixo | Médias, imóveis | Longo sedoso |
| Algol | Gêmeos | Tigrada cinza · orelha cortada | Baixa esguia | Curto desfiado | Médias, ponta cortada | Médio, balançando |
| Altair | Áries | Abissínia · raiz escura | Alta atlética | Curto para trás | Grandes, como asas | Longo afilado |
| Electra | Escorpião | Tricolor · raio laranja | Média atlética | Raspado de um lado | Grandes, pontas arrepiadas | Médio eriçado |
| Spica | Virgem | Ponta de chama · cor de trigo | Baixa esguia | Trança em espiga | Médias, pontas ruivas | Longo, ponta ruiva |
| Adara | Libra | Siamesa · pontas azuladas | Alta esguia | Curto moderno | Enormes | Fino muito longo |
| Maia | Sagitário | Laranja rajada · metade branca | Média esguia | Duas mechas baixas | Grandes, para frente | Médio, ponta dobrada |
| Alcione | Touro | Tricolor diluída · quase creme | Média atlética | Curto com franja | Médias arredondadas | Longo liso |
| Cassiopeia | Libra | Prata rajada · coroa de listras | Alta esguia | Longo ondulado | Grandes elegantes | Longo anelado |
| Carina | Peixes | Van · cinza-azulada | Média esguia | Longo, presilha de concha | Cinza, caídas | Longo anelado cinza |
| Vela | Câncer | Cinza-azulada · mecha branca | Baixa esguia | Curto com franja | Médias, caem para trás | Médio fino |
| Auriga | Aquário | Abissínia · canela | Média esguia | Curto, óculos de aviador | Enormes | Longo fino |
| Alya | Câncer | Tricolor diluída · rosto em 2 cores | Média atlética | Médio meio preso | Médias, 2 cores | Médio, abraça |
| Alcor | Aquário | Pontas rajadas · tufos de lince | Baixa esguia | Assimétrico | Médias com tufos | Curto anelado |
| Alhena | Gêmeos | Chocolate · luvas brancas | Alta esguia | Longo, laço grande | Médias arredondadas | Longo fofo |
| Mizar | Áries | Escaminha · rosto dividido | Média atlética | Curto, 2 cores | Pontudas, 2 cores | Médio mesclado |
| Dubhe | Câncer | Creme · cabelo amassado | Alta atlética | Longo fofo | Pequenas arredondadas | Grande felpudo |
| Almach | Capricórnio | Chinchila dourada · delineado | Alta esguia | Coque alto rígido | Pequenas com tufos | Longo muito peludo |
| Elnath | Touro | Pintada · rosetas nos ombros | Alta atlética | Trança única | Pequenas, base larga | Grosso cilíndrico |
| Nunki | Sagitário | Pontas rajadas · rímel | Alta esguia | Preso alto com fita | Altas, tufos curtos | Longo reto anelado |
| Ankaa | Câncer | Ponta de chama · ruivo-vivo | Média esguia | Longo solto em chamas | Pequenas | Longo, pluma ruiva |
| Zosma | Peixes | Fumaça · raiz prata | Alta esguia | Longo preto solto | Grandes | Longo esfumado |
| Mintaka | Capricórnio | Tigrada cinza · pinta no queixo | Baixa atlética | Rabo baixo | Pequenas firmes | Médio listrado |
| Mérope | Virgem | Escaminha rajada · listras finas | Baixa atlética | Chanel curto | Médias | Médio enrolado |
| Celeno | Gêmeos | Chocolate · pontas café com leite | Baixa esguia | Duas tranças laterais | Médias, inquietas | Médio |
| Andrômeda | Aquário | Pintada clara | Alta atlética | Curto armado, correntes | Pequenas, pontas pretas | Longo grosso |
| Bellatrix | Escorpião | Preta · cicatriz, olho verde | Média atlética | Raspado na nuca | Pequenas, para trás | Com dobra |
| Columba | Leão | Laranja rajada · pelo longo, gola | Média atlética | Cacheado, juba | Médias com tufos | Pluma |
| Fênix | Peixes | Rajada marrom · pontas de brasa | Média esguia | Longo desfiado | Médias, tufos internos | Longo peludo, ponta ruiva |
| Corona | Leão | Chinchila dourada · champanhe | Média esguia | Longo cacheado, tiara | Pequenas, tufos dourados | Peludo dourado |
| Hidra | Escorpião | Escaminha · mescla fina | Alta atlética | Longo em camadas | Grandes | Longo grosso |
| Zaniah | Libra | Van · ruiva | Baixa atlética | Dois coques | Médias ruivas | Todo ruivo, anelado |
| Tucana | Leão | Frajola · bigode | Baixa atlética | Topete grande | Grandes pretas | Todo branco |
| Deneb | Libra | Rajada marrom · borboleta | Média esguia | Médio ondulado | Médias, pontas redondas | Longo, anéis largos |
| Albireo | Gêmeos | Branca · heterocromia | Média esguia | Repartido, 2 presilhas | Médias | Longo fino |
| Hamal | Áries | Tricolor diluída · máscara | Baixa atlética | Curto cacheado | Pequenas, curvas | Curto fofo |
| Achernar | Sagitário | Prata pintada | Média atlética | Curto espetado | Médias pontudas | Longo, ponta preta |
| Mimosa | Touro | Creme · nariz rosado | Baixa esguia | Curto ondulado, flores | Médias macias | Médio enrolado |
| Mirach | Aquário | Fumaça azul | Baixa esguia | Médio repicado | Dobradas | Médio |
| Saiph | Virgem | Branca · "boné" cinza | Alta atlética | Curto prático | Grandes, 1 mancha | Médio reto |
| Alnair | Touro | Escaminha rajada · listras largas | Alta atlética | Duas tranças grossas | Médias largas | Médio peludo listrado |
| Naos | Capricórnio | Cinza-azulada · semi-longo | Alta esguia | Rabo baixo com fita | Grandes | Pluma |
| Avior | Gêmeos | Abissínia · azul | Baixa atlética | Preso alto com lenço | Grandes, tufo curto | Médio |
| Atria | Capricórnio | Arlequim | Alta esguia | Longo, 2 mechas pretas | 1 branca, 1 preta | Todo preto |

**Corpos (50):** baixa esguia 8, baixa atlética 7, média esguia 9, média atlética 8, alta esguia 11, alta atlética 7 (contando as rivais). Dá variedade nas largadas sem nenhuma silhueta dominar.

---

## 7. Próximos passos

1. ~~**Dados:** levar signo, aniversário, pelagem, marca, corpo e as cores para `data/garotas.json`.~~ Feito em 2026-11-17: `tools/importar_visual.py` lê este documento e grava em cada garota (e nas rivais) `signo`, `elemento`, `aniversario` ([dia, mês]) e `visual` (`pelagem`, `paleta`, `marca`, `altura`, `porte`, `cabelo`, `olhos`, `orelhas`, `rabo`). O `tools/gerar_elenco.py` chama o importador no fim. **Este documento é a fonte:** mudou uma ficha, rode `python tools/importar_visual.py`. As variações descritas na ficha (ex.: siamesa de pontas azuladas, abissínia azul) trocam 1 ou 2 cores da paleta da pelagem.
2. **Protótipo:** encontro "Feliz aniversário" e o +5 de afinidade por elemento.
3. **Arte:** desenho de frente e perfil da garota de referência (GDD §11.4). Recomendo a **Lira**: tem pelagem rajada (testa listras na paleta), entalhe na orelha e rabo anelado, então valida as partes mais difíceis do pipeline de uma vez.
4. **Afinidades novas sugeridas** (para o elenco, se o Lucas quiser): Mizar e Alcor como dupla (+20), o dormitório das Plêiades (Maia, Alcione, Electra, Celeno e Mérope, +10 entre elas), e Shaula e Bellatrix (as duas pretas, atrito que vira respeito).
