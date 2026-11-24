class_name TelaCarreira
extends Control
## Tela de turno da carreira: atributos, energia, humor, fama e objetivos à esquerda;
## data, clima, rota e a decisão do turno à direita (ações, mapa, férias, encontro ou corrida).

signal ir_correr
signal ir_patio
signal atualizou(msg: String)
signal ir_academia

var c: Carreira
var msg: String
## Amuleto escolhido quando os 6 espaços já estão cheios (falta dizer qual sai).
var amuleto_escolhido := ""


func _init(carreira: Carreira, mensagem: String) -> void:
	c = carreira
	msg = mensagem


func _ready() -> void:
	_registrar_delta()
	_montar()


func _montar() -> void:
	var raiz := UI.vbox(10)
	raiz.add_child(_barra_topo())
	var meio := UI.hbox(14)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_child(_palco())
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var direita := _painel_turno()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(direita)
	meio.add_child(rolagem)
	raiz.add_child(meio)
	raiz.add_child(_faixa_atributos())
	add_child(UI.margem(raiz, 14))
	if detalhe != "":
		add_child(_janela_detalhe())


# ---------- estado guardado entre telas ----------

## Estado da tela anterior (atributos, energia e fama), para mostrar o que mudou com a
## última ação ou corrida. Vale só para a mesma carreira.
static var anterior := {}
## Janela de detalhes aberta por cima ("" nenhuma, "objetivos", "relacoes", "itens") e loja.
static var detalhe := ""
static var loja_aberta := false
## Quantos resultados já tinham banner mostrado (para o banner de objetivo sair uma vez só).
static var resultados_vistos := -1

var _delta := {}
var anterior_attrs := {}
## Atalhos de teclado da tela atual: keycode -> Callable.
var _atalhos := {}


func _registrar_delta() -> void:
	var id := c.get_instance_id()
	if anterior.get("id", -1) == id and int(anterior.get("turno_save", -1)) <= c.turno:
		for k in SimCorrida.KEYS:
			var d: float = c.attrs[k] - float(anterior.attrs[k])
			if absf(d) >= 1.0:
				_delta[k] = d
		var de: int = c.energia - int(anterior.energia)
		if de != 0:
			_delta["energia"] = de
		anterior_attrs = anterior.attrs
		var df: int = c.fama - int(anterior.get("fama", c.fama))
		if df != 0:
			_delta["fama"] = df
	anterior = {"id": id, "turno_save": c.turno, "attrs": c.attrs.duplicate(), "energia": c.energia, "fama": c.fama}


# ---------- barra do topo ----------

func _barra_topo() -> Control:
	var p := UI.painel(UI.PAINEL, 10)
	var h := UI.hbox(12)
	h.add_child(UI.faixa(Calendario.data_texto(c.turno), UI.CEU, 20))
	var cap := UI.capsula("Turno %d/%d" % [c.turno, Carreira.BAL.turnos], Color("#2c3550"), 14)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cap)
	var tr := _trilha()
	tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tr)
	var cl: Dictionary = Dados.calendario.climas[c.clima()]
	var clima := UI.capsula("%s %s" % [cl.icone, cl.nome], Color("#5aa9d6"), 14)
	clima.tooltip_text = cl.get("descricao", cl.nome)
	clima.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(clima)
	var b_guia := UI.botao("Guia", func(): TelaGuia.abrir(self, "turno"), 14)
	b_guia.tooltip_text = "Como funcionam treino, energia, humor, corridas e objetivos (F1)"
	UI.tecla(b_guia, "F1")
	b_guia.custom_minimum_size.x = 100
	h.add_child(b_guia)
	var b_menu := UI.botao("Academia", func(): ir_academia.emit(), 14)
	b_menu.tooltip_text = "Volta à academia (Esc). A carreira fica salva e continua de onde parou."
	UI.tecla(b_menu, "Esc")
	b_menu.custom_minimum_size.x = 150
	h.add_child(b_menu)
	_atalhos[KEY_ESCAPE] = func():
		if detalhe != "":
			_abrir_detalhe("")
		else:
			ir_academia.emit()
	p.add_child(h)
	return p


# ---------- palco da garota ----------

