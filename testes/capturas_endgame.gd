extends SceneTree
## Capturas das telas do endgame (docs/endgame.md) em testes/capturas/: academia com o
## desafio da semana e a magnitude, circuito, escalação, resultado de uma copa, carreira com
## maldições e fim de um desafio. Usa caminhos de save próprios.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas_endgame.gd
## Na nuvem: xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 --resolution 1600x900 --script res://testes/capturas_endgame.gd

var main: Node
var dados: Node
var passo := 0
var espera := 0
var passos: Array[Callable] = []


func _salva(nome: String, media: float) -> Dictionary:
	var g: Dictionary = dados.garota(nome)
	var soma := 0.0
	for k in SimCorrida.KEYS:
		soma += g.atributos[k]
	var a := {}
	for k in SimCorrida.KEYS:
		a[k] = roundi(g.atributos[k] * media * 5.0 / soma)
	return {"attrs": a, "nota": dados.nota(a), "objetivos": 8, "habilidades": dados.habilidades.get("iniciais", []),
		"estilo": g.estilo, "dist": dados.config_carreira(nome).distancia, "piso": dados.config_carreira(nome).piso}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://captura_endgame_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://captura_endgame_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	dados = root.get_node("Dados")
	passos = [
		func():
			var p = perfil_s.novo("Lira")
			p.moeda = 840
			p.giro = 6
			var elenco := {"Lira": 880, "Mira": 860, "Electra": 900, "Nashira": 820, "Antares": 840, "Deneb": 800, "Shaula": 780}
			for n in elenco:
				p.elenco[n] = {"vinculo": 2 + elenco[n] % 3, "salva": _salva(n, elenco[n])}
			p.magnitudes["Lira"] = {"liberada": 3, "vencida": 2}
			p.magnitudes["Mira"] = {"liberada": 1, "vencida": 0}
			for id in ["sprint", "milha", "media"]:
				p.circuito["bronze:" + id] = {"vitorias": 1, "melhor": 24, "giro_premio": 5}
			p.circuito["prata:sprint"] = {"vitorias": 2, "melhor": 21, "giro_premio": 6}
			p.desafios["7"] = {"tentativas": 2, "melhor": {"objetivos": 6, "gp": false, "fama": 5240, "nota": "A"}, "pago": true}
			p.salvar()
			main.perfil = p
			main.mostrar_academia("Pool girou: o circuito tem condições novas nesta rotação."),
		func():
			_salvar("50_academia_endgame")
			main.mostrar_circuito(),
		func():
			_salvar("51_circuito")
			main.tela._trocar_nivel(1),
		func():
			_salvar("52_circuito_prata")
			main.tela._abrir("milha"),
		func():
			_salvar("53_escalacao")
			main.tela._correr(),
		func():
			_salvar("54_resultado_copa")
			main._comecar_carreira("Lira", 3),
		func():
			# sem madrinha, para ir direto à carreira na Magnitude 3
			if main.tela.has_signal("escolheu"):
				main.tela.escolheu.emit({}),
		func():
			var c = main.carreira
			c.maldicoes = ["coleira", "nuvem"]
			main.mostrar_carreira("Magnitude 3: as metas sobem um degrau."),
		func():
			_salvar("55_carreira_magnitude")
			main._comecar_desafio(),
		func():
			_salvar("56_carreira_desafio")
			var c = main.carreira
			c.turno = 73
			c.terminou = true
			c.fama = 6100
			main.mostrar_carreira(""),
		func():
			_salvar("57_fim_desafio"),
	]


func _salvar(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)


func _process(_delta: float) -> bool:
	espera += 1
	if espera < 20:
		return false
	espera = 0
	if passo >= passos.size():
		load("res://scripts/perfil.gd").apagar()
		load("res://scripts/carreira.gd").apagar_save()
		return true
	passos[passo].call()
	passo += 1
	return false
