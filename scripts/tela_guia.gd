class_name TelaGuia
extends Control
## Guia do jogo: janela por cima da tela atual, com capítulos à esquerda e páginas à direita.
## O conteúdo fica em data/tutorial.json. Números entre chaves no texto são lidos dos dados
## do jogo na hora ({bal:descanso}, {d:calendario.categorias.prata.fama_entrada}...), então
## mudar o balanceamento não deixa o guia desatualizado. Abre com F1 em qualquer tela, pelo
## botão Guia da academia e da carreira, e sozinho no começo do jogo.
## Teclas: Esc fecha, ← → trocam de página, ↑ ↓ trocam de capítulo.

signal fechou

const CORES := {"rosa": UI.ROSA, "ceu": UI.CEU, "verde": UI.VERDE, "laranja": UI.LARANJA,
	"roxo": UI.ROXO, "ouro": UI.OURO}

## Guia aberto agora (para F1 não abrir dois).
static var aberto: TelaGuia

var cap := 0
var pag := 0
var _janela: Control


## Abre o guia por cima de `pai` (normalmente a tela atual), no capítulo de id `capitulo`.
static func abrir(pai: Node, capitulo: String = "") -> TelaGuia:
	if is_instance_valid(aberto):
		aberto.ir_para(capitulo)
		return aberto
	var g := TelaGuia.new()
	g.ir_para(capitulo, false)
	pai.add_child(g)
	aberto = g
	return g


static func capitulos() -> Array:
	return Dados.tutorial.get("capitulos", [])


static func indice(id: String) -> int:
	var lista := capitulos()
	for i in lista.size():
		if lista[i].id == id:
			return i
	return -1


func ir_para(id: String, montar: bool = true) -> void:
	var i := indice(id)
	if i >= 0:
		cap = i
		pag = 0
	if montar and is_inside_tree():
		_montar()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.15, 0.25, 0.5)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			fechar())
	add_child(escuro)
	_montar()
	if _janela:
		UI.pop(_janela)


func fechar() -> void:
	if aberto == self:
		aberto = null
	fechou.emit()
	queue_free()


func _montar() -> void:
	if _janela:
		_janela.queue_free()
	var lista := capitulos()
	if lista.is_empty():
		return
	cap = clampi(cap, 0, lista.size() - 1)
	var c: Dictionary = lista[cap]
	var paginas: Array = c.paginas
	pag = clampi(pag, 0, paginas.size() - 1)
	var cor := cor_de(c.get("cor", "ceu"))

	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + lado, 60)
	for lado in ["top", "bottom"]:
		mc.add_theme_constant_override("margin_" + lado, 34)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := UI.painel(UI.PAINEL, 16)
	mc.add_child(p)
	_janela = mc
	add_child(mc)

	var v := UI.vbox(12)
	var topo := UI.hbox(10)
	topo.add_child(UI.faixa("Guia do jogo", UI.ROSA, 26))
	var sub := UI.label("Como funciona a vida na Academia Estelar", 15, UI.SUAVE)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(sub)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	var bf := UI.botao("Fechar", fechar, 15)
	UI.tecla(bf, "Esc")
	bf.custom_minimum_size.x = 120
	topo.add_child(bf)
	v.add_child(topo)

	var meio := UI.hbox(16)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_child(_indice(lista))
	meio.add_child(_pagina(c, paginas, cor))
	v.add_child(meio)
	p.add_child(v)


## Coluna de capítulos: um botão por capítulo, o atual pintado na cor dele.
func _indice(lista: Array) -> Control:
	var rol := ScrollContainer.new()
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rol.custom_minimum_size.x = 250
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in lista.size():
		var ci: Dictionary = lista[i]
		var idx := i
		var b := UI.botao("%d. %s" % [i + 1, ci.titulo], func():
			cap = idx
			pag = 0
			_montar(), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text = ci.get("resumo", "")
		if i == cap:
			UI.colorir_botao(b, cor_de(ci.get("cor", "ceu")))
		v.add_child(b)
	var mg := MarginContainer.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 4)
	mg.add_child(v)
	rol.add_child(mg)
	return rol


