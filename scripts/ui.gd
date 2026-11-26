class_name UI
extends RefCounted
## Atalhos para montar a interface em código, com a linguagem visual do jogo:
## tema claro em tons pastel, fundo listrado em diagonal, cartões brancos com sombra suave,
## faixas de título inclinadas, botões em pílula com volume e fonte arredondada.

const FUNDO := Color("#eef6fb")
const PAINEL := Color("#ffffff")
const TEXTO := Color("#2c3550")
const SUAVE := Color("#6b7a99")
const DESTAQUE := Color("#f0761b")
const OURO := Color("#f5b301")
const PERIGO := Color("#e0453a")
const OK := Color("#22a35a")
const BOTAO := Color("#ffffff")
const BORDA := Color("#d3dfea")
const VERDE := Color("#3cc96f")
const CEU := Color("#3fa9f5")
const ROSA := Color("#ff6fa8")
const LARANJA := Color("#ff9a1f")
const ROXO := Color("#9b7bff")

## Cor e ícone de cada atributo: aparecem nas barras, nos treinos e nos ganhos.
const ATTR_COR := {"vel": Color("#2f97f0"), "est": Color("#2fbf71"), "pod": Color("#f2554a"),
	"det": Color("#ff9a1f"), "int": Color("#9b6bff")}
## Cor de cada nota, do G ao S.
const NOTA_COR := {"S": Color("#ffb300"), "A": Color("#ff5fa2"), "B": Color("#9b6bff"), "C": Color("#2f97f0"),
	"D": Color("#2fbf71"), "E": Color("#8a96ad"), "F": Color("#a3abbd"), "G": Color("#b8bfcc")}

## Cor de cada estilo de corrida, distância e piso (cápsulas dos cartões).
const ESTILO_COR := {"pon": Color("#ff6a3d"), "per": Color("#3f8cf5"), "arr": Color("#9b6bff"), "fec": Color("#22b573")}
const DIST_COR := {"sprint": Color("#ff6fa8"), "milha": Color("#ff9a1f"), "media": Color("#3fa9f5"), "longa": Color("#7b6bff")}
const PISO_COR := {"grama": Color("#3cc96f"), "terra": Color("#c98a4b")}

## Escala de fontes: use estas em vez de números soltos.
const F_TITULO := 30
const F_SUBTITULO := 22
const F_CORPO := 16
const F_PEQUENO := 14
const F_LEGENDA := 13

static var _tema: Theme
static var _fonte_negrito: Font
## Última quantidade de moedas mostrada: quando muda, o contador sobe/desce até a nova.
static var _ultima_moeda := -1


## Fonte arredondada (M PLUS Rounded 1c, OFL) no peso pedido. Os símbolos (★ ✓ ◆ → ...),
## que o subconjunto latino não tem, vêm de um recorte da DejaVu Sans: no navegador não há
## fontes do sistema para o Godot buscar, e eles virariam quadradinhos.
const FONTE_SIMBOLOS := "res://fontes/dejavu-sans-bold-simbolos.woff2"

static func fonte(peso: int = 700) -> Font:
	var caminho := "res://fontes/m-plus-rounded-1c-latin-%d-normal.woff2" % peso
	var f: FontFile = load(caminho) if ResourceLoader.exists(caminho) else null
	if f == null:
		return ThemeDB.fallback_font
	f = f.duplicate()
	var reservas: Array[Font] = []
	if ResourceLoader.exists(FONTE_SIMBOLOS):
		reservas.append(load(FONTE_SIMBOLOS))
	reservas.append(ThemeDB.fallback_font)
	f.fallbacks = reservas
	return f


static func negrito() -> Font:
	if _fonte_negrito == null:
		_fonte_negrito = fonte(800)
	return _fonte_negrito


## Clareia uma cor escura para o tom pastel do tema (os painéis especiais das telas foram
## escritos com cores escuras; aqui viram a versão clara da mesma cor).
static func pastel(cor: Color) -> Color:
	if cor.v >= 0.6:
		return cor
	if cor.s < 0.12:
		return PAINEL
	return Color.from_hsv(cor.h, clampf(cor.s * 0.35 + 0.06, 0.08, 0.22), 0.99)


