class_name ModeloGarota
extends Node3D
## Modelo 3D low-poly de uma garota (GDD §11). As 8 do elenco principal vêm dos modelos que o
## Lucas gerou no Tripo (arte/3d/*.glb), reduzidos e com o mesmo esqueleto e as mesmas
## animações do Mixamo em todas (tools/blender/tripo_preparar.py e tripo_rig.py).
## Sombra pintada na textura (material sem luz) e contorno por casco invertido. Rosto e íris
## estão pintados na textura do Tripo: expressão e olhar só funcionam em modelo que tem o atlas
## do rosto e os ossos dos olhos (o da Lira feito à mão tinha); nos outros não fazem nada.
## Garotas fora da lista continuam de cápsula na corrida.

const MODELOS := {
	"Lira": "res://modelos/lira.glb", "Nashira": "res://modelos/nashira.glb",
	"Mira": "res://modelos/mira.glb", "Capela": "res://modelos/capela.glb",
	"Antares": "res://modelos/antares.glb", "Shaula": "res://modelos/shaula.glb",
	"Polaris": "res://modelos/polaris.glb", "Algol": "res://modelos/algol.glb",
}
## Mesma ordem do atlas (tools/blender/lira.py) e das fichas conceituais.
const EXPRESSOES := ["normal", "fechados", "feliz", "surpresa", "tonta", "piscadinha"]
## Quais íris aparecem em cada expressão: [direita, esquerda] (lado dela).
const IRIS_VISIVEL := {
	"normal": [true, true], "fechados": [false, false], "feliz": [false, false],
	"surpresa": [true, true], "tonta": [false, false], "piscadinha": [true, false],
}
## Animações que tocam uma vez e param no último quadro (o resto fica em loop).
const UMA_VEZ := ["largada", "pular", "sim", "nao", "concordar", "brava", "irritada", "convencida",
	"desdenhar", "gesto_feliz", "suspiro", "desviar_olhar", "sarcasmo", "pensativa", "bocejar"]
const ATLAS_COLS := 3
const ATLAS_ROWS := 2
## Altura do modelo no Blender (m), até o topo do cabelo.
const ALTURA_ORIGINAL := 1.6
## Multiplica a textura (1 = cores do Blender). A sombra já vem pintada.
const BRILHO := Color(1, 1, 1)
const COR_CONTORNO := Color("#2a1a16")
## Espessura do contorno (m, na altura original de 1,6 m).
const CONTORNO := 0.006
## Quanto a íris gira (graus) com olhar(±1, ±1).
const OLHAR_MAX := Vector2(9.0, 6.0)

var nome: String
var animacao: AnimationPlayer
var esqueleto: Skeleton3D
var _rosto: StandardMaterial3D
var _iris: Array = [null, null]  # [direita, esquerda]
var _expressao := "normal"
var _olhar := Vector2.ZERO


static func tem_modelo(nome_garota: String) -> bool:
	return MODELOS.has(nome_garota)


func _init(nome_garota := "Lira", altura := ALTURA_ORIGINAL) -> void:
	nome = nome_garota
	var cena: PackedScene = load(MODELOS[nome])
	var inst := cena.instantiate()
	# no glTF a garota olha para +Z; no Godot "frente" é -Z (look_at)
	inst.rotation_degrees.y = 180.0
	inst.scale = Vector3.ONE * (altura / ALTURA_ORIGINAL)
	add_child(inst)
	_materiais(inst)
	var esqs := inst.find_children("*", "Skeleton3D", true, false)
	esqueleto = esqs[0] as Skeleton3D if esqs.size() > 0 else null
	animacao = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacao:
		for a in animacao.get_animation_list():
			var anim := animacao.get_animation(a)
			anim.loop_mode = Animation.LOOP_NONE if a in UMA_VEZ else Animation.LOOP_LINEAR
		tocar("parada")
	expressao("normal")


func _materiais(no: Node) -> void:
	for filho in no.find_children("*", "MeshInstance3D", true, false):
		var mi := filho as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(s) as BaseMaterial3D
			var nome_mat: String = orig.resource_name if orig else ""
			var m := StandardMaterial3D.new()
			m.albedo_texture = orig.albedo_texture if orig else null
			m.albedo_color = BRILHO
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			# sombra já vem pintada na textura (PDF de pipeline §3): sem luz do Godot
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# a saia da jaqueta e a calota do cabelo são abertas: desenha os dois lados
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if nome_mat.ends_with("Contorno"):
				# casco invertido: só a parte de trás aparece, como contorno escuro
				m.albedo_texture = null
				m.albedo_color = COR_CONTORNO
				m.cull_mode = BaseMaterial3D.CULL_BACK
			elif nome_mat.ends_with("Rosto") or nome_mat.contains("Iris"):
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_BACK
				if nome_mat.ends_with("Rosto"):
					_rosto = m
				elif nome_mat.ends_with("IrisD"):
					_iris[0] = m
				else:
					_iris[1] = m
			elif mi.mesh.get_surface_count() == 1:
				# modelo do Tripo: uma malha só, sem casco de contorno; o contorno é uma
				# segunda passada que cresce pela normal e só mostra o lado de trás
				var c := StandardMaterial3D.new()
				c.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				c.albedo_color = COR_CONTORNO
				c.cull_mode = BaseMaterial3D.CULL_FRONT
				c.grow = true
				c.grow_amount = CONTORNO
				m.next_pass = c
			mi.set_surface_override_material(s, m)


## Toca uma animação (ver `animacoes()`). velocidade multiplica o ritmo.
func tocar(anim: String, velocidade := 1.0, mistura := 0.2) -> void:
	if animacao == null or not animacao.has_animation(anim):
		return
	if animacao.current_animation != anim:
		animacao.play(anim, mistura)
	animacao.speed_scale = velocidade


func animacoes() -> PackedStringArray:
	return animacao.get_animation_list() if animacao else PackedStringArray()


## Duração de um ciclo (s), para casar o ritmo da passada com a velocidade.
func duracao(anim: String) -> float:
	if animacao == null or not animacao.has_animation(anim):
		return 1.0
	return animacao.get_animation(anim).length


func expressao(qual: String) -> void:
	var i := EXPRESSOES.find(qual)
	if i < 0 or _rosto == null:
		return
	_expressao = qual
	_rosto.uv1_offset = Vector3(float(i % ATLAS_COLS) / ATLAS_COLS, float(i / ATLAS_COLS) / ATLAS_ROWS, 0.0)
	var vis: Array = IRIS_VISIVEL[qual]
	for k in 2:
		var mat := _iris[k] as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 1.0 if vis[k] else 0.0


func expressao_atual() -> String:
	return _expressao


## Direção do olhar, de -1 a 1 em cada eixo (x: para a direita da tela, y: para cima).
func olhar(direcao: Vector2) -> void:
	_olhar = direcao.clamp(Vector2(-1, -1), Vector2(1, 1))
	if esqueleto == null:
		return
	for lado in ["L", "R"]:
		var b := esqueleto.find_bone("eye." + lado)
		if b < 0:
			continue
		# o osso do olho aponta para fora do rosto (+Y local): gira em torno de Z e X locais
		var rot := Quaternion(Vector3(0, 0, 1), deg_to_rad(-_olhar.x * OLHAR_MAX.x)) \
			* Quaternion(Vector3(1, 0, 0), deg_to_rad(_olhar.y * OLHAR_MAX.y))
		esqueleto.set_bone_pose_rotation(b, esqueleto.get_bone_rest(b).basis.get_rotation_quaternion() * rot)


func olhar_atual() -> Vector2:
	return _olhar