func _pagina(c: Dictionary, paginas: Array, cor: Color) -> Control:
	var pg: Dictionary = paginas[pag]
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cab := UI.hbox(10)
	cab.add_child(UI.faixa(pg.titulo, cor, 22))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(esp)
	var cp := UI.capsula("%s · %d/%d" % [c.titulo, pag + 1, paginas.size()], cor.darkened(0.1), 13)
	cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(cp)
	v.add_child(cab)

	var rol := ScrollContainer.new()
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var corpo := UI.vbox(12)
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var i := 0
	for bl in pg.get("blocos", []):
		var no := bloco(bl, cor)
		if no:
			corpo.add_child(no)
			UI.pop(no, 0.04 * i)
			i += 1
	var mg := MarginContainer.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 6)
	mg.add_child(corpo)
	rol.add_child(mg)
	v.add_child(rol)
	v.add_child(_navegacao(paginas.size(), cor))
	return v


## Anterior / bolinhas das páginas / Próximo. Na última página, Próximo vai ao capítulo seguinte.
func _navegacao(n: int, cor: Color) -> Control:
	var h := UI.hbox(10)
	var ba := UI.botao("◀ Anterior     ", _anterior, 15)
	ba.disabled = cap == 0 and pag == 0
	UI.tecla(ba, "←")
	h.add_child(ba)
	var esp1 := Control.new()
	esp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esp1)
	var bolas := UI.hbox(6)
	bolas.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in n:
		var bola := Bolinha.new()
		bola.cor = cor if i == pag else Color("#c3cfdc")
		bolas.add_child(bola)
	h.add_child(bolas)
	var esp2 := Control.new()
	esp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esp2)
	var ultimo := cap == capitulos().size() - 1 and pag == n - 1
	var texto := "Próximo ▶     "
	if pag == n - 1 and not ultimo:
		texto = "%s ▶     " % capitulos()[cap + 1].titulo
	var bp: Button
	if ultimo:
		bp = UI.botao_principal("Pronto!     ", fechar, 15)
	else:
		bp = UI.botao_cor(texto, _proximo, cor, 15)
	UI.tecla(bp, "→")
	h.add_child(bp)
	return h


func _anterior() -> void:
	if pag > 0:
		pag -= 1
	elif cap > 0:
		cap -= 1
		pag = capitulos()[cap].paginas.size() - 1
	_montar()


func _proximo() -> void:
	if pag < capitulos()[cap].paginas.size() - 1:
		pag += 1
	elif cap < capitulos().size() - 1:
		cap += 1
		pag = 0
	else:
		fechar()
		return
	_montar()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null:
		return
	# com o guia aberto, nenhuma tecla chega à tela de baixo (os atalhos dela gastariam o turno)
	get_viewport().set_input_as_handled()
	if not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_ESCAPE, KEY_F1:
			fechar()
		KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_proximo()
		KEY_LEFT:
			_anterior()
		KEY_DOWN:
			if cap < capitulos().size() - 1:
				cap += 1
				pag = 0
				_montar()
		KEY_UP:
			if cap > 0:
				cap -= 1
				pag = 0
				_montar()


# ---------- blocos ----------

static func cor_de(nome: String) -> Color:
	return CORES.get(nome, UI.CEU)


## Monta um bloco de conteúdo. Devolve null para um tipo desconhecido.
static func bloco(bl: Dictionary, cor: Color) -> Control:
	match str(bl.get("tipo", "")):
		"texto":
			return UI.label(preencher(bl.texto), 17, UI.TEXTO, true)
		"dica":
			return _dica(preencher(bl.texto))
		"itens":
			var itens: Array = bl.get("itens", [])
			return _grade(itens.map(func(it): return _cartao(it)), int(bl.get("colunas", 2)))
		"tabela":
			return _tabela(bl.colunas, bl.linhas, cor)
		"atributos":
			var desc: Dictionary = bl.get("descricoes", {})
			var lista := []
			for k in SimCorrida.KEYS:
				lista.append(_cartao({"titulo": Dados.ATTR_NOME[k], "texto": desc.get(k, ""), "icone": k}))
			return _grade(lista, 1)
		"nos":
			var nos: Dictionary = Dados.calendario.get("nos", {})
			var lista := []
			for id in nos:
				var n: Dictionary = nos[id]
				lista.append(_cartao({"titulo": "%s  %s" % [n.get("icone", ""), n.nome],
					"texto": str(n.get("descricao", "")).replace("%s", "um atributo"), "cor": "roxo"}))
			return _grade(lista, 2)
		"climas":
			var climas: Dictionary = Dados.calendario.get("climas", {})
			var lista := []
			for id in climas:
				var cl: Dictionary = climas[id]
				lista.append(_cartao({"titulo": "%s  %s" % [cl.get("icone", ""), cl.nome],
					"texto": cl.get("descricao", "Sem efeito no treino nem na corrida."), "cor": "ceu"}))
			return _grade(lista, 2)
	return null


