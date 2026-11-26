class_name TelaCorrida
extends Control
## Tela da corrida: vista 3D com troca de câmera (Corrida3D), minimapa, ranking ao vivo,
## avisos de habilidade e botões 1x / 2x / pular. O jogador só assiste.

signal terminou(posicao: int)

## Passos de simulação (0,1 s) por segundo real em 1x. 20 = corrida 2x mais rápida que o tempo real.
const PASSOS_1X := 20.0
const CORES := ["#c9a227", "#8e6cc9", "#c9568e", "#4fa3a5", "#b0764a", "#7f8fa6",
				"#a3b14f", "#d07a4a", "#5c7fb8", "#9a5bb0", "#6aa86a"]

var dados: Dictionary
var cor_jogadora: Color
var sim: SimCorrida
var cores: Array = []
var velocidade := 1.0
var acumulado := 0.0
var acabou := false
var emitiu := false   # evita registrar a corrida duas vezes (botão + Enter)
var avisos: Array = []   # [{idx, texto, vida}]
var linhas: Array = []   # [ColorRect, Label] por posição do ranking

var pista: Pista
var mundo: Corrida3D
var x_antes: Array = []   # posição de cada corredora no passo anterior (para interpolar)
var botao_camera: Button
var faixa_aviso: Label
var aviso: UI.Faixa   # faixa dourada com a habilidade da jogadora
var resultado_pos: Label
var resultado_meta: PanelContainer
var aviso_vida := 0.0
var ranking: VBoxContainer
var info: Label
var feed: VBoxContainer
var botoes: HBoxContainer
var continuar: Button
var resultado: PanelContainer
var resultado_txt: Label


func _init(d: Dictionary, cor: Color) -> void:
	dados = d
	cor_jogadora = cor
	sim = SimCorrida.new(d.field, d.distancia, d.get("seed", 0), d.get("clima", ""))
	for r in sim.rs:
		x_antes.append(r.x)
	var n := 0
	for g in d.field:
		if g.jogadora:
			cores.append(cor)
		else:
			cores.append(Color(CORES[n % CORES.size()]))
			n += 1


