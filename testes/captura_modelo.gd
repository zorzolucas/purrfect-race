extends SceneTree
## Capturas do modelo da Lira na vitrine (corpo inteiro, correndo e as 6 expressões)
## em testes/capturas/. Uso (com janela, não headless):
## Godot --path . --script res://testes/captura_modelo.gd

var vitrine: Node3D
var passo := 0
var espera := 0
var passos: Array[Callable] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	vitrine = load("res://cenas/vitrine_modelo.tscn").instantiate()
	root.add_child(vitrine)
	passos = [
		func(): vitrine.enquadrar(-35.0),
		func(): _salvar("lira_tres_quartos"),
		func(): vitrine.enquadrar(180.0),
		func(): _salvar("lira_costas"),
		func():
			vitrine.enquadrar(-80.0)
			vitrine.modelo.tocar("correr"),
		func(): _salvar("lira_correndo"),
		func():
			vitrine.modelo.tocar("parada")
			vitrine.enquadrar(-15.0, true),
	]
	for e in ModeloGarota.EXPRESSOES:
		var qual: String = e
		passos.append(func(): vitrine.modelo.expressao(qual))
		passos.append(func(): _salvar("lira_rosto_" + qual))
	# a Lira correndo na pista, entre as cápsulas das outras
	passos.append(func(): _corrida(Corrida3D.Camera.ACOMPANHAR))
	passos.append(func(): _salvar("lira_pista_acompanhar"))
	passos.append(func(): _corrida(Corrida3D.Camera.LATERAL))
	passos.append(func(): _salvar("lira_pista_lateral"))
	passos.append(func(): _corrida(Corrida3D.Camera.FRENTE))
	passos.append(func(): _salvar("lira_pista_frente"))


var mundo: Corrida3D
var _t := 0.0


func _corrida(cam: int) -> void:
	if vitrine:
		vitrine.queue_free()
		vitrine = null
	if mundo == null:
		var cores := [Color("#e8833a"), Color("#7d8a99"), Color("#c9a0dc"), Color("#5fa8d3"), Color("#d35f5f")]
		mundo = Corrida3D.new(cores, ["Lira", "Nashira", "Capela", "Mira", "Shaula"])
		root.add_child(mundo)
	mundo.modo = cam as Corrida3D.Camera
	mundo._primeiro_quadro = true


func _avancar(delta: float) -> void:
	if mundo == null:
		return
	_t += delta
	var xs := []
	var vs := []
	for i in 5:
		xs.append(300.0 + _t * 17.0 + [1.5, 0.0, -1.0, 0.8, -2.0][i])
		vs.append(17.0)
	mundo.atualizar(xs, 1600.0, vs, 1, 0, delta, false)


func _salvar(nome: String) -> void:
	if vitrine:
		vitrine.info.visible = false
	var img := root.get_texture().get_image()
	img.save_png("res://testes/capturas/%s.png" % nome)
	print("captura: ", nome)


func _process(delta: float) -> bool:
	_avancar(delta)
	espera += 1
	if espera < 12:
		return false
	espera = 0
	if passo >= passos.size():
		return true
	passos[passo].call()
	passo += 1
	return false