## Tema único do jogo (aplicado na raiz do main). Telas que montam botões com UI.botao
## herdam tudo.
static func tema() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	t.default_font = fonte(700)
	t.default_font_size = F_CORPO
	for nome in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(nome, "Button", estilo_botao(BOTAO, nome))
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", TEXTO)
	t.set_color("font_pressed_color", "Button", DESTAQUE)
	t.set_color("font_disabled_color", "Button", Color("#a9b4c8"))
	t.set_color("font_focus_color", "Button", TEXTO)
	t.set_color("font_hover_pressed_color", "Button", DESTAQUE)
	t.set_color("font_color", "Label", TEXTO)
	for nome in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(nome, "OptionButton", estilo_botao(BOTAO, nome))
	t.set_color("font_color", "OptionButton", TEXTO)
	t.set_color("font_hover_color", "OptionButton", TEXTO)
	var pop_sb := StyleBoxFlat.new()
	pop_sb.bg_color = PAINEL
	pop_sb.border_color = BORDA
	pop_sb.set_border_width_all(2)
	pop_sb.set_corner_radius_all(10)
	pop_sb.set_content_margin_all(6)
	t.set_stylebox("panel", "PopupMenu", pop_sb)
	t.set_color("font_color", "PopupMenu", TEXTO)
	t.set_color("font_hover_color", "PopupMenu", DESTAQUE)
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color("#2c3550")
	tip.set_corner_radius_all(8)
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	t.set_font_size("font_size", "TooltipLabel", F_PEQUENO)
	var sep := StyleBoxLine.new()
	sep.color = BORDA
	sep.thickness = 2
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 6)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("#c3d2e2")
	grab.set_corner_radius_all(6)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	var trilho := StyleBoxFlat.new()
	trilho.bg_color = Color(1, 1, 1, 0.5)
	trilho.set_corner_radius_all(6)
	trilho.content_margin_left = 6
	t.set_stylebox("scroll", "VScrollBar", trilho)
	_tema = t
	return t


## Rótulo de uma linha. Use quebra = true para textos longos (ocupa a largura disponível).
static func label(texto: String, tamanho: int = 16, cor: Color = TEXTO, quebra: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if tamanho >= 20:
		l.add_theme_font_override("font", negrito())
	if quebra:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 120
	return l


## Texto branco com contorno (números grandes, títulos sobre faixas coloridas).
static func label_contorno(texto: String, tamanho: int, cor: Color, contorno: Color, espessura: int = 6) -> Label:
	var l := label(texto, tamanho, cor)
	l.add_theme_font_override("font", negrito())
	l.add_theme_constant_override("outline_size", espessura)
	l.add_theme_color_override("font_outline_color", contorno)
	return l


## Deixa o texto do botão quebrar linha em vez de alargar o botão (e a tela junto). Para
## botões que ocupam a largura disponível (EXPAND_FILL ou dentro de VBox): a largura mínima
## vira `largura_min`, e a altura cresce com as linhas.
static func quebrar(b: Button, largura_min: float = 90.0) -> Button:
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, largura_min)
	return b


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


