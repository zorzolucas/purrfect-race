extends SceneTree
## Confere a integridade dos JSON de data/: campos obrigatórios, ids únicos e referências
## entre arquivos (colegas, rivais, habilidades, amuletos, campanhas, encontros e calendário).
## Pega erro de digitação nos dados antes de ele virar erro no meio de uma carreira.
## Uso: Godot --headless --path . --script res://testes/teste_dados.gd
var falhas := []

const ESTILOS := ["pon", "per", "arr", "fec"]
const DISTS := ["sprint", "milha", "media", "longa"]
const PISOS := ["grama", "terra"]
const NOTAS_APT := ["R", "O", "B", "X"]
## Chaves de efeito que Carreira.escolher entende (além dos 5 atributos).
const EFEITOS := ["humor", "energia", "afinidade", "nivel_treino", "fama", "serra", "pontos",
	"habilidade", "amuleto", "unico_garantido", "flag", "perde_turno"]


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _ids_unicos(lista: Array, onde: String) -> Dictionary:
	var vistos := {}
	for x in lista:
		_checar(x.has("id"), "%s sem id: %s" % [onde, x])
		_checar(not vistos.has(x.get("id")), "%s com id repetido: %s" % [onde, x.get("id")])
		vistos[x.get("id")] = x
	return vistos


func _escolhas(e: Dictionary, onde: String, dd: Node) -> void:
	var esc: Array = e.get("escolhas", [])
	_checar(not esc.is_empty(), "%s sem escolhas" % onde)
	for s in esc:
		_checar(s.has("texto") and s.has("resultado") and s.has("efeitos"), "%s: escolha incompleta" % onde)
		for chave in ["efeitos", "efeitos_falha"]:
			for k in s.get(chave, {}):
				_checar(k in EFEITOS or k in SimCorrida.KEYS, "%s: efeito desconhecido %s" % [onde, k])
			var hab = s.get(chave, {}).get("habilidade", null)
			if hab != null:
				_checar(not dd.habilidade(str(hab)).is_empty(), "%s: habilidade inexistente %s" % [onde, hab])
		if s.has("chance"):
			_checar(float(s.chance) > 0.0 and float(s.chance) < 1.0, "%s: chance fora de (0, 1)" % onde)


