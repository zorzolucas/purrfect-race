extends SceneTree
## Monta a campanha das 48 garotas e confere as regras de docs/campanhas.md: 6 objetivos nos
## turnos certos antes da virada, 2 caminhos com objetivo 7 e GP final, rival em toda meta de
## rival e em todo GP, outro piso nunca Ruim e condições de virada conhecidas. Depois salva
## uma carreira que já passou da virada e confere se os objetivos do caminho voltam ao carregar.
## Uso: Godot --headless --path . --script res://testes/teste_campanhas.gd
var CarreiraS: GDScript

const TURNOS := [13, 20, 24, 32, 40, 48]
const CONDICOES := ["ou", "e", "venceu", "top", "flag", "sem_lesao_desde", "saidas_min", "fama_min",
	"vitorias_min", "viradas_min", "festivais_min", "distancias_min", "distancias_top3_min"]


func _cond_ok(c: Dictionary) -> bool:
	if c.size() != 1 or not c.keys()[0] in CONDICOES:
		return false
	if c.has("ou"):
		return c.ou.all(func(x): return _cond_ok(x))
	if c.has("e"):
		return c.e.all(func(x): return _cond_ok(x))
	return true


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_campanhas.json"
	var dd: Node = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	var falhas := []
	for g in dd.garotas:
		var ini: Dictionary = dd.config_carreira(g.nome)
		var c := Campanha.montar(g.nome, g.estilo, g.aptidao, ini.distancia, ini.piso, 7)
		var turnos: Array = c.objetivos.map(func(o): return int(o.turno))
		if turnos != TURNOS:
			falhas.append("%s: turnos %s" % [g.nome, turnos])
		if not _cond_ok(c.virada):
			falhas.append("%s: virada %s" % [g.nome, c.virada])
		var todos: Array = c.objetivos.duplicate()
		for k in ["A", "B"]:
			var t2: Array = c.caminhos[k].objetivos.map(func(o): return int(o.turno))
			if t2 != [60, 72]:
				falhas.append("%s: caminho %s %s" % [g.nome, k, t2])
			todos.append_array(c.caminhos[k].objetivos)
		for o in todos:
			if (o.get("meta_rival", false) or o.cat.begins_with("gp")) and o.get("rival", "") == "":
				falhas.append("%s: turno %d sem rival" % [g.nome, o.turno])
			if g.aptidao[o.piso] == "R" or g.aptidao[o.dist] == "R":
				falhas.append("%s: turno %d em aptidão Ruim (%s %s)" % [g.nome, o.turno, o.dist, o.piso])
			if o.texto == "":
				falhas.append("%s: turno %d sem texto" % [g.nome, o.turno])
	# save e carregamento depois da virada
	var ini: Dictionary = dd.iniciais[0]
	var car = CarreiraS.new(dd.garota(ini.nome), ini, 42)
	car.turno = 49
	car.caminho = "B"
	car.objetivos.append_array(car.campanha.caminhos.B.objetivos)
	car.encontro_pendente = {}
	car.salvar()
	var d = CarreiraS.carregar()
	if d == null or d.objetivos.size() != 8 or d.objetivos[6].turno != 60 or d.caminho != "B":
		falhas.append("save depois da virada")
	CarreiraS.apagar_save()
	print("CAMPANHAS OK (%d garotas)" % dd.garotas.size() if falhas.is_empty() else "CAMPANHAS FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