## Estilo de botão em pílula com volume: uma "base" mais escura embaixo (sombra dura) que
## some quando ele é apertado, e um aro claro por dentro.
static func estilo_botao(cor: Color, estado: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.corner_detail = 10
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 7
	sb.content_margin_bottom = 9
	var base := cor
	var branco := cor.v > 0.95 and cor.s < 0.05
	match estado:
		"hover":
			base = cor.lightened(0.12) if not branco else Color("#f3f9ff")
		"pressed":
			base = cor.darkened(0.08)
		"disabled":
			base = Color("#eef2f7")
	sb.bg_color = base
	sb.border_color = Color("#d3dfea") if branco else cor.lightened(0.35)
	sb.set_border_width_all(2)
	sb.shadow_color = Color("#b9c8d8") if branco else cor.darkened(0.35)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 4)
	if estado == "hover":
		sb.border_color = DESTAQUE if branco else Color.WHITE
	elif estado == "pressed":
		sb.shadow_offset = Vector2(0, 1)
		sb.content_margin_top = 10
		sb.content_margin_bottom = 6
		sb.border_color = DESTAQUE if branco else cor.lightened(0.5)
	elif estado == "disabled":
		sb.border_color = Color("#e1e7ef")
		sb.shadow_color = Color("#dde4ed")
		sb.shadow_offset = Vector2(0, 2)
	if estado == "focus":
		sb.draw_center = false
		sb.border_color = DESTAQUE
		sb.set_border_width_all(3)
		sb.shadow_size = 0
	return sb


## Pinta um botão já criado com a cor `cor` (treinos na cor do atributo, raros em ouro...):
## fundo colorido, texto branco com contorno escuro.
static func colorir_botao(b: Button, cor: Color) -> void:
	for nome in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(nome, estilo_botao(cor, nome))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", cor.darkened(0.45))
	b.add_theme_constant_override("outline_size", 5)
	b.add_theme_font_override("font", negrito())


## Botão da ação principal da tela: verde, texto branco com contorno.
static func botao_principal(texto: String, acao: Callable, tamanho: int = 18) -> Button:
	var b := botao(texto, acao, tamanho)
	colorir_botao(b, VERDE)
	return b


## Botão em pílula numa cor qualquer (texto branco contornado).
static func botao_cor(texto: String, acao: Callable, cor: Color, tamanho: int = 16) -> Button:
	var b := botao(texto, acao, tamanho)
	colorir_botao(b, cor)
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


## Plaquinha com a tecla de atalho no canto de cima à direita de um botão.
static func tecla(b: Control, t: String) -> void:
	if Escala.toque:  # no celular não há teclado: a plaquinha só ocuparia espaço
		return
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.92)
	sb.border_color = Color("#c3d2e2")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	p.add_theme_stylebox_override("panel", sb)
	var l := label(t, 11, SUAVE)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	p.position += Vector2(-4, 4)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN


## Cápsula: pílula colorida com texto branco contornado (humor, turno, clima, aptidão...).
static func capsula(texto: String, cor: Color, tamanho: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(20)
	sb.corner_detail = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	sb.border_color = cor.lightened(0.4)
	sb.border_width_top = 2
	sb.shadow_color = cor.darkened(0.35)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label_contorno(texto, tamanho, Color.WHITE, cor.darkened(0.45), 4))
	return p


## Cartão branco (ou no tom pastel da cor pedida) com cantos bem redondos e sombra suave.
static func painel(cor: Color = PAINEL, margem: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var c := pastel(cor)
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(16)
	sb.corner_detail = 10
	sb.set_content_margin_all(margem)
	sb.border_color = Color("#d9e5ef") if c == PAINEL else c.darkened(0.1)
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0.16, 0.27, 0.43, 0.13)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Cartão com uma faixa de título colorida e inclinada em cima. Devolve o painel; o
## conteúdo vai no VBox que fica em get_meta("corpo").
static func painel_titulo(titulo: String, cor_faixa: Color, cor: Color = PAINEL) -> PanelContainer:
	var p := painel(cor, 0)
	var v := vbox(0)
	v.add_child(faixa(titulo, cor_faixa))
	var corpo := vbox(10)
	var mc := MarginContainer.new()
	for lado in ["left", "right", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, 16)
	mc.add_theme_constant_override("margin_top", 8)
	mc.add_child(corpo)
	v.add_child(mc)
	p.add_child(v)
	p.set_meta("corpo", corpo)
	return p


## Faixa de título: paralelogramo colorido com texto branco contornado e listras finas.
static func faixa(texto: String, cor: Color, tamanho: int = 18) -> Control:
	var f := Faixa.new()
	f.cor = cor
	var l := label_contorno(texto, tamanho, Color.WHITE, cor.darkened(0.4), 5)
	f.add_child(l)
	f.rotulo = l
	return f


