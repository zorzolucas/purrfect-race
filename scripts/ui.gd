class_name UI
extends RefCounted
## Atalhos para montar a interface placeholder em código.

const FUNDO := Color("#141824")
const PAINEL := Color("#1f2536")
const TEXTO := Color("#e9ecf5")
const SUAVE := Color("#9aa3b8")
const DESTAQUE := Color("#f2c14e")
const PERIGO := Color("#e5534b")
const OK := Color("#4caf7d")
const BOTAO := Color("#2c3550")
const BORDA := Color("#3d4867")

## Cor e ícone de cada atributo: aparecem nas barras, nos treinos e nos ganhos.
const ATTR_COR := {"vel": Color("#4fa3ff"), "est": Color("#4cd18a"), "pod": Color("#ff6b5b"),
	"det": Color("#ffb347"), "int": Color("#b48cff")}
## Cor de cada nota, do G ao S.
const NOTA_COR := {"S": Color("#ffd75e"), "A": Color("#ff8fd0"), "B": Color("#b48cff"), "C": Color("#4fa3ff"),
	"D": Color("#4cd18a"), "E": Color("#9aa3b8"), "F": Color("#7d8499"), "G": Color("#5d6478")}

## Escala de fontes: use estas em vez de números soltos.
const F_TITULO := 30
const F_SUBTITULO := 22
const F_CORPO := 16
const F_PEQUENO := 14
const F_LEGENDA := 13

static var _tema: Theme
## Última quantidade de moedas mostrada: quando muda, o contador sobe/desce até a nova.
static var _ultima_moeda := -1


## Tema único do jogo (aplicado na raiz do main): estados de botão bem distintos, foco
## visível e campos com a mesma paleta. Telas que montam botões com UI.botao herdam tudo.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font_size = F_CORPO
	for nome in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(nome, "Button", estilo_botao(BOTAO, nome))
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", DESTAQUE)
	t.set_color("font_disabled_color", "Button", Color("#5d6478"))
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_color", "Label", TEXTO)
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color("#0d1018")
	tip.border_color = BORDA
	tip.set_border_width_all(1)
	tip.set_corner_radius_all(6)
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TEXTO)
	t.set_font_size("font_size", "TooltipLabel", F_PEQUENO)
	_tema = t
	return t


## Rótulo de uma linha. Use quebra = true para textos longos (ocupa a largura disponível).
static func label(texto: String, tamanho: int = 16, cor: Color = TEXTO, quebra: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if quebra:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 120
	return l


static func botao(texto: String, acao: Callable, tamanho: int = 16) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tamanho)
	b.pressed.connect(acao)
	b.focus_mode = Control.FOCUS_NONE
	pulsar_no_hover(b)
	return b


## Hover cresce o botão um pouco (só no visual: o layout não muda) e o clique dá um "tapinha".
static func pulsar_no_hover(b: Control) -> void:
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.mouse_entered.connect(func():
		if b is BaseButton and b.disabled:
			return
		b.create_tween().tween_property(b, "scale", Vector2(1.035, 1.035), 0.08))
	b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	if b is BaseButton:
		b.button_down.connect(func(): b.create_tween().tween_property(b, "scale", Vector2(0.97, 0.97), 0.05))
		b.button_up.connect(func(): b.create_tween().tween_property(b, "scale", Vector2(1.035, 1.035), 0.08))


