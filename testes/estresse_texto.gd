extends SceneTree
## Abre a tela da carreira nos estados com os textos mais longos (todo turno com o nó de Circuito
## e a corrida fixa, o olheiro de cada corrida e de cada objetivo, todos os encontros, mistérios
## e capítulos, os amuletos de descrição mais longa) e confere com testes/estouro.gd se algum
## painel sai da área visível. Sai com código 1 se achar estouro.
## Uso: xvfb-run -a -s "-screen 0 1280x720x24" Godot --path . --rendering-driver opengl3 --script res://testes/estresse_texto.gd
## Com CAPTURAR=1 salva uma captura de cada estouro em testes/capturas/estresse_*.png; com
## CAPTURAR=tudo, de todo cenário. FILTRO=texto roda só os cenários com esse texto no nome.

const Estouro := preload("res://testes/estouro.gd")

var main: Node
var dados: Node
var c
var cenarios: Array[Dictionary] = []
var i := 0
var espera := 0
var total := 0
var vistos := {}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://estresse_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://estresse_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)


func _montar_cenarios() -> void:
	var cal: Dictionary = dados.calendario
	var longa := "Treino de Velocidade: +60 Vel, +22 Pod. " + "Ela volta exausta, mas sentindo as pernas mais fortes. ".repeat(3)
	for nome in ["Lira", "Mira", "Nashira", "Capela", "Antares"]:
		for t in range(1, 73):
			cenarios.append({"nome": "%s_t%d_circuito" % [nome, t], "garota": nome, "turno": t, "no": "circuito", "msg": longa})
			cenarios.append({"nome": "%s_t%d_desafio" % [nome, t], "garota": nome, "turno": t, "no": "desafio"})
			cenarios.append({"nome": "%s_t%d_olheiro" % [nome, t], "garota": nome, "turno": t, "no": "circuito", "olheiro": true})
	for e in dados.encontros.encontros:
		cenarios.append({"nome": "encontro_" + e.id, "garota": "Lira", "turno": 20, "encontro": {"id": e.id, "tipo": "encontro", "outra": "Cassiopeia"}})
	for e in cal.misterios:
		cenarios.append({"nome": "misterio_" + e.id, "garota": "Lira", "turno": 20, "encontro": {"id": e.id, "tipo": "misterio", "outra": "Cassiopeia"}})
	for nome in ["Lira", "Mira", "Nashira", "Capela", "Antares"]:
		for t in range(1, 73):
			cenarios.append({"nome": "%s_t%d_capitulo" % [nome, t], "garota": nome, "turno": t, "capitulo": true})
	var amuletos: Array = dados.amuletos.lista.duplicate()
	amuletos.sort_custom(func(a, b): return a.descricao.length() > b.descricao.length())
	var ids: Array = amuletos.map(func(a): return a.id)
	cenarios.append({"nome": "amuleto_oferta", "garota": "Lira", "turno": 20, "oferta": ids.slice(0, 4)})
	cenarios.append({"nome": "amuleto_cheio", "garota": "Lira", "turno": 20, "oferta": ids.slice(6, 9), "cheio": ids.slice(0, 6)})


func _aplicar(cen: Dictionary) -> bool:
	if c == null or c.nome != cen.garota:
		main._iniciar(cen.garota, {})
		c = main.carreira
	c.encontro_pendente = {}
	c.oferta_amuleto = []
	c.corrida_atual = {}
	c.turno = cen.turno
	c.energia = 100
	var t: int = c.trecho()
	if t >= 0:
		# a rota inteira do trecho pelo nó pedido (coluna 0)
		var mapa: Array = c.mapas[t]
		for linha in mapa:
			linha[0].tipo = cen.get("no", linha[0].tipo)
		c.rota[t] = []
		for linha in mapa:
			c.rota[t].append(0)
	if cen.has("encontro"):
		c.encontro_pendente = cen.encontro
	if cen.get("capitulo", false):
		if c._capitulo_do_turno().is_empty():
			return false
		c.encontro_pendente = {"id": str(c.turno), "tipo": "capitulo", "outra": "", "rival": c.campanha.rival}
	if cen.has("oferta"):
		c.oferta_amuleto = cen.oferta
		c.amuletos = cen.get("cheio", [])
	if cen.get("olheiro", false):
		var lista: Array = c.corridas_opcionais()
		if lista.is_empty():
			if c.objetivo_do_turno().is_empty():
				return false
		else:
			# a de nome mais comprido (a fixa costuma ter as séries)
			lista.sort_custom(func(a, b): return a.nome.length() > b.nome.length())
			c.corrida_atual = lista[0]
	var tela = load("res://scripts/tela_carreira.gd")
	tela.detalhe = ""
	tela.loja_aberta = cen.get("loja", false)
	main.mostrar_carreira(cen.get("msg", ""))
	if cen.has("cheio"):
		main.tela._escolher_amuleto(cen.oferta[0])
	return true


func _process(_delta: float) -> bool:
	if dados == null:
		dados = root.get_node("Dados")
		main._primeira_garota(dados.iniciais[0])
		for nome in ["Lira", "Mira", "Nashira", "Capela", "Antares"]:
			main.perfil.elenco[nome] = {"vinculo": 0, "salva": {}}
		_montar_cenarios()
		return false
	if espera > 0:
		espera -= 1
		if espera == 0:
			var cen: Dictionary = cenarios[i - 1]
			var n := Estouro.checar(root, cen.nome)
			total += n
			if n > 0 and OS.get_environment("CAPTURAR") == "1" or OS.get_environment("CAPTURAR") == "tudo":
				root.get_texture().get_image().save_png("res://testes/capturas/estresse_%s.png" % cen.nome)
		return false
	while i < cenarios.size():
		var cen: Dictionary = cenarios[i]
		i += 1
		if OS.get_environment("FILTRO") != "" and not OS.get_environment("FILTRO") in cen.nome:
			continue
		if _aplicar(cen):
			espera = 12
			return false
	print("estresse: %d cenários, %d estouro(s)" % [cenarios.size(), total])
	load("res://scripts/perfil.gd").apagar()
	load("res://scripts/carreira.gd").apagar_save()
	quit(1 if total > 0 else 0)
	return true