func _palco() -> Control:
	var p := UI.painel(UI.PAINEL, 12)
	p.custom_minimum_size.x = 330
	var v := UI.vbox(8)
	var topo := UI.hbox(8)
	var faixa_nome := UI.faixa(c.nome, c.cor.darkened(0.05) if c.cor.v > 0.35 else UI.ROSA, 22)
	topo.add_child(faixa_nome)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	var hf := UI.hbox(4)
	hf.add_child(UI.label("★", 18, UI.OURO))
	var l_fama := UI.label(str(c.fama), 18, UI.DESTAQUE)
	l_fama.add_theme_font_override("font", UI.negrito())
	hf.add_child(l_fama)
	hf.tooltip_text = "Fama: abre as corridas de categoria mais alta"
	hf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dfama: int = _delta.get("fama", 0)
	if dfama != 0:
		UI.contar(l_fama, c.fama - dfama, c.fama)
		var lf := UI.label("%+d" % dfama, 14, UI.OK if dfama > 0 else UI.PERIGO)
		hf.add_child(lf)
		UI.pop(lf, 0.3)
	topo.add_child(hf)
	v.add_child(topo)
	v.add_child(UI.label("%s · %s" % [Dados.ESTILO_NOME[c.estilo], "lesionada (treino rende metade)" if c.lesionada else "pronta para treinar"],
		13, UI.PERIGO if c.lesionada else UI.SUAVE))

	var palco := UI.Palco.new()
	palco.nome = c.nome
	palco.cor = c.cor
	palco.custom_minimum_size = Vector2(300, 236)
	palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# humor no canto de cima à esquerda, nota no de cima à direita
	var cor_h: Color = [UI.PERIGO, UI.LARANJA, UI.CEU, UI.VERDE, UI.VERDE][c.humor]
	var humor := UI.capsula("Humor: %s" % Carreira.HUMOR_NOME[c.humor], cor_h, 13)
	humor.position = Vector2(4, 4)
	palco.add_child(humor)
	var selo := UI.SeloNota.new(Dados.nota(c.attrs), 56)
	selo.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	selo.position += Vector2(-60, 2)
	palco.add_child(selo)
	if not _delta.is_empty() and not anterior_attrs.is_empty() and Dados.nota(c.attrs) != Dados.nota(anterior_attrs):
		UI.pop(selo, 0.4)
	v.add_child(palco)

	var cor_e := UI.VERDE if c.energia >= 60 else (UI.LARANJA if c.energia >= Carreira.BAL.limite_falha else UI.PERIGO)
	v.add_child(_linha_barra("Energia", c.energia, 100, cor_e, "energia"))
	v.add_child(_chips_aptidao())
	var bot := UI.hbox(6)
	for d in [["objetivos", "Objetivos", "O"], ["relacoes", "Relações", "R"], ["itens", "Itens", "I"]]:
		var id: String = d[0]
		var b := UI.botao(d[1], func(): _abrir_detalhe(id), 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot.add_child(b)
	v.add_child(bot)
	p.add_child(v)
	return p


# ---------- atributos em blocos ----------

func _faixa_atributos() -> Control:
	var h := UI.hbox(10)
	var o := c.proximo_objetivo()
	var marca := c.forca_prevista(o) if not o.is_empty() else -1.0
	for k in SimCorrida.KEYS:
		var bloco := _bloco_atributo(k, marca)
		bloco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(bloco)
	return h


## Bloco de um atributo: faixa colorida com ícone e nome, nota num quadrado e o valor grande;
## embaixo, a barra até o limite com a marca dourada do próximo objetivo.
func _bloco_atributo(k: String, marca: float) -> Control:
	var cor: Color = UI.ATTR_COR[k]
	var valor: float = c.attrs[k]
	var d: float = _delta.get(k, 0.0)
	var p := UI.painel(UI.PAINEL, 0)
	var v := UI.vbox(0)
	var cab := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = cor
	sc.corner_radius_top_left = 14
	sc.corner_radius_top_right = 14
	sc.content_margin_left = 8
	sc.content_margin_top = 3
	sc.content_margin_bottom = 3
	sc.border_color = cor.lightened(0.35)
	sc.border_width_top = 2
	cab.add_theme_stylebox_override("panel", sc)
	var hc := UI.hbox(6)
	hc.add_child(UI.Icone.new(k, 18))
	hc.add_child(UI.label_contorno(Dados.ATTR_NOME[k], 14, Color.WHITE, cor.darkened(0.45), 4))
	cab.add_child(hc)
	v.add_child(cab)
	var corpo := UI.hbox(8)
	var mc := MarginContainer.new()
	for lado in ["left", "right"]:
		mc.add_theme_constant_override("margin_" + lado, 10)
	mc.add_theme_constant_override("margin_top", 4)
	mc.add_theme_constant_override("margin_bottom", 8)
	var n := Dados.nota({k: valor})
	var selo := UI.SeloNota.new(n, 38)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	corpo.add_child(selo)
	var dir := UI.vbox(2)
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hv := UI.hbox(6)
	var num := UI.label_contorno("%d" % valor, 26, UI.TEXTO, Color.WHITE, 2)
	hv.add_child(num)
	if d != 0.0:
		UI.contar(num, valor - d, valor)
		var dl := UI.label("%+d" % roundi(d), 15, UI.OK if d > 0 else UI.PERIGO)
		dl.add_theme_font_override("font", UI.negrito())
		dl.size_flags_vertical = Control.SIZE_SHRINK_END
		hv.add_child(dl)
		UI.pop(dl, 0.25)
	dir.add_child(hv)
	var b := UI.barra(valor - d if d > 0 else valor, c.limite, cor, 60)
	b.custom_minimum_size.y = 10
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if d > 0:
		b.create_tween().tween_property(b, "value", valor, 0.6).set_delay(0.15).set_trans(Tween.TRANS_CUBIC)
		p.modulate = Color(1.25, 1.25, 1.25)
		p.create_tween().tween_property(p, "modulate", Color.WHITE, 0.9).set_delay(0.2)
		var txt_f := "+%d" % roundi(d)
		p.ready.connect(func():
			await p.get_tree().process_frame
			if is_instance_valid(p):
				UI.numero_flutuante(p, txt_f, cor, Vector2(p.size.x * 0.55, 40), 22), CONNECT_ONE_SHOT)
	if marca > 0.0:
		var m := MarcaBarra.new()
		m.frac = clampf(marca / c.limite, 0.0, 1.0)
		m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(m)
		p.tooltip_text = "%s %d (nota %s). A marca dourada é a média das adversárias do próximo objetivo: %d." % [
			Dados.ATTR_NOME[k], valor, n, roundi(marca)]
	dir.add_child(b)
	corpo.add_child(dir)
	mc.add_child(corpo)
	v.add_child(mc)
	p.add_child(v)
	return p


func _linha_barra(rotulo: String, valor: float, maximo: float, cor: Color, chave: String = "") -> Control:
	var h := UI.hbox(8)
	var l := UI.label(rotulo, 14)
	l.custom_minimum_size.x = 64
	h.add_child(l)
	var d: float = _delta.get(chave, 0.0)
	var b := UI.barra(valor - d if d > 0 else valor, maximo, cor, 150)
	b.custom_minimum_size.y = 18
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if d > 0:
		b.create_tween().tween_property(b, "value", valor, 0.6).set_delay(0.15).set_trans(Tween.TRANS_CUBIC)
	h.add_child(b)
	var num := UI.label("%d/%d" % [valor, maximo], 14)
	num.add_theme_font_override("font", UI.negrito())
	h.add_child(num)
	if d != 0.0:
		var dl := UI.label("%+d" % roundi(d), 14, UI.OK if d > 0 else UI.PERIGO)
		h.add_child(dl)
		dl.create_tween().tween_property(dl, "modulate:a", 0.0, 1.2).set_delay(3.0)
	return h


## Risco vertical na barra: a força média das adversárias do próximo objetivo.
class MarcaBarra extends Control:
	var frac := 0.0

	func _draw() -> void:
		var x := size.x * frac
		draw_line(Vector2(x, -4), Vector2(x, size.y + 4), Color("#f5b301"), 3.0)
		draw_line(Vector2(x, -4), Vector2(x, size.y + 4), Color("#8a5a00"), 1.0)


static func _cor_apt(a: String) -> Color:
	return {"R": UI.PERIGO, "O": Color("#8a96ad"), "B": UI.CEU, "X": UI.VERDE}[a]


func _chips_aptidao() -> Control:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 4)
	f.add_theme_constant_override("v_separation", 4)
	var nomes := {"sprint": "Sprint", "milha": "Milha", "media": "Média", "longa": "Longa", "grama": "Grama", "terra": "Terra"}
	for d in nomes:
		var a: String = c.aptidao[d]
		var cap := UI.capsula("%s %s" % [nomes[d], Dados.APT_NOME[a]], _cor_apt(a), 12)
		cap.tooltip_text = "Aptidão %s em %s" % [Dados.APT_NOME[a], nomes[d]]
		f.add_child(cap)
	return f


func _reconstruir() -> void:
	for filho in get_children():
		filho.queue_free()
	_atalhos.clear()
	_montar()


# ---------- janela de detalhes (objetivos, relações, itens) ----------

func _abrir_detalhe(qual: String) -> void:
	detalhe = qual
	_reconstruir()