func _ready() -> void:
	var em_pe := UI.em_pe()
	var raiz := UI.vbox(8 if em_pe else 10)
	var topo := UI.hbox(8)
	topo.add_child(UI.faixa(dados.nome, UI.ROSA, 16 if em_pe else 22))
	var chips: Container = UI.fluxo(6) if em_pe else UI.hbox(6)
	chips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chips.add_child(UI.capsula("%d m" % dados.distancia, UI.CEU, 15))
	if dados.objetivo > 0:
		chips.add_child(UI.capsula("Objetivo: %s" % dados.get("texto_objetivo", ""), UI.LARANJA, 15))
	else:
		chips.add_child(UI.capsula("Corrida opcional", Color("#8a96ad"), 15))
	if dados.get("clima", "") != "":
		var cl: Dictionary = Dados.calendario.climas[dados.clima]
		chips.add_child(UI.capsula("%s %s" % [cl.icone, cl.nome], Color("#5bb8e8"), 15))
	if not em_pe:
		topo.add_child(chips)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	botoes = UI.hbox(6)
	for v in [["1x", 1.0], ["2x", 2.0]]:
		var vel: float = v[1]
		var bv := UI.botao(v[0], func(): _mudar_velocidade(vel), 16)
		bv.custom_minimum_size.x = 46 if em_pe else 52
		bv.set_meta("vel", vel)
		botoes.add_child(bv)
	botoes.add_child(UI.botao_cor("Pular ▶▶", _pular, UI.LARANJA, 16))
	topo.add_child(botoes)
	# no fim, o Continuar fica no topo (no lugar dos botões de velocidade), sempre visível
	continuar = UI.botao_principal("Continuar ▶", _continuar, 20)
	continuar.visible = false
	topo.add_child(continuar)
	raiz.add_child(topo)
	if em_pe:
		# em pé: distância, objetivo e clima numa segunda linha
		raiz.add_child(chips)
	_mudar_velocidade(1.0)

	var meio := UI.fila(16 if not em_pe else 8)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var area := Control.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if em_pe:
		# em pé: a pista em cima (um pouco mais da metade) e a classificação embaixo
		area.custom_minimum_size.y = 330
		area.size_flags_stretch_ratio = 1.3
	area.clip_contents = true
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.add_child(vista)
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_2X if Escala.compacto() else Viewport.MSAA_4X  # celular: mais leve
	vista.add_child(vp)
	mundo = Corrida3D.new(cores, dados.field.map(func(g): return g.nome))
	vp.add_child(mundo)
	meio.add_child(area)
	# por cima da vista 3D: câmeras e aviso de habilidade da jogadora
	var sobre := Control.new()
	sobre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sobre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(sobre)
	var cams := UI.hbox(6)
	cams.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cams.position = Vector2(12, -52)
	cams.grow_vertical = Control.GROW_DIRECTION_BEGIN
	botao_camera = UI.botao("", _proxima_camera, 16)
	if em_pe:
		# em pé só cabe o botão que troca de câmera (cada toque vai para a próxima)
		cams.position = Vector2(8, -8)
		botao_camera.custom_minimum_size.y = 44
		cams.add_child(botao_camera)
	else:
		cams.add_child(UI.label("Câmera (C):", 16))
		cams.add_child(botao_camera)
		for m in Corrida3D.CAMERA_NOME.size():
			var modo: int = m
			cams.add_child(UI.botao(str(m + 1), func(): _usar_camera(modo), 16))
	sobre.add_child(cams)
	aviso = UI.faixa(" ", UI.OURO, 18 if em_pe else 24) as UI.Faixa
	faixa_aviso = aviso.rotulo
	aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aviso.position.y = 16
	aviso.modulate.a = 0.0
	sobre.add_child(aviso)
	# cartão de resultado no centro da vista 3D, com outro botão de continuar
	resultado = UI.painel(UI.PAINEL, 18)
	# embaixo, no centro: a chegada continua visível atrás
	resultado.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	resultado.position.y -= 60 if em_pe else 96
	resultado.grow_horizontal = Control.GROW_DIRECTION_BOTH
	resultado.grow_vertical = Control.GROW_DIRECTION_BEGIN
	resultado.visible = false
	var rv := UI.vbox(8)
	var rh := UI.hbox(14)
	rh.alignment = BoxContainer.ALIGNMENT_CENTER
	rh.add_child(UI.medalhao(dados.field[0].nome, 52 if em_pe else 72, "feliz"))
	resultado_pos = UI.label_contorno("", 44 if em_pe else 60, UI.OURO, Color.WHITE, 12)
	resultado_pos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh.add_child(resultado_pos)
	var rtv := UI.vbox(6)
	rtv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resultado_txt = UI.label("", 17 if em_pe else 20, UI.TEXTO)
	rtv.add_child(resultado_txt)
	resultado_meta = PanelContainer.new()
	resultado_meta.visible = false
	rtv.add_child(resultado_meta)
	rh.add_child(rtv)
	rv.add_child(rh)
	var b := UI.botao_principal("Continuar (Enter)", _continuar, 20)
	b.custom_minimum_size = Vector2(240 if em_pe else 300, 50)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rv.add_child(b)
	resultado.add_child(rv)
	sobre.add_child(resultado)

	var lado := UI.painel_titulo("Classificação", UI.CEU)
	lado.custom_minimum_size.x = 0 if em_pe else 310
	lado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if em_pe:
		lado.custom_minimum_size.y = 220
	var lv := UI.vbox(6)
	info = UI.label("", 15, UI.SUAVE)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_override("font", UI.negrito())
	lv.add_child(info)
	ranking = UI.vbox(2)
	lv.add_child(ranking)
	pista = Pista.new()
	pista.tela = self
	pista.custom_minimum_size = Vector2(0, 110)
	lv.add_child(pista)
	lv.add_child(UI.label("Habilidades", 14, UI.SUAVE))
	feed = UI.vbox(2)
	lv.add_child(feed)
	# o painel lateral rola se não couber, para nunca empurrar nada para fora da tela
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(lv)
	var corpo_lado: VBoxContainer = lado.get_meta("corpo")
	corpo_lado.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo_lado.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo_lado.add_child(rolagem)
	meio.add_child(lado)
	raiz.add_child(meio)
	add_child(UI.margem(raiz, 8 if em_pe else 16))
	_atualizar_ranking()


