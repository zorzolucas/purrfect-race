class_name TelaCircuito
extends Control
## Circuito em níveis (GDD §7 e docs/campanhas.md §2.3): 5 copas e o Campeonato Final em
## Bronze, Prata e Ouro. O jogador escala garotas salvas diferentes (3 por copa, 5 no Final)
## e vence somando mais pontos que as 3 casas rivais. Clima e traçado de cada corrida mudam
## a cada rotação da pool, então a melhor escalação muda de semana para semana.

signal voltar

## Cor de cada nível (Bronze, Prata, Ouro).
const COR_NIVEL := [Color("#d08a4e"), Color("#8fa6bf"), Color("#f5b301")]

var perfil: Perfil
var nivel := 0
var evento_id := ""          # evento sendo escalado ("" = lista de eventos)
var escalacao: Array = []    # [{nome, instrucao}] por corrida
var resultado := {}


func _init(p: Perfil) -> void:
	perfil = p
	# abre no maior nível com algo aberto e ainda não vencido
	for n in Endgame.niveis().size():
		for ev in Endgame.eventos():
			if perfil.evento_aberto(n, ev.id) and not perfil.venceu_evento(n, ev.id):
				nivel = n
				return


func _ready() -> void:
	_montar()


func _montar() -> void:
	for c in get_children():
		c.queue_free()
	var em_pe := UI.em_pe()
	var v := UI.vbox(12)
	var topo := UI.hbox(12)
	topo.add_child(UI.faixa("Circuito · rotação %d" % (perfil.giro + 1), UI.LARANJA, 22 if em_pe else 30))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	topo.add_child(UI.moedas(perfil.moeda))
	var bts: BoxContainer = topo
	if em_pe:
		v.add_child(topo)
		bts = UI.hbox(8)
	if evento_id != "":
		bts.add_child(UI.botao("Voltar às copas", func(): _abrir(""), 16 if em_pe else 18))
	bts.add_child(UI.botao("Voltar à academia", func(): voltar.emit(), 16 if em_pe else 18))
	if em_pe:
		for b in bts.get_children():
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 44
	v.add_child(bts)
	if not resultado.is_empty():
		v.add_child(_painel_resultado())
	elif evento_id != "":
		v.add_child(_painel_escalacao())
	else:
		v.add_child(_painel_eventos())
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mg := MarginContainer.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 6)
	mg.add_child(v)
	add_child(UI.margem(UI.rolavel(mg), 4 if em_pe else 18))


func _abrir(id: String) -> void:
	evento_id = id
	resultado = {}
	escalacao = sugerir(perfil, nivel, id) if id != "" else []
	_montar()


# ---------- lista de copas ----------

func _painel_eventos() -> Control:
	var v := UI.vbox(10)
	v.add_child(UI.label("Cada copa tem 3 corridas e pede 3 garotas salvas diferentes; o Campeonato Final tem 5 e pede 5. Pontos por colocação: %s. Vence quem somar mais que cada uma das 3 casas rivais (%s). O clima e o traçado de cada corrida mudam a cada rotação da pool, e cada evento aceita %d tentativas por rotação: se a semana não favorece o seu elenco, a próxima pode favorecer." % [
		", ".join(Dados.endgame.circuito.pontos.map(func(x): return str(int(x)))), ", ".join(Dados.endgame.circuito.casas),
		int(Dados.endgame.circuito.tentativas_por_rotacao)], 14, UI.SUAVE, true))
	var abas: Container = UI.fluxo(6) if UI.em_pe() else UI.hbox(8)
	for n in Endgame.niveis().size():
		var nv: Dictionary = Endgame.niveis()[n]
		var b := UI.botao("%s · força %d" % [nv.nome, int(nv.forca)], func(): _trocar_nivel(n), 18)
		if n == nivel:
			UI.colorir_botao(b, COR_NIVEL[n % COR_NIVEL.size()])
			b.custom_minimum_size.y = 50
		abas.add_child(b)
	v.add_child(abas)
	var aptas := perfil.aptas_circuito()
	if aptas.size() < 3:
		v.add_child(UI.label("Você tem %d garota(s) com versão salva. Para correr uma copa, salve pelo menos 3 no fim das carreiras." % aptas.size(), 16, UI.PERIGO, true))
	var grade := GridContainer.new()
	grade.columns = 1 if UI.em_pe() else 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for ev in Endgame.eventos():
		grade.add_child(_cartao_evento(ev, aptas.size()))
	v.add_child(grade)
	return v


func _trocar_nivel(n: int) -> void:
	nivel = n
	_montar()