func _janela_detalhe() -> Control:
	var fundo := Control.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.15, 0.25, 0.45)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_abrir_detalhe(""))
	fundo.add_child(escuro)
	var titulos := {"objetivos": "Objetivos", "relacoes": "Relações", "itens": "Itens e habilidades"}
	var cores := {"objetivos": UI.LARANJA, "relacoes": UI.ROSA, "itens": UI.ROXO}
	var p := UI.painel_titulo(titulos.get(detalhe, ""), cores.get(detalhe, UI.CEU))
	p.custom_minimum_size = Vector2(700, 480)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var corpo: VBoxContainer = p.get_meta("corpo")
	var abas := UI.hbox(6)
	for id in titulos:
		var qual: String = id
		var b := UI.botao(titulos[id], func(): _abrir_detalhe(qual), 14)
		if id == detalhe:
			UI.colorir_botao(b, cores[id])
		abas.add_child(b)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abas.add_child(esp)
	var fechar := UI.botao("Fechar", func(): _abrir_detalhe(""), 14)
	UI.tecla(fechar, "Esc")
	abas.add_child(fechar)
	corpo.add_child(abas)
	var rol := ScrollContainer.new()
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rol.custom_minimum_size.y = 380
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match detalhe:
		"objetivos":
			_detalhe_objetivos(v)
		"relacoes":
			_detalhe_relacoes(v)
		_:
			_detalhe_itens(v)
	rol.add_child(v)
	corpo.add_child(rol)
	fundo.add_child(p)
	UI.pop(p)
	return fundo


func _detalhe_objetivos(v: VBoxContainer) -> void:
	if c.caminho != "":
		v.add_child(UI.label("Caminho \"%s\"" % c.campanha.caminhos[c.caminho].nome, 15, UI.DESTAQUE))
	for ob in c.objetivos:
		var res := c.resultados.filter(func(r): return r.turno == ob.turno and r.objetivo > 0)
		var m := "○"
		var cor := UI.TEXTO
		if not res.is_empty():
			m = "✓" if res[0].ok else "✗"
			cor = UI.OK if res[0].ok else UI.PERIGO
		elif ob.turno == c.turno:
			m = "►"
			cor = UI.DESTAQUE
		var txt := "%s  Turno %d · %s · %s %s · %s" % [m, ob.turno, ob.texto, Dados.DIST_NOME[ob.dist], ob.piso, ob.get("nome", "")]
		v.add_child(UI.label(txt, 15, cor, true))
	var o := c.proximo_objetivo()
	if not o.is_empty():
		v.add_child(UI.label("A marca dourada nos atributos é a média das adversárias do próximo objetivo (%d)." % roundi(c.forca_prevista(o)), 13, UI.SUAVE, true))
	if c.magnitude > 0 or c.desafio > 0 or not c.maldicoes.is_empty():
		v.add_child(HSeparator.new())
		_linha_endgame(v)


func _linha_endgame(v: VBoxContainer) -> void:
	var partes := []
	if c.desafio > 0:
		partes.append("Desafio da semana #%d · regra: %s" % [c.desafio, Endgame.regra(c.regra).get("nome", c.regra)])
	if c.magnitude > 0:
		partes.append("Magnitude %d" % c.magnitude)
	if not c.maldicoes.is_empty():
		partes.append("Maldições: %s" % ", ".join(c.maldicoes.map(func(id): return Dados.amuleto(id).nome)))
	v.add_child(UI.label(" · ".join(partes), 14, UI.PERIGO, true))
	var dicas := []
	if c.magnitude > 0:
		dicas.append(Endgame.resumo_magnitude(c.magnitude))
	if c.desafio > 0:
		dicas.append(Endgame.regra(c.regra).get("descricao", ""))
	for id in c.maldicoes:
		dicas.append("%s: %s" % [Dados.amuleto(id).nome, Dados.amuleto(id).descricao])
	for d in dicas:
		if d != "":
			v.add_child(UI.label(d, 13, UI.SUAVE, true))


func _detalhe_relacoes(v: VBoxContainer) -> void:
	v.add_child(UI.label("Afinidade com as colegas. Com %d ou mais, ela pode aparecer num treino para uma dupla (+25%%)." % Carreira.BAL.afinidade_dupla, 14, UI.SUAVE, true))
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 24)
	grade.add_theme_constant_override("v_separation", 10)
	for colega in c.afinidade:
		var h := UI.hbox(8)
		h.add_child(RetratoGarota.new(colega, 44))
		var l := UI.label(colega.split(" ")[0], 15)
		l.custom_minimum_size.x = 80
		h.add_child(l)
		var af: int = c.afinidade[colega]
		var cor := UI.PERIGO if af < 0 else (UI.VERDE if af >= Carreira.BAL.afinidade_dupla else UI.ROSA)
		var b := UI.barra(maxi(af, 0), 100, cor, 140)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		h.add_child(UI.label(str(af), 15, UI.SUAVE))
		grade.add_child(h)
	v.add_child(grade)
	if not c.madrinha.is_empty():
		v.add_child(HSeparator.new())
		v.add_child(UI.label("Madrinha: %s (inspira nos turnos 25 e 49)" % c.madrinha.get("nome", "?"), 14, UI.SUAVE, true))


func _detalhe_itens(v: VBoxContainer) -> void:
	v.add_child(UI.label("Amuletos (%d/%d)" % [c.amuletos.size(), c.limite_amuletos()], 16, UI.DESTAQUE))
	if c.amuletos.is_empty():
		v.add_child(UI.label("Nenhum ainda. Objetivos cumpridos e o top 3 num Desafio dão amuletos.", 14, UI.SUAVE, true))
	for id in c.amuletos:
		var a := Dados.amuleto(id)
		v.add_child(UI.label("%s: %s" % [a.nome, a.descricao], 14, UI.DESTAQUE if a.tipo == "raro" else UI.TEXTO, true))
	v.add_child(HSeparator.new())
	v.add_child(UI.label("Habilidades (%d/%d)" % [c.habilidades.size(), Dados.habilidades.limite], 16, UI.DESTAQUE))
	if c.unica != "":
		v.add_child(UI.label("%s ★ (única)" % SimCorrida.UNICAS[c.unica].nome, 14, UI.DESTAQUE, true))
	for id in c.habilidades:
		var hb := Dados.habilidade(id)
		v.add_child(UI.label("%s: %s" % [hb.nome, hb.descricao], 14, UI.TEXTO, true))
	if not c.titulos.is_empty():
		v.add_child(HSeparator.new())
		v.add_child(UI.label("Títulos: %s" % ", ".join(c.titulos.map(func(t): return t.nome)), 14, UI.DESTAQUE, true))


# ---------- painel do turno ----------

