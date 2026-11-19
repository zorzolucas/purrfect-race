extends SceneTree
## Procura "meta" no Circuito (docs/campanhas.md §2.3): mede, em cada corrida das copas,
## a chance de vencer e os pontos médios de cada estilo e de cada garota com a mesma força,
## em cada clima e traçado. Se um estilo ou garota vencer em quase tudo, há meta.
## Uso: Godot --headless --path . --script res://testes/meta_circuito.gd -- modo N media [parte i/n] [saida.json] [climas] [tracados] [corridas]
##   modo: "estilo" (perfil neutro, todos os atributos iguais, aptidão Ótima/Ótima),
##         "nivel" (chance de vencer cada evento em cada nível com elencos de média 700 a 1100),
##         "garota" (as 48 com o próprio perfil e aptidões) ou "attr" (+10% em um atributo por vez)
##   media: média dos atributos da corredora da jogadora; o pelotão usa o nível mais próximo abaixo.
##   climas: lista separada por vírgula (padrão "bom,chuva,calor").
##   tracados: lista separada por vírgula ou "todos" (padrão). corridas: "evento:i" separados por vírgula.
var EndgameS: GDScript
var dd: Node


func _initialize() -> void:
	EndgameS = load("res://scripts/endgame.gd")
	dd = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "estilo"
	var n: int = int(args[1]) if args.size() > 1 else 40
	var media: float = float(args[2]) if args.size() > 2 else 800.0
	var parte := [0, 1]
	if args.size() > 3 and args[3].contains("/"):
		var pn: PackedStringArray = args[3].split("/")
		parte = [int(pn[0]), int(pn[1])]
	var saida: String = args[4] if args.size() > 4 else ""
	var nivel := 0
	for i in EndgameS.niveis().size():
		if float(EndgameS.niveis()[i].forca) <= media:
			nivel = i
	var climas: Array = ["bom", "chuva", "calor"]
	if args.size() > 5:
		climas = Array(args[5].split(","))
	var tracados: Array = dd.endgame.circuito.tracados.map(func(t): return t.id)
	if args.size() > 6 and args[6] != "todos":
		tracados = Array(args[6].split(","))
	var so_corridas: Array = Array(args[7].split(",")) if args.size() > 7 else []
	var resultado := {}
	var idx := 0
	var t0 := Time.get_ticks_msec()
	if modo == "nivel":
		_niveis(n, parte, saida)
		return
	for ev in EndgameS.eventos():
		for i in ev.corridas.size():
			var corrida: Dictionary = ev.corridas[i]
			if not so_corridas.is_empty() and not "%s:%d" % [ev.id, i] in so_corridas:
				continue
			for clima in climas:
				for tr in tracados:
					idx += 1
					if idx % parte[1] != parte[0]:
						continue
					var chave := "%s|%d|%s %s %dm|%s|%s" % [ev.id, i, corrida.dist, corrida.piso, corrida.metros, clima, tr]
					resultado[chave] = _medir(modo, ev.id, i, corrida, clima, tr, n, media, nivel)
	print("tempo: %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify(resultado))
	else:
		for k in resultado:
			print(k, " ", resultado[k])
	quit()


func _corredoras(modo: String, corrida: Dictionary, media: float) -> Dictionary:
	var lista := {}
	match modo:
		"estilo":
			for st in ["pon", "per", "arr", "fec"]:
				var a := {}
				for k in SimCorrida.KEYS:
					a[k] = media
				lista[st] = {"nome": "Teste", "estilo": st, "attrs": a, "mult": 1.05 * 1.05, "unica": "", "jogadora": true}
		"garota":
			for g in dd.garotas:
				# só quem tem aptidão para disputar: Ótima numa e pelo menos Boa na outra
				if dd.APT[g.aptidao[corrida.dist]] * dd.APT[g.aptidao[corrida.piso]] < 1.05:
					continue
				var c: Dictionary = EndgameS.corredora_npc(g, media, corrida)
				c.jogadora = true
				lista[g.nome] = c
		"attr":
			for st in ["pon", "per", "arr", "fec"]:
				for k in ["base"] + SimCorrida.KEYS:
					var a := {}
					for kk in SimCorrida.KEYS:
						a[kk] = media * (1.1 if kk == k else 1.0)
					lista["%s+%s" % [st, k]] = {"nome": "Teste", "estilo": st, "attrs": a, "mult": 1.05 * 1.05, "unica": "", "jogadora": true}
	return lista


func _medir(modo: String, id: String, i: int, corrida: Dictionary, clima: String, tr: String, n: int, media: float, nivel: int) -> Dictionary:
	var r := {}
	var corredoras := _corredoras(modo, corrida, media)
	for nome in corredoras:
		var vit := 0
		var pts := 0
		var soma_pos := 0
		for s in n:
			# a semana (giro) muda as casas e as avulsas; a semente muda a sorte
			var giro := s
			var minha: Dictionary = corredoras[nome]
			var excluir := [nome] if modo == "garota" else []
			var casas: Array = EndgameS.escalacao_casas(giro, id, excluir)
			# números aleatórios comuns: a mesma semente para todas as variantes, então a diferença
			# entre elas é efeito do atributo ou estilo, não da sorte (bem menos ruído)
			var m: Dictionary = EndgameS.montar_corrida(nivel, giro, id, i, minha, casas, excluir, hash([s, id, i]))
			# o teste fixa clima e traçado em vez dos da semana
			var field: Array = m.field
			var t: Dictionary = EndgameS.tracado(tr)
			field[0] = minha.duplicate(true)
			EndgameS.aplicar_tracado(field[0], t)
			var tr_semana: Dictionary = EndgameS.tracado(m.condicao.tracado)
			for j in range(1, field.size()):
				_desfazer_tracado(field[j], tr_semana)
				EndgameS.aplicar_tracado(field[j], t)
			var sim := SimCorrida.new(field, m.metros, m.seed, clima)
			EndgameS.aplicar_pista(sim, t)
			var ordem: Array = sim.rodar_ate_o_fim()
			var pos: int = ordem.find(0) + 1
			if pos == 1:
				vit += 1
			pts += EndgameS.pontos(pos)
			soma_pos += pos
		r[nome] = [snappedf(float(vit) / n, 0.001), snappedf(float(pts) / n, 0.01), snappedf(float(soma_pos) / n, 0.01)]
	return r


func _desfazer_tracado(c: Dictionary, t: Dictionary) -> void:
	var ef: Dictionary = t.get("efeito", {})
	c.mult = float(c.mult) / float(ef.get("estilo", {}).get(c.estilo, 1.0))
	var pa: Dictionary = ef.get("attr", {})
	for k in pa:
		c.attrs[k] = float(c.attrs[k]) / float(pa[k])


## Dificuldade de cada nível: elencos com a melhor aptidão possível em cada corrida e
## atributos de média M, em semanas sorteadas (condições e casas mudam). N tentativas.
func _niveis(n: int, parte: Array, saida: String) -> void:
	var resultado := {}
	var idx := 0
	for media in [700, 800, 850, 900, 950, 1000, 1050, 1100]:
		for nivel in EndgameS.niveis().size():
			for ev in EndgameS.eventos():
				idx += 1
				if idx % parte[1] != parte[0]:
					continue
				var vit := 0
				var pts := 0
				for s in n:
					var giro := 1000 + s
					var r := RandomNumberGenerator.new()
					r.seed = hash([s, ev.id, nivel, media])
					var esc := []
					var usadas := []
					for corrida in ev.corridas:
						var cand: Array = dd.garotas.filter(func(g): return not g.nome in usadas)
						var notas := {}
						for g in cand:
							notas[g.nome] = dd.APT[g.aptidao[corrida.dist]] * dd.APT[g.aptidao[corrida.piso]] + r.randf() * 0.01
						cand.sort_custom(func(a, b): return notas[a.nome] > notas[b.nome])
						var g: Dictionary = cand[0]
						usadas.append(g.nome)
						var soma := 0.0
						for k in SimCorrida.KEYS:
							soma += g.atributos[k]
						var at := {}
						for k in SimCorrida.KEYS:
							at[k] = g.atributos[k] * media * 5.0 / soma
						esc.append({"nome": g.nome, "salva": {"attrs": at, "habilidades": dd.habilidades.get("iniciais", [])}})
					var res: Dictionary = EndgameS.correr_evento(nivel, giro, ev.id, esc, hash([s, "nivel", media]))
					vit += 1 if res.venceu else 0
					pts += int(res.total)
				resultado["%d|%s|%s" % [media, EndgameS.niveis()[nivel].id, ev.id]] = [snappedf(float(vit) / n, 0.01), snappedf(float(pts) / n, 0.1)]
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify(resultado))
	else:
		for k in resultado:
			print(k, " ", resultado[k])
	quit()
