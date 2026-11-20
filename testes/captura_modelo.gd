extends SceneTree
## Capturas dos modelos 3D das 8 garotas (arte/3d, do Tripo) em testes/capturas/: elenco lado a
## lado, as 8 em poses diferentes e a corrida com todas na pista.
## Uso (com janela, não headless): Godot --path . --script res://testes/captura_modelo.gd

const ELENCO := ["Lira", "Nashira", "Mira", "Capela", "Antares", "Shaula", "Polaris", "Algol"]
var palco: Node3D
var modelos: Array = []
var camera: Camera3D
var passo := 0
var espera := 0
var passos: Array[Callable] = []
var mundo: Corrida3D
var _t := 0.0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://testes/capturas"))
	_palco()
	passos = [
		func(): _pose("parada", 0.0, 1.0),
		func(): _salvar("elenco_frente"),
		func(): _pose("parada", -35.0, 1.0),
		func(): _salvar("elenco_tres_quartos"),
		func(): _pose("correr", -90.0, 0.3),
		func(): _salvar("elenco_correndo"),
		func(): _poses_variadas(),
		func(): _salvar("elenco_poses"),
		func(): _corrida(Corrida3D.Camera.ACOMPANHAR),
		func(): _salvar("pista_acompanhar"),
		func(): _corrida(Corrida3D.Camera.LATERAL),
		func(): _salvar("pista_lateral"),
		func(): _corrida(Corrida3D.Camera.FRENTE),
		func(): _salvar("pista_frente"),
	]


func _palco() -> void:
	palco = Node3D.new()
	root.add_child(palco)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#bfe3f5")
	amb.environment = env
	palco.add_child(amb)
	var chao := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(30, 10)
	chao.mesh = pl
	var mg := StandardMaterial3D.new()
	mg.albedo_color = Color("#6fae5a")
	mg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chao.material_override = mg
	palco.add_child(chao)
	for i in ELENCO.size():
		var m := ModeloGarota.new(ELENCO[i])
		m.position.x = (i - (ELENCO.size() - 1) / 2.0) * 1.05
		palco.add_child(m)
		modelos.append(m)
		var etq := Label3D.new()
		etq.text = ELENCO[i]
		etq.font_size = 40
		etq.pixel_size = 0.004
		etq.outline_size = 10
		etq.position = Vector3(m.position.x, 0.05, 0.6)
		etq.rotation_degrees.x = -30
		palco.add_child(etq)
	camera = Camera3D.new()
	camera.fov = 30.0
	palco.add_child(camera)
	camera.look_at_from_position(Vector3(0, 1.1, 9.6), Vector3(0, 0.8, 0))
	camera.make_current()


## Todas na mesma animação, viradas para a câmera (+Z) mais `angulo` graus.
func _pose(anim: String, angulo: float, quando: float) -> void:
	for m in modelos:
		m.rotation_degrees.y = 180.0 + angulo
		m.tocar(anim, 1.0, 0.0)
		m.animacao.seek(m.duracao(anim) * quando * 0.5, true)
		m.animacao.pause()


func _poses_variadas() -> void:
	var anims := ["comemorar", "animada", "brava", "convencida", "pensativa", "gesto_feliz", "sim", "desdenhar"]
	for i in modelos.size():
		var m: ModeloGarota = modelos[i]
		m.rotation_degrees.y = 180.0 - 20.0
		m.tocar(anims[i], 1.0, 0.0)
		m.animacao.seek(m.duracao(anims[i]) * 0.45, true)
		m.animacao.pause()


func _corrida(cam: int) -> void:
	if palco:
		palco.queue_free()
		palco = null
	if mundo == null:
		var cores := []
		for i in ELENCO.size():
			cores.append(Color.from_hsv(i / 8.0, 0.5, 0.9))
		mundo = Corrida3D.new(cores, ELENCO)
		root.add_child(mundo)
	mundo.modo = cam as Corrida3D.Camera
	mundo._primeiro_quadro = true


func _avancar(delta: float) -> void:
	if mundo == null:
		return
	_t += delta
	var xs := []
	var vs := []
	for i in ELENCO.size():
		xs.append(300.0 + _t * 17.0 + [1.5, 0.0, -1.0, 0.8, -2.0, 0.4, -0.5, 2.2][i])
		vs.append(17.0)
	mundo.atualizar(xs, 1600.0, vs, 1, 0, delta, false)


func _salvar(nome: String) -> void:
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