func _cartao_evento(ev: Dictionary, n_aptas: int) -> Control:
	var reg := perfil.registro_circuito(nivel, ev.id)
	var cor_n: Color = COR_NIVEL[nivel % COR_NIVEL.size()]
	var p := UI.painel_titulo("%s %s" % [ev.nome, Endgame.niveis()[nivel].nome], UI.ROSA if ev.id == "final" else cor_n)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 0 if UI.em_pe() else 520
	var v: VBoxContainer = p.get_meta("corpo")
	v.add_theme_constant_override("separation", 5)
	if reg.vitorias > 0:
		# o PanelContainer encaixa os filhos: a cápsula fica numa camada solta por cima
		var camada := Control.new()
		camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(camada)
		var cv := UI.capsula("✓ vencida %d×" % reg.vitorias, UI.VERDE, 13)
		camada.add_child(cv)
		cv.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		cv.position += Vector2(-12, 8)
		cv.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var conds := Endgame.condicoes(perfil.giro, ev.id)
	for i in ev.corridas.size():
		v.add_child(_linha_corrida(ev.corridas[i], conds[i]))
	var aberto := perfil.evento_aberto(nivel, ev.id)
	var precisa: int = ev.corridas.size()
	var linha := UI.hbox(8)
	var info: String
	if not aberto:
		if ev.id == "final":
			info = "Fechado: vença as 5 copas %s%s." % [Endgame.niveis()[nivel].nome,
				" e o Final %s" % Endgame.niveis()[nivel - 1].nome if nivel > 0 else ""]
		else:
			info = "Fechado: vença esta copa no %s." % Endgame.niveis()[nivel - 1].nome
	else:
		var primeira: bool = reg.vitorias == 0
		var ja_pago: bool = not primeira and int(reg.giro_premio) == perfil.giro
		linha.add_child(UI.Moeda.new(22))
		info = "%d moedas%s" % [Endgame.premio(nivel, ev.id, primeira),
			" (1ª vitória)" if primeira else (" — já recebido nesta rotação" if ja_pago else " (repetição, 1 vez por rotação)")]
		if reg.melhor > 0:
			info += " · recorde %d pts" % reg.melhor
		info += " · %d de %d tentativas nesta rotação" % [perfil.tentativas_restantes(nivel, ev.id),
			int(Dados.endgame.circuito.tentativas_por_rotacao)]
	var l := UI.label(info, 13, UI.TEXTO if aberto else UI.SUAVE, true)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(l)
	var b := UI.botao("Escalar", func(): _abrir(ev.id), 16)
	b.disabled = not aberto or n_aptas < precisa or perfil.tentativas_restantes(nivel, ev.id) <= 0
	if not b.disabled:
		UI.colorir_botao(b, UI.VERDE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(b)
	v.add_child(linha)
	return p


## Uma corrida da copa em cápsulas: distância, piso e metros, e o clima e o traçado.
func _linha_corrida(corrida: Dictionary, cond: Dictionary) -> Control:
	var h := UI.hbox(5)
	var t := Endgame.tracado(cond.tracado)
	var cl: Dictionary = Dados.calendario.climas.get(cond.clima, {})
	h.add_child(UI.capsula(Dados.DIST_NOME[corrida.dist], UI.DIST_COR.get(corrida.dist, UI.CEU), 12))
	h.add_child(UI.capsula(str(corrida.piso).capitalize(), UI.PISO_COR.get(corrida.piso, UI.VERDE), 12))
	var l := UI.label("%d m · %s %s · %s" % [int(corrida.metros), cl.get("icone", ""), cl.get("nome", cond.clima), t.get("nome", "")], 13, UI.SUAVE, UI.em_pe())
	l.tooltip_text = t.get("descricao", "")
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(l)
	return h


# ---------- escalação ----------

## Escalação inicial: para cada corrida, a garota ainda livre com a maior força efetiva
## (média dos atributos × aptidão). É só um ponto de partida; o jogador troca à vontade.
static func sugerir(p: Perfil, _nivel: int, id: String) -> Array:
	var ev := Endgame.evento(id)
	var livres := p.aptas_circuito()
	var lista := []
	for corrida in ev.corridas:
		var melhor := ""
		var melhor_v := -1.0
		for n in livres:
			var f := forca_efetiva(p, n, corrida)
			if f > melhor_v:
				melhor_v = f
				melhor = n
		if melhor != "":
			livres.erase(melhor)
		lista.append({"nome": melhor, "instrucao": "normal"})
	return lista


static func forca_efetiva(p: Perfil, nome: String, corrida: Dictionary) -> float:
	var salva: Dictionary = p.elenco[nome].salva
	var apt: Dictionary = salva.get("aptidao", Dados.garota(nome).aptidao)
	var s := 0.0
	for k in SimCorrida.KEYS:
		s += float(salva.attrs[k])
	return s / 5.0 * Dados.APT[apt[corrida.dist]] * Dados.APT[apt[corrida.piso]]


func _painel_escalacao() -> Control:
	var ev := Endgame.evento(evento_id)
	var v := UI.vbox(10)
	var hc := UI.hbox(10)
	hc.add_child(UI.faixa("Escalação · %s %s" % [ev.nome, Endgame.niveis()[nivel].nome], COR_NIVEL[nivel % COR_NIVEL.size()], 17 if UI.em_pe() else 22))
	var cf := UI.capsula("NPCs com força média %d" % int(Endgame.niveis()[nivel].forca), UI.ROXO, 14)
	cf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hc.add_child(cf)
	v.add_child(hc)
	v.add_child(UI.label("Escolha uma garota diferente para cada corrida. A letra mostra a aptidão dela na distância e no piso; o traçado e o clima pesam diferente em cada estilo.", 14, UI.SUAVE, true))
	var conds := Endgame.condicoes(perfil.giro, evento_id)
	var aptas := perfil.aptas_circuito()
	aptas.sort_custom(func(a, b): return a < b)
	var usadas := escalacao.map(func(e): return e.nome)
	for i in ev.corridas.size():
		var corrida: Dictionary = ev.corridas[i]
		var p := UI.painel(UI.PAINEL, 12)
		var pv := UI.vbox(6)
		var t := Endgame.tracado(conds[i].tracado)
		var hl := UI.fila(6 if UI.em_pe() else 8)
		var cap_c := UI.capsula("Corrida %d" % (i + 1), UI.CEU, 14)
		cap_c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hl.add_child(cap_c)
		hl.add_child(_linha_corrida(corrida, conds[i]))
		pv.add_child(hl)
		if t.get("descricao", "") != "":
			pv.add_child(UI.label("%s: %s" % [t.nome, t.descricao], 13, UI.SUAVE, true))
		var linha := UI.hbox(8)
		var op := OptionButton.new()
		op.focus_mode = Control.FOCUS_NONE
		op.custom_minimum_size.x = 0 if UI.em_pe() else 420
		for j in aptas.size():
			var n: String = aptas[j]
			op.add_item(_rotulo_garota(n, corrida), j)
			if n == escalacao[i].nome:
				op.select(j)
		op.item_selected.connect(func(j): _escolher(i, aptas[j]))
		if UI.em_pe():
			# em pé: a garota numa linha, instrução e rosto na de baixo
			op.custom_minimum_size.y = 44
			op.clip_text = true
			pv.add_child(op)
		else:
			linha.add_child(op)
		var ins := OptionButton.new()
		ins.focus_mode = Control.FOCUS_NONE
		var chaves := ["normal", "poupar", "forcar"]
		for j in chaves.size():
			ins.add_item(SimCorrida.INSTRUCAO_NOME[chaves[j]], j)
			if chaves[j] == escalacao[i].instrucao:
				ins.select(j)
		ins.item_selected.connect(func(j): escalacao[i].instrucao = chaves[j])
		linha.add_child(ins)
		if usadas.count(escalacao[i].nome) > 1:
			linha.add_child(UI.capsula("repetida!", UI.PERIGO, 14))
		if escalacao[i].nome != "":
			linha.add_child(UI.medalhao(escalacao[i].nome, 40))
		pv.add_child(linha)
		p.add_child(pv)
		v.add_child(p)
	var valida: bool = usadas.size() == ev.corridas.size() and not usadas.has("") \
		and usadas.all(func(n): return usadas.count(n) == 1)
	var restantes := perfil.tentativas_restantes(nivel, evento_id)
	var b := UI.botao_principal("Correr %s (%d tentativa(s) nesta rotação)" % [ev.nome, restantes], _correr, 20)
	if UI.em_pe():
		UI.quebrar(b)
	b.disabled = not valida or restantes <= 0
	v.add_child(b)
	if not valida:
		v.add_child(UI.label("Cada corrida precisa de uma garota diferente.", 14, UI.PERIGO))
	return v


func _rotulo_garota(n: String, corrida: Dictionary) -> String:
	var salva: Dictionary = perfil.elenco[n].salva
	var apt: Dictionary = salva.get("aptidao", Dados.garota(n).aptidao)
	return "%s · %s · nota %s · %s/%s" % [n, Dados.ESTILO_NOME[Dados.garota(n).estilo], salva.nota,
		Dados.APT_NOME[apt[corrida.dist]], Dados.APT_NOME[apt[corrida.piso]]]


func _escolher(i: int, nome: String) -> void:
	escalacao[i].nome = nome
	_montar()


func _correr() -> void:
	resultado = perfil.correr_circuito(nivel, evento_id, escalacao)
	_montar()


# ---------- resultado ----------

func _painel_resultado() -> Control:
	var ev := Endgame.evento(evento_id)
	var casas: Array = Dados.endgame.circuito.casas
	var v := UI.vbox(10)
	var titulo := "Vitória na %s %s!" % [ev.nome, Endgame.niveis()[nivel].nome] if resultado.venceu else "%s %s: não foi desta vez" % [ev.nome, Endgame.niveis()[nivel].nome]
	var ft := UI.faixa(titulo, UI.VERDE if resultado.venceu else UI.PERIGO, 18 if UI.em_pe() else 26)
	v.add_child(ft)
	UI.pop(ft)
	for i in resultado.corridas.size():
		var r: Dictionary = resultado.corridas[i]
		var p := UI.painel(UI.PAINEL, 10)
		var ph := UI.hbox(12)
		ph.add_child(UI.medalhao(escalacao[i].nome, 56, "feliz" if r.posicao <= 3 else "normal"))
		var pv := UI.vbox(3)
		pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hl := UI.hbox(8)
		hl.add_child(UI.capsula("Corrida %d" % (i + 1), UI.CEU, 13))
		hl.add_child(_linha_corrida(r.corrida, r.condicao))
		pv.add_child(hl)
		var cor_pos: Color = {1: UI.OURO, 2: Color("#9fb3c8"), 3: Color("#d08a4e")}.get(r.posicao, UI.SUAVE)
		var hp := UI.hbox(8)
		var lp := UI.label_contorno("%dº" % r.posicao, 24, cor_pos, Color.WHITE, 6)
		hp.add_child(lp)
		var ln := UI.label("%s · %d pts" % [escalacao[i].nome, Endgame.pontos(r.posicao)], 17)
		ln.add_theme_font_override("font", UI.negrito())
		ln.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hp.add_child(ln)
		pv.add_child(hp)
		var partes := []
		for c in casas.size():
			var pos: int = r.posicoes_casas[c]
			partes.append("%s (%s): %dº" % [casas[c], resultado.escalacao_casas[i][c], pos])
		pv.add_child(UI.label(" · ".join(partes), 13, UI.SUAVE, true))
		var vencedora: String = r.nomes[r.ordem[0]]
		if r.ordem[0] != 0:
			pv.add_child(UI.label("Vencedora: %s" % vencedora, 13, UI.SUAVE))
		ph.add_child(pv)
		p.add_child(ph)
		v.add_child(p)
	var placar := UI.painel(Color("#fff3c4"), 12)
	var sbp: StyleBoxFlat = placar.get_theme_stylebox("panel").duplicate()
	sbp.border_color = UI.OURO
	sbp.set_border_width_all(3)
	placar.add_theme_stylebox_override("panel", sbp)
	var pl := UI.vbox(4)
	pl.add_child(UI.label_contorno("Você: %d pts" % resultado.total, 24, UI.DESTAQUE, Color.WHITE, 6))
	for c in casas.size():
		pl.add_child(UI.label("%s: %d pts" % [casas[c], resultado.casas[c]], 16))
	if resultado.premio > 0:
		var hm := UI.hbox(8)
		hm.add_child(UI.Moeda.new(26))
		hm.add_child(UI.label_contorno("+%d moedas%s" % [resultado.premio, " (1ª vitória)" if resultado.primeira else ""], 20, Color.WHITE, Color("#b07a00"), 6))
		pl.add_child(hm)
	elif resultado.venceu:
		pl.add_child(UI.label("O prêmio de repetição desta copa já foi recebido nesta rotação.", 15, UI.SUAVE, true))
	placar.add_child(pl)
	v.add_child(placar)
	var botoes := UI.hbox(12)
	var de_novo := UI.botao("Tentar de novo (%d restante(s))" % perfil.tentativas_restantes(nivel, evento_id), func():
		resultado = {}
		_montar(), 18)
	de_novo.disabled = perfil.tentativas_restantes(nivel, evento_id) <= 0
	botoes.add_child(de_novo)
	botoes.add_child(UI.botao_principal("Voltar às copas", func(): _abrir(""), 18))
	v.add_child(botoes)
	return v
