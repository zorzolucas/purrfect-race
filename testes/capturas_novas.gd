extends SceneTree
## Capturas das telas do olheiro, da instrução, das séries e da madrinha em testes/capturas/.
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas_novas.gd
## Na nuvem dá para rodar com xvfb-run (ver docs/campanhas.md §7).

var main: Node
var dados: Node
var passo := 0
var espera := 0
var ESPERA := int(OS.get_environment("CAPTURA_ESPERA")) if OS.get_environment("CAPTURA_ESPERA") != "" else 75
var passos: Array[Callable] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://captura_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://captura_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	dados = root.get_node("Dados")
	passos = [
		func():
			# perfil com 2 garotas salvas, para a tela da madrinha ter escolha
			var p = perfil_s.novo("Lira")
			p.elenco["Lira"].vinculo = 2
			p.elenco["Mira"] = {"vinculo": 1, "salva": {"attrs": {"vel": 780, "est": 820, "pod": 700, "det": 760, "int": 640},
				"nota": "A", "objetivos": 8, "titulos": ["Estrela da Longa"], "dist": "longa", "piso": "grama"}}
			p.elenco["Capela"] = {"vinculo": 0, "salva": {"attrs": {"vel": 560, "est": 430, "pod": 520, "det": 480, "int": 400},
				"nota": "C", "objetivos": 4, "dist": "milha", "piso": "grama"}}
			main.perfil = p
			main._comecar_carreira("Lira"),
		func():
			_salvar("17_madrinha")
			main.tela.escolheu.emit(load("res://scripts/carreira.gd").madrinha_de("Mira", main.perfil.elenco.Mira.salva)),
		func():
			_avancar_ate(13)
			_resolver_encontro()
			main.mostrar_carreira("A Estreia chegou."),
		func():
			_salvar("18_olheiro_objetivo")
			# ano 3: forte, com uma Ouro do calendário fixo já vencida para mostrar as séries
			var c = main.carreira
			_avancar_ate(51)
			for k in c.attrs:
				c.attrs[k] = 760.0
			c.fama = 6000
			c.resultados.append({"turno": 41, "nome": "Prêmio Duna", "cat": "ouro", "posicao": 1, "objetivo": 0,
				"ok": true, "fama": 800, "dist": "milha", "piso": "terra", "etiqueta": "disputada", "fixa": true})
			c.turno = 52
			c.encontro_pendente = {}
			c.corrida_atual = {}
			while c.pendencia() == "mapa":
				c.escolher_no(c.opcoes_mapa()[0])
			c.encontro_pendente = {}
			main.mostrar_carreira("Ano 3: a Taça Poeira Alta está no calendário."),
		func():
			_salvar("19_cartoes_olheiro")
			var c = main.carreira
			var lista: Array = c.corridas_opcionais()
			if not lista.is_empty():
				main.tela._correr(lista[0]),
		func():
			_salvar("20_olheiro_serie")
			var c = main.carreira
			c.titulos = [{"id": "triplice_milha_grama", "nome": "Estrela da Milha", "turno": 64}]
			c.corrida_atual = {}
			main.mostrar_carreira(""),
		func():
			_salvar("21_titulos"),
	]


func _resolver_encontro() -> void:
	var c = main.carreira
	while not c.encontro_pendente.is_empty():
		c.escolher(0)


## Joga sozinho (sem tela) até o turno pedido.
func _avancar_ate(alvo: int) -> void:
	var c = main.carreira
	var guard := 0
	while c.turno < alvo and not c.terminou and guard < 300:
		guard += 1
		match c.pendencia():
			"encontro": c.escolher(0)
			"mapa": c.escolher_no(c.opcoes_mapa()[0])
			"ferias": c.escolher_acampamento("praia")
			"corrida", "objetivo":
				c.registrar_corrida(1, {"rival_pos": 12})
			"amuleto": c.escolher_amuleto(c.oferta_amuleto[0], c.amuletos[0] if c.amuletos.size() >= c.limite_amuletos() else "")
			_:
				if c.energia < 45:
					c.descansar()
				else:
					c.treinar(["vel", "est", "pod"][c.turno % 3])


func _salvar(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)
	load("res://testes/estouro.gd").checar(root, nome)


func _process(_delta: float) -> bool:
	espera += 1
	if espera < ESPERA:
		return false
	espera = 0
	if passo >= passos.size():
		load("res://scripts/perfil.gd").apagar()
		load("res://scripts/carreira.gd").apagar_save()
		return true
	passos[passo].call()
	passo += 1
	return false
