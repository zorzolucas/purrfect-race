extends SceneTree
## Confere o modelo low-poly da Lira importado do Blender: esqueleto com orelhas e rabo,
## animações, material toon com paleta e troca de expressão pelo atlas do rosto.
## Uso: Godot --headless --path . --script res://testes/teste_modelo.gd
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


## Transform do nó em relação a um ancestral (sem depender da árvore já pronta).
func _relativo(no: Node3D, ate: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = no
	while n != ate and n is Node3D:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _initialize() -> void:
	var ModeloS: GDScript = load("res://scripts/modelo_garota.gd")
	var elenco := ["Lira", "Nashira", "Mira", "Capela", "Antares", "Shaula", "Polaris", "Algol"]
	_checar(not ModeloS.tem_modelo("Altair"), "fora do elenco principal continua de cápsula")
	var resumo := []
	for nome in elenco:
		_checar(ModeloS.tem_modelo(nome), nome + " tem modelo")
		if ModeloS.tem_modelo(nome):
			resumo.append(_conferir(ModeloS, nome))
	print("\n".join(resumo))
	print("MODELO OK" if falhas.is_empty() else "MODELO FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)


func _conferir(ModeloS: GDScript, nome: String) -> String:
	var m = ModeloS.new(nome, 1.6)
	root.add_child(m)

	# o mesmo esqueleto (o da Lira) em todas
	var skel: Skeleton3D = m.esqueleto
	_checar(skel != null, nome + ": tem Skeleton3D")
	if skel:
		for osso in ["hips", "spine", "chest", "neck", "head", "thigh.L", "shin.R", "foot.L",
				"upper_arm.R", "forearm.L", "hand.R", "ear.L", "ear.R", "tail.001", "tail.006"]:
			_checar(skel.find_bone(osso) >= 0, nome + ": osso " + osso)

	# e as mesmas animações
	_checar(m.animacao != null, nome + ": tem AnimationPlayer")
	if m.animacao:
		_checar(m.animacao.get_animation_list().size() >= 31, nome + ": 31 animações")
		for a in ["parada", "andar", "trote", "correr", "sprint", "comemorar", "perder", "treino_vel",
				"treino_est", "treino_pod", "treino_det", "treino_int"]:
			_checar(m.animacao.has_animation(a), nome + ": animação " + a)
			if m.animacao.has_animation(a):
				_checar(m.animacao.get_animation(a).loop_mode == Animation.LOOP_LINEAR, nome + ": loop " + a)
		_checar(m.animacao.has_animation("sim") and m.animacao.get_animation("sim").loop_mode == Animation.LOOP_NONE,
			nome + ": gesto toca uma vez")

	var tris := 0
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			tris += idx.size() / 3 if idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size() / 3
			var mat := mi.get_surface_override_material(s) as StandardMaterial3D
			_checar(mat != null and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, nome + ": material sem luz")
			_checar(mat != null and mat.albedo_texture != null, nome + ": textura")
			_checar(mat != null and mat.next_pass != null, nome + ": contorno")
	_checar(tris > 8000 and tris < 20000, nome + ": triângulos low-poly (veio %d)" % tris)

	var aabb := AABB()
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		aabb = aabb.merge(_relativo(mi, m) * mi.get_aabb())
	_checar(aabb.size.y > 1.45 and aabb.size.y < 1.85, nome + ": altura (veio %.2f)" % aabb.size.y)

	# sem atlas de rosto nem ossos de olho: expressão e olhar não quebram
	m.expressao("tonta")
	m.olhar(Vector2(1, 0))
	m.tocar("correr")
	m.queue_free()
	return "%s: tris=%d altura=%.2f anims=%d" % [nome, tris, aabb.size.y, m.animacoes().size()]