static func _grade(filhos: Array, colunas: int) -> Control:
	var g := GridContainer.new()
	g.columns = maxi(1, colunas)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	for f in filhos:
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(f)
	return g


## Cartão de um item: ícone do atributo (ou uma tarja na cor dele), título e texto.
static func _cartao(it: Dictionary) -> Control:
	var attr: String = it.get("icone", "")
	var cor: Color = UI.ATTR_COR[attr] if UI.ATTR_COR.has(attr) else cor_de(it.get("cor", "ceu"))
	var p := UI.painel(cor, 10)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.bg_color = Color.WHITE.lerp(cor, 0.1)
	sb.border_color = cor.lightened(0.35)
	sb.border_width_left = 6
	sb.border_color = cor
	sb.shadow_size = 5
	p.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(10)
	if attr != "":
		var ic := UI.Icone.new(attr, 36)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(ic)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UI.label(preencher(str(it.get("titulo", ""))), 17, cor.darkened(0.35))
	t.add_theme_font_override("font", UI.negrito())
	v.add_child(t)
	var tx := str(it.get("texto", ""))
	if tx != "":
		v.add_child(UI.label(preencher(tx), 15, UI.TEXTO, true))
	h.add_child(v)
	p.add_child(h)
	return p


static func _dica(texto: String) -> Control:
	var p := UI.painel(Color("#fff4cc"), 10)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.bg_color = Color("#fff6d6")
	sb.border_color = Color("#f5c84c")
	p.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(10)
	var cp := UI.capsula("Dica", UI.OURO, 14)
	cp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(cp)
	h.add_child(UI.label(texto, 16, UI.TEXTO, true))
	p.add_child(h)
	return p


static func _tabela(colunas: Array, linhas: Array, cor: Color) -> Control:
	var p := UI.painel(UI.PAINEL, 8)
	var g := GridContainer.new()
	g.columns = colunas.size()
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	for c in colunas:
		var cel := _celula(Color(cor, 1.0))
		var l := UI.label_contorno(preencher(str(c)), 15, Color.WHITE, cor.darkened(0.45), 4)
		cel.add_child(l)
		g.add_child(cel)
	for i in linhas.size():
		for j in linhas[i].size():
			var cel := _celula(Color("#f3f7fb") if i % 2 == 0 else Color.WHITE)
			var l := UI.label(preencher(str(linhas[i][j])), 15, UI.TEXTO)
			if j == 0:
				l.add_theme_font_override("font", UI.negrito())
			cel.add_child(l)
			g.add_child(cel)
	p.add_child(g)
	return p


static func _celula(fundo: Color) -> PanelContainer:
	var cel := PanelContainer.new()
	cel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	cel.add_theme_stylebox_override("panel", sb)
	return cel


## Troca {fonte:chave} pelo valor nos dados do jogo (ver o _doc de data/tutorial.json).
## Uma chave que não existe vira "?" (teste_dados confere que nenhuma falta).
static func preencher(texto: String) -> String:
	var re := RegEx.create_from_string("\\{(bal|pct|perfil|d|pctd):([A-Za-z0-9_.]+)\\}")
	var saida := texto
	for m in re.search_all(texto):
		var v = valor(m.get_string(1), m.get_string(2))
		saida = saida.replace(m.get_string(), "?" if v == null else formatar(v))
	return saida


## Valor de uma chave ou null se ela não existe.
static func valor(fonte: String, chave: String):
	var v = null
	match fonte:
		"bal", "pct":
			v = Carreira.BAL.get(chave)
		"perfil":
			v = Perfil.BAL.get(chave)
		"d", "pctd":
			var partes := chave.split(".")
			v = Dados.get(partes[0])
			for parte in partes.slice(1):
				if v is Dictionary and v.has(parte):
					v = v[parte]
				else:
					return null
	if v == null or not (v is float or v is int):
		return v if v is String else null
	if fonte in ["pct", "pctd"]:
		v = float(v) * 100.0
	return v


## Número no jeito brasileiro: inteiro sem casas, fração com vírgula (0,75).
static func formatar(v) -> String:
	if v is String:
		return v
	var f := float(v)
	if is_equal_approx(f, roundf(f)):
		return str(roundi(f))
	return ("%.2f" % f).rstrip("0").replace(".", ",")


class Bolinha extends Control:
	var cor := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(12, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size / 2.0, 6.0, cor.darkened(0.2))
		draw_circle(size / 2.0, 4.5, cor)
