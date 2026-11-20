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
	var raiz := UI.hbox(18)
	raiz.add_child(_painel_garota())
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var direita := _painel_turno()
	direita.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(direita)
	raiz.add_child(rolagem)
	add_child(UI.margem(raiz, 20))


# ---------- painel da garota ----------

## Estado da tela anterior (atributos e energia), para mostrar o que mudou com a última ação
## ou corrida. Vale só para a mesma carreira.
static var anterior := {}
## Aba do painel da garota (0 = Status, 1 = Relações e equipamento) e loja aberta ou não.
static var aba := 0
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


func _linha_barra(rotulo: String, valor: float, maximo: float, cor: Color, chave: String = "", marca: float = -1.0) -> Control:
	var h := UI.hbox(8)
	if chave in SimCorrida.KEYS:
		h.add_child(UI.Icone.new(chave, 20))
		cor = UI.ATTR_COR[chave]
	var l := UI.label(rotulo, 14)
	l.custom_minimum_size.x = 128 if not chave in SimCorrida.KEYS else 100
	h.add_child(l)
	var d: float = _delta.get(chave, 0.0)
	var b := UI.barra(valor - d if d > 0 else valor, maximo, cor, 150)
	if d > 0:
		# a barra cresce do valor antigo até o novo, com um brilho e o ganho subindo
		b.create_tween().tween_property(b, "value", valor, 0.6).set_delay(0.15).set_trans(Tween.TRANS_CUBIC)
		b.modulate = Color(1.8, 1.8, 1.8)
		b.create_tween().tween_property(b, "modulate", Color.WHITE, 0.9).set_delay(0.2)
		var txt_f := "+%d" % roundi(d)
		b.ready.connect(func():
			UI.numero_flutuante(b, txt_f, cor.lightened(0.3), Vector2(b.size.x * clampf(valor / maximo, 0.0, 1.0) - 10, -14), 18),
			CONNECT_ONE_SHOT)
	if marca > 0.0:
		var m := MarcaBarra.new()
		m.frac = clampf(marca / maximo, 0.0, 1.0)
		m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(m)
	h.add_child(b)
	var num := UI.label("%d" % valor, 14)
	num.custom_minimum_size.x = 34
	h.add_child(num)
	if d != 0.0:
		UI.contar(num, valor - d, valor)
	if chave in SimCorrida.KEYS:
		var n := Dados.nota({chave: valor})
		h.add_child(UI.label(n, 14, UI.NOTA_COR.get(n, UI.SUAVE)))
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
		draw_line(Vector2(x, -3), Vector2(x, size.y + 3), Color("#f2c14e"), 2.0)


static func _cor_apt(a: String) -> Color:
	return {"R": UI.PERIGO, "O": UI.SUAVE, "B": Color("#7fb3e6"), "X": UI.OK}[a]


func _chips_aptidao() -> Control:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 4)
	f.add_theme_constant_override("v_separation", 4)
	var nomes := {"sprint": "Sprint", "milha": "Milha", "media": "Média", "longa": "Longa", "grama": "Grama", "terra": "Terra"}
	for d in nomes:
		var a: String = c.aptidao[d]
		var p := UI.painel(_cor_apt(a).darkened(0.65), 4)
		var l := UI.label("%s %s" % [nomes[d], Dados.APT_NOME[a]], 12, _cor_apt(a).lightened(0.2))
		p.add_child(l)
		p.tooltip_text = "Aptidão %s em %s" % [Dados.APT_NOME[a], nomes[d]]
		f.add_child(p)
	return f