func _process(delta: float) -> void:
	if not acabou:
		acumulado += delta * PASSOS_1X * velocidade
		while acumulado >= 1.0 and not sim.done:
			acumulado -= 1.0
			for i in sim.rs.size():
				x_antes[i] = sim.rs[i].x
			_registrar(sim.step())
		if sim.done:
			_finalizar()
		_atualizar_ranking()
	for a in avisos:
		a.vida -= delta
	avisos = avisos.filter(func(a): return a.vida > 0.0)
	aviso_vida -= delta
	aviso.modulate.a = clampf(aviso_vida, 0.0, 1.0)
	_atualizar_3d(delta)
	pista.queue_redraw()


func _atualizar_3d(delta: float) -> void:
	var xs := []
	var vs := []
	var lider := 0
	for i in sim.rs.size():
		var r: Dictionary = sim.rs[i]
		var x: float = r.x if acabou else lerpf(x_antes[i], r.x, clampf(acumulado, 0.0, 1.0))
		xs.append(minf(x, sim.D))
		vs.append(0.0 if r.t >= 0.0 else r.v)
		if r.x > sim.rs[lider].x:
			lider = i
	var fase := SimCorrida.fase(minf(sim.rs[lider].x, sim.D - 0.01), sim.D)
	mundo.atualizar(xs, sim.D, vs, fase, lider, delta, sim.rs[0].t >= 0.0)
	var nome: String = Corrida3D.CAMERA_NOME[mundo.modo]
	if mundo.modo == Corrida3D.Camera.AUTO:
		nome += " · " + Corrida3D.CAMERA_NOME[mundo.modo_efetivo]
	botao_camera.text = nome


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if acabou and k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_continuar()
		return
	if k.keycode == KEY_C:
		_proxima_camera()
	elif k.keycode >= KEY_1 and k.keycode < KEY_1 + Corrida3D.CAMERA_NOME.size():
		_usar_camera(k.keycode - KEY_1)


func _proxima_camera() -> void:
	mundo.proxima_camera()


func _usar_camera(m: int) -> void:
	mundo.modo = m as Corrida3D.Camera


func _registrar(ev: Array) -> void:
	for e in ev:
		var g: Dictionary = dados.field[e.idx]
		avisos.append({"idx": e.idx, "texto": e.nome, "vida": 1.6})
		var txt := "%s: %s" % [g.nome.split(" ")[0], e.nome]
		var cor := UI.DESTAQUE if g.jogadora else UI.SUAVE
		if e.unica:
			txt += " ★"
		if g.jogadora:
			faixa_aviso.text = "%s: %s%s" % [g.nome.split(" ")[0], e.nome, " ★" if e.unica else ""]
			aviso.update_minimum_size()
			aviso.queue_sort()
			aviso.queue_redraw()
			if aviso_vida <= 0.0:
				UI.pop(aviso)
			aviso_vida = 2.0
		feed.add_child(UI.label(txt, 13, cor))
		while feed.get_child_count() > 6:
			var velho := feed.get_child(0)
			feed.remove_child(velho)
			velho.queue_free()


func _pular() -> void:
	while not sim.done:
		_registrar(sim.step())
	avisos.clear()
	_finalizar()
	_atualizar_ranking()


