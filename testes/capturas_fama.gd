extends SceneTree
## Capturas do Prestígio, da meta de fama, dos boosts e do equipamento (docs/fama-e-crescimento.md).
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas_fama.gd
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
			main.perfil = perfil_s.novo("Lira")
			main._comecar_carreira("Lira"),
		func():
			var c = main.carreira
			_avancar_ate(30)
			c.encontro_pendente = {}
			c.fama = 3400
			c.prestigio_visto = c.prestigio()
			c.equip_pendente = 1
			c.adicionar_boost("embalo")
			c.adicionar_boost("licao", "est")
			c.adicionar_boost("cansaco")
			while c.pendencia() == "mapa":
				c.escolher_no(c.opcoes_mapa()[0])
			main.mostrar_carreira("Lira terminou em 1º. Embalo: +10% em todos os treinos! Prestígio 3: Destaque (ganho ×1,12), e um grau de equipamento para escolher!"),
		func():
			_salvar("70_equipamento"),
		func():
			var c = main.carreira
			c.escolher_equipamento("vel")
			main.mostrar_carreira("Equipamento de Velocidade no grau 1: +6% de ganho."),
		func():
			_salvar("71_turno_prestigio")
			var c = main.carreira
			# um turno com corridas opcionais, para os cartões mostrarem os atributos
			var guard := 0
			while c.corridas_opcionais().is_empty() and guard < 40:
				guard += 1
				c.descansar()
				c.encontro_pendente = {}
				c.oferta_amuleto = []
				while c.pendencia() == "mapa":
					c.escolher_no(c.opcoes_mapa()[0])
				if c.pendencia() == "objetivo":
					c.registrar_corrida(1, {"rival_pos": 12})
					c.oferta_amuleto = []
					c.encontro_pendente = {}
			main.mostrar_carreira(""),
		func():
			_salvar("72_cartoes_corrida"),
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
