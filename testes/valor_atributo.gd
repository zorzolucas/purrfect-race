extends SceneTree
## Quanto vale +10% em cada atributo, por nível e distância (corrida.md §8.2): pelotão de 12 com
## 3 de cada estilo, todas com os mesmos atributos; uma delas ganha +10% em um atributo. Mede as
## posições ganhas na média, com a mesma semente em todas as variantes (números aleatórios comuns).
## Uso: Godot --headless --path . --script res://testes/valor_atributo.gd -- [corridas] [níveis] [fôlego]
##   níveis: ex. 300,550,800. fôlego: "nivel,fracao" de SimCorrida.FOLEGO_PELOTAO, ex. 350,1.0
const ESTILOS := ["pon", "per", "arr", "fec"]
const DISTS := [1200, 1600, 2000, 2400, 3200]
const ATTRS := ["vel", "est", "pod", "det", "int"]


func _initialize() -> void:
	var n := 60
	var niveis := [300, 550, 800]
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.size() > 1:
		niveis = Array(args[1].split(",")).map(func(x): return int(x))
	if args.size() > 2:
		var fp: PackedStringArray = args[2].split(",")
		SimCorrida.FOLEGO_PELOTAO.nivel = float(fp[0])
		SimCorrida.FOLEGO_PELOTAO.fracao = float(fp[1])
	print("fôlego %s | posições ganhas com +10%%: vel / est / pod / det / int" % str(SimCorrida.FOLEGO_PELOTAO))
	for lv in niveis:
		var media := {}
		for a in ATTRS:
			media[a] = 0.0
		for d in DISTS:
			var ganho := {}
			for a in ATTRS:
				ganho[a] = 0.0
			for st_i in ESTILOS.size():
				var alvo: int = st_i * 3  # a primeira corredora de cada estilo
				for i in n:
					var semente: int = 1 + hash([lv, d, st_i, i]) % 1000000000
					var base := _posicao(lv, d, alvo, "", semente)
					for a in ATTRS:
						ganho[a] += float(base - _posicao(lv, d, alvo, a, semente)) / (n * ESTILOS.size())
			for a in ATTRS:
				media[a] += ganho[a] / DISTS.size()
			print("%4d %5d | %s" % [lv, d, " / ".join(ATTRS.map(func(a): return "%+.2f" % ganho[a]))])
		print("%4d média | %s" % [lv, " / ".join(ATTRS.map(func(a): return "%+.2f" % media[a]))])
	quit()


func _posicao(lv: int, d: int, alvo: int, attr: String, semente: int) -> int:
	var field := []
	for st in ESTILOS:
		for q in 3:
			var a := {}
			for k in ATTRS:
				a[k] = float(lv)
			field.append({"nome": st, "estilo": st, "attrs": a, "mult": 1.0})
	if attr != "":
		field[alvo].attrs[attr] *= 1.1
	var sim := SimCorrida.new(field, float(d), semente, "")
	return sim.rodar_ate_o_fim().find(alvo)
