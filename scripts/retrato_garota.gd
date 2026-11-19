class_name RetratoGarota
extends Control
## Retrato de uma garota nos encontros e no pátio: o rosto da ficha conceitual com a
## expressão pedida e um gesto simples (pulinho, concordar, negar...) feito com tween,
## mais um balão com um ícone (coração, nota, "!", "?"...). Quem não tem ficha usa o
## círculo com a inicial (UI.Retrato) e faz os mesmos gestos.

## Gestos: "pulinho", "concordar", "negar", "tremer", "encolher", "inclinar", "danca",
## "cochilo", "susto", "aceno" ou "" (parada).
const GESTOS := ["pulinho", "concordar", "negar", "tremer", "encolher", "inclinar", "danca", "cochilo", "susto", "aceno"]
## Ícones do balão.
const EMOTES := ["coracao", "nota", "exclamacao", "interrogacao", "reticencias", "raiva", "gota", "zz", "estrela"]

var nome: String
var expressao := "normal"
var _figura: Control
var _balao: Balao
var _tween: Tween


func _init(nome_garota: String, tamanho: float = 96.0, expressao_ := "normal") -> void:
	nome = nome_garota
	expressao = expressao_
	custom_minimum_size = Vector2(tamanho, tamanho)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := SpritesGarota.rosto(nome, expressao)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_figura = tr
	else:
		var dd: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
		var cor = dd.config_carreira(nome).get("cor", null)
		_figura = UI.retrato(nome, Color(cor) if cor != null else SpritesGarota.paleta(nome)[0], tamanho)
	_figura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_figura)
	_balao = Balao.new()
	_balao.visible = false
	add_child(_balao)
	resized.connect(_ajustar)


func _ready() -> void:
	_ajustar()


func _ajustar() -> void:
	_figura.size = size
	_figura.pivot_offset = Vector2(size.x / 2.0, size.y)
	var lado := maxf(28.0, size.x * 0.36)
	_balao.size = Vector2(lado, lado)
	_balao.position = Vector2(size.x - lado * 0.7, -lado * 0.25)


func mudar_expressao(e: String) -> void:
	expressao = e
	if _figura is TextureRect:
		(_figura as TextureRect).texture = SpritesGarota.rosto(nome, e)


## Expressão + gesto + balão de uma vez (o formato das reações dos encontros).
func reagir(reacao: Dictionary) -> void:
	if reacao.has("expressao"):
		mudar_expressao(str(reacao.expressao))
	mostrar_emote(str(reacao.get("emote", "")))
	gesto(str(reacao.get("gesto", "")))


func mostrar_emote(e: String) -> void:
	_balao.icone = e
	_balao.visible = e != ""
	_balao.queue_redraw()