func _painel_turno() -> VBoxContainer:
	var v := UI.vbox(10)
	var topo := UI.painel(UI.PAINEL, 12)
	var tv := UI.vbox(4)
	var cl: Dictionary = Dados.calendario.climas[c.clima()]
	if cl.has("descricao"):
		tv.add_child(UI.label("%s %s: %s" % [cl.icone, cl.nome, cl.descricao], 14, UI.TEXTO, true))
	var no := c.no_atual()
	if not no.is_empty():
		tv.add_child(UI.label("Rota: %s" % _descricao_no(no), 14, UI.TEXTO, true))
	elif c.em_ferias():
		tv.add_child(UI.label("Férias de verão: sem corridas, Sair sempre gera encontro e o descanso rende +50%.", 14, UI.TEXTO, true))
	elif Calendario.e_vespera(c.turno):
		tv.add_child(UI.label("Véspera do objetivo: sem corridas opcionais.", 14, UI.TEXTO, true))
	var o := c.proximo_objetivo()
	if not o.is_empty():
		var faltam: int = o.turno - c.turno
		var quando := "NESTE TURNO" if faltam == 0 else "em %d turno%s" % [faltam, "s" if faltam > 1 else ""]
		var ho := UI.hbox(8)
		var cap := UI.capsula("Objetivo %s" % quando, UI.LARANJA if faltam > 0 else UI.PERIGO, 13)
		cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ho.add_child(cap)
		ho.add_child(UI.label("%s · %s %s · %s" % [o.texto, Dados.DIST_NOME[o.dist], o.piso, o.nome], 15, UI.DESTAQUE, true))
		tv.add_child(ho)
	topo.add_child(tv)
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(Color("#eaf4ff"), 10)
		var reacao := c.ultima_reacao
		if reacao.has("quem"):
			# quem falou no encontro reage à escolha (expressão da ficha + gesto)
			var hm := UI.hbox(12)
			var med := UI.medalhao(reacao.quem, 76, reacao.get("expressao", "normal"))
			var ret: RetratoGarota = med.get_child(0)
			hm.add_child(med)
			hm.add_child(UI.label(msg, 15, UI.TEXTO, true))
			pm.add_child(hm)
			ret.call_deferred("reagir", reacao)
			c.ultima_reacao = {}
		else:
			pm.add_child(UI.label(msg, 15, UI.TEXTO, true))
		v.add_child(pm)

	var banner := _banner_objetivo()
	if banner:
		v.add_child(banner)

	match c.pendencia():
		"encontro":
			v.add_child(_painel_encontro(c.encontro_atual()))
		"amuleto":
			v.add_child(_painel_amuleto())
		"mapa":
			v.add_child(_painel_mapa())
		"ferias":
			v.add_child(_painel_ferias())
		"corrida", "objetivo":
			v.add_child(_painel_olheiro(c.corrida_da_vez(), c.pendencia() == "objetivo"))
		_:
			_acoes(v)
	return v


func _descricao_no(no: Dictionary) -> String:
	var info: Dictionary = Dados.calendario.nos[no.tipo]
	var desc: String = info.descricao
	if no.tipo == "foco":
		desc = desc % Dados.ATTR_NOME[no.foco]
	var nome_no: String = info.nome
	if no.tipo == "foco":
		nome_no += " (%s)" % Dados.ATTR_NOME[no.foco]
	return "%s %s. %s" % [info.icone, nome_no, desc]


func _botao_grande(texto: String, acao: Callable) -> Button:
	var b := UI.botao(texto, acao, 22)
	b.custom_minimum_size.y = 64
	return b


func _acoes(v: VBoxContainer) -> void:
	v.add_child(_faixa_patio())
	var corridas := c.corridas_opcionais()
	if not corridas.is_empty():
		v.add_child(_titulo_secao("Correr", UI.ROSA, "gasta %d de energia, sem treino neste turno" % c.energia_corrida()))
		var hc := UI.hbox(8)
		for i in corridas.size():
			var bc := _cartao_corrida(corridas[i])
			if i < 3:
				UI.tecla(bc, ["Q", "W", "R"][i])
				_atalho([KEY_Q, KEY_W, KEY_R][i], bc)
			hc.add_child(bc)
		v.add_child(hc)

	v.add_child(_titulo_secao("Treinar", UI.CEU, "um treino por turno"))
	var grade := GridContainer.new()
	grade.columns = 5
	grade.add_theme_constant_override("h_separation", 8)
	var lista_treinos: Array = Carreira.TREINOS.keys()
	for i in lista_treinos.size():
		var b := _botao_treino(lista_treinos[i])
		UI.tecla(b, str(i + 1))
		_atalho(KEY_1 + i, b)
		grade.add_child(b)
	v.add_child(grade)

	v.add_child(_titulo_secao("Outras ações", UI.VERDE, ""))
	var h := UI.hbox(8)
	var b_desc := _botao_acao("Descansar\n+%d energia" % c.descanso_previsto(), c.descansar)
	UI.tecla(b_desc, "D")
	_atalho(KEY_D, b_desc)
	h.add_child(b_desc)
	var sair_txt := "Sair\n+humor, +%d energia" % Carreira.BAL.sair_energia
	if c.tipo_no() == "festival" or c.em_ferias():
		sair_txt += "\nencontro garantido"
	var b_sair := _botao_acao(sair_txt, c.sair)
	UI.tecla(b_sair, "S")
	_atalho(KEY_S, b_sair)
	h.add_child(b_sair)
	if c.lesionada:
		var b_enf := _botao_acao("Enfermaria\ncura a lesão", c.enfermaria)
		UI.tecla(b_enf, "E")
		_atalho(KEY_E, b_enf)
		h.add_child(b_enf)
	var b_loja := _botao_acao("Habilidades\n%d pontos\n%s" % [c.pontos, "fechar ▴" if loja_aberta else "abrir ▾"], Callable())
	b_loja.pressed.connect(_alternar_loja)
	UI.tecla(b_loja, "H")
	_atalho(KEY_H, b_loja)
	if _alguma_compravel():
		UI.colorir_botao(b_loja, UI.ROXO)
	h.add_child(b_loja)
	for filho in h.get_children():
		filho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filho.custom_minimum_size.y = 86
	v.add_child(h)
	if loja_aberta:
		v.add_child(_loja_habilidades())


## Título de seção: faixa colorida e, ao lado, uma dica curta.
func _titulo_secao(texto: String, cor: Color, dica: String) -> Control:
	var h := UI.hbox(10)
	h.add_child(UI.faixa(texto, cor, 17))
	if dica != "":
		var l := UI.label(dica, 13, UI.SUAVE)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	return h


