class_name TelaPool
extends Control
## Pool semanal (GDD §6): rotação de garotas, chances visíveis, garantia e vínculo.

signal voltar

var perfil: Perfil
var resultado := {}


func _init(p: Perfil) -> void:
	perfil = p


func _ready() -> void:
	_montar()


func _montar() -> void:
	for c in get_children():
		c.queue_free()
	var v := UI.vbox(12)
	var topo := UI.hbox(10)
	var em_pe := UI.em_pe()
	topo.add_child(UI.faixa(("Pool · rot. %d" if em_pe else "Pool semanal · rotação %d") % (perfil.giro + 1), UI.ROSA, 22 if em_pe else 30))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	topo.add_child(UI.moedas(perfil.moeda))
	topo.add_child(UI.botao("Voltar", func(): voltar.emit(), 16 if em_pe else 18))
	if em_pe:
		topo.add_theme_constant_override("separation", 4)
	v.add_child(topo)
	if not resultado.is_empty():
		v.add_child(_painel_resultado())

	# faixa da tiragem: explicação, garantia e o botão grande
	var pt := UI.painel(UI.PAINEL, 12)
	var ht := UI.fila(14)
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lg := UI.hbox(8)
	lg.add_child(UI.capsula("Garantia", UI.LARANJA, 13))
	var lm := UI.label("%s vem em no máximo %d tiragem(ns)." % [perfil.escolhida, perfil.faltam_para_garantia()], 16, UI.TEXTO, em_pe)
	lm.add_theme_font_override("font", UI.negrito())
	lg.add_child(lm)
	tv.add_child(lg)
	tv.add_child(UI.label("Cada tiragem custa %d moedas e sempre traz uma destas garotas. Garota nova entra no elenco; repetida sobe o vínculo. A rotação muda a cada carreira concluída." % Perfil.BAL.custo_tiragem, 14, UI.SUAVE, true))
	ht.add_child(tv)
	var b := UI.botao_cor("Tirar 1 · %d moedas" % Perfil.BAL.custo_tiragem, _tirar, UI.ROSA, 20)
	b.custom_minimum_size = Vector2(240, 58)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not perfil.pode_tirar()
	if b.disabled:
		b.tooltip_text = "Moedas insuficientes. Conclua uma carreira para ganhar mais."
	ht.add_child(b)
	pt.add_child(ht)
	v.add_child(pt)

	var grade := GridContainer.new()
	grade.columns = 1 if em_pe else 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for nome in perfil.pool:
		grade.add_child(_cartao(nome))
	v.add_child(grade)
	add_child(UI.margem(v, 10 if em_pe else 22))


func _cartao(nome: String) -> Control:
	var tem: bool = perfil.elenco.has(nome)
	var p := CartaoGarota.criar(nome, perfil.elenco[nome].vinculo if tem else -1)
	if nome == perfil.escolhida:
		var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
		sb.border_color = UI.LARANJA
		sb.set_border_width_all(4)
		sb.bg_color = Color("#fff6ea")
		p.add_theme_stylebox_override("panel", sb)
	var v: VBoxContainer = p.get_child(0)
	var linha := UI.hbox(8)
	linha.add_child(UI.capsula("%d%%" % roundi(perfil.chance(nome) * 100), UI.CEU, 14))
	if tem:
		linha.add_child(UI.label("No elenco: repetida sobe o vínculo", 13, UI.SUAVE, true))
	else:
		linha.add_child(UI.capsula("NOVA", UI.VERDE, 13))
	v.add_child(linha)
	if nome != perfil.escolhida:
		v.add_child(UI.botao("Marcar para a garantia", func(): _marcar(nome), 14))
	else:
		var mc := UI.capsula("★ Marcada para a garantia", UI.LARANJA, 14)
		mc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(mc)
	return p


func _painel_resultado() -> Control:
	var p := UI.painel(Color("#fff3c4"), 10)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.border_color = UI.OURO
	sb.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(14)
	h.add_child(UI.medalhao(resultado.nome, 72, "feliz"))
	var txt: String
	if resultado.nova:
		txt = "%s entrou no elenco!" % resultado.nome
	elif resultado.vinculo_max:
		txt = "%s de novo! O vínculo já está no máximo, então voltaram %d moedas." % [resultado.nome, Perfil.BAL.custo_tiragem / 2]
	else:
		txt = "%s de novo! Vínculo subiu para %d." % [resultado.nome, resultado.vinculo]
	if resultado.garantida:
		txt += " (garantia)"
	var tv := UI.vbox(4)
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(UI.faixa("NOVA GAROTA!" if resultado.nova else "VÍNCULO!", UI.OURO if resultado.nova else UI.ROSA, 20))
	tv.add_child(UI.label(txt, 18, UI.TEXTO, UI.em_pe()))
	if UI.em_pe():
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	p.add_child(h)
	UI.pop(p)
	if resultado.nova:
		p.ready.connect(func():
			await p.get_tree().process_frame
			UI.confete(p, p.size / 2.0, 70))
	return p


func _marcar(nome: String) -> void:
	perfil.escolher(nome)
	_montar()


func _tirar() -> void:
	resultado = perfil.tirar()
	_montar()
