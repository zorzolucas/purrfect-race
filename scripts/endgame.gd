class_name Endgame
extends RefCounted
## Regras do endgame (docs/campanhas.md §2.3), com os números em data/endgame.json:
## - Magnitude 0 a 5 por garota (calendario.md §10): força das NPCs, maldições, metas e mapa.
## - Circuito em níveis (GDD §7): 5 copas e o Campeonato Final em Bronze, Prata e Ouro,
##   corridos com as versões salvas do elenco e decididos por pontos contra 3 casas rivais.
## - Desafio da semana: uma carreira com semente, garota e regra fixas por rotação da pool.
## Tudo é estático e determinístico: a mesma semente dá o mesmo resultado.


static func _dados() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Dados")


static func eg() -> Dictionary:
	return _dados().endgame


static func _rng(contexto: Array) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(["endgame"] + contexto)
	return r


# ---------- Magnitude (calendario.md §10) ----------

static func _mag(campo: String, m: int) -> Variant:
	var lista: Array = eg().magnitude[campo]
	return lista[clampi(m, 0, lista.size() - 1)]


static func mag_max() -> int:
	return int(eg().magnitude.max)


## Multiplicador da força de todas as NPCs.
static func forca_npc(m: int) -> float:
	return float(_mag("forca_npc", m))


## Multiplicador extra das rivais com nome, em relação ao normal (+25% em vez de +15% = ×1,087).
static func extra_rival(m: int) -> float:
	return float(_mag("forca_rival", m)) / float(_mag("forca_rival", 0))


static func n_maldicoes(m: int) -> int:
	return int(_mag("maldicoes", m))


static func descricao_magnitude(m: int) -> String:
	return eg().magnitude.descricao[clampi(m, 0, mag_max())]


## Tudo o que a magnitude m acumula, em uma linha por nível (para a tela de escolha).
static func resumo_magnitude(m: int) -> String:
	if m <= 0:
		return descricao_magnitude(0)
	var partes := []
	for i in range(1, m + 1):
		partes.append("M%d: %s" % [i, descricao_magnitude(i)])
	return "\n".join(partes)


## Sorteia n maldições diferentes com a semente da carreira.
static func sortear_maldicoes(semente: int, n: int) -> Array:
	var ids: Array = eg().maldicoes.map(func(x): return x.id)
	var r := _rng(["maldicao", semente])
	var escolhidas := []
	for i in mini(n, ids.size()):
		escolhidas.append(ids.pop_at(r.randi() % ids.size()))
	return escolhidas


## Magnitude 3: cada meta sobe um degrau (top 5 → top 3, top 3 → vencer). Mexe no objetivo.
static func subir_meta(o: Dictionary) -> void:
	var meta := int(o.get("meta", 0))
	if meta <= 1:
		return
	o.meta = maxi(1, meta - 2)
	o.dificil = o.meta == 1
	o.texto = Campanha.texto_meta(o)


## Aplica a subida de meta em todos os objetivos da campanha, inclusive os dos 2 caminhos.
static func subir_metas(campanha: Dictionary) -> void:
	for o in campanha.get("objetivos", []):
		subir_meta(o)
	for k in campanha.get("caminhos", {}):
		for o in campanha.caminhos[k].get("objetivos", []):
			subir_meta(o)


## Magnitude 5: tira 1 nó de Recuperação do mapa do trecho (vira Treino focado).
static func tirar_recuperacao(mapa: Array, semente: int, trecho: int) -> void:
	var lugares := []
	for i in mapa.size():
		for col in mapa[i].size():
			if mapa[i][col].tipo == "recuperacao":
				lugares.append([i, col])
	if lugares.is_empty():
		return
	var r := _rng(["recuperacao", semente, trecho])
	var l: Array = lugares[r.randi() % lugares.size()]
	mapa[l[0]][l[1]] = {"tipo": "foco", "foco": SimCorrida.KEYS[r.randi() % 5]}


## Bônus de moeda no fim da carreira (+20% por nível).
static func mult_moeda(m: int) -> float:
	return 1.0 + float(eg().magnitude.moeda_por_nivel) * m


# ---------- Desafio da semana ----------

static func regra(id: String) -> Dictionary:
	for r in eg().desafio.regras:
		if r.id == id:
			return r
	return {}