## Estilo "de jogo" para um botão de cor `cor`: borda de cima clara e de baixo grossa e
## escura (parece que dá para apertar); pressionado, a borda de baixo some e o texto desce.
static func estilo_botao(cor: Color, estado: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	var base := cor
	match estado:
		"hover":
			base = cor.lightened(0.14)
		"pressed":
			base = cor.darkened(0.18)
		"disabled":
			base = Color("#1b2030")
	sb.bg_color = base
	sb.border_color = base.lightened(0.22)
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 4
	sb.border_blend = false
	if estado == "pressed":
		sb.border_width_bottom = 1
		sb.border_width_top = 2
		sb.content_margin_top = 9
		sb.content_margin_bottom = 3
		sb.border_color = DESTAQUE
	elif estado == "hover":
		sb.border_color = DESTAQUE.darkened(0.15)
	elif estado == "disabled":
		sb.border_color = Color("#262c3d")
		sb.border_width_bottom = 1
	if estado == "focus":
		sb.draw_center = false
		sb.border_color = DESTAQUE
		sb.set_border_width_all(2)
	if estado in ["normal", "hover"]:
		# a borda de baixo é a "espessura" do botão: mais escura que o resto
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 3
		sb.shadow_offset = Vector2(0, 2)
	return sb


## Aplica a cor `cor` a um botão já criado (treinos com a cor do atributo, raros em ouro...).
static func colorir_botao(b: Button, cor: Color) -> void:
	for nome in ["normal", "hover", "pressed"]:
		var sb := estilo_botao(cor.darkened(0.55), nome)
		if nome == "normal":
			sb.border_color = cor.darkened(0.1)
		b.add_theme_stylebox_override(nome, sb)


## Botão da ação principal da tela: fundo dourado e texto escuro.
static func botao_principal(texto: String, acao: Callable, tamanho: int = 18) -> Button:
	var b := botao(texto, acao, tamanho)
	for nome in ["normal", "hover", "pressed"]:
		var sb: StyleBoxFlat = tema().get_stylebox(nome, "Button").duplicate()
		sb.bg_color = {"normal": DESTAQUE.darkened(0.1), "hover": DESTAQUE, "pressed": DESTAQUE.darkened(0.3)}[nome]
		sb.border_color = DESTAQUE.darkened(0.35) if nome != "pressed" else DESTAQUE.darkened(0.5)
		b.add_theme_stylebox_override(nome, sb)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, FUNDO)
	return b


## Botão para ações sem volta: o primeiro clique só pede confirmação (o texto muda e fica
## vermelho por 3 s); o segundo executa.
static func botao_confirmar(texto: String, acao: Callable, tamanho: int = 16, pergunta: String = "") -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tamanho)
	b.focus_mode = Control.FOCUS_NONE
	pulsar_no_hover(b)
	b.set_meta("armado", false)
	b.pressed.connect(func():
		if b.get_meta("armado"):
			acao.call()
			return
		b.set_meta("armado", true)
		b.text = pergunta if pergunta != "" else "%s? Clique de novo para confirmar" % texto
		b.add_theme_color_override("font_color", PERIGO)
		b.add_theme_color_override("font_hover_color", PERIGO)
		# o Timer é filho do botão: some junto com ele se a tela trocar antes dos 3 s
		var tm := Timer.new()
		tm.one_shot = true
		tm.wait_time = 3.0
		b.add_child(tm)
		tm.timeout.connect(func():
			b.set_meta("armado", false)
			b.text = texto
			b.remove_theme_color_override("font_color")
			b.remove_theme_color_override("font_hover_color")
			tm.queue_free())
		tm.start())
	return b


## Prefixa a tecla de atalho no texto do botão: "[1] Vel ...".
static func com_tecla(tecla: String, texto: String) -> String:
	return "[%s] %s" % [tecla, texto]


## Painel com moldura de jogo: borda clara em cima, mais escura embaixo e sombra.
static func painel(cor: Color = PAINEL, margem: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(margem)
	sb.border_color = cor.lightened(0.16)
	sb.border_width_top = 2
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Painel com uma faixa de título colorida em cima (o "cabeçalho" de janela de jogo).
## Devolve o painel; o conteúdo vai no VBox que fica em get_meta("corpo").
static func painel_titulo(titulo: String, cor_faixa: Color, cor: Color = PAINEL) -> PanelContainer:
	var p := painel(cor, 0)
	var v := vbox(0)
	var faixa := PanelContainer.new()
	var sf := StyleBoxFlat.new()
	sf.bg_color = cor_faixa
	sf.corner_radius_top_left = 12
	sf.corner_radius_top_right = 12
	sf.content_margin_left = 16
	sf.content_margin_top = 6
	sf.content_margin_bottom = 6
	sf.border_color = cor_faixa.lightened(0.25)
	sf.border_width_top = 2
	faixa.add_theme_stylebox_override("panel", sf)
	var l := label(titulo, 18, FUNDO)
	faixa.add_child(l)
	v.add_child(faixa)
	var corpo := vbox(10)
	var mc := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, 16)
	mc.add_child(corpo)
	v.add_child(mc)
	p.add_child(v)
	p.set_meta("corpo", corpo)
	return p


