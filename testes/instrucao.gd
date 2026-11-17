extends SceneTree
## Compara as 3 instruções pré-corrida (GDD §5.7) em corridas equilibradas: cada estilo × cada
## distância, com a jogadora um pouco acima do pelotão. Mostra a colocação média e a % de vitória
## com cada instrução, e a estimativa do olheiro, para calibrar os dois.
## Uso: Godot --headless --path . --script res://testes/instrucao.gd -- N [garotas,separadas] [ajuste]
##   ajuste: "pr=0.98,ps=1.03,fr=1.02,ff=1.10" troca os valores de SimCorrida.INSTRUCAO ("-" = nenhum)
##   est: multiplica a Estamina da jogadora (ex.: 0.75 = fôlego curto para a distância)
##   distâncias: lista separada por vírgula (padrão: as 4)
const DISTS := ["sprint", "milha", "media", "longa"]


func _initialize() -> void:
	var dd = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	var C = load("res://scripts/carreira.gd")
	C.CAMINHO_SAVE = "user://teste_instrucao.json"
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 40
	var nomes: Array = args[1].split(",") if args.size() > 1 and args[1] != "" else ["Lira", "Nashira", "Capela", "Mira"]
	var est_mult := float(args[3]) if args.size() > 3 else 1.0
	var dists: Array = Array(args[4].split(",")) if args.size() > 4 else DISTS
	if args.size() > 2 and args[2] != "-":
		for par in args[2].split(","):
			var kv: PackedStringArray = par.split("=")
			var ins: String = {"p": "poupar", "f": "forcar"}[kv[0][0]]
			var campo: String = {"r": "ritmo", "s": "sprint", "f": "folego"}[kv[0][1]]
			SimCorrida.INSTRUCAO[ins][campo] = float(kv[1])
	var ganhou := {"poupar": 0, "normal": 0, "forcar": 0}
	var erro := 0.0
	var casos := 0
	for nome in nomes:
		for d in dists:
			var c = C.new(dd.garota(nome), dd.config_carreira(nome), hash([nome, d]))
			c.turno = 52
			var cr := {"id": "i_%s" % d, "cat": "prata", "dist": d, "piso": c.piso, "nome": "Teste"}
			# jogadora com o perfil dela, um pouco acima do pelotão já contando a aptidão
			var mult: float = dd.APT[c.aptidao[d]] * dd.APT[c.aptidao[c.piso]]
			var alvo: float = c.forca_categoria("prata", d) * 1.12 / mult
			var soma := 0.0
			for k in c.attrs:
				soma += c.attrs[k]
			for k in c.attrs:
				c.attrs[k] = c.attrs[k] * alvo * 5.0 / soma
			c.attrs.est *= est_mult
			var ol: Dictionary = c.olheiro(cr)
			var linha := "%-8s %-6s %s " % [nome, d, dd.ESTILO_NOME[c.estilo].substr(0, 3)]
			var melhor := ""
			var melhor_pos := INF
			for ins in ["poupar", "normal", "forcar"]:
				c.instrucao = ins
				c.corrida_atual = cr
				var m: Dictionary = c.montar_corrida(dd.garotas)
				var pos := 0.0
				var v := 0
				for i in n:
					var s := SimCorrida.new(m.field, m.distancia, 5000 + i, "")
					var p: int = s.rodar_ate_o_fim().find(0) + 1
					pos += p
					if p == 1:
						v += 1
				pos /= n
				erro += absf(float(v) / n - ol.chances[ins])
				casos += 1
				linha += "| %s pos %.2f vit %3d%% est %3d%% " % [ins.substr(0, 3), pos, 100 * v / n, roundi(100 * ol.chances[ins])]
				if pos < melhor_pos:
					melhor_pos = pos
					melhor = ins
			ganhou[melhor] += 1
			print(linha, "| melhor %s, olheiro sugere %s" % [melhor, ol.sugestao])
	print("MELHOR %s  erro médio do olheiro %.3f" % [ganhou, erro / maxi(1, casos)])
	quit()
