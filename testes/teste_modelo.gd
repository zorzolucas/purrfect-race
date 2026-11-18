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
	_checar(ModeloS.tem_modelo("Lira") and not ModeloS.tem_modelo("Nashira"), "só a Lira tem modelo")
	var m = ModeloS.new("Lira", 1.6)
	root.add_child(m)

	var skel: Skeleton3D = m.find_children("*", "Skeleton3D", true, false)[0] if m.find_children("*", "Skeleton3D", true, false).size() > 0 else null
	_checar(skel != null, "tem Skeleton3D")
	if skel:
		for osso in ["hips", "spine", "chest", "neck", "head", "thigh.L", "shin.R", "foot.L",
				"upper_arm.R", "forearm.L", "hand.R", "ear.L", "ear.R", "tail.001", "tail.006"]:
			_checar(skel.find_bone(osso) >= 0, "osso " + osso)

	_checar(m.animacao != null, "tem AnimationPlayer")
	if m.animacao:
		for a in ["parada", "correr"]:
			_checar(m.animacao.has_animation(a), "animação " + a)
			if m.animacao.has_animation(a):
				_checar(m.animacao.get_animation(a).loop_mode == Animation.LOOP_LINEAR, "loop " + a)

	var tris := 0
	var superficies := 0
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			superficies += 1
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			tris += idx.size() / 3 if idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size() / 3
			var mat := mi.get_surface_override_material(s) as StandardMaterial3D
			_checar(mat != null and mat.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "material toon")
			_checar(mat != null and mat.albedo_texture != null, "textura de paleta/rosto")
	_checar(superficies == 2, "2 superfícies: paleta e rosto (veio %d)" % superficies)
	_checar(tris > 800 and tris < 4000, "triângulos low-poly (veio %d)" % tris)

	# altura: o topo das orelhas fica perto de 1,6 m
	var aabb := AABB()
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		aabb = aabb.merge(_relativo(mi, m) * mi.get_aabb())
	_checar(aabb.size.y > 1.45 and aabb.size.y < 1.85, "altura (veio %.2f)" % aabb.size.y)

	m.expressao("surpresa")
	_checar(m.expressao_atual() == "surpresa", "troca de expressão")
	_checar(m._rosto != null and m._rosto.uv1_offset.is_equal_approx(Vector3(2.0 / 3.0, 0.5, 0)), "UV da expressão no atlas")

	print("tris=%d altura=%.2f" % [tris, aabb.size.y])
	print("MODELO OK" if falhas.is_empty() else "MODELO FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