class Faixa extends Container:
	var cor := Color.WHITE
	var rotulo: Label
	var inclinacao := 14.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN and rotulo:
			var ms := rotulo.get_combined_minimum_size()
			fit_child_in_rect(rotulo, Rect2(Vector2(inclinacao + 10, 3), ms))

	func _get_minimum_size() -> Vector2:
		if rotulo == null:
			return Vector2.ZERO
		var ms := rotulo.get_combined_minimum_size()
		return Vector2(ms.x + inclinacao * 2 + 24, ms.y + 6)

	func _draw() -> void:
		var w := get_combined_minimum_size().x
		var h := size.y
		var pts := PackedVector2Array([Vector2(inclinacao, 0), Vector2(w, 0), Vector2(w - inclinacao, h), Vector2(0, h)])
		draw_colored_polygon(pts + PackedVector2Array(), cor.darkened(0.25))
		var desloc := PackedVector2Array()
		for p in pts:
			desloc.append(p + Vector2(-3, -3))
		draw_colored_polygon(desloc, cor)
		# listras finas em diagonal por cima
		for i in range(0, int(w) + int(h), 9):
			var a := Vector2(i, -3)
			var b := Vector2(i - h, h - 3)
			draw_line(a, b, Color(1, 1, 1, 0.12), 3.0)
		draw_line(Vector2(inclinacao - 3, -3), Vector2(w - 3, -3), cor.lightened(0.4), 2.0)


## Barra arredondada com brilho em cima (atributos, energia, afinidade).
static func barra(valor: float, maximo: float, cor: Color, largura: float = 220.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = maximo
	b.value = valor
	b.show_percentage = false
	b.custom_minimum_size = Vector2(largura, 16)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#e4ebf3")
	fundo.set_corner_radius_all(8)
	fundo.border_color = Color("#d3dfea")
	fundo.set_border_width_all(1)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = cor
	cheio.set_corner_radius_all(8)
	cheio.border_color = cor.lightened(0.45)
	cheio.border_width_top = 3
	cheio.border_width_bottom = 1
	cheio.border_blend = true
	b.add_theme_stylebox_override("background", fundo)
	b.add_theme_stylebox_override("fill", cheio)
	return b


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


## Celular em pé: as telas trocam linhas por colunas.
static func em_pe() -> bool:
	return Escala.retrato()


## Linha no desktop, coluna no celular em pé (painéis lado a lado que viram pilha).
static func fila(sep: int = 8) -> BoxContainer:
	return vbox(sep) if Escala.retrato() else hbox(sep)


## Grade com `colunas` no desktop e `colunas_pe` no celular em pé.
static func grade(colunas: int, colunas_pe: int, sep: int = 8) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas_pe if Escala.retrato() else colunas
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	return g


## Lista que rola dentro da tela (desktop). No celular a tela inteira já rola, então devolve
## o conteúdo direto: duas rolagens, uma dentro da outra, brigam pelo dedo.
static func rolavel(conteudo: Control) -> Control:
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Escala.compacto():
		return conteudo
	var r := ScrollContainer.new()
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r.add_child(conteudo)
	return r


## Linha de botões que quebra em mais linhas quando falta largura (topo das telas no celular).
static func fluxo(sep: int = 8) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## Onde pôr janelas que cobrem a tela (guia, detalhes): a camada do Main, que fica por cima
## da rolagem e tem sempre o tamanho visível. Fora do jogo (testes), o próprio nó.
static func camada(no: Node) -> Node:
	if no.is_inside_tree():
		var m := no.get_tree().root.get_node_or_null("Main")
		if m != null and m.get("camada") != null:
			return m.camada
	return no


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
		draw_circle(size / 2.0, r, Color.WHITE)
		draw_circle(size / 2.0, r * 0.9, cor)
		draw_circle(size / 2.0, r * 0.74, cor.lightened(0.25))
		var f := UI.negrito()
		var fs := int(r)
		var ts := f.get_string_size(letra, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var pos := size / 2.0 + Vector2(-ts.x / 2.0, fs * 0.35)
		draw_string_outline(f, pos, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, cor.darkened(0.4))
		draw_string(f, pos, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Fundo das telas: degradê céu → menta, listras diagonais brancas que deslizam devagar e
## patinhas de gato espalhadas.
class Fundo extends Control:
	var _t := 0.0
	var _patas: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r := RandomNumberGenerator.new()
		r.seed = 7
		for i in 26:
			_patas.append([Vector2(r.randf(), r.randf()), r.randf_range(10.0, 22.0), r.randf_range(-0.6, 0.6)])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("#dff1ff"), Color("#e9f6ff"), Color("#effbea"), Color("#e6f7f0")]))
		var passo := 46.0
		var desloc := fmod(_t * 12.0, passo * 2.0)
		var i := -h - passo * 2.0
		while i < w + passo * 2.0:
			var x := i + desloc
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + passo, 0),
				Vector2(x + passo + h * 0.5, h), Vector2(x + h * 0.5, h)]), Color(1, 1, 1, 0.28))
			i += passo * 2.0
		for p in _patas:
			_pata(Vector2(p[0].x * w, fmod(p[0].y * h - _t * 6.0 + h, h)), p[1], p[2])

	func _pata(c: Vector2, r: float, ang: float) -> void:
		var cor := Color(0.55, 0.75, 0.9, 0.16)
		draw_circle(c, r * 0.55, cor)
		for k in 4:
			var a := ang - 0.9 + k * 0.6
			draw_circle(c + Vector2(sin(a), -cos(a)) * r * 0.85, r * 0.22, cor)


