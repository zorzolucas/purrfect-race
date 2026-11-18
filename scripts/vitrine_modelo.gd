extends Node3D
## Vitrine do modelo low-poly: a garota num disco de grama, girando devagar.
## Teclas: 1–6 trocam a expressão, Espaço alterna parada/correr, setas giram, G pausa o giro.
## Abra cenas/vitrine_modelo.tscn no editor e aperte F6.

@export var garota := "Lira"
var modelo: ModeloGarota
var camera: Camera3D
var info: Label
var girar := true


func _ready() -> void:
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#20283a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b9d3ee")
	env.ambient_light_energy = 0.6
	amb.environment = env
	add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 25, 0)
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	sol.shadow_bias = 0.08
	sol.shadow_normal_bias = 2.0
	add_child(sol)

	var disco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.9
	cil.bottom_radius = 0.95
	cil.height = 0.08
	cil.radial_segments = 12
	disco.mesh = cil
	var mg := StandardMaterial3D.new()
	mg.albedo_color = Color("#3f7f3c")
	mg.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	disco.material_override = mg
	disco.position.y = -0.04
	add_child(disco)

	modelo = ModeloGarota.new(garota)
	modelo.rotation.y = PI
	add_child(modelo)

	camera = Camera3D.new()
	camera.fov = 35.0
	add_child(camera)
	camera.position = Vector3(0, 1.05, 3.9)
	camera.look_at(Vector3(0, 0.85, 0))
	camera.make_current()

	var tela := CanvasLayer.new()
	add_child(tela)
	info = Label.new()
	info.position = Vector2(16, 12)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_constant_override("outline_size", 6)
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	tela.add_child(info)
	_atualizar_info()


func _process(delta: float) -> void:
	if girar:
		modelo.rotation.y += delta * 0.5


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode >= KEY_1 and k.keycode < KEY_1 + ModeloGarota.EXPRESSOES.size():
		modelo.expressao(ModeloGarota.EXPRESSOES[k.keycode - KEY_1])
	elif k.keycode == KEY_SPACE:
		modelo.tocar("parada" if modelo.animacao.current_animation == "correr" else "correr")
	elif k.keycode == KEY_LEFT:
		modelo.rotation.y -= 0.4
	elif k.keycode == KEY_RIGHT:
		modelo.rotation.y += 0.4
	elif k.keycode == KEY_G:
		girar = not girar
	_atualizar_info()


## Posição fixa da câmera e do modelo, usada pelas capturas.
func enquadrar(angulo_graus: float, close_rosto := false) -> void:
	girar = false
	# o modelo olha para -Z (frente da corrida); a câmera fica em +Z
	modelo.rotation.y = deg_to_rad(angulo_graus + 180.0)
	if close_rosto:
		camera.fov = 20.0
		camera.position = Vector3(0, 1.43, 1.7)
		camera.look_at(Vector3(0, 1.4, 0))
	else:
		camera.fov = 35.0
		camera.position = Vector3(0, 1.05, 3.9)
		camera.look_at(Vector3(0, 0.85, 0))


func _atualizar_info() -> void:
	if info == null:
		return
	var anim: String = modelo.animacao.current_animation if modelo.animacao else "-"
	info.text = "%s · %s · %s\n1–6 expressão · Espaço anda/corre · setas giram · G pausa" % [
		garota, anim, modelo.expressao_atual()]
