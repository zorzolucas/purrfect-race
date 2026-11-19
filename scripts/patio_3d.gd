class_name Patio3D
extends Node3D
## Pátio da academia em 3D (GDD §11.3): cenário de primitivas (prédio, marquise, fonte,
## árvores, bancos, beira da pista) e as colegas passeando como sprites das fichas
## conceituais, cada uma com o seu hábito (data/patio.json). O clima muda a luz e o céu, e
## o evento do turno arruma a cena (festa em roda, todas na marquise, bolo na fonte...).
## Quem não tem ficha vira uma gata de primitivas com as cores da pelagem.

signal clicou(nome: String)

const ALTURA := 1.9           # altura das garotas (m), um pouco acima da escala para ler melhor
const VEL_ANDAR := 1.3
const AREA := Rect2(-7.5, -5.2, 15.0, 8.0)   # x, z onde elas passeiam
const COR_GRAMA := Color("#4a8238")
const COR_CAMINHO := Color("#b3a184")
const COR_PREDIO := Color("#d9c7a5")
const COR_TELHADO := Color("#b5533c")
const COR_PEDRA := Color("#a9a39a")
const COR_MADEIRA := Color("#8a5a3b")
const COR_PELE := Color("#f3c9a5")

var colegas: Array
var evento: Dictionary
var clima: String
var camera: Camera3D
var gatas := {}               # nome -> Gata
var _dados: Dictionary
var _emotes := {}             # ícone -> ViewportTexture
var _rng := RandomNumberGenerator.new()


func _init(colegas_: Array, evento_: Dictionary = {}, clima_ := "bom", semente := 0) -> void:
	colegas = colegas_
	evento = evento_ if not evento_.is_empty() else {"id": "habitos", "outra": ""}
	clima = clima_
	_rng.seed = semente if semente != 0 else 7


func _ready() -> void:
	_dados = Dados.patio
	_ambiente()
	_cenario()
	camera = Camera3D.new()
	camera.fov = 46.0
	add_child(camera)
	camera.look_at_from_position(Vector3(0, 5.4, 11.0), Vector3(0, 1.1, -2.6))
	camera.make_current()
	for i in colegas.size():
		var g := Gata.new(self, colegas[i])
		add_child(g)
		gatas[colegas[i]] = g
	_arrumar_cena()


func _process(delta: float) -> void:
	for n in gatas:
		gatas[n].passo(delta)
	_vizinhas()


# ---------- clima e cenário ----------

