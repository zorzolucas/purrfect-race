class_name ModeloGarota
extends Node3D
## Modelo 3D low-poly de uma garota (GDD §11), importado do Blender em glTF.
## Aplica o material toon com a paleta, toca as animações e troca a expressão
## do rosto deslocando a UV no atlas (3 × 2 expressões).
## Por enquanto só a Lira tem modelo; as outras continuam de cápsula na corrida.

const MODELOS := {"Lira": "res://modelos/lira.glb"}
const EXPRESSOES := ["normal", "feliz", "determinada", "cansada", "triste", "surpresa"]
const ATLAS_COLS := 3
const ATLAS_ROWS := 2
## Altura do modelo no Blender (m). A corrida usa outra escala, ver `altura`.
const ALTURA_ORIGINAL := 1.6
## O toon acende o lado claro por inteiro; escurece a paleta para não estourar no sol da pista.
const BRILHO := Color(0.62, 0.62, 0.62)

var nome: String
var animacao: AnimationPlayer
var _rosto: StandardMaterial3D
var _expressao := "normal"


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
	animacao = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animacao:
		for a in animacao.get_animation_list():
			animacao.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		tocar("parada")


func _materiais(no: Node) -> void:
	for filho in no.find_children("*", "MeshInstance3D", true, false):
		var mi := filho as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var orig := mi.mesh.surface_get_material(s) as BaseMaterial3D
			var m := StandardMaterial3D.new()
			m.albedo_texture = orig.albedo_texture if orig else null
			m.albedo_color = BRILHO
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			m.roughness = 1.0
			# a faixa da jaqueta e a calota do cabelo são abertas: desenha os dois lados
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if orig and orig.resource_name.ends_with("Rosto"):
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_BACK
				_rosto = m
			mi.set_surface_override_material(s, m)


## Toca uma animação ("parada" ou "correr"). velocidade multiplica o ritmo.
func tocar(anim: String, velocidade := 1.0) -> void:
	if animacao == null or not animacao.has_animation(anim):
		return
	if animacao.current_animation != anim:
		animacao.play(anim, 0.2)
	animacao.speed_scale = velocidade


func expressao(qual: String) -> void:
	var i := EXPRESSOES.find(qual)
	if i < 0 or _rosto == null:
		return
	_expressao = qual
	_rosto.uv1_offset = Vector3(float(i % ATLAS_COLS) / ATLAS_COLS, float(i / ATLAS_COLS) / ATLAS_ROWS, 0.0)


func expressao_atual() -> String:
	return _expressao
