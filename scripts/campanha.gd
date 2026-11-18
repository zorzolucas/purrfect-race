class_name Campanha
extends RefCounted
## Campanha única de cada garota (docs/campanhas.md): 8 objetivos, capítulos de história,
## ponto de virada depois do GP do ano 2 e 2 caminhos com objetivo 7, GP final e final próprios.
## As 6 do MVP estão escritas em data/campanhas.json; as outras 42 são montadas aqui a partir
## do arquétipo e da casa (§4).

const ORDEM := ["sprint", "milha", "media", "longa"]
const TURNO_VIRADA := 48


static func _dados() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Dados")


## Monta a campanha resolvida: objetivos com distância, piso, meta, rival, nome e texto.
static func montar(nome: String, estilo: String, aptidao: Dictionary, distancia: String, piso: String, semente: int) -> Dictionary:
	var dd := _dados()
	var dados: Dictionary = dd.campanhas
	var base: Dictionary
	var modelo := false
	if dados.mvp.has(nome):
		base = dados.mvp[nome]
	else:
		var arq_id: String = dados.arquetipo_por_garota.get(nome, _arquetipo_padrao(estilo))
		base = _do_arquetipo(dados.arquetipos[arq_id], distancia, piso)
		base.arquetipo = arq_id
		modelo = true
	var ctx := {"nome": nome, "estilo": estilo, "aptidao": aptidao, "distancia": distancia, "piso": piso,
		"semente": semente, "modelo": modelo}
	var c := {
		"tema": base.get("tema", ""),
		"arquetipo": base.get("arquetipo", ""),
		"rival": rival_da_casa(distancia, piso, nome),
		"objetivos": base.objetivos.map(func(o): return resolver(o, ctx)),
		"capitulos": base.capitulos.duplicate(true),
		"virada": base.virada.duplicate(true),
		"caminhos": {},
	}
	for k in ["A", "B"]:
		var cam: Dictionary = base.caminhos[k].duplicate(true)
		cam.objetivos = cam.objetivos.map(func(o): return resolver(o, ctx))
		c.caminhos[k] = cam
	return c


static func _arquetipo_padrao(estilo: String) -> String:
	return {"pon": "competitiva", "per": "estrategista", "arr": "estrela", "fec": "sonhadora"}[estilo]


## Os 6 objetivos até o GP do ano 2 de uma garota do modelo (campanhas.md §4.1).
static func _do_arquetipo(a: Dictionary, distancia: String, piso: String) -> Dictionary:
	var nome_cometa := "Prêmio Cometa" if distancia == "milha" and piso == "grama" else ""
	var obj5 := {"turno": 40, "cat": "ouro", "onde": "casa", "meta": {"max": 3}}
	if nome_cometa != "":
		obj5.nome = nome_cometa
	return {
		"tema": a.tema,
		"objetivos": [
			{"turno": 13, "cat": "estreia", "onde": "casa", "meta": {"max": 5}},
			a.obj2.duplicate(true),
			{"turno": 24, "cat": "gp1", "onde": "casa", "meta": {"max": 5}},
			a.obj4.duplicate(true),
			obj5,
			{"turno": 48, "cat": "gp2", "onde": "casa", "meta": {"max": 3}},
		],
		"capitulos": a.capitulos,
		"virada": a.virada,
		"caminhos": a.caminhos,
	}


## Distância vizinha: Sprint vai para a Milha, Longa para a Média, o resto para a mais longa.
static func vizinha(distancia: String) -> String:
	var i := ORDEM.find(distancia)
	return ORDEM[i + 1] if i < 3 else ORDEM[2]


static func outro_piso(piso: String) -> String:
	return "terra" if piso == "grama" else "grama"


## Rival da campanha numa casa: a rival com nome, se houver, ou a campeã da casa (§4.3).
static func rival_da_casa(distancia: String, piso: String, jogadora: String) -> String:
	var dd := _dados()
	var com_nome: String = dd.calendario.rivais_gp.get("%s_%s" % [distancia, piso], "")
	if com_nome != "":
		return com_nome
	return campea_da_casa(distancia, piso, jogadora)


## A garota do elenco da mesma casa com maior soma de atributos, sem contar a jogadora.
static func campea_da_casa(distancia: String, piso: String, jogadora: String) -> String:
	var dd := _dados()
	var casa := [ORDEM.find(distancia), ["grama", "terra"].find(piso)]
	var melhor := ""
	var soma_melhor := -1.0
	for g in dd.garotas:
		if g.nome == jogadora or int(g.casa[0]) != casa[0] or int(g.casa[1]) != casa[1]:
			continue
		var s := 0.0
		for k in g.atributos:
			s += g.atributos[k]
		if s > soma_melhor:
			soma_melhor = s
			melhor = g.nome
	return melhor