## O desafio da rotação "giro" do perfil. A semente não usa o perfil: na mesma rotação,
## todo jogador recebe a mesma garota, a mesma regra e o mesmo mapa (semente fixa).
## As regras giram em ordem embaralhada por ciclo, para nunca repetir a da semana anterior.
static func desafio_da_semana(giro: int) -> Dictionary:
	var dd := _dados()
	var regras: Array = eg().desafio.regras
	var n := regras.size()
	var ciclo := giro / n
	var ordem := range(n)
	var r := _rng(["desafio_ordem", ciclo])
	for i in range(n - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = ordem[i]
		ordem[i] = ordem[j]
		ordem[j] = tmp
	# a 1ª do ciclo nunca é igual à última do ciclo anterior
	if ciclo > 0:
		var anterior: Array = range(n)
		var ra := _rng(["desafio_ordem", ciclo - 1])
		for i in range(n - 1, 0, -1):
			var j := ra.randi() % (i + 1)
			var tmp = anterior[i]
			anterior[i] = anterior[j]
			anterior[j] = tmp
		if ordem[0] == anterior[-1]:
			var tmp = ordem[0]
			ordem[0] = ordem[1]
			ordem[1] = tmp
	var rg := _rng(["desafio_garota", giro])
	var nomes: Array = dd.garotas.map(func(g): return g.nome)
	var semente := absi(hash(["desafio", giro])) % 2000000000 + 1
	return {"semana": giro + 1, "semente": semente, "garota": nomes[rg.randi() % nomes.size()],
		"regra": regras[ordem[giro % n]]}


## Pontuação de uma carreira de desafio, para comparar tentativas: objetivos, depois
## vitória no GP final, depois fama.
static func placar_desafio(c) -> Dictionary:
	return {"objetivos": c.objetivos_cumpridos(), "gp": c.venceu_gp(), "fama": c.fama,
		"nota": Dados.nota(c.attrs)}


static func placar_melhor(a: Dictionary, b: Dictionary) -> bool:
	if b.is_empty():
		return true
	if int(a.objetivos) != int(b.objetivos):
		return int(a.objetivos) > int(b.objetivos)
	if bool(a.gp) != bool(b.gp):
		return bool(a.gp)
	return int(a.fama) > int(b.fama)


static func texto_placar(p: Dictionary) -> String:
	if p.is_empty():
		return "sem resultado ainda"
	return "%d/8 objetivos%s · fama %d · nota %s" % [int(p.objetivos), " · GP vencido" if p.gp else "", int(p.fama), p.nota]


# ---------- Circuito (GDD §7) ----------

static func niveis() -> Array:
	return eg().circuito.niveis


## As 5 copas e o Campeonato Final, nessa ordem.
static func eventos() -> Array:
	var lista: Array = eg().circuito.copas.duplicate()
	lista.append(eg().circuito.final)
	return lista


static func evento(id: String) -> Dictionary:
	for e in eventos():
		if e.id == id:
			return e
	return {}


static func chave(nivel: int, id: String) -> String:
	return "%s:%s" % [niveis()[nivel].id, id]


## Condições da semana de cada corrida de um evento: clima e traçado. Mudam a cada rotação
## da pool e são iguais para todo jogador na mesma rotação. É o que evita uma escalação
## "certa" para sempre: cada traçado favorece outro estilo ou atributo (docs/campanhas.md §2.3).
static func condicoes(giro: int, id: String) -> Array:
	var cfg: Dictionary = eg().circuito
	var ev := evento(id)
	var lista := []
	for i in ev.corridas.size():
		var r := _rng(["condicao", giro, id, i])
		var clima := Calendario.sortear_peso(r, cfg.clima)
		var pesos := {}
		for t in cfg.tracados:
			pesos[t.id] = float(t.get("peso", 1))
		lista.append({"clima": clima, "tracado": Calendario.sortear_peso(r, pesos)})
	return lista


static func tracado(id: String) -> Dictionary:
	for t in eg().circuito.tracados:
		if t.id == id:
			return t
	return {}


## Aplica o traçado na pista: muda a física da corrida para todas igualmente, mas cada
## mudança deixa outro atributo mais valioso (docs/endgame.md §3.4):
## folego (×fôlego máximo: Estamina), acel (×aceleração: Poder), bloqueio (×chance de
## bloqueio: Poder e Inteligência) e teto (×velocidade máxima: corta o valor da Velocidade).
static func aplicar_pista(sim: SimCorrida, t: Dictionary) -> void:
	var ef: Dictionary = t.get("efeito", {})
	sim.mult_acel *= float(ef.get("acel", 1.0))
	sim.mult_bloqueio *= float(ef.get("bloqueio", 1.0))
	var folego := float(ef.get("folego", 1.0))
	var folego_dist := float(ef.get("folego_dist", 1.0))
	var teto := float(ef.get("teto", 1.0))
	var teto_abs := float(ef.get("teto_abs", 0.0)) * SimCorrida.V0 * SimCorrida.ESCALA
	for r in sim.rs:
		# folego_dist só mexe na parte do fôlego que vem da distância: sobra a da Estamina
		r.hpmax = (r.hpmax - SimCorrida.K_HP_D * sim.D * (1.0 - folego_dist)) * folego
		r.hp = r.hpmax
		r.vmax *= teto
		if teto_abs > 0.0:
			r.vmax = minf(r.vmax, teto_abs)


## Parte do traçado que mexe na corredora (por estilo ou atributo). Vale igual para a
## jogadora e para as NPCs.
static func aplicar_tracado(corredora: Dictionary, t: Dictionary) -> void:
	var ef: Dictionary = t.get("efeito", {})
	var por_estilo: Dictionary = ef.get("estilo", {})
	corredora.mult = float(corredora.mult) * float(por_estilo.get(corredora.estilo, 1.0))
	var por_attr: Dictionary = ef.get("attr", {})
	for k in por_attr:
		corredora.attrs[k] = float(corredora.attrs[k]) * float(por_attr[k])


## Corredora da jogadora a partir da versão salva (atributos, habilidades e aptidões).
static func corredora_salva(nome: String, salva: Dictionary, corrida: Dictionary, instrucao: String = "normal") -> Dictionary:
	var dd := _dados()
	var g: Dictionary = dd.garota(nome)
	var cfg: Dictionary = dd.config_carreira(nome)
	var apt: Dictionary = salva.get("aptidao", g.aptidao)
	var attrs := {}
	for k in SimCorrida.KEYS:
		attrs[k] = float(salva.attrs[k])
	var habs: Array = salva.get("habilidades", dd.habilidades.get("iniciais", []))
	return {
		"nome": nome, "estilo": g.estilo, "attrs": attrs,
		"mult": Dados.APT[apt[corrida.dist]] * Dados.APT[apt[corrida.piso]],
		"unica": cfg.get("unica", ""), "jogadora": true, "instrucao": instrucao,
		"habilidades": habs.map(func(id): return dd.habilidade(id)).filter(func(h): return not h.is_empty()),
	}


## NPC com o perfil da garota escalado para a média pedida (igual a Carreira._adversaria).
static func corredora_npc(g: Dictionary, media: float, corrida: Dictionary) -> Dictionary:
	var soma := 0.0
	for k in SimCorrida.KEYS:
		soma += g.atributos[k]
	var a := {}
	for k in SimCorrida.KEYS:
		a[k] = g.atributos[k] * media * 5.0 / soma
	return {"nome": g.nome, "estilo": g.estilo, "attrs": a,
		"mult": Dados.APT[g.aptidao[corrida.dist]] * Dados.APT[g.aptidao[corrida.piso]],
		"unica": "", "jogadora": false}


## Quem cada casa rival escala em cada corrida do evento: as garotas que melhor combinam
## com a corrida, sem repetir dentro do evento e sem usar as da jogadora.
## Devolve [corrida][casa] = nome.
static func escalacao_casas(giro: int, id: String, excluir: Array) -> Array:
	var dd := _dados()
	var ev := evento(id)
	var n_casas: int = eg().circuito.casas.size()
	var usadas := excluir.duplicate()
	var r := _rng(["casas", giro, id])
	var lista := []
	for corrida in ev.corridas:
		var cand: Array = dd.garotas.filter(func(g): return not g.nome in usadas)
		# melhor aptidão primeiro; o desempate é sorteado, para as casas variarem por semana
		var notas := {}
		for g in cand:
			notas[g.nome] = Dados.APT[g.aptidao[corrida.dist]] * Dados.APT[g.aptidao[corrida.piso]] + r.randf() * 0.01
		cand.sort_custom(func(a, b): return notas[a.nome] > notas[b.nome])
		var da_corrida := []
		for i in n_casas:
			da_corrida.append(cand[i].nome)
			usadas.append(cand[i].nome)
		lista.append(da_corrida)
	return lista


## Monta o pelotão de uma corrida do circuito: a jogadora (índice 0), uma corredora de
## cada casa (índices 1..3) e avulsas até 12.
static func montar_corrida(nivel: int, giro: int, id: String, i: int, minha: Dictionary,
		casas: Array, excluir: Array, seed_: int) -> Dictionary:
	var dd := _dados()
	var cfg: Dictionary = eg().circuito
	var ev := evento(id)
	var corrida: Dictionary = ev.corridas[i]
	var cond: Dictionary = condicoes(giro, id)[i]
	var forca: float = float(cfg.niveis[nivel].forca)
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_, "pelotao", i])
	var field := [minha.duplicate(true)]
	var fc: Array = cfg.forca_casa
	for nome in casas[i]:
		field.append(corredora_npc(dd.garota(nome), forca * r.randf_range(fc[0], fc[1]), corrida))
	var fora := excluir.duplicate()
	for linha in casas:
		fora.append_array(linha)
	var avulsas: Array = dd.garotas.filter(func(g): return not g.nome in fora)
	for k in range(avulsas.size() - 1, 0, -1):
		var j := r.randi() % (k + 1)
		var tmp = avulsas[k]
		avulsas[k] = avulsas[j]
		avulsas[j] = tmp
	var fa: Array = cfg.forca_avulsa
	for g in avulsas.slice(0, 12 - field.size()):
		field.append(corredora_npc(g, forca * r.randf_range(fa[0], fa[1]), corrida))
	var t := tracado(cond.tracado)
	for c in field:
		aplicar_tracado(c, t)
	return {"field": field, "metros": float(corrida.metros), "clima": cond.clima,
		"seed": hash([seed_, "corrida", i]), "corrida": corrida, "condicao": cond, "tracado": t}


