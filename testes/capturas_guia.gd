extends SceneTree
## Capturas do guia do jogo em testes/capturas/: o guia aberto sozinho no começo, cada página
## de cada capítulo e o guia por cima da carreira (F1).
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso (com janela, não headless): Godot --path . --script res://testes/capturas_guia.gd

var main: Node
var passo := 0
var espera := 0
var ESPERA := int(OS.get_environment("CAPTURA_ESPERA")) if OS.get_environment("CAPTURA_ESPERA") != "" else 60
var passos: Array[Callable] = []


func _guia():
	return load("res://scripts/tela_guia.gd").aberto


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://captura_guia_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://captura_guia_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	var dados: Node = root.get_node("Dados")
	if dados.tutorial.is_empty():
		dados._ready()
	passos.append(func(): main._primeira_garota(dados.iniciais[0]))
	var caps: Array = dados.tutorial.capitulos
	for i in caps.size():
		for j in caps[i].paginas.size():
			var ci: int = i
			var pj: int = j
			passos.append(func():
				var g = _guia()
				g.cap = ci
				g.pag = pj
				g._montar())
			passos.append(func(): _salvar("70_guia_%02d_%s_%d" % [ci + 1, caps[ci].id, pj + 1]))
	passos.append(func():
		_guia().fechar()
		main._comecar_carreira(dados.iniciais[0].nome))
	passos.append(func():
		var c = main.carreira
		c.encontro_pendente = {}
		main.mostrar_carreira(""))
	passos.append(func():
		var ev := InputEventKey.new()
		ev.keycode = KEY_F1
		ev.pressed = true
		Input.parse_input_event(ev))
	passos.append(func(): _salvar("71_guia_na_carreira"))
	passos.append(func(): _guia().fechar())
	passos.append(func(): _salvar("72_carreira_com_botao_guia"))
	passos.append(func(): main.mostrar_academia(""))
	passos.append(func(): _salvar("73_academia_com_botao_guia"))


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