func _material(cor: Color, transparente := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	if transparente:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _caixa(tam: Vector3, pos: Vector3, cor: Color, pai: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = _material(cor)
	mi.position = pos
	pai.add_child(mi)
	return mi


func _cilindro(r_baixo: float, r_cima: float, h: float, pos: Vector3, cor: Color, lados := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.bottom_radius = r_baixo
	c.top_radius = r_cima
	c.height = h
	c.radial_segments = lados
	c.rings = 1
	mi.mesh = c
	mi.material_override = _material(cor)
	mi.position = pos
	add_child(mi)
	return mi


func _ambiente() -> void:
	var noite := clima == "estrelas"
	var cores: Array = {
		"bom": ["#3d6fb6", "#b9d3ee", Color("#fff3df"), 0.85],
		"chuva": ["#5b6470", "#9aa3ad", Color("#cfd6de"), 0.4],
		"calor": ["#4f86c9", "#f3dfb0", Color("#ffe0a8"), 1.0],
		"frio": ["#7d9cc0", "#dfe9f3", Color("#e3ecff"), 0.65],
		"vento": ["#4a7cc0", "#c9dcef", Color("#fff3df"), 0.8],
		"estrelas": ["#0b1030", "#24305e", Color("#9fb2ff"), 0.3],
	}.get(clima, ["#3d6fb6", "#b9d3ee", Color("#fff3df"), 0.85])
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(cores[0])
	ceu.sky_horizon_color = Color(cores[1])
	ceu.ground_horizon_color = Color(cores[1])
	ceu.ground_bottom_color = COR_GRAMA.darkened(0.4)
	sky.sky_material = ceu
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(cores[1]).lerp(Color.WHITE, 0.3)
	env.ambient_light_energy = 0.35 if noite else 0.5
	if clima in ["chuva", "frio"]:
		env.fog_enabled = true
		env.fog_light_color = Color(cores[1])
		env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_color = cores[2]
	sol.light_energy = cores[3]
	sol.shadow_enabled = not noite and clima != "chuva"
	add_child(sol)
	if noite:
		_estrelas()
	if clima == "chuva":
		_chuva()
	elif clima == "vento":
		_folhas()


func _estrelas() -> void:
	var m := _material(Color(1, 1, 0.9))
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var esf := SphereMesh.new()
	esf.radius = 0.09
	esf.height = 0.18
	esf.radial_segments = 6
	esf.rings = 3
	for i in 90:
		var mi := MeshInstance3D.new()
		mi.mesh = esf
		mi.material_override = m
		mi.position = Vector3(_rng.randf_range(-40, 40), _rng.randf_range(9, 26), _rng.randf_range(-34, -22))
		mi.scale = Vector3.ONE * _rng.randf_range(0.6, 1.6)
		add_child(mi)


func _chuva() -> void:
	var p := CPUParticles3D.new()
	p.amount = 700
	p.lifetime = 1.0
	p.preprocess = 1.0
	var gota := BoxMesh.new()
	gota.size = Vector3(0.02, 0.35, 0.02)
	p.mesh = gota
	var m := _material(Color(0.8, 0.88, 1.0, 0.55), true)
	p.material_override = m
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 0.5, 10)
	p.direction = Vector3(0.1, -1, 0)
	p.spread = 3.0
	p.gravity = Vector3(0, -2, 0)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 14.0
	p.position = Vector3(0, 11, -1)
	add_child(p)


func _folhas() -> void:
	var p := CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 5.0
	p.preprocess = 5.0
	var folha := QuadMesh.new()
	folha.size = Vector2(0.14, 0.09)
	p.mesh = folha
	var m := _material(Color("#d9822b"))
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	p.material_override = m
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(2, 3, 9)
	p.direction = Vector3(1, -0.15, 0)
	p.spread = 15.0
	p.gravity = Vector3(0, -0.3, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 5.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.position = Vector3(-15, 3, -1)
	add_child(p)


func _cenario() -> void:
	var noite := clima == "estrelas"
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(120, 80)
	chao.mesh = plano
	chao.material_override = _material(COR_GRAMA.lightened(0.08) if clima != "frio" else Color("#8fae86"))
	add_child(chao)
	# caminhos de pedra em cruz até a fonte e a porta
	_caixa(Vector3(2.6, 0.04, 9.0), Vector3(0, 0.02, -2.0), COR_CAMINHO)
	_caixa(Vector3(22.0, 0.04, 2.0), Vector3(0, 0.02, 1.0), COR_CAMINHO)
	_caixa(Vector3(26.0, 0.04, 2.4), Vector3(0, 0.02, -6.6), COR_CAMINHO)
	# prédio da academia com marquise e escada
	_caixa(Vector3(26.0, 7.0, 3.0), Vector3(0, 3.5, -9.4), COR_PREDIO)
	_caixa(Vector3(27.0, 0.6, 3.6), Vector3(0, 7.2, -9.4), COR_TELHADO)
	var janela := Color("#ffd98a") if noite else Color("#4a6c8f")
	for x in [-10.5, -7.0, -3.5, 3.5, 7.0, 10.5]:
		for y in [2.2, 5.0]:
			_caixa(Vector3(1.6, 1.4, 0.1), Vector3(x, y, -7.88), janela)
	_caixa(Vector3(2.4, 3.0, 0.1), Vector3(0, 1.5, -7.88), Color("#5a3a2a"))
	_caixa(Vector3(9.0, 0.18, 2.4), Vector3(0, 3.6, -6.9), COR_TELHADO.darkened(0.15))
	for x in [-4.3, 4.3]:
		_caixa(Vector3(0.18, 3.6, 0.18), Vector3(x, 1.8, -5.85), Color("#ffffff"))
	for i in 3:
		_caixa(Vector3(5.0 - i * 0.8, 0.18, 0.5), Vector3(0, 0.09 + i * 0.18, -6.9 - i * 0.25), COR_PEDRA.lightened(0.15))
	# placa com o nome
	var placa := Label3D.new()
	placa.text = "ACADEMIA ESTELAR"
	placa.font_size = 96
	placa.pixel_size = 0.012
	placa.outline_size = 12
	placa.modulate = Color("#7a3524")
	placa.position = Vector3(0, 6.25, -7.85)
	add_child(placa)
	# fonte
	var f: Array = _lugar("fonte")
	_cilindro(1.7, 1.8, 0.55, Vector3(f[0], 0.27, f[1]), COR_PEDRA, 16)
	var agua := _cilindro(1.5, 1.5, 0.05, Vector3(f[0], 0.5, f[1]), Color("#5fa8d3"), 16)
	agua.material_override.roughness = 0.2
	_cilindro(0.22, 0.28, 1.3, Vector3(f[0], 0.9, f[1]), COR_PEDRA.lightened(0.1), 8)
	_cilindro(0.65, 0.5, 0.18, Vector3(f[0], 1.55, f[1]), COR_PEDRA.lightened(0.1), 12)
	var peixe := _caixa(Vector3(0.22, 0.06, 0.1), Vector3(f[0] + 0.7, 0.54, f[1] + 0.3), Color("#f0a030"))
	peixe.rotation_degrees.y = 30.0
	# árvores (tronco + copa facetada)
	for p in [Vector2(8.2, -5.6), Vector2(-10.5, -4.5), Vector2(-12.0, 2.5), Vector2(-9.5, -1.2)]:
		_cilindro(0.22, 0.18, 1.8, Vector3(p.x, 0.9, p.y), COR_MADEIRA, 6)
		var copa := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 1.4
		esf.height = 2.4
		esf.radial_segments = 7
		esf.rings = 3
		copa.mesh = esf
		copa.material_override = _material(Color("#3f7a3a") if clima != "calor" else Color("#4f8a3a"))
		copa.position = Vector3(p.x, 2.8, p.y)
		add_child(copa)
	# bancos
	for nome_l in ["banco_esq", "banco_dir"]:
		var b: Array = _lugar(nome_l)
		_caixa(Vector3(2.0, 0.1, 0.55), Vector3(b[0], 0.5, b[1] - 0.6), COR_MADEIRA)
		_caixa(Vector3(2.0, 0.5, 0.08), Vector3(b[0], 0.8, b[1] - 0.9), COR_MADEIRA)
		for lx in [-0.85, 0.85]:
			_caixa(Vector3(0.08, 0.5, 0.5), Vector3(b[0] + lx, 0.25, b[1] - 0.6), Color("#3b3b3b"))
	# faixa de sol (a cama da Lira)
	if clima in ["bom", "calor", "vento"]:
		var sol := MeshInstance3D.new()
		var q := PlaneMesh.new()
		q.size = Vector2(2.6, 1.6)
		sol.mesh = q
		sol.material_override = _material(Color(1.0, 0.92, 0.55, 0.35), true)
		var s: Array = _lugar("sol")
		sol.position = Vector3(s[0], 0.03, s[1])
		add_child(sol)
	# beira da pista à direita, com a cerca branca
	_caixa(Vector3(6.0, 0.03, 30.0), Vector3(11.8, 0.015, -2.0), Color("#b88a5a"))
	_caixa(Vector3(0.08, 0.08, 30.0), Vector3(8.7, 0.9, -2.0), Color.WHITE)
	for z in range(-16, 13, 2):
		_caixa(Vector3(0.08, 0.9, 0.08), Vector3(8.7, 0.45, z), Color.WHITE)
	# postes de luz (acesos à noite)
	for p in [Vector2(-3.2, 1.0), Vector2(3.2, 1.0), Vector2(-7.0, -6.0), Vector2(7.0, -6.0)]:
		_cilindro(0.06, 0.06, 2.8, Vector3(p.x, 1.4, p.y), Color("#33363d"), 6)
		var lampada := _cilindro(0.2, 0.14, 0.3, Vector3(p.x, 2.9, p.y), Color("#fff1c1") if noite else Color("#d8d8d8"), 8)
		if noite:
			lampada.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var luz := OmniLight3D.new()
			luz.light_color = Color("#ffd98a")
			luz.light_energy = 1.6
			luz.omni_range = 6.0
			luz.position = Vector3(p.x, 2.6, p.y)
			add_child(luz)
	if evento.id == "festival":
		_barracas()
	if evento.id in ["aniversario", "aniversario_dela"]:
		_bandeirinhas()


func _barracas() -> void:
	var cores := [Color("#e5534b"), Color("#f2c14e"), Color("#4c8fd6"), Color("#b07cc6")]
	var xs := [-7.5, -3.6, 3.6, 7.5]
	for i in 4:
		var x: float = xs[i]
		_caixa(Vector3(2.4, 1.0, 1.2), Vector3(x, 0.5, -4.3), Color("#f5efe0"))
		var teto := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(2.8, 0.9, 1.6)
		teto.mesh = pr
		teto.material_override = _material(cores[i])
		teto.position = Vector3(x, 2.4, -4.3)
		add_child(teto)
		for lx in [-1.1, 1.1]:
			_caixa(Vector3(0.08, 2.0, 0.08), Vector3(x + lx, 1.0, -3.75), Color("#7a5a3a"))
	_bandeirinhas()


func _bandeirinhas() -> void:
	var cores := [Color("#e5534b"), Color("#f2c14e"), Color("#4c8fd6"), Color("#4caf7d"), Color("#b07cc6")]
	for i in 26:
		var x := -9.0 + i * 0.72
		var y := 3.4 - 0.5 * sin(PI * float(i) / 25.0)
		var b := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(0.35, 0.4, 0.02)
		b.mesh = pr
		b.material_override = _material(cores[i % cores.size()])
		b.position = Vector3(x, y, -5.6)
		b.rotation_degrees.z = 180.0
		add_child(b)


func _bolo(pos: Vector3) -> Node3D:
	var raiz := Node3D.new()
	raiz.position = pos
	add_child(raiz)
	var base := _cilindro(0.32, 0.32, 0.22, Vector3.ZERO, Color("#fbe3ee"), 12)
	base.reparent(raiz, false)
	base.position = Vector3(0, 0.11, 0)
	var cobertura := _cilindro(0.33, 0.33, 0.05, Vector3.ZERO, Color("#e5534b"), 12)
	cobertura.reparent(raiz, false)
	cobertura.position = Vector3(0, 0.24, 0)
	var vela := _cilindro(0.025, 0.025, 0.18, Vector3.ZERO, Color("#f2c14e"), 6)
	vela.reparent(raiz, false)
	vela.position = Vector3(0, 0.35, 0)
	return raiz


func _lugar(id: String) -> Array:
	return _dados.lugares.get(id, [0.0, 0.0])


func _ponto(id: String, espalhar := 0.6) -> Vector3:
	var l := _lugar(id)
	return Vector3(l[0] + _rng.randf_range(-espalhar, espalhar), 0, l[1] + _rng.randf_range(-espalhar * 0.5, espalhar * 0.5))


# ---------- comportamento ----------

func info(nome: String) -> Dictionary:
	return _dados.garotas.get(nome, {"lugar": "centro", "gesto": "", "emote": "", "falas": []})


## Onde a garota vai agora. Cada cena do evento puxa as garotas para um lugar.
func proximo_alvo(g: Gata) -> Vector3:
	var cena: String = _dados.eventos.get(evento.id, {}).get("cena", "normal")
	match cena:
		"marquise":
			return _ponto(["marquise_esq", "marquise_dir", "escada"][_rng.randi() % 3], 1.0)
		"fonte":
			var a := _rng.randf() * TAU
			var f := _lugar("fonte")
			return Vector3(f[0] + cos(a) * 2.3, 0, f[1] + sin(a) * 1.6 + 0.4)
		"roda", "consolo":
			return g.posicao_fixa if g.fixa else _ponto("centro", 3.0)
		"bolo":
			if g.nome == evento.outra:
				return g.posicao_fixa
	var x := _rng.randf()
	if x < 0.55:
		return _ponto(info(g.nome).get("lugar", "centro"))
	if x < 0.85:
		var ids: Array = _dados.lugares.keys()
		return _ponto(ids[_rng.randi() % ids.size()])
	return Vector3(_rng.randf_range(AREA.position.x, AREA.end.x), 0, _rng.randf_range(AREA.position.y, AREA.end.y))


func _arrumar_cena() -> void:
	var cena: String = _dados.eventos.get(evento.id, {}).get("cena", "normal")
	var nomes := gatas.keys()
	match cena:
		"roda":
			for i in nomes.size():
				var a := PI * (0.15 + 0.7 * float(i) / maxf(1.0, nomes.size() - 1))
				var g: Gata = gatas[nomes[i]]
				g.fixar(Vector3(cos(a) * 3.2, 0, 1.6 - sin(a) * 2.2), "pulinho", "coracao" if i % 2 == 0 else "nota")
			if evento.id == "aniversario_dela":
				_bolo(Vector3(0, 0, 1.8))
		"consolo":
			if gatas.has(evento.outra):
				gatas[evento.outra].fixar(Vector3(0, 0, 2.6), "inclinar", "reticencias")
		"bolo":
			if gatas.has(evento.outra):
				var f := _lugar("fonte")
				gatas[evento.outra].fixar(Vector3(f[0] + 1.3, 0, f[1] + 1.7), "", "estrela")
				_bolo(Vector3(f[0] + 0.7, 0.55, f[1] + 1.45))
	for n in nomes:
		var g: Gata = gatas[n]
		g.position = g.posicao_fixa if g.fixa else _ponto(info(n).get("lugar", "centro"), 1.5)
		g.alvo = g.position


## Amigas perto uma da outra trocam um balão; atrito (Lira e Shaula) também, de outro jeito.
func _vizinhas() -> void:
	for par in _dados.get("amizades", []) + _dados.get("atritos", []):
		if not gatas.has(par[0]) or not gatas.has(par[1]):
			continue
		var a: Gata = gatas[par[0]]
		var b: Gata = gatas[par[1]]
		if a.position.distance_to(b.position) < 2.2 and a.parada() and b.parada() and a.espera_balao <= 0.0:
			var atrito: bool = par in _dados.get("atritos", [])
			a.balao("raiva" if atrito else "nota", 2.0)
			b.balao("raiva" if atrito else "coracao", 2.0)
			a.espera_balao = 8.0
			b.espera_balao = 8.0


## Textura do balão de um ícone (desenhado uma vez num SubViewport).
func textura_emote(icone: String) -> Texture2D:
	if not _emotes.has(icone):
		var vp := SubViewport.new()
		vp.size = Vector2i(128, 128)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var b := RetratoGarota.Balao.new()
		b.icone = icone
		b.size = Vector2(128, 128)
		vp.add_child(b)
		add_child(vp)
		_emotes[icone] = vp.get_texture()
	return _emotes[icone]


## Gesto e balão de uma garota (a reação de uma conversa).
func reagir(nome: String, reacao: Dictionary) -> void:
	if gatas.has(nome):
		gatas[nome].gesto(str(reacao.get("gesto", "")))
		gatas[nome].balao(str(reacao.get("emote", "")), 3.0)


## Quem está sob o ponto (coordenadas do viewport), a mais perto da câmera; ou "".
func garota_em(p: Vector2) -> String:
	var melhor := ""
	var dist := INF
	for n in gatas:
		var g: Gata = gatas[n]
		if camera.is_position_behind(g.global_position):
			continue
		var pe := camera.unproject_position(g.global_position)
		var topo := camera.unproject_position(g.global_position + Vector3.UP * ALTURA)
		var alt := pe.y - topo.y
		var r := Rect2(pe.x - alt * 0.3, topo.y, alt * 0.6, alt)
		var d := camera.global_position.distance_to(g.global_position)
		if r.has_point(p) and d < dist:
			melhor = n
			dist = d
	return melhor


## Uma garota no pátio: sprite da ficha (ou primitivas), sombra, nome e balão.
class Gata extends Node3D:
	var patio: Patio3D
	var nome: String
	var alvo := Vector3.ZERO
	var fixa := false
	var posicao_fixa := Vector3.ZERO
	var espera := 0.0
	var espera_balao := 0.0
	var _corpo: Node3D
	var _sprite: Sprite3D
	var _balao: Sprite3D
	var _tempo_balao := 0.0
	var _t := 0.0
	var _gesto := ""
	var _t_gesto := 0.0
	var _gesto_fixo := ""
	var _emote_fixo := ""

	func _init(p: Patio3D, nome_: String) -> void:
		patio = p
		nome = nome_
		_t = p._rng.randf() * 10.0
		_corpo = Node3D.new()
		add_child(_corpo)
		var tex := SpritesGarota.corpo(nome)
		if tex:
			_sprite = Sprite3D.new()
			_sprite.texture = tex
			_sprite.pixel_size = ALTURA / float(tex.get_height())
			_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			_sprite.shaded = false
			_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			_sprite.position.y = ALTURA / 2.0
			_corpo.add_child(_sprite)
		else:
			_primitivas()
		var sombra := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.38
		c.bottom_radius = 0.38
		c.height = 0.01
		sombra.mesh = c
		sombra.material_override = p._material(Color(0, 0, 0, 0.28), true)
		sombra.position.y = 0.02
		add_child(sombra)
		var etq := Label3D.new()
		etq.text = nome
		etq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etq.font_size = 30
		etq.pixel_size = 0.01
		etq.outline_size = 8
		etq.position.y = ALTURA + 0.22
		add_child(etq)
		_balao = Sprite3D.new()
		_balao.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_balao.pixel_size = 0.0045
		_balao.no_depth_test = true
		_balao.position = Vector3(0.55, ALTURA + 0.55, 0)
		_balao.visible = false
		add_child(_balao)
		espera = p._rng.randf_range(0.5, 3.0)

	## Gata de primitivas com as cores da pelagem, para quem ainda não tem ficha.
	func _primitivas() -> void:
		var pal := SpritesGarota.paleta(nome)
		var tronco := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.22
		cap.height = 0.95
		tronco.mesh = cap
		tronco.material_override = patio._material(pal[1])
		tronco.position.y = 0.6
		_corpo.add_child(tronco)
		var cabeca := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.2
		esf.height = 0.4
		cabeca.mesh = esf
		cabeca.material_override = patio._material(COR_PELE)
		cabeca.position.y = 1.3
		_corpo.add_child(cabeca)
		var cabelo := MeshInstance3D.new()
		var ce := SphereMesh.new()
		ce.radius = 0.22
		ce.height = 0.3
		cabelo.mesh = ce
		cabelo.material_override = patio._material(pal[0])
		cabelo.position = Vector3(0, 1.42, -0.03)
		_corpo.add_child(cabelo)
		for lado in [-1.0, 1.0]:
			var orelha := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.07
			cone.height = 0.18
			cone.radial_segments = 4
			orelha.mesh = cone
			orelha.material_override = patio._material(pal[0])
			orelha.position = Vector3(lado * 0.12, 1.58, 0.0)
			_corpo.add_child(orelha)
		var rabo := MeshInstance3D.new()
		var rc := CapsuleMesh.new()
		rc.radius = 0.05
		rc.height = 0.6
		rabo.mesh = rc
		rabo.material_override = patio._material(pal[0])
		rabo.position = Vector3(0.18, 0.75, -0.15)
		rabo.rotation_degrees.z = -35.0
		_corpo.add_child(rabo)

	func fixar(pos: Vector3, gesto_: String, emote: String) -> void:
		fixa = true
		posicao_fixa = pos
		_gesto_fixo = gesto_
		_emote_fixo = emote

	func parada() -> bool:
		return position.distance_to(alvo) < 0.05

	func balao(icone: String, tempo: float) -> void:
		if icone == "":
			return
		_balao.texture = patio.textura_emote(icone)
		_balao.visible = true
		_tempo_balao = tempo

	func gesto(g: String) -> void:
		_gesto = g
		_t_gesto = 0.0

	func passo(delta: float) -> void:
		_t += delta
		espera_balao -= delta
		if _tempo_balao > 0.0:
			_tempo_balao -= delta
			if _tempo_balao <= 0.0:
				_balao.visible = false
		var andando := false
		if not parada():
			var d := alvo - position
			var passo_ := minf(d.length(), VEL_ANDAR * delta)
			position += d.normalized() * passo_
			andando = true
			if _sprite and absf(d.x) > 0.05:
				_sprite.flip_h = d.x < 0.0
		else:
			espera -= delta
			if espera <= 0.0:
				_chegou_ou_sai()
		_animar(delta, andando)

	func _chegou_ou_sai() -> void:
		if fixa:
			espera = patio._rng.randf_range(2.5, 4.5)
			gesto(_gesto_fixo)
			balao(_emote_fixo, 2.0)
			return
		# na metade das paradas faz o hábito dela antes de seguir
		var inf := patio.info(nome)
		if patio._rng.randf() < 0.5 and position.distance_to(patio._ponto(inf.get("lugar", "centro"), 0.0)) < 1.6:
			gesto(inf.get("gesto", ""))
			balao(inf.get("emote", ""), 2.5)
			espera = patio._rng.randf_range(4.0, 7.0)
			return
		alvo = patio.proximo_alvo(self)
		espera = patio._rng.randf_range(1.5, 4.0)

	func _animar(delta: float, andando: bool) -> void:
		var y := 0.0
		var x := 0.0
		var sy := 1.0
		if andando:
			y = absf(sin(_t * 9.0)) * 0.06
		_t_gesto += delta
		var g := _t_gesto
		match _gesto:
			"pulinho":
				if g < 0.8:
					y += absf(sin(g * TAU * 1.25)) * 0.28
			"concordar":
				if g < 0.6:
					sy = 1.0 - absf(sin(g * TAU * 1.6)) * 0.05
			"negar", "tremer":
				if g < 0.5:
					x = sin(g * 60.0) * 0.05
			"encolher":
				sy = 1.0 - minf(g * 0.4, 0.08)
			"cochilo":
				sy = 1.0 - (sin(g * 2.0) * 0.5 + 0.5) * 0.04
			"danca":
				if g < 2.4:
					x = sin(g * 7.0) * 0.12
					y += absf(sin(g * 7.0)) * 0.08
					if _sprite:
						_sprite.flip_h = sin(g * 3.5) < 0.0
			"susto":
				if g < 0.3:
					y += sin(g / 0.3 * PI) * 0.2
			"aceno", "inclinar":
				if g < 0.5:
					y += sin(g / 0.5 * PI) * 0.06
		if andando and _gesto in ["encolher", "cochilo"]:
			_gesto = ""
		_corpo.position = Vector3(x, y, 0)
		_corpo.scale = Vector3(1.0 + (1.0 - sy) * 0.5, sy, 1.0)
