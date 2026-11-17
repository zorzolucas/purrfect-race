extends SceneTree
## Teste headless de balanceamento (docs/campanhas.md §6): joga carreiras completas de 72 turnos
## com um bot simples e mede quantas cumprem cada objetivo, a divisão no ponto de virada,
## a curva de atributos, a fama e o número de corridas.
## Uso: Godot --headless --path . --script res://testes/balanco.gd -- N [filtro] [conta] [saida.json]
##   filtro: "mvp" (padrão), "todas", "modelo" ou o começo do nome de uma garota
##   conta: "nova" (padrão) ou "madura" (vínculo 3 e madrinha de nota ~700, campanhas.md §1)
# Carreira é carregada em tempo de execução: no modo --script, os autoloads (Dados) só
# existem depois que este script compila, e carreira.gd depende deles.
var CarreiraS: GDScript
var dd: Node

const PESO_ALVO := {"vel": 1.2, "est": 1.0, "pod": 0.9, "det": 0.8, "int": 0.7}
const OBJ := [13, 20, 24, 32, 40, 48, 60, 72]
const CURVA := [13, 24, 36, 48, 60, 72]
const MADRINHA := {"vel": 760, "est": 700, "pod": 700, "det": 660, "int": 680}


func _media(c) -> float:
	var s := 0.0
	for k in c.attrs:
		s += c.attrs[k]
	return s / 5.0


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_balanco.json"
	var n := 20
	var filtro := "mvp"
	var conta := "nova"
	var saida := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.size() > 1:
		filtro = args[1]
	if args.size() > 2:
		conta = args[2]
	if args.size() > 3:
		saida = args[3]
	dd = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	var nomes := []
	for g in dd.garotas:
		var mvp: bool = not dd.inicial(g.nome).is_empty()
		match filtro:
			"mvp":
				if not mvp: continue
			"modelo":
				if mvp: continue
			"todas":
				pass
			_:
				if g.nome != filtro: continue
		nomes.append(g.nome)
	var todos := []
	for nome in nomes:
		var r := _rodar(nome, n, conta)
		todos.append(r)
		_imprimir(r)
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify(todos))
	quit()


func _rodar(nome: String, n: int, conta: String) -> Dictionary:
	var ini: Dictionary = dd.config_carreira(nome)
	var passou := [0, 0, 0, 0, 0, 0, 0, 0]
	var curva := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var curva_n := [0, 0, 0, 0, 0, 0]
	var caminho := {"A": 0, "B": 0}
	var completou := {"A": 0, "B": 0}
	var fama32 := 0
	var fama40 := 0
	var corridas := 0
	var gp_final := 0
	var arquetipo := ""
	var na_virada := []  # contadores no turno 48, para calibrar as regras de virada
	var gp2_venceu := 0
	for i in n:
		var madrinha := {}
		var vinculo := 0
		if conta == "madura":
			vinculo = 3
			madrinha = {"attrs": MADRINHA, "dist": Campanha.vizinha(ini.distancia),
				"piso": Campanha.outro_piso(ini.piso)}
		var c = CarreiraS.new(dd.garota(nome), ini, i + 1, vinculo, madrinha)
		arquetipo = c.campanha.arquetipo
		var peso := PESO_ALVO.duplicate()
		if c.distancia in ["media", "longa"]:
			peso.est = 1.3
		var guard := 0
		var ultimo_turno := 0
		while not c.terminou and guard < 600:
			guard += 1
			var t0: int = c.turno
			if t0 != ultimo_turno:
				ultimo_turno = t0
				var k := CURVA.find(t0)
				if k >= 0:
					curva[k] += _media(c)
					curva_n[k] += 1
			var p: String = c.pendencia()
			if OS.has_environment("TRACE") and i == 0:
				print("t%d %s e%d m%.0f fama%d no=%s" % [c.turno, p, c.energia, _media(c), c.fama, c.tipo_no()])
			match p:
				"encontro":
					var re := RandomNumberGenerator.new()
					re.seed = hash([i, c.turno, "esc"])
					c.escolher(re.randi() % c.encontro_atual().escolhas.size())
				"amuleto":
					if c.amuletos.size() < 6:
						c.escolher_amuleto(c.oferta_amuleto[0])
					else:
						c.escolher_amuleto(c.oferta_amuleto[0], c.amuletos[0])
				"mapa":
					c.escolher_no(_melhor_no(c))
				"ferias":
					c.escolher_acampamento("serra" if c.distancia in ["media", "longa"] else "praia")
				"corrida", "objetivo":
					if p == "objetivo" and t0 == 32:
						fama32 += c.fama
					if p == "objetivo" and t0 == 40:
						fama40 += c.fama
					var corrida = c.montar_corrida(dd.garotas)
					var sim := SimCorrida.new(corrida.field, corrida.distancia, corrida.seed, corrida.clima)
					var ordem: Array = sim.rodar_ate_o_fim()
					var pos: int = ordem.find(0) + 1
					c.registrar_corrida(pos, CarreiraS.extra_da_corrida(corrida, ordem, sim.ordem_meio))
					corridas += 1
					if c.falhou_objetivo and OS.has_environment("CURVA"):
						# modo curva: segue a carreira depois da falha, só para medir os atributos
						c.falhou_objetivo = false
						c.terminou = false
						c._fim_turno()
						continue
					if p == "objetivo" and not c.falhou_objetivo:
						passou[OBJ.find(t0)] += 1
						if t0 == 48:
							caminho[c.caminho] += 1
							if pos == 1:
								gp2_venceu += 1
							var ds := {}
							for res in c.resultados:
								ds[res.dist] = true
							var d3 := {}
							for res in c.resultados:
								if res.posicao <= 3:
									d3[res.dist] = true
							na_virada.append({"flags": c.flags.size(), "dist_top3": d3.size(), "fama": c.fama, "vitorias": c.resultados.filter(func(x): return x.posicao == 1).size(),
								"festivais": c.nos_visitados("festival"), "distancias": ds.size(), "saidas": c.saidas,
								"viradas": c.viradas, "lesao": c.ultima_lesao})
						if t0 == 72:
							completou[c.caminho] += 1
							if pos == 1:
								gp_final += 1
				_:
					_acao(c, peso)
	var cv := []
	for j in CURVA.size():
		cv.append(roundi(curva[j] / maxi(1, curva_n[j])))
	if arquetipo == "":
		arquetipo = "(MVP)"
	return {"nome": nome, "arquetipo": arquetipo, "casa": "%s_%s" % [ini.distancia, ini.piso],
		"n": n, "conta": conta, "passou": passou, "caminho": caminho, "completou": completou,
		"curva": cv, "fama32": fama32 / maxi(1, passou[2]), "fama40": fama40 / maxi(1, passou[3]),
		"corridas": float(corridas) / n, "gp_final": gp_final, "gp2_venceu": gp2_venceu, "na_virada": na_virada}