static func barra(valor: float, maximo: float, cor: Color, largura: float = 220.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(largura, 16)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#151a28")
	fundo.set_corner_radius_all(6)
	fundo.border_color = Color("#2b3247")
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	cheio.set_corner_radius_all(6)
	# brilho em cima e sombra embaixo dão volume à barra
	cheio.border_color = cor.lightened(0.35)
	cheio.border_width_top = 2
	cheio.border_width_bottom = 2
	cheio.border_blend = true
	b.add_theme_stylebox_override("background", fundo)
	b.add_theme_stylebox_override("fill", cheio)
	return b


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margem(filho: Control, m: int = 24) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, m)
	mc.add_child(filho)
	return mc


## Retrato placeholder: círculo com a inicial.
static func retrato(nome: String, cor: Color, tamanho: float = 72.0) -> Control:
	var c := Retrato.new()
	c.letra = nome.substr(0, 1)
	c.cor = cor
	c.custom_minimum_size = Vector2(tamanho, tamanho)
	return c


class Retrato extends Control:
	var letra := "?"
	var cor := Color.WHITE

	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0
		draw_circle(size / 2.0, r, cor)
		draw_circle(size / 2.0, r * 0.82, cor.darkened(0.35))
		var f := get_theme_default_font()
		var fs := int(r)
		var ts := f.get_string_size(letra, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, size / 2.0 + Vector2(-ts.x / 2.0, fs * 0.35), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Número que sobe e some a partir de `origem` (ganho de atributo, fama, moeda...).
static func numero_flutuante(pai: Control, texto: String, cor: Color, origem: Vector2, tamanho: int = 20) -> void:
	var l := label(texto, tamanho, cor)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.position = origem
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 10
	pai.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", origem.y - 34, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(l.queue_free)


## Conta de `de` até `ate` num Label, com o formato `fmt` ("%d" por padrão).
static func contar(l: Label, de: float, ate: float, fmt: String = "%d", duracao: float = 0.8) -> void:
	l.text = fmt % roundi(de)
	l.create_tween().tween_method(func(x: float): l.text = fmt % roundi(x), de, ate, duracao) \
		.set_delay(0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## "Pop": cresce de 0,6 a 1 com um quique. Bom para banners e selos.
static func pop(c: Control, atraso: float = 0.0) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	c.scale = Vector2(0.6, 0.6)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "scale", Vector2.ONE, 0.45).set_delay(atraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(atraso)


## Confete por cima de `pai` (vitórias e objetivos cumpridos).
static func confete(pai: Control, centro: Vector2, quantidade: int = 90) -> void:
	var p := CPUParticles2D.new()
	p.position = centro
	p.amount = quantidade
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 2.2
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 520.0
	p.gravity = Vector2(0, 520)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([DESTAQUE, Color("#ff6b9a"), Color("#4fa3ff"), OK, Color("#b48cff")])
	p.color_initial_ramp = g
	p.z_index = 20
	pai.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Ícone desenhado de um atributo (raio, coração, punho/losango, chama, estrela) num disco
## da cor dele.
class Icone extends Control:
	var attr := "vel"

	func _init(a: String = "vel", tamanho: float = 22.0) -> void:
		attr = a
		custom_minimum_size = Vector2(tamanho, tamanho)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0
		var c := size / 2.0
		var cor: Color = UI.ATTR_COR.get(attr, Color.WHITE)
		draw_circle(c, r, cor.darkened(0.45))
		draw_circle(c, r * 0.86, cor.darkened(0.15))
		var b := Color.WHITE
		var k := r * 0.55
		match attr:
			"vel":  # raio
				draw_colored_polygon(PackedVector2Array([c + Vector2(0.2, -1.1) * k, c + Vector2(-0.6, 0.15) * k,
					c + Vector2(-0.05, 0.15) * k, c + Vector2(-0.25, 1.1) * k, c + Vector2(0.6, -0.2) * k,
					c + Vector2(0.05, -0.2) * k]), b)
			"est":  # coração
				draw_circle(c + Vector2(-0.42, -0.25) * k, 0.48 * k, b)
				draw_circle(c + Vector2(0.42, -0.25) * k, 0.48 * k, b)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-0.88, -0.1) * k, c + Vector2(0.88, -0.1) * k,
					c + Vector2(0, 0.95) * k]), b)
			"pod":  # losango com núcleo (força)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -1.0) * k, c + Vector2(0.9, 0) * k,
					c + Vector2(0, 1.0) * k, c + Vector2(-0.9, 0) * k]), b)
				draw_circle(c, 0.32 * k, cor.darkened(0.15))
			"det":  # chama
				draw_circle(c + Vector2(0, 0.35) * k, 0.62 * k, b)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-0.6, 0.25) * k, c + Vector2(0.15, -1.15) * k,
					c + Vector2(0.62, 0.25) * k]), b)
			"int":  # estrela de 4 pontas
				var pts := PackedVector2Array()
				for i in 8:
					var ang := PI / 4.0 * i - PI / 2.0
					var rr := 1.05 if i % 2 == 0 else 0.35
					pts.append(c + Vector2(cos(ang), sin(ang)) * rr * k)
				draw_colored_polygon(pts, b)