func _painel_garota() -> Control:
	var p := UI.painel()
	p.custom_minimum_size.x = 410
	var v := UI.vbox(7)
	var topo := UI.hbox(12)
	topo.add_child(RetratoGarota.new(c.nome, 72, SpritesGarota.expressao_do_humor(c.humor)))
	var nomes := UI.vbox(2)
	nomes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nomes.add_child(UI.label(c.nome, 22))
	nomes.add_child(UI.label(Dados.ESTILO_NOME[c.estilo], 14, UI.SUAVE))
	var hf := UI.hbox(6)
	hf.add_child(UI.label("★ Fama", 15, UI.DESTAQUE))
	var l_fama := UI.label(str(c.fama), 15, UI.DESTAQUE)
	hf.add_child(l_fama)
	var dfama: int = _delta.get("fama", 0)
	if dfama != 0:
		UI.contar(l_fama, c.fama - dfama, c.fama)
		var lf := UI.label("%+d" % dfama, 14, UI.OK if dfama > 0 else UI.PERIGO)
		hf.add_child(lf)
		UI.pop(lf, 0.3)
	nomes.add_child(hf)
	topo.add_child(nomes)
	var selo := UI.SeloNota.new(Dados.nota(c.attrs), 58)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(selo)
	if not _delta.is_empty() and Dados.nota(c.attrs) != Dados.nota(anterior_attrs):
		UI.pop(selo, 0.4)
	v.add_child(topo)

	var abas := UI.hbox(6)
	for i in 2:
		var idx := i
		var b := UI.botao(["Status", "Relações e itens"][i], func(): _trocar_aba(idx), 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = aba == i
		abas.add_child(b)
	v.add_child(abas)

	var corpo := UI.vbox(7)
	if aba == 0:
		_aba_status(corpo)
	else:
		_aba_relacoes(corpo)
	var rol := ScrollContainer.new()
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(corpo)
	v.add_child(rol)
	p.add_child(v)
	return p


func _trocar_aba(i: int) -> void:
	aba = i
	_reconstruir()


func _reconstruir() -> void:
	for filho in get_children():
		filho.queue_free()
	_atalhos.clear()
	_montar()


func _aba_status(v: VBoxContainer) -> void:
	var o := c.proximo_objetivo()
	var marca := c.forca_prevista(o) if not o.is_empty() else -1.0
	for k in SimCorrida.KEYS:
		v.add_child(_linha_barra(Dados.ATTR_NOME[k], c.attrs[k], c.limite, c.cor, k, marca))
	if marca > 0.0:
		v.add_child(UI.label("▏ Média das adversárias do próximo objetivo: %d" % roundi(marca), 12, UI.DESTAQUE, true))
	v.add_child(HSeparator.new())
	var cor_e := UI.OK if c.energia >= 60 else (UI.DESTAQUE if c.energia >= Carreira.BAL.limite_falha else UI.PERIGO)
	v.add_child(_linha_barra("Energia", c.energia, 100, cor_e, "energia"))
	var cor_h: Color = [UI.PERIGO, UI.DESTAQUE, UI.TEXTO, UI.OK, UI.OK][c.humor]
	var humor_txt := "Humor: %s" % Carreira.HUMOR_NOME[c.humor]
	if c.lesionada:
		humor_txt += " · Lesionada (treino rende metade)"
	v.add_child(UI.label(humor_txt, 15, UI.PERIGO if c.lesionada else cor_h, true))
	v.add_child(_chips_aptidao())

	v.add_child(HSeparator.new())
	var titulo_obj := "Objetivos"
	if c.caminho != "":
		titulo_obj += " · caminho \"%s\"" % c.campanha.caminhos[c.caminho].nome
	v.add_child(UI.label(titulo_obj, 15, UI.SUAVE))
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
		var txt := "%s Turno %d · %s · %s %s" % [m, ob.turno, ob.texto, Dados.DIST_NOME[ob.dist], ob.piso]
		v.add_child(UI.label(txt, 13, cor, true))
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
	v.add_child(UI.label(" · ".join(partes), 13, UI.PERIGO, true))
	var dicas := []
	if c.magnitude > 0:
		dicas.append(Endgame.resumo_magnitude(c.magnitude))
	if c.desafio > 0:
		dicas.append(Endgame.regra(c.regra).get("descricao", ""))
	for id in c.maldicoes:
		dicas.append("%s: %s" % [Dados.amuleto(id).nome, Dados.amuleto(id).descricao])
	for d in dicas:
		if d != "":
			v.add_child(UI.label(d, 12, UI.SUAVE, true))


func _aba_relacoes(v: VBoxContainer) -> void:
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 10)
	for colega in c.afinidade:
		var h := UI.hbox(5)
		var l := UI.label(colega.split(" ")[0], 13)
		l.custom_minimum_size.x = 62
		h.add_child(l)
		var af: int = c.afinidade[colega]
		var cor := UI.PERIGO if af < 0 else (UI.OK if af >= Carreira.BAL.afinidade_dupla else Color("#b07cc6"))
		h.add_child(UI.barra(maxi(af, 0), 100, cor, 70))
		h.add_child(UI.label(str(af), 13, UI.SUAVE))
		grade.add_child(h)
	v.add_child(UI.label("Afinidade (%d+ treina em dupla)" % Carreira.BAL.afinidade_dupla, 14, UI.SUAVE))
	v.add_child(grade)

	v.add_child(HSeparator.new())
	v.add_child(UI.label("Amuletos (%d/%d)" % [c.amuletos.size(), c.limite_amuletos()], 14, UI.SUAVE))
	if c.amuletos.is_empty():
		v.add_child(UI.label("Nenhum ainda. Objetivos cumpridos e o top 3 num Desafio dão amuletos.", 13, UI.SUAVE, true))
	for id in c.amuletos:
		var a := Dados.amuleto(id)
		v.add_child(UI.label("%s: %s" % [a.nome, a.descricao], 13, UI.DESTAQUE if a.tipo == "raro" else UI.TEXTO, true))

	v.add_child(HSeparator.new())
	v.add_child(UI.label("Habilidades (%d/%d)" % [c.habilidades.size(), Dados.habilidades.limite], 14, UI.SUAVE))
	if c.unica != "":
		v.add_child(UI.label("%s ★ (única)" % SimCorrida.UNICAS[c.unica].nome, 13, UI.DESTAQUE, true))
	for id in c.habilidades:
		var hb := Dados.habilidade(id)
		v.add_child(UI.label("%s: %s" % [hb.nome, hb.descricao], 13, UI.TEXTO, true))
	if not c.titulos.is_empty():
		v.add_child(HSeparator.new())
		v.add_child(UI.label("Títulos: %s" % ", ".join(c.titulos.map(func(t): return t.nome)), 13, UI.DESTAQUE, true))
	if not c.madrinha.is_empty():
		v.add_child(UI.label("Madrinha: %s (inspira nos turnos 25 e 49)" % c.madrinha.get("nome", "?"), 13, UI.SUAVE, true))