func _imprimir(r: Dictionary) -> void:
	var linha := []
	for j in 8:
		linha.append("%3d" % (100 * r.passou[j] / r.n))
	var chegou: int = r.caminho.A + r.caminho.B
	print("%-11s %-14s obj%% %s | virada A %d%% | curva %s | fama t32 %d t40 %d | %.1f corridas | GP final venceu %d" % [
		r.nome, r.arquetipo, " ".join(linha), 100 * r.caminho.A / maxi(1, chegou),
		"/".join(r.curva.map(func(x): return str(x))), r.fama32, r.fama40, r.corridas, r.gp_final])


func _melhor_no(c) -> int:
	var t: int = c.trecho()
	var linha: int = c.rota[t].size()
	var melhor := -1
	var nota := -INF
	for col in c.opcoes_mapa():
		var no: Dictionary = c.mapas[t][linha][col]
		var v: float = {"circuito": 2.0, "foco": 2.5, "recuperacao": 1.0, "festival": 1.0,
			"biblioteca": 1.0, "desafio": 1.5, "misterio": 1.2}[no.tipo]
		if no.tipo == "recuperacao" and c.energia < 50:
			v += 1.5
		# olha uma linha à frente: preferir quem leva a um Circuito
		if linha + 1 < c.mapas[t].size():
			for viz in Calendario.vizinhos(col):
				if c.mapas[t][linha + 1][viz].tipo == "circuito":
					v += 0.3
		if v > nota:
			nota = v
			melhor = col
	return melhor


func _acao(c, peso: Dictionary) -> void:
	# compra habilidades quando dá
	for h in dd.habilidades.lista:
		if c.pode_comprar(h.id):
			c.comprar_habilidade(h.id)
	if c.lesionada:
		c.enfermaria()
		return
	var media := _media(c)
	if c.energia >= 50:
		var melhor := {}
		for cr in c.corridas_opcionais():
			var forca: float = c.forca_categoria(cr.cat, cr.dist)
			if cr.get("desafio", false):
				forca *= 1.2
			var apt: float = dd.APT[c.aptidao[cr.dist]] * dd.APT[c.aptidao[cr.piso]]
			# corre quando a corrida é acessível (o olheiro diria Favorita ou Disputada)
			if c.pode_entrar(cr) and media * apt >= forca * 0.95:
				if melhor.is_empty() or c.fama_prevista(cr) > c.fama_prevista(melhor):
					melhor = cr
		if not melhor.is_empty():
			c.escolher_corrida(melhor)
			return
	if c.energia < 45:
		if c.humor <= 2:
			c.sair()
		else:
			c.descansar()
		return
	var escolhido := "vel"
	var menor := INF
	for t in CarreiraS.TREINOS:
		var r: float = c.attrs[t] / peso[t] / (1.0 + 0.15 * (c.nivel_efetivo(t) - c.nivel_treino(t)))
		if r < menor:
			menor = r
			escolhido = t
	c.treinar(escolhido)
