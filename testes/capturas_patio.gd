extends SceneTree
## Capturas do pátio, das conversas e dos encontros com as expressões das fichas em
## testes/capturas/. Usa caminhos de save próprios (não mexe no perfil nem na carreira).
## Uso (com janela): Godot --path . --script res://testes/capturas_patio.gd
## Na nuvem: xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3
##   --resolution 1600x900 --script res://testes/capturas_patio.gd

var main: Node
var passo := 0
var espera := 0
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
	passos = [
		func():
			var p = perfil_s.novo("Lira")
			for n in ["Mira", "Capela", "Nashira", "Antares", "Shaula"]:
				p.elenco[n] = {"vinculo": 0, "salva": {}}
			main.perfil = p
			main.mostrar_academia(),
		func():
			_salvar("28_academia_retratos")
			main._iniciar("Lira", {})
			main.carreira.encontro_pendente = {},
		func():
			# turno 1: aniversário da Mira (ninguém sabe)
			main.mostrar_patio(),
		func(): pass,
		func():
			_salvar("29_patio_aniversario")
			main.tela.abrir("Mira"),
		func():
			_salvar("30_patio_conversa")
			main.tela._escolher("Mira", 1),
		func(): pass,
		func():
			_salvar("31_patio_reacao")
			main.tela.voltar.emit(main.tela._resultado),
		func():
			_salvar("32_carreira_faixa_patio")
			# um turno comum: hábitos de cada uma
			var c = main.carreira
			c.turno = 4
			c.encontro_pendente = {}
			while c.pendencia() == "mapa":
				c.escolher_no(c.opcoes_mapa()[0])
			c.encontro_pendente = {}
			c.conversa_turno = 0
			main.mostrar_patio(),
		func(): pass,
		func(): pass,
		func():
			_salvar("33_patio_habitos")
			main.tela.abrir("Capela"),
		func():
			_salvar("34_patio_capela")
			# encontro genérico com a expressão de quem fala
			var c = main.carreira
			c.encontro_pendente = {"id": "gen_conselho", "tipo": "encontro", "outra": "Shaula"}
			main.mostrar_carreira(""),
		func():
			_salvar("35_encontro_expressao")
			main.tela.atualizou.emit(main.carreira.escolher(0)),
		func(): pass,
		func():
			_salvar("36_encontro_reacao")
			var c = main.carreira
			c.encontro_pendente = {"id": "lira_rival", "tipo": "encontro", "outra": ""}
			main.mostrar_carreira(""),
		func():
			_salvar("37_encontro_lira")
			# noite de estrelas e chuva
			var c = main.carreira
			c.encontro_pendente = {}
			_turno_com_clima(c, "estrelas")
			main.mostrar_patio(),
		func(): pass,
		func():
			_salvar("38_patio_estrelas")
			var c = main.carreira
			_turno_com_clima(c, "chuva")
			main.mostrar_patio(),
		func(): pass,
		func():
			_salvar("39_patio_chuva")
			var c = main.carreira
			c.turno = 30
			c.resultados.append({"turno": 29, "nome": "Taça", "cat": "aberta", "posicao": 1, "objetivo": 0, "ok": true, "fama": 100})
			main.mostrar_patio(),
		func(): pass,
		func(): pass,
		func():
			_salvar("40_patio_vitoria")
			main.mostrar_patio_academia(),
		func(): pass,
		func():
			_salvar("41_patio_academia"),
	]


## Procura um turno (sem aniversário nem corrida antes) com o clima pedido.
## Troca a semente se precisar (só para a captura: o clima sai da semente).
func _turno_com_clima(c, clima: String) -> void:
	c.resultados = []
	for s in range(c.semente, c.semente + 200):
		c.semente = s
		for t in range(2, 72):
			c.turno = t
			if c.evento_patio().id == clima and c.pendencia() == "":
				c.conversa_turno = 0
				return


func _salvar(nome: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)


func _process(_delta: float) -> bool:
	espera += 1
	if espera < 75:
		return false
	espera = 0
	if passo >= passos.size():
		load("res://scripts/perfil.gd").apagar()
		load("res://scripts/carreira.gd").apagar_save()
		return true
	passos[passo].call()
	passo += 1
	return false