func _initialize() -> void:
	var dd: Node = root.get_node("Dados")
	if dd.garotas.is_empty():
		dd._ready()

	# elenco
	var nomes := {}
	for g in dd.garotas:
		var n: String = g.get("nome", "?")
		_checar(not nomes.has(n), "garota repetida: %s" % n)
		_checar(not " " in n, "nome com sobrenome (os saves usam só o primeiro nome): %s" % n)
		nomes[n] = true
		_checar(g.get("estilo", "") in ESTILOS, "%s: estilo inválido" % n)
		for k in SimCorrida.KEYS:
			var v = g.atributos.get(k, -1)
			_checar(v is float and v > 0.0 and v < 1200.0, "%s: atributo %s inválido" % [n, k])
		for k in DISTS + PISOS:
			_checar(g.aptidao.get(k, "") in NOTAS_APT, "%s: aptidão %s inválida" % [n, k])
		_checar(g.casa.size() == 2 and int(g.casa[0]) in range(4) and int(g.casa[1]) in range(2), "%s: casa inválida" % n)
		_checar(not dd.config_carreira(n).is_empty(), "%s: sem configuração de carreira" % n)
	_checar(dd.garotas.size() == 48, "elenco com %d garotas (esperava 48)" % dd.garotas.size())
	var mvp: Array = dd.garotas.filter(func(g): return g.get("mvp", false)).map(func(g): return g.nome)

	# iniciais (as 6 do MVP)
	for ini in dd.iniciais:
		var n: String = ini.nome
		_checar(nomes.has(n), "inicial fora do elenco: %s" % n)
		_checar(n in mvp, "inicial sem mvp: true no elenco: %s" % n)
		_checar(ini.get("distancia", "") in DISTS and ini.get("piso", "") in PISOS, "%s: casa inválida" % n)
		for k in ini.get("naturais", []):
			_checar(k in SimCorrida.KEYS, "%s: treino natural inválido %s" % [n, k])
		var u: String = ini.get("unica", "")
		_checar(u == "" or SimCorrida.UNICAS.has(u), "%s: única desconhecida %s" % [n, u])
		_checar(dd.campanhas.mvp.has(n), "%s: sem campanha escrita" % n)

	# rivais com nome
	for r in dd.rivais:
		_checar(r.get("estilo", "") in ESTILOS, "rival %s: estilo inválido" % r.nome)
		var u: String = r.get("unica", "")
		_checar(u == "" or SimCorrida.UNICAS.has(u), "rival %s: única desconhecida %s" % [r.nome, u])
	var rivais: Array = dd.rivais.map(func(r): return r.nome)
	for casa in dd.calendario.rivais_gp:
		_checar(dd.calendario.rivais_gp[casa] in rivais, "rivais_gp: %s não está em rivais.json" % casa)

	# habilidades
	var habs := _ids_unicos(dd.habilidades.lista, "habilidade")
	for h in dd.habilidades.lista:
		_checar(int(h.fase) in range(4), "habilidade %s: fase inválida" % h.id)
		_checar(h.tipo in ["vel", "hp"], "habilidade %s: tipo inválido" % h.id)
		_checar(int(h.custo) > 0, "habilidade %s: sem custo" % h.id)
	for id in dd.habilidades.iniciais:
		_checar(habs.has(id), "habilidade inicial inexistente: %s" % id)
	for cat in dd.calendario.categorias:
		_checar(dd.habilidades.pontos_por_categoria.has(cat), "pontos_por_categoria sem %s" % cat)

	# amuletos
	_ids_unicos(dd.amuletos.lista, "amuleto")
	for a in dd.amuletos.lista:
		_checar(dd.amuletos.peso_tipo.has(a.tipo), "amuleto %s: tipo sem peso" % a.id)
		_checar(not a.has("estilo") or a.estilo in ESTILOS, "amuleto %s: estilo inválido" % a.id)
		_checar(a.has("nome") and a.has("descricao") and a.has("efeito"), "amuleto %s incompleto" % a.id)
	_checar(int(dd.amuletos.limite) > 0, "limite de amuletos")

	# encontros
	var enc: Dictionary = dd.encontros
	for colega in enc.colegas:
		_checar(nomes.has(colega), "colega fora do elenco: %s" % colega)
	for quem in enc.afinidade_inicial:
		_checar(nomes.has(quem), "afinidade_inicial de quem não existe: %s" % quem)
		for colega in enc.afinidade_inicial[quem]:
			_checar(colega in enc.colegas, "afinidade_inicial com quem não é colega: %s" % colega)
	_ids_unicos(enc.encontros, "encontro")
	for e in enc.encontros:
		_checar(e.garota == null or nomes.has(e.garota), "encontro %s: garota desconhecida" % e.id)
		_escolhas(e, "encontro " + e.id, dd)

	# calendário
	var cal: Dictionary = dd.calendario
	_ids_unicos(cal.misterios, "mistério")
	for m in cal.misterios:
		_escolhas(m, "mistério " + m.id, dd)
	_escolhas(cal.vespera, "véspera", dd)
	for f in cal.fixas.lista:
		_checar(cal.categorias.has(f.cat), "fixa %s: categoria inválida" % f.nome)
		_checar(f.dist in DISTS and f.piso in PISOS, "fixa %s: casa inválida" % f.nome)
		_checar(int(f.turno_ano) >= 1 and int(f.turno_ano) <= 24, "fixa %s: turno_ano inválido" % f.nome)
	for t in cal.trechos:
		var dur: int = int(t.turnos[1]) - int(t.turnos[0]) + 1
		_checar(dur == 2 * int(t.nos), "trecho %s: %d turnos para %d nós de 2 turnos" % [t.turnos, dur, t.nos])
		for tipo in t.get("sem", []):
			_checar(cal.nos.has(tipo), "trecho %s: tipo proibido desconhecido %s" % [t.turnos, tipo])
	for est in cal.chance_clima:
		for clima in cal.chance_clima[est]:
			_checar(cal.climas.has(clima), "clima desconhecido em %s: %s" % [est, clima])
	for est in cal.estacoes:
		_checar(cal.chance_clima.has(est), "estação sem chance de clima: %s" % est)
	for cat in ["aberta", "prata", "ouro", "desafio"]:
		_checar(not cal.nomes_corrida.get(cat, []).is_empty(), "sem nomes de corrida para %s" % cat)
	for d in DISTS:
		_checar(cal.distancia_gp.has(d), "distancia_gp sem %s" % d)

	# campanhas
	var camp: Dictionary = dd.campanhas
	for n in camp.arquetipo_por_garota:
		_checar(nomes.has(n), "arquetipo_por_garota: garota desconhecida %s" % n)
		_checar(camp.arquetipos.has(camp.arquetipo_por_garota[n]), "arquétipo desconhecido para %s" % n)
	for n in camp.mvp:
		_checar(nomes.has(n), "campanha de garota desconhecida: %s" % n)
	for g in dd.garotas:
		var ini: Dictionary = dd.config_carreira(g.nome)
		var c := Campanha.montar(g.nome, g.estilo, g.aptidao, ini.distancia, ini.piso, 1)
		for cap in c.capitulos:
			if cap.has("escolhas"):
				_escolhas(cap, "capítulo de %s" % g.nome, dd)
		for k in ["A", "B"]:
			var cam: Dictionary = c.caminhos[k]
			_checar(cam.has("nome") and cam.has("final") and cam.has("capitulo"), "%s: caminho %s incompleto" % [g.nome, k])
			if cam.capitulo.has("escolhas"):
				_escolhas(cam.capitulo, "capítulo do caminho %s de %s" % [k, g.nome], dd)

	print("DADOS OK" if falhas.is_empty() else "DADOS FALHOU (%d): %s" % [falhas.size(), "; ".join(falhas.slice(0, 20))])
	quit(0 if falhas.is_empty() else 1)
