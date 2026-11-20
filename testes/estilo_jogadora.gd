extends SceneTree
## A jogadora contra um pelotão do elenco (campanhas.md §7): mede o top 3 e a vitória de cada estilo
## com o mesmo perfil de atributos, para separar o efeito do estilo do efeito do perfil de treino.
## Pelotão: 11 garotas sorteadas do elenco, com o perfil delas escalado para a média do nível.
## Uso: Godot --headless --path . --script res://testes/estilo_jogadora.gd -- [corridas] [perfil]
## [níveis, ex.: 250,350]
##   perfil: "bot" (o do testes/balanco.gd: Vel 1,2, Est 1,0, Pod 0,9, Det 0,8, Int 0,7), "estilo"
##   (o do bot multiplicado pelos pesos do estilo) ou "plano"
const ESTILOS := ["pon", "per", "arr", "fec"]
var NIVEIS := [250, 350, 450, 600]
const DISTS := [1200, 1600, 2000, 2400, 3200]


func _initialize() -> void:
	var dd: Node = root.get_node("Dados")
	if dd.garotas.is_empty():
		dd._ready()
	var n := 200
	var perfil_nome := "bot"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.size() > 1:
		perfil_nome = args[1]
	if args.size() > 2:
		NIVEIS = Array(args[2].split(",")).map(func(x): return int(x))
	print("perfil %s | top 3 (vitória) por estilo: pon / per / arr / fec" % perfil_nome)
	var total := {}
	for st in ESTILOS:
		total[st] = [0.0, 0.0]
	for lv in NIVEIS:
		for d in DISTS:
			var perfil := {"vel": 1.0, "est": 1.0, "pod": 1.0, "det": 1.0, "int": 1.0}
			if perfil_nome == "bot":
				perfil = {"vel": 1.2, "est": 1.3 if d >= 2000 else 1.0, "pod": 0.9, "det": 0.8, "int": 0.7}
			var cel := []
			for st in ESTILOS:
				var p := perfil.duplicate()
				if perfil_nome == "estilo":
					# o perfil do bot puxado para os atributos que o estilo usa mais (corrida.md §3.1)
					p = {"vel": 1.2, "est": 1.3 if d >= 2000 else 1.0, "pod": 0.9, "det": 0.8, "int": 0.7}
					for k in p:
						p[k] *= SimCorrida.PESOS[st][k]
				var soma := 0.0
				for k in p:
					soma += p[k]
				var top := 0
				var vit := 0
				for i in n:
					var r := RandomNumberGenerator.new()
					r.seed = hash([lv, d, i])  # mesmo pelotão e mesma sorte para os 4 estilos
					var a := {}
					for k in p:
						a[k] = lv * 5.0 * p[k] / soma
					var field := [{"nome": "J", "estilo": st, "attrs": a, "mult": 1.0}]
					var pool: Array = dd.garotas.duplicate()
					for j in 11:
						var g: Dictionary = pool.pop_at(r.randi() % pool.size())
						var sg := 0.0
						for k in SimCorrida.KEYS:
							sg += g.atributos[k]
						var b := {}
						for k in SimCorrida.KEYS:
							b[k] = g.atributos[k] * lv * 5.0 / sg
						field.append({"nome": g.nome, "estilo": g.estilo, "attrs": b, "mult": 1.0})
					var sim := SimCorrida.new(field, float(d), 1 + r.randi() % 1000000000, "")
					var ordem: Array = sim.rodar_ate_o_fim()
					var pos: int = ordem.find(0)
					if pos < 3:
						top += 1
					if pos == 0:
						vit += 1
				cel.append("%2d (%2d)" % [roundi(100.0 * top / n), roundi(100.0 * vit / n)])
				total[st][0] += 100.0 * top / n / (NIVEIS.size() * DISTS.size())
				total[st][1] += 100.0 * vit / n / (NIVEIS.size() * DISTS.size())
			print("%4d %5d | %s" % [lv, d, " / ".join(cel)])
	print("média     | %s" % " / ".join(ESTILOS.map(func(s): return "%2d (%2d)" % [roundi(total[s][0]), roundi(total[s][1])])))
	quit()