func _finalizar() -> void:
	if acabou:
		return
	acabou = true
	botoes.visible = false
	var pos := posicao_jogadora()
	info.text = "Chegada! %s terminou em %dº." % [dados.field[0].nome.split(" ")[0], pos]
	continuar.visible = true
	aviso_vida = 0.0
	var nome_j: String = dados.field[0].nome.split(" ")[0]
	resultado_pos.text = "%dº" % pos
	var medalha := {1: UI.OURO, 2: Color("#9fb3c8"), 3: Color("#d08a4e")}
	resultado_pos.add_theme_color_override("font_color", medalha.get(pos, UI.CEU))
	resultado_txt.text = "%s cruzou a linha!" % nome_j if pos == 1 else "%s terminou em %dº" % [nome_j, pos]
	var ok := pos == 1
	if dados.get("texto_objetivo", "") != "":
		ok = pos <= (int(dados.objetivo) if int(dados.objetivo) > 0 else 12)
		var ri: int = dados.get("rival_idx", -1)
		if dados.get("meta_rival", false) and ri >= 0:
			ok = ok and sim.classificacao().find(ri) + 1 > pos
		var txt_obj: String = dados.get("texto_objetivo", "top %d" % dados.objetivo)
		var meta: String
		if dados.get("maratona", 0) > 0:
			meta = "%s · %s" % ["✓ Dentro da meta" if ok else "✗ Fora da meta", txt_obj]
		else:
			meta = "%s · %s" % ["✓ Objetivo cumprido" if ok else "✗ Objetivo não cumprido", txt_obj]
		var cap := UI.capsula(meta, UI.VERDE if ok else UI.PERIGO, 17)
		resultado_meta.replace_by(cap)
		resultado_meta.queue_free()
		resultado_meta = cap
	resultado.visible = true
	UI.pop(resultado)
	UI.pop(resultado_pos, 0.15)
	if ok:
		var alvo: Control = resultado.get_parent()
		UI.confete(alvo, Vector2(alvo.size.x / 2.0, alvo.size.y - 120), 140)


func posicao_jogadora() -> int:
	return sim.classificacao().find(0) + 1


func _continuar() -> void:
	if not acabou or emitiu:
		return
	emitiu = true
	terminou.emit(posicao_jogadora())


func _atualizar_ranking() -> void:
	if not acabou:
		var lider: float = 0.0
		for r in sim.rs:
			lider = maxf(lider, r.x)
		var fases := ["Largada", "Meio", "Final", "Sprint"]
		info.text = "%s · %.0f m restantes · %.0f s" % [
			fases[SimCorrida.fase(minf(lider, sim.D - 0.01), sim.D)], maxf(0.0, sim.D - lider), sim.t]
	if linhas.is_empty():
		for i in sim.rs.size():
			var linha := PanelContainer.new()
			var h := UI.hbox(6)
			var num := UI.label_contorno("", 13, Color.WHITE, Color("#6b7a99"), 4)
			num.custom_minimum_size = Vector2(30, 0)
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var selo := PanelContainer.new()
			selo.add_child(num)
			h.add_child(selo)
			var bola := ColorRect.new()
			bola.custom_minimum_size = Vector2(10, 10)
			bola.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(bola)
			var l := UI.label("", 14)
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
			h.add_child(l)
			var t := UI.label("", 13, UI.SUAVE)
			h.add_child(t)
			linha.add_child(h)
			ranking.add_child(linha)
			linhas.append([bola, l, selo, t, linha, num])
	var ordem := sim.classificacao()
	for i in ordem.size():
		var idx: int = ordem[i]
		var g: Dictionary = dados.field[idx]
		var r: Dictionary = sim.rs[idx]
		var extra := ""
		if r.t >= 0.0:
			extra = "%.1f s" % r.t
		elif r.hp <= 0.0:
			extra = "sem fôlego"
		linhas[i][0].color = cores[idx]
		var l: Label = linhas[i][1]
		l.text = "%s · %s" % [g.nome, g.estilo.to_upper()]
		l.add_theme_color_override("font_color", UI.DESTAQUE if g.jogadora else UI.TEXTO)
		linhas[i][3].text = extra
		linhas[i][5].text = "%dº" % (i + 1)
		var chave := "%d:%s" % [i, g.jogadora]
		if linhas[i][4].get_meta("chave", "") != chave:
			linhas[i][4].set_meta("chave", chave)
			_estilo_linha(linhas[i], i + 1, g.jogadora)