func gesto(g: String) -> void:
	if _tween:
		_tween.kill()
	_figura.position = Vector2.ZERO
	_figura.rotation = 0.0
	_figura.scale = Vector2.ONE
	if g == "":
		return
	var h := size.y
	_tween = create_tween()
	match g:
		"pulinho":
			for i in 2:
				_tween.tween_property(_figura, "position:y", -h * 0.12, 0.13).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				_tween.tween_property(_figura, "position:y", 0.0, 0.13).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		"concordar":
			for i in 2:
				_tween.tween_property(_figura, "position:y", h * 0.05, 0.12)
				_tween.tween_property(_figura, "position:y", 0.0, 0.12)
		"negar":
			for i in 2:
				_tween.tween_property(_figura, "rotation", deg_to_rad(-7.0), 0.1)
				_tween.tween_property(_figura, "rotation", deg_to_rad(7.0), 0.1)
			_tween.tween_property(_figura, "rotation", 0.0, 0.08)
		"tremer":
			for i in 6:
				_tween.tween_property(_figura, "position:x", h * (0.025 if i % 2 == 0 else -0.025), 0.04)
			_tween.tween_property(_figura, "position:x", 0.0, 0.04)
		"encolher":
			_tween.tween_property(_figura, "scale", Vector2(1.04, 0.9), 0.25).set_ease(Tween.EASE_OUT)
		"inclinar":
			_tween.tween_property(_figura, "rotation", deg_to_rad(9.0), 0.3).set_ease(Tween.EASE_OUT)
		"danca":
			_tween.set_loops(3)
			_tween.tween_property(_figura, "rotation", deg_to_rad(-6.0), 0.18)
			_tween.tween_property(_figura, "rotation", deg_to_rad(6.0), 0.18)
			_tween.chain().tween_property(_figura, "rotation", 0.0, 0.1)
		"cochilo":
			_tween.set_loops(2)
			_tween.tween_property(_figura, "scale", Vector2(1.0, 0.96), 0.7).set_trans(Tween.TRANS_SINE)
			_tween.tween_property(_figura, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
		"susto":
			_tween.tween_property(_figura, "position:y", -h * 0.08, 0.07)
			_tween.parallel().tween_property(_figura, "scale", Vector2(1.08, 1.08), 0.07)
			_tween.tween_property(_figura, "position:y", 0.0, 0.18)
			_tween.parallel().tween_property(_figura, "scale", Vector2.ONE, 0.18)
		"aceno":
			_tween.tween_property(_figura, "rotation", deg_to_rad(-5.0), 0.12)
			_tween.tween_property(_figura, "position:y", -h * 0.05, 0.12)
			_tween.tween_property(_figura, "position:y", 0.0, 0.12)
			_tween.tween_property(_figura, "rotation", 0.0, 0.12)


## Balão redondo com um ícone desenhado à mão (não depende de fonte com emoji).
class Balao extends Control:
	var icone := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if icone == "":
			return
		Balao.desenhar(self, icone, size)

	## Também usado pelo pátio 3D para gerar a textura do balão.
	static func desenhar(ci: CanvasItem, icone_: String, tam: Vector2) -> void:
		var c := tam / 2.0
		var r := minf(tam.x, tam.y) * 0.46
		ci.draw_circle(c + Vector2(r * 0.12, r * 0.12), r, Color(0, 0, 0, 0.25))
		ci.draw_circle(c, r, Color("#fffaf0"))
		ci.draw_arc(c, r, 0, TAU, 32, Color("#2a1a16"), maxf(1.5, r * 0.08), true)
		var k := r * 0.55
		match icone_:
			"coracao":
				var pts := PackedVector2Array()
				for i in 40:
					var t := TAU * i / 40.0
					var x := 16.0 * pow(sin(t), 3)
					var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
					pts.append(c + Vector2(x, y) * k / 16.0)
				ci.draw_colored_polygon(pts, Color("#e5534b"))
			"nota":
				var cor := Color("#3a6fd8")
				ci.draw_circle(c + Vector2(-k * 0.35, k * 0.5), k * 0.32, cor)
				ci.draw_line(c + Vector2(-k * 0.05, k * 0.5), c + Vector2(-k * 0.05, -k * 0.75), cor, k * 0.16)
				ci.draw_line(c + Vector2(-k * 0.05, -k * 0.75), c + Vector2(k * 0.55, -k * 0.45), cor, k * 0.16)
			"estrela":
				var pts := PackedVector2Array()
				for i in 10:
					var rr := k if i % 2 == 0 else k * 0.42
					var a := -PI / 2.0 + PI * i / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * rr)
				ci.draw_colored_polygon(pts, Color("#f2c14e"))
			"raiva":
				var cor := Color("#e5534b")
				for s in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
					var o: Vector2 = c + s * k * 0.45
					ci.draw_line(o + Vector2(-s.x, 0) * k * 0.35, o, cor, k * 0.18)
					ci.draw_line(o + Vector2(0, -s.y) * k * 0.35, o, cor, k * 0.18)
			"gota":
				var cor := Color("#5aa9e6")
				ci.draw_circle(c + Vector2(0, k * 0.25), k * 0.45, cor)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-k * 0.42, k * 0.1), c + Vector2(0, -k * 0.8),
					c + Vector2(k * 0.42, k * 0.1)]), cor)
			_:
				var txt: String = {"exclamacao": "!", "interrogacao": "?", "reticencias": "...", "zz": "Zz"}.get(icone_, "?")
				var cor: Color = {"exclamacao": Color("#e5534b"), "zz": Color("#7a6fd8")}.get(icone_, Color("#2a1a16"))
				var f := ThemeDB.fallback_font
				var fs := int(r * (1.2 if txt.length() == 1 else 0.8))
				var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
				ci.draw_string(f, c + Vector2(-ts.x / 2.0, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cor)
