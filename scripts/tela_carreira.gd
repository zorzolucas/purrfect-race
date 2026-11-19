class_name TelaCarreira
extends Control
## Tela de turno da carreira: atributos, energia, humor, fama e objetivos à esquerda;
## data, clima, rota e a decisão do turno à direita (ações, mapa, férias, encontro ou corrida).

signal ir_correr
signal atualizou(msg: String)

var c: Carreira
var msg: String
## Amuleto escolhido quando os 6 espaços já estão cheios (falta dizer qual sai).
var amuleto_escolhido := ""


func _init(carreira: Carreira, mensagem: String) -> void:
	c = carreira
	msg = mensagem


func _ready() -> void:
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

func _linha_barra(rotulo: String, valor: float, maximo: float, cor: Color) -> Control:
	var h := UI.hbox(8)
	var l := UI.label(rotulo, 14)
	l.custom_minimum_size.x = 104
	h.add_child(l)
	h.add_child(UI.barra(valor, maximo, cor, 190))
	h.add_child(UI.label("%d" % valor, 14))
	return h


func _painel_garota() -> Control:
	var p := UI.painel()
	p.custom_minimum_size.x = 410
	var v := UI.vbox(7)
	var topo := UI.hbox(12)
	topo.add_child(UI.retrato(c.nome, c.cor, 64))
	var nomes := UI.vbox(2)
	nomes.add_child(UI.label(c.nome, 22))
	nomes.add_child(UI.label("%s · Nota %s · Fama %d" % [Dados.ESTILO_NOME[c.estilo], Dados.nota(c.attrs), c.fama], 15, UI.DESTAQUE))
	topo.add_child(nomes)
	v.add_child(topo)
	for k in SimCorrida.KEYS:
		v.add_child(_linha_barra(Dados.ATTR_NOME[k], c.attrs[k], c.limite, c.cor))
	v.add_child(HSeparator.new())
	var cor_e := UI.OK if c.energia >= 60 else (UI.DESTAQUE if c.energia >= Carreira.BAL.limite_falha else UI.PERIGO)
	v.add_child(_linha_barra("Energia", c.energia, 100, cor_e))
	var cor_h: Color = [UI.PERIGO, UI.DESTAQUE, UI.TEXTO, UI.OK, UI.OK][c.humor]
	var humor_txt := "Humor: %s" % Carreira.HUMOR_NOME[c.humor]
	if c.lesionada:
		humor_txt += " · Lesionada (treino rende metade)"
	v.add_child(UI.label(humor_txt, 15, UI.PERIGO if c.lesionada else cor_h, true))
	var apt := []
	for d in ["sprint", "milha", "media", "longa", "grama", "terra"]:
		apt.append("%s %s" % [d.capitalize().substr(0, 3), Dados.APT_NOME[c.aptidao[d]]])
	v.add_child(UI.label(" · ".join(apt), 12, UI.SUAVE, true))

	v.add_child(HSeparator.new())
	var titulo_obj := "Objetivos"
	if c.caminho != "":
		titulo_obj += " · caminho \"%s\"" % c.campanha.caminhos[c.caminho].nome
	v.add_child(UI.label(titulo_obj, 15, UI.SUAVE))
	for o in c.objetivos:
		var res := c.resultados.filter(func(r): return r.turno == o.turno and r.objetivo > 0)
		var marca := "○"
		var cor := UI.TEXTO
		if not res.is_empty():
			marca = "✓" if res[0].ok else "✗"
			cor = UI.OK if res[0].ok else UI.PERIGO
		elif o.turno == c.turno:
			marca = "►"
			cor = UI.DESTAQUE
		var txt := "%s Turno %d · %s · %s %s" % [marca, o.turno, o.texto, Dados.DIST_NOME[o.dist], o.piso]
		v.add_child(UI.label(txt, 13, cor, true))

	v.add_child(HSeparator.new())
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 10)
	for colega in c.afinidade:
		var h := UI.hbox(5)
		var l := UI.label(colega.split(" ")[0], 12)
		l.custom_minimum_size.x = 58
		h.add_child(l)
		var af: int = c.afinidade[colega]
		var cor := UI.PERIGO if af < 0 else (UI.OK if af >= Carreira.BAL.afinidade_dupla else Color("#b07cc6"))
		h.add_child(UI.barra(maxi(af, 0), 100, cor, 70))
		h.add_child(UI.label(str(af), 12, UI.SUAVE))
		grade.add_child(h)
	v.add_child(UI.label("Afinidade (%d+ treina em dupla)" % Carreira.BAL.afinidade_dupla, 13, UI.SUAVE))
	v.add_child(grade)

	v.add_child(HSeparator.new())
	var amu: Array = c.amuletos.map(func(id): return Dados.amuleto(id).nome)
	var l_amu := UI.label("Amuletos (%d/%d): %s" % [c.amuletos.size(), c.limite_amuletos(),
		", ".join(amu) if not amu.is_empty() else "nenhum ainda"], 13, UI.TEXTO, true)
	l_amu.tooltip_text = "\n".join(c.amuletos.map(func(id): return "%s: %s" % [Dados.amuleto(id).nome, Dados.amuleto(id).descricao]))
	l_amu.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(l_amu)
	if not c.titulos.is_empty():
		v.add_child(UI.label("Títulos: %s" % ", ".join(c.titulos.map(func(t): return t.nome)), 13, UI.DESTAQUE, true))
	if c.magnitude > 0 or c.desafio > 0 or not c.maldicoes.is_empty():
		var partes := []
		if c.desafio > 0:
			partes.append("Desafio da semana #%d · regra: %s" % [c.desafio, Endgame.regra(c.regra).get("nome", c.regra)])
		if c.magnitude > 0:
			partes.append("Magnitude %d" % c.magnitude)
		if not c.maldicoes.is_empty():
			partes.append("Maldições: %s" % ", ".join(c.maldicoes.map(func(id): return Dados.amuleto(id).nome)))
		var l_end := UI.label(" · ".join(partes), 13, UI.PERIGO, true)
		var dicas := []
		if c.magnitude > 0:
			dicas.append(Endgame.resumo_magnitude(c.magnitude))
		if c.desafio > 0:
			dicas.append(Endgame.regra(c.regra).get("descricao", ""))
		for id in c.maldicoes:
			dicas.append("%s: %s" % [Dados.amuleto(id).nome, Dados.amuleto(id).descricao])
		l_end.tooltip_text = "\n".join(dicas)
		l_end.mouse_filter = Control.MOUSE_FILTER_PASS
		v.add_child(l_end)
	if not c.madrinha.is_empty():
		v.add_child(UI.label("Madrinha: %s (inspira nos turnos 25 e 49)" % c.madrinha.get("nome", "?"), 13, UI.SUAVE, true))
	var hab: Array = c.habilidades.map(func(id): return Dados.habilidade(id).nome)
	if c.unica != "":
		hab.push_front(SimCorrida.UNICAS[c.unica].nome + " ★")
	v.add_child(UI.label("Habilidades: %s" % ", ".join(hab), 13, UI.TEXTO, true))
	p.add_child(v)
	return p


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
	tv.add_child(cab)
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
		pm.add_child(UI.label(msg, 15, UI.TEXTO, true))
		v.add_child(pm)

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
	var corridas := c.corridas_opcionais()
	if not corridas.is_empty():
		v.add_child(UI.label("Correr (gasta %d de energia, sem treino neste turno)" % c.energia_corrida(), 16, UI.SUAVE))
		var hc := UI.hbox(8)
		for cr in corridas:
			hc.add_child(_cartao_corrida(cr))
		v.add_child(hc)

	v.add_child(UI.label("Treinar", 16, UI.SUAVE))
	var grade := GridContainer.new()
	grade.columns = 5
	grade.add_theme_constant_override("h_separation", 6)
	for t in Carreira.TREINOS:
		grade.add_child(_botao_treino(t))
	v.add_child(grade)

	v.add_child(UI.label("Outras ações", 16, UI.SUAVE))
	var h := UI.hbox(8)
	h.add_child(_botao_acao("Descansar\n+%d energia" % c.descanso_previsto(), c.descansar))
	var sair_txt := "Sair\n+humor, +%d energia" % Carreira.BAL.sair_energia
	if c.tipo_no() == "festival" or c.em_ferias():
		sair_txt += "\nencontro garantido"
	h.add_child(_botao_acao(sair_txt, c.sair))
	if c.lesionada:
		h.add_child(_botao_acao("Enfermaria\ncura a lesão", c.enfermaria))
	v.add_child(h)
	v.add_child(_loja_habilidades())


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
		for id in c.oferta_amuleto:
			var a := Dados.amuleto(id)
			var tipo: String = {"simples": "Simples", "troca": "Troca", "estilo": "Estilo", "raro": "Raro"}[a.tipo]
			var b := UI.botao("%s  (%s)\n%s" % [a.nome, tipo, a.descricao], func(): _escolher_amuleto(id), 16)
			b.custom_minimum_size.y = 62
			if a.tipo == "raro":
				b.add_theme_color_override("font_color", UI.DESTAQUE)
			v.add_child(b)
		v.add_child(UI.botao("Não quero nenhum", func(): atualizou.emit(c.descartar_oferta()), 14))
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
	for filho in get_children():
		filho.queue_free()
	_ready()


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
	var etq := UI.label("%s · chance de vencer ~%d%% · fama ×%s" % [Carreira.nome_etiqueta(ol.etiqueta),
		roundi(ol.chance * 100), _mult_txt(ol.mult)], 20, _cor_etiqueta(ol.etiqueta))
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
	for ins in ["poupar", "normal", "forcar"]:
		var txt := "%s%s\n%s\nchance ~%d%%" % [SimCorrida.INSTRUCAO_NOME[ins], " ★" if ins == ol.sugestao else "",
			desc[ins], roundi(ol.chances[ins] * 100)]
		var b := UI.botao(txt, func(): _largar(ins), 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 96
		if ins == ol.sugestao:
			b.add_theme_color_override("font_color", UI.DESTAQUE)
		h.add_child(b)
	v.add_child(h)
	if not e_objetivo:
		v.add_child(UI.botao("Desistir desta corrida e voltar às ações", func(): atualizou.emit(c.cancelar_corrida()), 14))
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
	for i in mapa.size():
		var turno_linha: int = turno0 + i * 2
		var h := UI.hbox(8)
		var cl: Dictionary = Dados.calendario.climas[c.clima_em(turno_linha)]
		var mes := UI.label("%s %s" % [Dados.calendario.meses[Calendario.mes_idx(turno_linha) % 12].substr(0, 3), cl.icone], 15)
		mes.custom_minimum_size.x = 64
		mes.tooltip_text = cl.nome
		h.add_child(mes)
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
			if escolhida:
				b.text = "● " + b.text
				b.add_theme_color_override("font_disabled_color", UI.DESTAQUE)
			h.add_child(b)
		v.add_child(h)
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
	v.add_child(_botao_grande("Serra: Estamina e Determinação contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("serra"))))
	v.add_child(_botao_grande("Praia: Velocidade e Poder contam 1 nível acima", func(): atualizou.emit(c.escolher_acampamento("praia"))))
	p.add_child(v)
	return p


## Encontro, Mistério ou véspera: diálogo curto com 1 a 3 escolhas (GDD §4.7).
func _painel_encontro(e: Dictionary) -> Control:
	var tipo: String = c.encontro_pendente.get("tipo", "encontro")
	var p := UI.painel(Color("#2b2440") if tipo != "misterio" else Color("#3a2a20"), 18)
	var v := UI.vbox(10)
	var topo := UI.hbox(12)
	var quem: String = c.nome
	if tipo == "encontro" and e.get("garota") == null:
		quem = c.encontro_pendente.get("outra", c.nome)
	elif tipo == "vespera":
		quem = c.encontro_pendente.get("rival", c.nome)
	var ini := Dados.config_carreira(quem)
	topo.add_child(UI.retrato(quem, Color(ini.get("cor", "#b07cc6")), 60))
	var tv := UI.vbox(2)
	tv.add_child(UI.label({"encontro": "Encontro", "misterio": "Mistério", "vespera": "Véspera",
		"capitulo": "História"}.get(tipo, "Encontro"), 14, UI.SUAVE))
	tv.add_child(UI.label(c.texto(e.titulo), 22, UI.DESTAQUE))
	topo.add_child(tv)
	v.add_child(topo)
	v.add_child(UI.label(c.texto(e.texto), 17, UI.TEXTO, true))
	for i in e.escolhas.size():
		var idx: int = i
		var b := UI.botao(c.texto(e.escolhas[i].texto), func(): atualizou.emit(c.escolher(idx)), 17)
		b.custom_minimum_size.y = 48
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
	linhas.append("Falha %d%%" % round(falha * 100))
	var b := _botao_acao("\n".join(linhas), func(): return c.treinar(t))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = Dados.ATTR_NOME[t]
	if falha > 0.0:
		b.add_theme_color_override("font_color", UI.PERIGO if falha >= 0.25 else UI.DESTAQUE)
	return b


func _botao_acao(texto: String, acao: Callable) -> Button:
	var b := UI.botao(texto, func(): atualizou.emit(acao.call()), 14)
	b.custom_minimum_size = Vector2(130, 112)
	return b