# ---------- painel do turno ----------

func _painel_turno() -> VBoxContainer:
	var v := UI.vbox(10)
	var topo := UI.painel()
	var tv := UI.vbox(4)
	var cab := UI.hbox(12)
	var data := UI.label(Calendario.data_texto(c.turno), 24, UI.DESTAQUE)
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(data)
	cab.add_child(UI.label("Turno %d de %d" % [c.turno, Carreira.BAL.turnos], 15, UI.SUAVE))
	var b_menu := UI.botao("Academia (Esc)", func(): ir_academia.emit(), 13)
	b_menu.tooltip_text = "Volta à academia. A carreira fica salva e continua de onde parou."
	cab.add_child(b_menu)
	_atalhos[KEY_ESCAPE] = func(): ir_academia.emit()
	tv.add_child(cab)
	tv.add_child(_trilha())
	var cl: Dictionary = Dados.calendario.climas[c.clima()]
	tv.add_child(UI.label("%s %s%s" % [cl.icone, cl.nome, ": " + cl.descricao if cl.has("descricao") else ""], 14, UI.TEXTO, true))
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
		var quando := "neste turno" if faltam == 0 else "em %d turno%s" % [faltam, "s" if faltam > 1 else ""]
		tv.add_child(UI.label("Próximo objetivo (%s): %s · %s %s · %s" % [quando, o.texto, Dados.DIST_NOME[o.dist],
			o.piso, o.nome], 14, UI.DESTAQUE, true))
	topo.add_child(tv)
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(Color("#2a3150"), 10)
		var reacao := c.ultima_reacao
		if reacao.has("quem"):
			# quem falou no encontro reage à escolha (expressão da ficha + gesto)
			var hm := UI.hbox(12)
			var ret := RetratoGarota.new(reacao.quem, 72, reacao.get("expressao", "normal"))
			hm.add_child(ret)
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
		v.add_child(UI.label("Correr (gasta %d de energia, sem treino neste turno)" % c.energia_corrida(), 16, UI.SUAVE))
		var hc := UI.hbox(8)
		for i in corridas.size():
			var bc := _cartao_corrida(corridas[i])
			if i < 3:
				var tecla: String = ["Q", "W", "R"][i]
				bc.text = "[%s]\n%s" % [tecla, bc.text]
				bc.custom_minimum_size.y += 20
				_atalho([KEY_Q, KEY_W, KEY_R][i], bc)
			hc.add_child(bc)
		v.add_child(hc)

	v.add_child(UI.label("Treinar  (teclas 1 a 5)", 16, UI.SUAVE))
	var grade := GridContainer.new()
	grade.columns = 5
	grade.add_theme_constant_override("h_separation", 6)
	var lista_treinos: Array = Carreira.TREINOS.keys()
	for i in lista_treinos.size():
		var b := _botao_treino(lista_treinos[i])
		b.text = UI.com_tecla(str(i + 1), b.text)
		_atalho(KEY_1 + i, b)
		grade.add_child(b)
	v.add_child(grade)

	v.add_child(UI.label("Outras ações", 16, UI.SUAVE))
	var h := UI.hbox(8)
	var b_desc := _botao_acao(UI.com_tecla("D", "Descansar\n+%d energia" % c.descanso_previsto()), c.descansar)
	_atalho(KEY_D, b_desc)
	h.add_child(b_desc)
	var sair_txt := "Sair\n+humor, +%d energia" % Carreira.BAL.sair_energia
	if c.tipo_no() == "festival" or c.em_ferias():
		sair_txt += "\nencontro garantido"
	var b_sair := _botao_acao(UI.com_tecla("S", sair_txt), c.sair)
	_atalho(KEY_S, b_sair)
	h.add_child(b_sair)
	if c.lesionada:
		var b_enf := _botao_acao(UI.com_tecla("E", "Enfermaria\ncura a lesão"), c.enfermaria)
		_atalho(KEY_E, b_enf)
		h.add_child(b_enf)
	var b_loja := _botao_acao(UI.com_tecla("H", "Habilidades\n%d pontos\n%s" % [c.pontos, "fechar ▴" if loja_aberta else "abrir ▾"]), Callable())
	b_loja.pressed.connect(_alternar_loja)
	_atalho(KEY_H, b_loja)
	if _alguma_compravel():
		b_loja.add_theme_color_override("font_color", UI.DESTAQUE)
	h.add_child(b_loja)
	v.add_child(h)
	if loja_aberta:
		v.add_child(_loja_habilidades())