static func resolver(o: Dictionary, ctx: Dictionary) -> Dictionary:
	var dd := _dados()
	var cal: Dictionary = dd.calendario
	var r := o.duplicate(true)
	var turno: int = r.turno
	if not r.has("dist"):
		var d: String = ctx.distancia
		var p: String = ctx.piso
		match r.get("onde", "casa"):
			"vizinha": d = vizinha(d)
			"outro_piso":
				p = outro_piso(p)
				if ctx.aptidao[p] == "R":  # outro piso Ruim: vira "fora de casa" (§4.1)
					p = ctx.piso
					d = vizinha(ctx.distancia)
		# A Fechadora de Longa corria o ano 1 na Média (§4.2) até a v0.6: com o GP do ano 1 na Média,
		# a Misteriosa (só Fechadoras) completava 10 pontos acima dos outros arquétipos.
		r.dist = d
		r.piso = p
	r.erase("onde")
	var meta: Dictionary = r.meta
	# Fechadora de Sprint: Estreia com top 3 (§4.2). A Ponteira de Longa saiu da exceção na v0.4:
	# com top 3 a Estreia derrubava 29% delas.
	if ctx.modelo and turno == 13 and ctx.estilo == "fec" and ctx.distancia == "sprint":
		meta.max = 3
	r.meta = int(meta.get("max", 0))
	if meta.has("maratona"):
		r.maratona = int(meta.maratona)
	var rival = meta.get("rival", false)
	if rival is String:
		r.rival = rival
		r.meta_rival = true
	elif rival:
		r.rival = rival_da_casa(r.dist, r.piso, ctx.nome)
		r.meta_rival = true
	elif r.cat.begins_with("gp"):
		r.rival = rival_da_casa(r.dist, r.piso, ctx.nome)
	r.dificil = r.meta == 1
	r.id = "obj%d" % turno
	if not r.has("nome"):
		match r.cat:
			"estreia": r.nome = cal.nome_estreia
			"gp1", "gp2", "gp3": r.nome = cal.nome_gp[int(r.cat.substr(2)) - 1]
			_:
				var rng := Calendario.rng(int(ctx.semente), ["objetivo", turno])
				var nomes: Array = cal.nomes_corrida.get(r.cat, ["Corrida"])
				r.nome = nomes[rng.randi() % nomes.size()]
	r.texto = texto_meta(r)
	return r


## Texto curto da meta: "Top 3", "Vencer", "À frente de Polaris", "2 corridas com top 5"...
static func texto_meta(o: Dictionary) -> String:
	var partes := []
	if o.has("maratona"):
		partes.append("%d corridas com top %d desde o objetivo anterior" % [o.maratona, o.meta])
	elif o.meta == 1:
		partes.append("Vencer")
	elif o.meta > 0:
		partes.append("Top %d" % o.meta)
	if o.get("meta_rival", false):
		partes.append("à frente de %s" % o.rival if not partes.is_empty() else "Chegar à frente de %s" % o.rival)
	return " e ".join(partes)


## A condição de virada é verdadeira para esta carreira? (campanhas.md §5.5)
static func avaliar(cond: Dictionary, c) -> bool:
	if cond.has("ou"):
		return cond.ou.any(func(x): return avaliar(x, c))
	if cond.has("e"):
		return cond.e.all(func(x): return avaliar(x, c))
	if cond.has("venceu"):
		return c.resultados.any(func(r): return r.objetivo > 0 and int(r.turno) in cond.venceu.map(func(t): return int(t)) and r.posicao == 1)
	if cond.has("top"):
		var t: int = int(cond.top[0])
		return c.resultados.any(func(r): return r.objetivo > 0 and r.turno == t and r.posicao <= int(cond.top[1]))
	if cond.has("flag"):
		return cond.flag in c.flags
	if cond.has("sem_lesao_desde"):
		return c.ultima_lesao < int(cond.sem_lesao_desde)
	if cond.has("saidas_min"):
		return c.saidas >= int(cond.saidas_min)
	if cond.has("fama_min"):
		return c.fama >= int(cond.fama_min)
	if cond.has("vitorias_min"):
		return c.resultados.filter(func(r): return r.posicao == 1).size() >= int(cond.vitorias_min)
	if cond.has("viradas_min"):
		return c.viradas >= int(cond.viradas_min)
	if cond.has("festivais_min"):
		return c.nos_visitados("festival") >= int(cond.festivais_min)
	if cond.has("distancias_top3_min"):
		var d3 := {}
		for r in c.resultados:
			if r.has("dist") and r.posicao <= 3:
				d3[r.dist] = true
		return d3.size() >= int(cond.distancias_top3_min)
	if cond.has("distancias_min"):
		var ds := {}
		for r in c.resultados:
			if r.has("dist"):
				ds[r.dist] = true
		return ds.size() >= int(cond.distancias_min)
	push_error("Condição de virada desconhecida: %s" % cond)
	return false