## Entrada do pátio: o evento do turno e se ainda dá para conversar (não gasta o turno).
func _faixa_patio() -> Control:
	var ev := c.evento_patio()
	var info: Dictionary = Dados.patio.eventos.get(ev.id, {})
	var p := UI.painel(Color("#e9fbef"), 10)
	var h := UI.hbox(10)
	if ev.outra != "":
		var med := UI.medalhao(ev.outra, 52, "feliz" if ev.id == "aniversario" else "normal")
		med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(med)
	var tv := UI.vbox(3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ht := UI.hbox(8)
	ht.add_child(UI.capsula("Pátio", UI.VERDE, 13))
	var titulo_p := str(info.get("titulo", ""))
	if titulo_p != "" and titulo_p != "Pátio":
		var lt := UI.label(titulo_p, 15, UI.TEXTO)
		lt.add_theme_font_override("font", UI.negrito())
		ht.add_child(lt)
	tv.add_child(ht)
	var extra := " Conversa disponível." if c.pode_conversar_no_patio() else " Já conversaram neste turno."
	tv.add_child(UI.label(c.texto_patio(info.get("banner", ""), ev.outra) + extra, 13, UI.TEXTO, true))
	h.add_child(tv)
	var b := UI.botao("Ir ao pátio", func(): ir_patio.emit(), 16)
	UI.tecla(b, "P")
	UI.colorir_botao(b, UI.VERDE)
	_atalho(KEY_P, b)
	b.custom_minimum_size = Vector2(176, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	p.add_child(h)
	return p


## Loja de habilidades genéricas: comprar não gasta o turno (GDD §3.4).
func _loja_habilidades() -> Control:
	var p := UI.painel_titulo("Loja de habilidades", UI.ROXO)
	var v: VBoxContainer = p.get_meta("corpo")
	var desconto := " · Biblioteca: −30% no preço" if c.tipo_no() == "biblioteca" else ""
	var hl := UI.hbox(8)
	hl.add_child(UI.capsula("%d pontos" % c.pontos, UI.ROXO, 14))
	hl.add_child(UI.capsula("%d/%d equipadas" % [c.habilidades.size(), Dados.habilidades.limite], UI.CEU, 14))
	hl.add_child(UI.label("comprar não gasta o turno%s" % desconto, 13, UI.SUAVE, true))
	v.add_child(hl)
	var grade := GridContainer.new()
	grade.columns = 5
	grade.add_theme_constant_override("h_separation", 6)
	grade.add_theme_constant_override("v_separation", 6)
	for h in Dados.habilidades.lista:
		var tem: bool = h.id in c.habilidades
		var txt := "%s\n%s" % [h.nome, "✓ aprendida" if tem else "%d pts" % c.custo_habilidade(h.id)]
		var b := UI.botao(txt, func(): atualizou.emit(c.comprar_habilidade(h.id)), 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 46
		b.tooltip_text = h.descricao
		b.disabled = not c.pode_comprar(h.id)
		if tem:
			b.add_theme_color_override("font_disabled_color", UI.OK)
		elif not b.disabled:
			UI.colorir_botao(b, UI.ROXO)
		grade.add_child(b)
	v.add_child(grade)
	return p


## Escolha de amuleto (1 entre 3 ou 4). Com 6 equipados, pede qual sai.
func _painel_amuleto() -> Control:
	var p := UI.painel_titulo("Escolha um amuleto" if amuleto_escolhido == "" else "Amuletos cheios", UI.ROXO)
	var v: VBoxContainer = p.get_meta("corpo")
	if amuleto_escolhido == "":
		v.add_child(UI.label("Ele vale até o fim da carreira, mas não passa para a versão salva. Máximo de %d." % c.limite_amuletos(), 14, UI.SUAVE, true))
		for n_of in c.oferta_amuleto.size():
			var id: String = c.oferta_amuleto[n_of]
			var a := Dados.amuleto(id)
			var tipo: String = {"simples": "Simples", "troca": "Troca", "estilo": "Estilo", "raro": "Raro"}[a.tipo]
			var b := UI.botao("%s  (%s)\n%s" % [a.nome, tipo, a.descricao], func(): _escolher_amuleto(id), 16)
			UI.tecla(b, str(n_of + 1))
			b.custom_minimum_size.y = 62
			_atalho(KEY_1 + n_of, b)
			UI.colorir_botao(b, {"simples": Color("#8a96ad"), "troca": Color("#b48cff"), "estilo": Color("#4fa3ff"), "raro": UI.OURO}[a.tipo])
			UI.pop(b, 0.08 * n_of)
			v.add_child(b)
		v.add_child(UI.botao_confirmar("Não quero nenhum", func(): atualizou.emit(c.descartar_oferta()), 14,
			"Ficar sem amuleto desta vez? Clique de novo para confirmar"))
	else:
		v.add_child(UI.label("Os %d espaços estão cheios. Qual amuleto sai para entrar %s?" % [
			c.limite_amuletos(), Dados.amuleto(amuleto_escolhido).nome], 18, UI.DESTAQUE, true))
		for id in c.amuletos:
			var a := Dados.amuleto(id)
			v.add_child(UI.botao("Tirar %s: %s" % [a.nome, a.descricao], func(): atualizou.emit(c.escolher_amuleto(amuleto_escolhido, id)), 14))
		v.add_child(UI.botao("Deixar o novo de lado", func(): atualizou.emit(c.escolher_amuleto(amuleto_escolhido, "")), 14))
	return p


func _escolher_amuleto(id: String) -> void:
	if c.amuletos.size() < c.limite_amuletos():
		atualizou.emit(c.escolher_amuleto(id))
		return
	amuleto_escolhido = id
	_reconstruir()


func _cartao_corrida(cr: Dictionary) -> Control:
	var cat: Dictionary = Dados.calendario.categorias[cr.cat]
	var ol := c.olheiro(cr)
	var linhas := ["%s%s%s" % ["⚔ " if cr.get("desafio", false) else "", "📅 " if cr.get("fixa", false) else "", cr.nome],
		"%s · %s %s · %d m" % [cat.nome, Dados.DIST_NOME[cr.dist], cr.piso, Calendario.metros(cr)],
		"Aptidão %s/%s · fama até %d" % [Dados.APT_NOME[c.aptidao[cr.dist]], Dados.APT_NOME[c.aptidao[cr.piso]], c.fama_prevista(cr, 1, ol.mult)],
		"Olheiro: %s (%d%%) · fama ×%s" % [Carreira.nome_etiqueta(ol.etiqueta), roundi(ol.chance * 100), _mult_txt(ol.mult)]]
	if cr.get("fixa", false):
		var ss := c.series_da_corrida(cr).map(func(x): return "%s %d/%d" % [x.nome, x.feitas, x.total])
		if not ss.is_empty():
			linhas.append("Séries: " + ", ".join(ss))
	var pode := c.pode_entrar(cr)
	if not pode:
		linhas.append("Precisa de %d de fama" % cat.fama_entrada)
	var b := UI.botao("\n".join(linhas), func(): _correr(cr), 14)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 124 if cr.get("fixa", false) else 108
	b.disabled = not pode
	b.add_theme_color_override("font_color", _cor_etiqueta(ol.etiqueta))
	return b


## 0.985 -> "−1,5%", 1.12 -> "+12%"
static func _pct(m: float) -> String:
	var v := snappedf((m - 1.0) * 100.0, 0.1)
	var txt := str(absf(v)).replace(".", ",").trim_suffix(",0")
	return ("+" if v >= 0 else "−") + txt + "%"


static func _mult_txt(m: float) -> String:
	return str(m).replace(".", ",")


static func _cor_etiqueta(etq: String) -> Color:
	return {"favorita": UI.OK, "disputada": UI.TEXTO, "azarao": UI.DESTAQUE}[etq]


## Olheiro antes da largada (calendario.md §7.3) e a instrução (GDD §5.7): o botão de cada
## instrução já leva para a corrida.
func _painel_olheiro(cr: Dictionary, e_objetivo: bool) -> Control:
	var ol := c.olheiro(cr)
	var p := UI.painel_titulo("%s: %s" % ["Objetivo" if e_objetivo else "Corrida", cr.nome], UI.LARANJA if e_objetivo else UI.ROSA)
	var v: VBoxContainer = p.get_meta("corpo")
	var cat: Dictionary = Dados.calendario.categorias[cr.cat]
	var hc := HFlowContainer.new()
	hc.add_theme_constant_override("h_separation", 6)
	hc.add_theme_constant_override("v_separation", 4)
	hc.add_child(UI.capsula(cat.nome, UI.ROXO, 13))
	hc.add_child(UI.capsula("%s · %d m" % [Dados.DIST_NOME[cr.dist], Calendario.metros(cr)], UI.DIST_COR.get(cr.dist, UI.CEU), 13))
	hc.add_child(UI.capsula(str(cr.piso).capitalize(), UI.PISO_COR.get(cr.piso, UI.VERDE), 13))
	if e_objetivo:
		hc.add_child(UI.capsula("Meta: %s" % cr.texto, UI.LARANJA, 13))
	v.add_child(hc)
	var rel := UI.painel(Color("#eef5fc"), 12)
	var rv := UI.vbox(4)
	var hr := UI.hbox(8)
	hr.add_child(UI.label("Relatório do olheiro", 16, UI.SUAVE))
	hr.get_child(0).add_theme_font_override("font", UI.negrito())
	var esp_r := Control.new()
	esp_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(esp_r)
	hr.add_child(UI.capsula(Carreira.nome_etiqueta(ol.etiqueta), {"favorita": UI.VERDE, "disputada": UI.CEU, "azarao": UI.LARANJA}[ol.etiqueta], 15))
	rv.add_child(hr)
	rv.add_child(UI.label("Força média do pelotão: %d · %s, com aptidão e humor: %d" % [
		roundi(ol.forca), c.nome, roundi(ol.media)], 15, UI.TEXTO, true))
	rv.add_child(UI.label("Rival: %s" % ol.rival if ol.rival != "" else "Sem rival com nome nesta corrida.", 15, UI.TEXTO, true))
	if e_objetivo and ol.has("chance_meta"):
		var cm: float = ol.chance_meta
		var cor_m := UI.OK if cm >= 0.7 else (UI.DESTAQUE if cm >= 0.4 else UI.PERIGO)
		rv.add_child(UI.label("Chance de cumprir a meta (%s): ~%d%%" % [cr.texto, roundi(cm * 100)], 22, cor_m, true))
		if cr.has("maratona"):
			rv.add_child(UI.label("Conta só esta corrida; a maratona soma as boas colocações desde o último objetivo.", 13, UI.SUAVE, true))
	var etq := UI.label("%s · chance de vencer ~%d%% · fama ×%s" % [Carreira.nome_etiqueta(ol.etiqueta),
		roundi(ol.chance * 100), _mult_txt(ol.mult)], 17 if e_objetivo else 20, _cor_etiqueta(ol.etiqueta))
	rv.add_child(etq)
	rv.add_child(UI.label("Favorita rende menos fama (×0,75); Azarão rende mais (×1,5).", 13, UI.SUAVE, true))
	if cr.get("fixa", false):
		for x in c.series_da_corrida(cr):
			rv.add_child(UI.label("Série %s: %d de %d vitórias" % [x.nome, x.feitas, x.total], 14, UI.DESTAQUE, true))
	rel.add_child(rv)
	v.add_child(rel)
	v.add_child(UI.label("Instrução antes da largada (o olheiro sugere %s)" % SimCorrida.INSTRUCAO_NOME[ol.sugestao], 16, UI.SUAVE, true))
	var h := UI.hbox(8)
	var desc := {"normal": "ritmo do estilo"}
	for ins in ["poupar", "forcar"]:
		var x: Dictionary = SimCorrida.INSTRUCAO[ins]
		var partes := ["ritmo %s no começo" % _pct(x.ritmo)]
		if x.sprint != 1.0:
			partes.append("Sprint %s" % _pct(x.sprint))
		partes.append("fôlego %s" % _pct(x.folego))
		desc[ins] = ",\n".join(partes)
	var ordem_ins := ["poupar", "normal", "forcar"]
	for n_ins in 3:
		var ins: String = ordem_ins[n_ins]
		var txt := "%s%s\n%s\nvitória ~%d%%" % [SimCorrida.INSTRUCAO_NOME[ins], " ★" if ins == ol.sugestao else "",
			desc[ins], roundi(ol.chances[ins] * 100)]
		var b := UI.botao(txt, func(): _largar(ins), 15)
		UI.tecla(b, str(n_ins + 1))
		_atalho(KEY_1 + n_ins, b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 96
		if ins == ol.sugestao:
			UI.colorir_botao(b, UI.LARANJA)
		h.add_child(b)
	v.add_child(h)
	if not e_objetivo:
		v.add_child(UI.botao_confirmar("Desistir desta corrida e voltar às ações", func(): atualizou.emit(c.cancelar_corrida()), 14))
	return p


func _largar(ins: String) -> void:
	c.escolher_instrucao(ins)
	ir_correr.emit()


## Escolher a corrida abre o relatório do olheiro, onde se escolhe a instrução e larga.
func _correr(cr: Dictionary) -> void:
	c.escolher_corrida(cr)
	atualizou.emit("Inscrição na %s. Veja o relatório do olheiro e escolha a instrução." % cr.nome)


func _painel_mapa() -> Control:
	var t := c.trecho()
	var mapa: Array = c.mapas[t]
	var feitas: Array = c.rota[t]
	var opcoes := c.opcoes_mapa()
	var p := UI.painel_titulo("Trecho %d · escolha a rota dos próximos 2 turnos" % (t + 1), UI.CEU)
	var v: VBoxContainer = p.get_meta("corpo")
	var aviso := "Cada nó dura 2 turnos e liga ao de baixo e às diagonais."
	if not "circuito" in Dados.calendario.trechos[t].get("sem", []):
		aviso += " Todo caminho passa por pelo menos um Circuito, onde há corridas geradas. As corridas do calendário fixo valem em qualquer nó."
	else:
		aviso += " No semestre de base não há corridas: só treino, encontros e história."
	v.add_child(UI.label(aviso, 13, UI.SUAVE, true))
	var turno0: int = Dados.calendario.trechos[t].turnos[0]
	# alcance: a partir das opções desta linha, cada linha seguinte abre os vizinhos
	var alcance := {}
	var atual: Array = opcoes.duplicate()
	for i in range(feitas.size(), mapa.size()):
		alcance[i] = atual
		var prox := []
		for col in atual:
			for viz in Calendario.vizinhos(col):
				if not viz in prox:
					prox.append(viz)
		atual = prox
	var linhas := UI.vbox(30)
	var botoes := []   # botoes[i][col]
	for i in mapa.size():
		var turno_linha: int = turno0 + i * 2
		var h := UI.hbox(8)
		var cl: Dictionary = Dados.calendario.climas[Calendario.clima(c.semente, turno_linha)]
		var mes := UI.label("%s %s" % [Dados.calendario.meses[Calendario.mes_idx(turno_linha) % 12].substr(0, 3), cl.icone], 15)
		mes.custom_minimum_size.x = 64
		mes.tooltip_text = cl.nome
		mes.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(mes)
		var linha_b := []
		for col in 3:
			var no: Dictionary = mapa[i][col]
			var info: Dictionary = Dados.calendario.nos[no.tipo]
			var txt := "%s %s" % [info.icone, info.nome]
			if no.tipo == "foco":
				txt += "\n%s" % Dados.ATTR_NOME[no.foco]
			var b := UI.botao(txt, func(): atualizou.emit(c.escolher_no(col)), 14)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 50
			b.tooltip_text = _descricao_no(no)
			var escolhida: bool = i < feitas.size() and feitas[i] == col
			var disponivel: bool = i == feitas.size() and col in opcoes
			b.disabled = not disponivel
			if disponivel:
				UI.tecla(b, str(col + 1))
				UI.colorir_botao(b, UI.CEU)
				_atalho(KEY_1 + col, b)
			if escolhida:
				b.text = "● " + b.text
				b.add_theme_color_override("font_disabled_color", UI.DESTAQUE)
			elif i < feitas.size() or (i > feitas.size() and not col in alcance.get(i, [])):
				# caminho que já passou ou que a escolha de agora não alcança mais
				b.modulate.a = 0.35
			h.add_child(b)
			linha_b.append(b)
		botoes.append(linha_b)
		linhas.add_child(h)
	# ligações entre os nós, desenhadas atrás dos botões
	linhas.draw.connect(func():
		for i in range(botoes.size() - 1):
			for col in 3:
				for viz in Calendario.vizinhos(col):
					var a: Button = botoes[i][col]
					var b: Button = botoes[i + 1][viz]
					var pa := a.get_global_rect().get_center() - linhas.get_global_rect().position
					var pb := b.get_global_rect().get_center() - linhas.get_global_rect().position
					pa.y += a.size.y / 2.0
					pb.y -= b.size.y / 2.0
					var no_caminho: bool = i + 1 < feitas.size() and feitas[i] == col and feitas[i + 1] == viz
					var abre: bool = (i < feitas.size() and feitas[i] == col and i + 1 == feitas.size() and viz in opcoes) \
						or (i >= feitas.size() and col in alcance.get(i, []) and viz in alcance.get(i + 1, []))
					var cor := UI.DESTAQUE if no_caminho else (Color("#5a8fc8") if abre else Color("#d5dfea"))
					linhas.draw_line(pa, pb, cor, 3.0 if no_caminho else 2.0, true))
	v.add_child(linhas)
	var tr: Dictionary = Dados.calendario.trechos[t]
	var depois := []
	for f in Dados.calendario.ferias:
		if int(f[0]) > int(tr.turnos[1]) and int(f[0]) < int(tr.objetivo):
			depois.append("Férias (turnos %d–%d)" % [f[0], f[1]])
	for vs in Dados.calendario.vesperas:
		if int(vs) > int(tr.turnos[1]) and int(vs) < int(tr.objetivo):
			depois.append("Véspera (turno %d)" % vs)
	var fim := "Depois: %s, e o objetivo no turno %d." % [", ".join(depois), tr.objetivo] if not depois.is_empty() \
		else "Depois: o objetivo no turno %d." % tr.objetivo
	v.add_child(UI.label(fim, 13, UI.SUAVE, true))
	return p


func _painel_ferias() -> Control:
	var p := UI.painel_titulo("Férias de verão: escolha o acampamento", UI.VERDE)
	var v: VBoxContainer = p.get_meta("corpo")
	v.add_child(UI.label("Durante as férias não há corridas, Sair sempre gera encontro e o descanso rende +50%.", 15, UI.TEXTO, true))
	var b1 := _botao_grande("Serra: Estamina e Determinação contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("serra")))
	var b2 := _botao_grande("Praia: Velocidade e Poder contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("praia")))
	UI.tecla(b1, "1")
	UI.tecla(b2, "2")
	UI.colorir_botao(b1, UI.VERDE)
	UI.colorir_botao(b2, UI.CEU)
	_atalho(KEY_1, b1)
	_atalho(KEY_2, b2)
	v.add_child(b1)
	v.add_child(b2)
	return p


## Encontro, Mistério ou véspera: diálogo curto com 1 a 3 escolhas (GDD §4.7).
func _painel_encontro(e: Dictionary) -> Control:
	var tipo: String = c.encontro_pendente.get("tipo", "encontro")
	var rotulo: String = {"encontro": "Encontro", "misterio": "Mistério", "vespera": "Véspera",
		"capitulo": "História"}.get(tipo, "Encontro")
	var cor_tipo: Color = {"encontro": UI.ROSA, "misterio": Color("#b0764a"), "vespera": UI.CEU,
		"capitulo": UI.ROXO}.get(tipo, UI.ROSA)
	var p := UI.painel_titulo(rotulo, cor_tipo)
	var v: VBoxContainer = p.get_meta("corpo")
	var topo := UI.hbox(14)
	var quem := c.quem_do_encontro()
	var med := UI.medalhao(quem, 104, e.get("expressao", "normal"))
	med.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var ret: RetratoGarota = med.get_child(0)
	topo.add_child(med)
	ret.call_deferred("gesto", e.get("gesto", ""))
	var tv := UI.vbox(6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ht := UI.hbox(8)
	if quem != "":
		ht.add_child(UI.capsula(quem, UI.cor_garota(quem), 14))
	var lt := UI.label(c.texto(e.titulo), 22, UI.TEXTO, true)
	ht.add_child(lt)
	tv.add_child(ht)
	# fala num balão claro
	var balao := UI.painel(Color("#f4f8fc"), 12)
	balao.add_child(UI.label(c.texto(e.texto), 17, UI.TEXTO, true))
	tv.add_child(balao)
	topo.add_child(tv)
	v.add_child(topo)
	for i in e.escolhas.size():
		var idx: int = i
		var b := UI.botao(c.texto(e.escolhas[i].texto), func(): atualizou.emit(c.escolher(idx)), 17)
		UI.tecla(b, str(i + 1))
		b.custom_minimum_size.y = 50
		_atalho(KEY_1 + i, b)
		UI.pop(b, 0.06 * i)
		v.add_child(b)
	return p


func _botao_treino(t: String) -> Button:
	var g := c.ganho_previsto(t)
	var nv := c.nivel_efetivo(t)
	var nv_txt := "Nv %d" % nv
	if nv > c.nivel_treino(t):
		nv_txt += "↑"
	var linhas := ["%s%s" % [Dados.ATTR_NOME[t], " ★" if t in c.naturais else ""], nv_txt]
	if c.duplas.has(t):
		linhas.append("com %s!" % c.duplas[t].split(" ")[0])
	for k in g:
		linhas.append("+%d %s" % [round(g[k]), Dados.ATTR_CURTO[k]])
	linhas.append("−%d energia" % c.custo(t))
	var falha := c.chance_falha(t)
	linhas.append(("⚠ Falha %d%%" if falha > 0.0 else "Falha %d%%") % round(falha * 100))
	var b := _botao_acao("\n".join(linhas), func(): return c.treinar(t))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = Dados.ATTR_NOME[t]
	b.custom_minimum_size.y = 150
	UI.colorir_botao(b, UI.ATTR_COR[t])
	b.add_theme_font_size_override("font_size", 14)
	# ícone do atributo no canto do cartão de treino
	var ic := UI.Icone.new(t, 26)
	ic.position = Vector2(8, 8)
	b.add_child(ic)
	if falha > 0.0:
		# risco de falha: borda vermelha/dourada (o texto fica branco para ler sobre a cor)
		var sb: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		sb.border_color = UI.PERIGO if falha >= 0.25 else UI.DESTAQUE
		sb.set_border_width_all(3)
		sb.border_width_bottom = 5
		b.add_theme_stylebox_override("normal", sb)
	return b


func _botao_acao(texto: String, acao: Callable) -> Button:
	var b: Button
	if acao.is_valid():
		b = UI.botao(texto, func(): atualizou.emit(acao.call()), 14)
	else:
		b = UI.botao(texto, func(): pass, 14)
	b.custom_minimum_size = Vector2(130, 112)
	return b


## Liga uma tecla a um botão: a tecla aperta o botão (respeitando se está desabilitado).
func _atalho(tecla: int, b: Button) -> void:
	_atalhos[tecla] = func():
		if is_instance_valid(b) and not b.disabled and b.is_visible_in_tree():
			b.pressed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	var tecla := k.keycode
	if tecla >= KEY_KP_1 and tecla <= KEY_KP_9:
		tecla = KEY_1 + (tecla - KEY_KP_1)
	if _atalhos.has(tecla):
		get_viewport().set_input_as_handled()
		_atalhos[tecla].call()


func _alternar_loja() -> void:
	loja_aberta = not loja_aberta
	_reconstruir()


func _alguma_compravel() -> bool:
	for h in Dados.habilidades.lista:
		if c.pode_comprar(h.id):
			return true
	return false


# ---------- progressão e recompensa ----------

## Banner grande quando a última corrida foi um objetivo (cumprido ou não). Sai uma vez.
func _banner_objetivo() -> Control:
	var n := c.resultados.size()
	if resultados_vistos < 0 or n <= resultados_vistos:
		resultados_vistos = n
		return null
	resultados_vistos = n
	var r: Dictionary = c.resultados[-1]
	if int(r.get("objetivo", 0)) <= 0:
		return null
	var ok: bool = r.ok
	var p := UI.painel(Color("#e6fbef") if ok else Color("#ffe9e7"), 12)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.border_color = UI.VERDE if ok else UI.PERIGO
	sb.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(14)
	h.add_child(UI.faixa("✓ OBJETIVO CUMPRIDO!" if ok else "✗ OBJETIVO NÃO CUMPRIDO", UI.VERDE if ok else UI.PERIGO, 24))
	var sub := UI.label("%s · %dº lugar · +%d de fama" % [r.nome, r.posicao, r.fama], 16, UI.TEXTO, true)
	sub.add_theme_font_override("font", UI.negrito())
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sub)
	p.add_child(h)
	UI.pop(p, 0.15)
	if ok:
		p.ready.connect(func():
			await get_tree().process_frame
			if is_instance_valid(p):
				UI.confete(self, p.get_global_rect().get_center() - get_global_rect().position, 110),
			CONNECT_ONE_SHOT)
	return p


func _trilha() -> Control:
	var t := TrilhaCarreira.new()
	t.carreira = c
	t.custom_minimum_size = Vector2(200, 36)
	return t


## Trilha da carreira: os 72 turnos numa linha, com os anos, os objetivos (✓, ✗, ★ o próximo)
## e a garota andando nela.
class TrilhaCarreira extends Control:
	var carreira: Carreira
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := carreira
		var total: float = Carreira.BAL.turnos
		var x0 := 10.0
		var x1 := size.x - 10.0
		var y := size.y * 0.55
		var px := func(turno: float) -> float: return lerpf(x0, x1, (turno - 1.0) / maxf(1.0, total - 1.0))
		draw_line(Vector2(x0, y), Vector2(x1, y), Color("#dbe5ef"), 8.0, true)
		draw_line(Vector2(x0, y), Vector2(px.call(c.turno), y), c.cor, 6.0, true)
		var f := UI.negrito()
		for ano in 3:
			var xa: float = px.call(ano * total / 3.0 + 1.0)
			if ano > 0:
				draw_line(Vector2(xa, y - 10), Vector2(xa, y + 10), Color("#b9c8d8"), 2.0)
			draw_string(f, Vector2(xa + 4, y - 9), "Ano %d" % (ano + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.SUAVE)
		var prox := c.proximo_objetivo()
		for o in c.objetivos:
			var xo: float = px.call(o.turno)
			var res := c.resultados.filter(func(r): return r.turno == o.turno and r.objetivo > 0)
			var cor := Color("#b9c8d8")
			var raio := 6.0
			if not res.is_empty():
				cor = UI.OK if res[0].ok else UI.PERIGO
			elif not prox.is_empty() and o.turno == prox.turno:
				cor = UI.DESTAQUE
				raio = 7.0 + sin(_t * 4.0) * 1.5
			draw_circle(Vector2(xo, y), raio + 2.0, Color.WHITE)
			draw_circle(Vector2(xo, y), raio, cor)
		# a garota: um disco da cor dela que pulsa
		var xg: float = px.call(c.turno)
		var pulso := 1.0 + sin(_t * 5.0) * 0.12
		draw_circle(Vector2(xg, y), 9.0 * pulso, Color.WHITE)
		draw_circle(Vector2(xg, y), 6.5 * pulso, c.cor)