static func pontos(posicao: int) -> int:
	var tabela: Array = eg().circuito.pontos
	return int(tabela[posicao - 1]) if posicao <= tabela.size() else 0


## Corre um evento inteiro. escalacao: [{nome, salva, instrucao}] na ordem das corridas.
## Devolve {corridas: [{posicao, ordem, nomes, pontos_casas}], total, casas: [pts], venceu}.
static func correr_evento(nivel: int, giro: int, id: String, escalacao: Array, seed_: int) -> Dictionary:
	var ev := evento(id)
	var meus: Array = escalacao.map(func(x): return x.nome)
	var casas := escalacao_casas(giro, id, meus)
	var n_casas: int = casas[0].size()
	var total := 0
	var pts_casas := []
	pts_casas.resize(n_casas)
	pts_casas.fill(0)
	var corridas := []
	var soma_pos := 0
	var soma_pos_casas := []
	soma_pos_casas.resize(n_casas)
	soma_pos_casas.fill(0)
	for i in ev.corridas.size():
		var e: Dictionary = escalacao[i]
		var minha := corredora_salva(e.nome, e.salva, ev.corridas[i], e.get("instrucao", "normal"))
		var m := montar_corrida(nivel, giro, id, i, minha, casas, meus, seed_)
		var sim := SimCorrida.new(m.field, m.metros, m.seed, m.clima)
		aplicar_pista(sim, m.tracado)
		var ordem: Array = sim.rodar_ate_o_fim()
		var pos: int = ordem.find(0) + 1
		total += pontos(pos)
		soma_pos += pos
		var pc := []
		for c in n_casas:
			var p_c: int = ordem.find(c + 1) + 1
			pts_casas[c] += pontos(p_c)
			soma_pos_casas[c] += p_c
			pc.append(p_c)
		corridas.append({"posicao": pos, "posicoes_casas": pc, "ordem": ordem,
			"nomes": m.field.map(func(x): return x.nome), "condicao": m.condicao,
			"metros": m.metros, "corrida": m.corrida})
	# vence com mais pontos que cada casa; no empate, a menor soma de colocações
	var venceu := true
	for c in n_casas:
		if pts_casas[c] > total or (pts_casas[c] == total and soma_pos_casas[c] <= soma_pos):
			venceu = false
	return {"corridas": corridas, "total": total, "casas": pts_casas, "venceu": venceu,
		"escalacao_casas": casas}


## Prêmio em moeda: cheio na 1ª vitória; nas outras, uma fração, uma vez por rotação.
static func premio(nivel: int, id: String, primeira: bool) -> int:
	var cfg: Dictionary = eg().circuito
	var p: float = float(cfg.niveis[nivel].premio)
	if id == "final":
		p *= float(cfg.premio_final)
	if not primeira:
		p *= float(cfg.premio_repeticao)
	return roundi(p)