## Entrada do pátio: o evento do turno e se ainda dá para conversar (não gasta o turno).
func _faixa_patio() -> Control:
	var ev := c.evento_patio()
	var info: Dictionary = Dados.patio.eventos.get(ev.id, {})
	var p := UI.painel(Color("#26382c"), 10)
	var h := UI.hbox(10)
	if ev.outra != "":
		h.add_child(RetratoGarota.new(ev.outra, 44, "feliz" if ev.id == "aniversario" else "normal"))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label("Pátio · %s" % info.get("titulo", ""), 15, UI.DESTAQUE))
	var extra := " Conversa disponível." if c.pode_conversar_no_patio() else " Já conversaram neste turno."
	tv.add_child(UI.label(c.texto_patio(info.get("banner", ""), ev.outra) + extra, 13, UI.TEXTO, true))
	h.add_child(tv)
	var b := UI.botao("[P] Ir ao pátio", func(): ir_patio.emit(), 16)
	_atalho(KEY_P, b)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	p.add_child(h)
	return p


## Loja de habilidades genéricas: comprar não gasta o turno (GDD §3.4).
func _loja_habilidades() -> Control:
	var p := UI.painel(Color("#1d2b3a"), 10)
	var v := UI.vbox(6)
	var desconto := " · Biblioteca: −30% no preço" if c.tipo_no() == "biblioteca" else ""
	v.add_child(UI.label("Habilidades · %d pontos · %d/%d equipadas%s (comprar não gasta o turno)" % [
		c.pontos, c.habilidades.size(), Dados.habilidades.limite, desconto], 15, UI.SUAVE, true))
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
		grade.add_child(b)
	v.add_child(grade)
	p.add_child(v)
	return p