## Selo da nota (G a S) num hexágono com a cor da nota.
class SeloNota extends Control:
	var nota := "G"

	func _init(n: String, tamanho: float = 52.0) -> void:
		nota = n
		custom_minimum_size = Vector2(tamanho, tamanho)
		tooltip_text = "Nota geral: média dos 5 atributos"

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var cor: Color = UI.NOTA_COR.get(nota, Color.WHITE)
		var hexa := func(raio: float) -> PackedVector2Array:
			var pts := PackedVector2Array()
			for i in 6:
				var ang := PI / 3.0 * i - PI / 2.0
				pts.append(c + Vector2(cos(ang), sin(ang)) * raio)
			return pts
		draw_colored_polygon(hexa.call(r), cor.darkened(0.5))
		draw_colored_polygon(hexa.call(r * 0.84), cor)
		draw_colored_polygon(hexa.call(r * 0.68), cor.darkened(0.25))
		var f := get_theme_default_font()
		var fs := int(r * 1.05)
		var ts := f.get_string_size(nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var pos := c + Vector2(-ts.x / 2.0, fs * 0.36)
		draw_string_outline(f, pos, nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.6))
		draw_string(f, pos, nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Contador de moedas: pílula dourada com uma moeda desenhada. Quando o valor mudou desde a
## última vez que apareceu, conta até o novo e mostra a diferença.
static func moedas(valor: int) -> Control:
	var p := painel(Color("#3a3220"), 6)
	var h := hbox(8)
	h.add_child(Moeda.new(26))
	var l := label(str(valor), 22, DESTAQUE)
	h.add_child(l)
	p.add_child(h)
	p.tooltip_text = "Moedas: servem para tirar garotas na pool"
	if _ultima_moeda >= 0 and _ultima_moeda != valor:
		contar(l, _ultima_moeda, valor, "%d", 1.0)
		var d := valor - _ultima_moeda
		var ld := label("%+d" % d, 18, OK if d > 0 else PERIGO)
		h.add_child(ld)
		pop(ld, 0.2)
	_ultima_moeda = valor
	return p


class Moeda extends Control:
	func _init(tamanho: float = 24.0) -> void:
		custom_minimum_size = Vector2(tamanho, tamanho)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c + Vector2(0, 1.5), r, Color("#8a6a1c"))
		draw_circle(c, r, Color("#f2c14e"))
		draw_circle(c, r * 0.72, Color("#d9a531"))
		draw_arc(c, r * 0.72, PI * 1.1, PI * 1.6, 8, Color("#fff1b8"), 2.0)
		# estrela no meio
		var pts := PackedVector2Array()
		for i in 10:
			var ang := PI / 5.0 * i - PI / 2.0
			var rr := r * (0.42 if i % 2 == 0 else 0.18)
			pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
		draw_colored_polygon(pts, Color("#fff1b8"))
