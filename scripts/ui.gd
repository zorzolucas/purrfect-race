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

## Escala de fontes: use estas em vez de números soltos.
const F_TITULO := 30
const F_SUBTITULO := 22
const F_CORPO := 16
const F_PEQUENO := 14
const F_LEGENDA := 13

static var _tema: Theme


## Tema único do jogo (aplicado na raiz do main): estados de botão bem distintos, foco
## visível e campos com a mesma paleta. Telas que montam botões com UI.botao herdam tudo.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font_size = F_CORPO
	var estados := {
		"normal": [BOTAO, BORDA, 1],
		"hover": [BOTAO.lightened(0.12), DESTAQUE.darkened(0.25), 1],
		"pressed": [BOTAO.darkened(0.25), DESTAQUE, 2],
		"disabled": [Color("#1b2030"), Color("#262c3d"), 1],
		"focus": [Color(0, 0, 0, 0), DESTAQUE, 2],
	}
	for nome in estados:
		var e: Array = estados[nome]
		var sb := StyleBoxFlat.new()
		sb.bg_color = e[0]
		sb.border_color = e[1]
		sb.set_border_width_all(e[2])
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		if nome == "focus":
			sb.draw_center = false
		t.set_stylebox(nome, "Button", sb)
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
	return b


## Botão da ação principal da tela: fundo dourado e texto escuro.
static func botao_principal(texto: String, acao: Callable, tamanho: int = 18) -> Button:
	var b := botao(texto, acao, tamanho)
	for nome in ["normal", "hover", "pressed"]:
		var sb: StyleBoxFlat = tema().get_stylebox(nome, "Button").duplicate()
		sb.bg_color = {"normal": DESTAQUE.darkened(0.1), "hover": DESTAQUE, "pressed": DESTAQUE.darkened(0.3)}[nome]
		sb.border_color = DESTAQUE.lightened(0.2)
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


static func painel(cor: Color = PAINEL, margem: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(margem)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func barra(valor: float, maximo: float, cor: Color, largura: float = 220.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(largura, 16)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#2b3247")
	fundo.set_corner_radius_all(4)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	cheio.set_corner_radius_all(4)
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
