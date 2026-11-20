extends SceneTree
## Calibra SimCorrida.CORRECAO_ESTILO (corrida.md §8.5): em cada célula da grade (nível x distância),
## corre um pelotão com 3 corredoras de cada estilo, todas com os mesmos atributos, e ajusta o
## multiplicador de cada estilo até a média entre a vitória e o top 3 dele ficar em 25%.
## Cada iteração usa sementes novas, com passo que diminui, e o resultado é a média das últimas
## iterações: com as mesmas sementes em todas, o ajuste decorava a sorte daquelas corridas.
## Uso: Godot --headless --path . --script res://testes/ajustar_estilo.gd -- [iterações] [corridas] [parte i/n] [níveis, ex.: 375,525]
const ESTILOS := ["pon", "per", "arr", "fec"]


func _rodada(lv: float, d: float, n: int, corr: Dictionary, semente0: int) -> Dictionary:
	var t: Dictionary = SimCorrida.CORRECAO_ESTILO
	var i: int = t.niveis.find(lv)
	var j: int = t.dists.find(d)
	for st in ESTILOS:
		t[st][i][j] = corr[st]
	var vit := {}
	var top := {}
	for st in ESTILOS:
		vit[st] = 0
		top[st] = 0
	for r in n:
		var field := []
		for st in ESTILOS:
			for q in 3:
				var a := {}
				for k in SimCorrida.KEYS:
					a[k] = lv
				field.append({"nome": st, "estilo": st, "attrs": a, "mult": 1.0})
		var sim := SimCorrida.new(field, d, 1 + hash([lv, d, r, semente0]) % 1000000000, "")
		var ordem: Array = sim.rodar_ate_o_fim()
		vit[field[ordem[0]].estilo] += 1
		for p in 3:
			top[field[ordem[p]].estilo] += 1
	var nota := {}
	for st in ESTILOS:
		nota[st] = 0.5 * (float(vit[st]) / n + float(top[st]) / (3.0 * n))
	return nota


func _initialize() -> void:
	var iters := 8
	var n := 300
	var parte := [0, 1]
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		iters = int(args[0])
	if args.size() > 1:
		n = int(args[1])
	if args.size() > 2:
		var pn: PackedStringArray = args[2].split("/")
		parte = [int(pn[0]), int(pn[1])]
	var so_niveis := []
	if args.size() > 3:
		so_niveis = Array(args[3].split(",")).map(func(x): return float(x))
	var t: Dictionary = SimCorrida.CORRECAO_ESTILO
	var celula := 0
	for lv in t.niveis:
		if not so_niveis.is_empty() and not lv in so_niveis:
			continue
		for d in t.dists:
			celula += 1
			if (celula - 1) % parte[1] != parte[0]:
				continue
			var corr := {}
			for st in ESTILOS:
				corr[st] = t[st][t.niveis.find(lv)][t.dists.find(d)]
			var nota := {}
			var media := {}
			for st in ESTILOS:
				media[st] = 0.0
			var n_media := 0
			for it in iters:
				nota = _rodada(lv, d, n, corr, it + 1)
				var soma := 0.0
				var passo := 0.25 / (1.0 + 0.25 * it)
				for st in ESTILOS:
					corr[st] *= 1.0 + passo * (0.25 - nota[st])
					soma += corr[st]
				for st in ESTILOS:
					corr[st] *= 4.0 / soma
				if it >= iters / 2:
					n_media += 1
					for st in ESTILOS:
						media[st] += corr[st]
			for st in ESTILOS:
				corr[st] = media[st] / n_media
			var final := _rodada(lv, d, 2 * n, corr, 777)  # conferência com sementes novas
			print("CEL %d %d %s | antes %s | conferência %s" % [lv, d,
				JSON.stringify(ESTILOS.map(func(s): return snappedf(corr[s], 0.0001))),
				"/".join(ESTILOS.map(func(s): return "%2d" % roundi(100 * nota[s]))),
				"/".join(ESTILOS.map(func(s): return "%2d" % roundi(100 * final[s])))])
	quit()