## Escolha de amuleto (1 entre 3 ou 4). Com 6 equipados, pede qual sai.
func _painel_amuleto() -> Control:
	var p := UI.painel(Color("#3a2f55"), 18)
	var v := UI.vbox(10)
	if amuleto_escolhido == "":
		v.add_child(UI.label("Escolha um amuleto", 22, UI.DESTAQUE))
		v.add_child(UI.label("Ele vale até o fim da carreira, mas não passa para a versão salva. Máximo de %d." % c.limite_amuletos(), 14, UI.SUAVE, true))
		for n_of in c.oferta_amuleto.size():
			var id: String = c.oferta_amuleto[n_of]
			var a := Dados.amuleto(id)
			var tipo: String = {"simples": "Simples", "troca": "Troca", "estilo": "Estilo", "raro": "Raro"}[a.tipo]
			var b := UI.botao("[%d] %s  (%s)\n%s" % [n_of + 1, a.nome, tipo, a.descricao], func(): _escolher_amuleto(id), 16)
			b.custom_minimum_size.y = 62
			_atalho(KEY_1 + n_of, b)
			UI.colorir_botao(b, {"simples": Color("#7d8499"), "troca": Color("#b48cff"), "estilo": Color("#4fa3ff"), "raro": UI.DESTAQUE}[a.tipo])
			if a.tipo == "raro":
				b.add_theme_color_override("font_color", UI.DESTAQUE)
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
	p.add_child(v)
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
	var p := UI.painel(Color("#1d2b3a"), 16)
	var v := UI.vbox(8)
	var cat: Dictionary = Dados.calendario.categorias[cr.cat]
	v.add_child(UI.label("%s: %s" % ["Objetivo" if e_objetivo else "Corrida", cr.nome], 22, UI.DESTAQUE))
	v.add_child(UI.label("%s · %s %s · %d m" % [cat.nome, Dados.DIST_NOME[cr.dist], cr.piso, Calendario.metros(cr)], 15, UI.SUAVE))
	if e_objetivo:
		v.add_child(UI.label("Meta: %s" % cr.texto, 15, UI.TEXTO, true))
	var rel := UI.painel(Color("#26364a"), 12)
	var rv := UI.vbox(4)
	rv.add_child(UI.label("Relatório do olheiro", 16, UI.SUAVE))
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
		var txt := "[%d] %s%s\n%s\nvitória ~%d%%" % [n_ins + 1, SimCorrida.INSTRUCAO_NOME[ins], " ★" if ins == ol.sugestao else "",
			desc[ins], roundi(ol.chances[ins] * 100)]
		var b := UI.botao(txt, func(): _largar(ins), 15)
		_atalho(KEY_1 + n_ins, b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 96
		if ins == ol.sugestao:
			b.add_theme_color_override("font_color", UI.DESTAQUE)
		h.add_child(b)
	v.add_child(h)
	if not e_objetivo:
		v.add_child(UI.botao_confirmar("Desistir desta corrida e voltar às ações", func(): atualizou.emit(c.cancelar_corrida()), 14))
	p.add_child(v)
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
	var p := UI.painel(Color("#1d2b3a"), 14)
	var v := UI.vbox(8)
	v.add_child(UI.label("Trecho %d · escolha a rota dos próximos 2 turnos" % (t + 1), 20, UI.DESTAQUE))
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
				b.text = "[%d] %s" % [col + 1, b.text]
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
					var cor := UI.DESTAQUE if no_caminho else (Color("#6d7a9c") if abre else Color("#2b3247"))
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
	p.add_child(v)
	return p


func _painel_ferias() -> Control:
	var p := UI.painel(Color("#2b3a2a"), 18)
	var v := UI.vbox(10)
	v.add_child(UI.label("Férias de verão: escolha o acampamento", 22, UI.DESTAQUE))
	v.add_child(UI.label("Durante as férias não há corridas, Sair sempre gera encontro e o descanso rende +50%.", 15, UI.TEXTO, true))
	var b1 := _botao_grande("[1] Serra: Estamina e Determinação contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("serra")))
	var b2 := _botao_grande("[2] Praia: Velocidade e Poder contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("praia")))
	_atalho(KEY_1, b1)
	_atalho(KEY_2, b2)
	v.add_child(b1)
	v.add_child(b2)
	p.add_child(v)
	return p


## Encontro, Mistério ou véspera: diálogo curto com 1 a 3 escolhas (GDD §4.7).
func _painel_encontro(e: Dictionary) -> Control:
	var tipo: String = c.encontro_pendente.get("tipo", "encontro")
	var p := UI.painel(Color("#2b2440") if tipo != "misterio" else Color("#3a2a20"), 18)
	var v := UI.vbox(10)
	var topo := UI.hbox(12)
	var quem := c.quem_do_encontro()
	var ret := RetratoGarota.new(quem, 96, e.get("expressao", "normal"))
	topo.add_child(ret)
	ret.call_deferred("gesto", e.get("gesto", ""))
	var tv := UI.vbox(2)
	tv.add_child(UI.label({"encontro": "Encontro", "misterio": "Mistério", "vespera": "Véspera",
		"capitulo": "História"}.get(tipo, "Encontro"), 14, UI.SUAVE))
	tv.add_child(UI.label(c.texto(e.titulo), 22, UI.DESTAQUE))
	topo.add_child(tv)
	v.add_child(topo)
	v.add_child(UI.label(c.texto(e.texto), 17, UI.TEXTO, true))
	for i in e.escolhas.size():
		var idx: int = i
		var b := UI.botao(UI.com_tecla(str(i + 1), c.texto(e.escolhas[i].texto)), func(): atualizou.emit(c.escolher(idx)), 17)
		b.custom_minimum_size.y = 48
		_atalho(KEY_1 + i, b)
		v.add_child(b)
	p.add_child(v)
	return p


func _botao_treino(t: String) -> Button:
	var g := c.ganho_previsto(t)
	var nv := c.nivel_efetivo(t)
	var nv_txt := "Nv %d" % nv
	if nv > c.nivel_treino(t):
		nv_txt += "↑"
	var linhas := ["%s %s%s" % [Dados.ATTR_CURTO[t], nv_txt, " ★" if t in c.naturais else ""]]
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
	b.custom_minimum_size.y = 128
	UI.colorir_botao(b, UI.ATTR_COR[t])
	# ícone do atributo no canto do cartão de treino
	var ic := UI.Icone.new(t, 22)
	ic.position = Vector2(6, 6)
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
	var p := UI.painel(Color("#1f4a35") if ok else Color("#4a1f24"), 14)
	var h := UI.hbox(14)
	var l := UI.label("✓ OBJETIVO CUMPRIDO!" if ok else "✗ OBJETIVO NÃO CUMPRIDO", 26, UI.DESTAQUE if ok else UI.PERIGO)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	h.add_child(l)
	var sub := UI.label("%s · %dº lugar · +%d de fama" % [r.nome, r.posicao, r.fama], 16, UI.TEXTO, true)
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
	t.custom_minimum_size = Vector2(0, 34)
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
		draw_line(Vector2(x0, y), Vector2(x1, y), Color("#2b3247"), 6.0, true)
		draw_line(Vector2(x0, y), Vector2(px.call(c.turno), y), c.cor, 6.0, true)
		var f := get_theme_default_font()
		for ano in 3:
			var xa: float = px.call(ano * total / 3.0 + 1.0)
			if ano > 0:
				draw_line(Vector2(xa, y - 10), Vector2(xa, y + 10), Color("#3d4867"), 2.0)
			draw_string(f, Vector2(xa + 4, y - 9), "Ano %d" % (ano + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.SUAVE)
		var prox := c.proximo_objetivo()
		for o in c.objetivos:
			var xo: float = px.call(o.turno)
			var res := c.resultados.filter(func(r): return r.turno == o.turno and r.objetivo > 0)
			var cor := Color("#5d6478")
			var raio := 6.0
			if not res.is_empty():
				cor = UI.OK if res[0].ok else UI.PERIGO
			elif not prox.is_empty() and o.turno == prox.turno:
				cor = UI.DESTAQUE
				raio = 7.0 + sin(_t * 4.0) * 1.5
			draw_circle(Vector2(xo, y), raio + 2.0, Color("#141824"))
			draw_circle(Vector2(xo, y), raio, cor)
		# a garota: um disco da cor dela que pulsa
		var xg: float = px.call(c.turno)
		var pulso := 1.0 + sin(_t * 5.0) * 0.12
		draw_circle(Vector2(xg, y), 9.0 * pulso, Color.WHITE)
		draw_circle(Vector2(xg, y), 6.5 * pulso, c.cor)
