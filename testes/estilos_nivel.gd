extends SceneTree
## Mede a vitória e o top 3 de cada estilo por nível de atributos e distância (campanhas.md §7):
## pelotão de 12 com 3 de cada estilo, todas com os mesmos atributos, como tools/ajustar_ritmo.py,
## mas nos níveis da carreira (250 a 850), onde o estilo forte pode mudar com o nível.
## Uso: Godot --headless --path . --script res://testes/estilos_nivel.gd -- [corridas por caso] [níveis, ex.: 250,525]
const ESTILOS := ["pon", "per", "arr", "fec"]
var NIVEIS := [250, 350, 450, 600, 800]
var DISTS := [1200, 1600, 2000, 2400, 3200]


func _initialize() -> void:
	var n := 150
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.size() > 1:
		NIVEIS = Array(args[1].split(",")).map(func(x): return int(x))
	print("nível dist  | vitória pon/per/arr/fec | top 3 pon/per/arr/fec")
	var soma := {}
	for lv in NIVEIS:
		var lin_v := {}
		var lin_t := {}
		for st in ESTILOS:
			lin_v[st] = 0.0
			lin_t[st] = 0.0
		for d in DISTS:
			var vit := {}
			var top := {}
			for st in ESTILOS:
				vit[st] = 0
				top[st] = 0
			for i in n:
				var field := []
				for st in ESTILOS:
					for j in 3:
						var a := {}
						for k in SimCorrida.KEYS:
							a[k] = float(lv)
						field.append({"nome": st, "estilo": st, "attrs": a, "mult": 1.0})
				var sim := SimCorrida.new(field, float(d), 1 + hash([lv, d, i]) % 1000000000, "")
				var ordem: Array = sim.rodar_ate_o_fim()
				vit[field[ordem[0]].estilo] += 1
				for p in 3:
					top[field[ordem[p]].estilo] += 1
			var tv := []
			var tt := []
			for st in ESTILOS:
				tv.append("%3d" % roundi(100.0 * vit[st] / n))
				tt.append("%3d" % roundi(100.0 * top[st] / (3.0 * n)))
				lin_v[st] += 100.0 * vit[st] / n / DISTS.size()
				lin_t[st] += 100.0 * top[st] / (3.0 * n) / DISTS.size()
			print("%5d %5d | %s | %s" % [lv, d, "/".join(tv), "/".join(tt)])
		print("%5d média | %s | %s" % [lv, "/".join(ESTILOS.map(func(s): return "%3d" % roundi(lin_v[s]))),
			"/".join(ESTILOS.map(func(s): return "%3d" % roundi(lin_t[s])))])
	quit()