## Número que sobe e some a partir de `origem` (ganho de atributo, fama, moeda...).
static func numero_flutuante(pai: Control, texto: String, cor: Color, origem: Vector2, tamanho: int = 20) -> void:
	var l := label_contorno(texto, tamanho, cor, Color.WHITE, 7)
	l.position = origem
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 10
	# dentro de um Container o número iria para o layout: usa uma camada livre por cima
	var camada: Control = l
	if pai is Container:
		camada = Control.new()
		camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
		camada.z_index = 10
		camada.add_child(l)
	pai.add_child(camada)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", origem.y - 34, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(camada.queue_free)


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
		var f := UI.negrito()
		var fs := int(r * 1.05)
		var ts := f.get_string_size(nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var pos := c + Vector2(-ts.x / 2.0, fs * 0.36)
		draw_string_outline(f, pos, nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, cor.darkened(0.55))
		draw_string(f, pos, nota, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Contador de moedas: pílula dourada com uma moeda desenhada. Quando o valor mudou desde a
## última vez que apareceu, conta até o novo e mostra a diferença.
static func moedas(valor: int) -> Control:
	var p := painel(Color("#ffe9a8"), 6)
	var h := hbox(8)
	h.add_child(Moeda.new(26))
	var l := label_contorno(str(valor), 22, Color.WHITE, Color("#b07a00"), 6)
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


## A garota em pé no palco: holofote, sombra no chão e o corpo da ficha conceitual
## balançando de leve. Sem ficha, um círculo grande com a inicial.
class Palco extends Control:
	var nome := ""
	var cor := Color.WHITE
	var _sprite: Control
	var _t := 0.0

	func _ready() -> void:
		clip_contents = true
		var tex := SpritesGarota.corpo(nome)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_sprite = tr
		else:
			_sprite = UI.retrato(nome, cor, 150)
		_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_sprite)
		move_child(_sprite, 0)
		resized.connect(_posicionar)
		_posicionar()

	func _posicionar() -> void:
		if _sprite is TextureRect:
			_sprite.size = Vector2(size.x, size.y - 4)
			_sprite.position = Vector2(0, 6)
		else:
			_sprite.size = Vector2(150, 150)
			_sprite.position = Vector2((size.x - 150) / 2.0, size.y - 175)

	func _process(delta: float) -> void:
		_t += delta
		if _sprite:
			var base := 6.0 if _sprite is TextureRect else size.y - 175
			_sprite.position.y = base + sin(_t * 2.2) * 3.0
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y * 0.5)
		# holofote: círculos concêntricos claros na cor dela
		for i in 6:
			var r := size.y * (0.55 - i * 0.07)
			draw_circle(c, r, Color(cor.r, cor.g, cor.b, 0.05 + i * 0.025).lerp(Color(1, 1, 1, 0.3), 0.4))
		# raios girando bem devagar
		for i in 12:
			var a := _t * 0.15 + TAU / 12.0 * i
			var p1 := c + Vector2(cos(a), sin(a)) * size.y * 0.7
			var p2 := c + Vector2(cos(a + 0.12), sin(a + 0.12)) * size.y * 0.7
			draw_colored_polygon(PackedVector2Array([c, p1, p2]), Color(1, 1, 1, 0.18))
		# sombra no chão
		var chao := Vector2(size.x / 2.0, size.y - 8)
		draw_set_transform(chao, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 70.0 - sin(_t * 2.2) * 2.0, Color(0.16, 0.27, 0.43, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Cor de uma garota: a da ficha de carreira ou, sem ela, a primeira da paleta visual.
static func cor_garota(nome: String) -> Color:
	var dd: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	var c = dd.config_carreira(nome).get("cor", null)
	if c != null:
		return Color(c)
	return SpritesGarota.paleta(nome)[0]


## Medalhão: o rosto da garota dentro de um círculo na cor dela, com aro branco.
static func medalhao(nome: String, tamanho: float = 72.0, expressao: String = "normal") -> Control:
	var cor := cor_garota(nome)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor.lightened(0.62)
	sb.set_corner_radius_all(int(tamanho))
	sb.corner_detail = 16
	sb.border_color = Color.WHITE
	sb.set_border_width_all(3)
	sb.shadow_color = Color(cor.darkened(0.3), 0.55)
	sb.shadow_size = 3
	sb.set_content_margin_all(3)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# num HBox/VBox ele esticaria e viraria oval
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.add_child(RetratoGarota.new(nome, tamanho - 6, expressao))
	return p


## Os cinco atributos lado a lado, cada um com o ícone e o valor.
static func linha_attrs(attrs: Dictionary, tamanho: int = 14, comparar: Dictionary = {}) -> Control:
	var h := hbox(10)
	for k in SimCorrida.KEYS:
		var hk := hbox(3)
		hk.add_child(Icone.new(k, tamanho + 3))
		var val := int(attrs.get(k, 0))
		var cor := TEXTO
		if not comparar.is_empty():
			var ref := int(comparar.get(k, 0))
			cor = OK if val > ref else (PERIGO if val < ref else TEXTO)
		var l := label(str(val), tamanho, cor)
		l.add_theme_font_override("font", negrito())
		hk.add_child(l)
		h.add_child(hk)
	return h


## Fila de estrelas douradas (vínculo, dificuldade...).
class Estrelas extends Control:
	var n := 0
	var total := 5

	func _init(n_: int, total_: int = 5, tamanho: float = 16.0) -> void:
		n = n_
		total = total_
		custom_minimum_size = Vector2(total * (tamanho + 3), tamanho)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _estrela(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for j in 10:
			var ang := PI / 5.0 * j - PI / 2.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * r * (1.0 if j % 2 == 0 else 0.46))
		return pts

	func _draw() -> void:
		var t := size.y
		for i in total:
			var c := Vector2(i * (t + 3) + t / 2.0, t / 2.0 + 1)
			var cheia := i < n
			draw_colored_polygon(_estrela(c + Vector2(0, 1), t * 0.56), Color("#c47f00") if cheia else Color("#c3cfdc"))
			draw_colored_polygon(_estrela(c, t * 0.46), Color("#ffc21a") if cheia else Color("#eef2f7"))