## Fundo da linha do ranking (destaque na jogadora) e o selo da posição (ouro, prata e
## bronze para o pódio).
func _estilo_linha(ln: Array, pos: int, jogadora: bool) -> void:
	var fundo := StyleBoxFlat.new()
	fundo.set_corner_radius_all(8)
	fundo.content_margin_left = 4
	fundo.content_margin_right = 6
	fundo.content_margin_top = 1
	fundo.content_margin_bottom = 1
	fundo.bg_color = Color("#fff1e3") if jogadora else Color(0, 0, 0, 0)
	if jogadora:
		fundo.border_color = UI.LARANJA
		fundo.set_border_width_all(2)
	ln[4].add_theme_stylebox_override("panel", fundo)
	if jogadora:
		ln[1].add_theme_font_override("font", UI.negrito())
	else:
		ln[1].remove_theme_font_override("font")
	var cores_pos := {1: UI.OURO, 2: Color("#9fb3c8"), 3: Color("#d08a4e")}
	var cor: Color = cores_pos.get(pos, Color("#b9c8d8"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(10)
	sb.shadow_color = cor.darkened(0.3)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 2)
	ln[2].add_theme_stylebox_override("panel", sb)
	ln[5].add_theme_color_override("font_outline_color", cor.darkened(0.45))


func _mudar_velocidade(v: float) -> void:
	velocidade = v
	for b in botoes.get_children():
		if b.has_meta("vel"):
			if is_equal_approx(float(b.get_meta("vel")), v):
				UI.colorir_botao(b, UI.CEU)
			else:
				for nome in ["normal", "hover", "pressed"]:
					b.remove_theme_stylebox_override(nome)
				for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_outline_color"]:
					b.remove_theme_color_override(k)
				b.remove_theme_constant_override("outline_size")
				b.remove_theme_font_override("font")


## Minimapa: a pista vista de cima, com um ponto por corredora.
class Pista extends Control:
	var tela: TelaCorrida

	func _draw() -> void:
		var largura_m := PistaGeo.RETA + 2.0 * (PistaGeo.RAIO + PistaGeo.LARGURA)
		var altura_m := 2.0 * (PistaGeo.RAIO + PistaGeo.LARGURA)
		var esc := minf(size.x / largura_m, size.y / altura_m) * 0.95
		var c := size / 2.0
		var pts := PackedVector2Array()
		for i in 121:
			pts.append(c + PistaGeo.ponto(PistaGeo.PERIMETRO * i / 120.0, PistaGeo.LARGURA / 2.0) * esc)
		draw_polyline(pts, Color("#b9e6c4"), maxf(3.0, PistaGeo.LARGURA * esc) + 4.0)
		draw_polyline(pts, Color("#5cc97a"), maxf(3.0, PistaGeo.LARGURA * esc))
		var chegada := PistaGeo.ponto(0.0, 0.0) * esc + c
		draw_line(chegada, chegada + Vector2(0, PistaGeo.LARGURA * esc), Color.WHITE, 2.0)
		var sim: SimCorrida = tela.sim
		for i in range(sim.rs.size() - 1, -1, -1):
			var s := PistaGeo.s_da_corrida(sim.rs[i].x, sim.D)
			var p := c + PistaGeo.ponto(s, Corrida3D.faixa(i)) * esc
			if i == 0:
				draw_circle(p, 6.0, Color.WHITE)
			draw_circle(p, 4.0, tela.cores[i])
