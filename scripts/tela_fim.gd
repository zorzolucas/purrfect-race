class_name TelaFim
extends Control
## Fim da carreira (GDD §4.8): moeda recebida e a escolha entre substituir a versão
## salva da garota ou descartar o resultado. No Desafio da semana não há versão salva:
## mostra o placar e o recorde da semana.
## Layout: a garota no palco à esquerda, com a nota final num selo grande; à direita os
## objetivos, a moeda e a comparação com a versão salva.

signal decidiu(substituir: bool)

var c: Carreira
var msg: String
var salva: Dictionary   # versão salva atual (vazio se ainda não tem)
var perfil: Perfil


func _init(carreira: Carreira, mensagem: String, salva_atual: Dictionary, perfil_: Perfil = null) -> void:
	c = carreira
	msg = mensagem
	salva = salva_atual
	perfil = perfil_


func _ready() -> void:
	var raiz := UI.vbox(12)
	var topo := UI.hbox(14)
	var titulo := "Carreira encerrada" if c.falhou_objetivo else "Carreira concluída!"
	topo.add_child(UI.faixa(titulo, UI.PERIGO if c.falhou_objetivo else UI.ROSA, 34))
	if msg != "":
		var lm := UI.label(msg, 17, UI.TEXTO, true)
		lm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		topo.add_child(lm)
	raiz.add_child(topo)

	var corpo := UI.hbox(14)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_child(_palco())

	# coluna da direita rola se não couber, para os botões nunca ficarem fora da tela
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mg := MarginContainer.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 6)
	mg.add_child(v)
	rolagem.add_child(mg)
	corpo.add_child(rolagem)
	raiz.add_child(corpo)
	add_child(UI.margem(raiz, 22))

	var final := c.final_da_campanha()
	if not final.is_empty():
		var pf := UI.painel_titulo("Final \"%s\" · caminho %s" % [final.titulo, final.caminho], UI.ROXO)
		pf.get_meta("corpo").add_child(UI.label(final.texto, 15, UI.TEXTO, true))
		v.add_child(pf)
	v.add_child(_painel_objetivos())
	v.add_child(_painel_moeda())

	if c.desafio > 0:
		_fim_desafio(v)
		return
	v.add_child(_comparacao())
	v.add_child(UI.label("Fica uma versão salva por garota. Ela é a que vai correr nas copas do circuito. A moeda você recebe de qualquer jeito, e a pool gira.", 14, UI.SUAVE, true))
	var botoes := UI.hbox(12)
	var bs := UI.botao_principal("Substituir a versão salva" if not salva.is_empty() else "Salvar esta versão", func(): decidiu.emit(true), 20)
	bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botoes.add_child(bs)
	botoes.add_child(UI.botao_confirmar("Descartar o resultado", func(): decidiu.emit(false), 18,
		"Descartar esta versão? Clique de novo para confirmar"))
	v.add_child(botoes)


## A garota em pé, com o nome na faixa, a nota final num selo grande e a fama.
func _palco() -> Control:
	var cor := UI.cor_garota(c.nome)
	var p := UI.painel(UI.PAINEL, 12)
	p.custom_minimum_size.x = 340
	var v := UI.vbox(8)
	var topo := UI.hbox(8)
	var fn := UI.faixa(c.nome, cor, 24)
	fn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(fn)
	var fama := UI.label_contorno("★ %d" % c.fama, 20, UI.OURO, Color.WHITE, 5)
	fama.tooltip_text = "Fama final"
	topo.add_child(fama)
	v.add_child(topo)
	var palco := UI.Palco.new()
	palco.nome = c.nome
	palco.cor = cor
	palco.custom_minimum_size = Vector2(300, 300)
	palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var nota := Dados.nota(c.attrs)
	var selo := UI.SeloNota.new(nota, 84)
	selo.position = Vector2(4, 4)
	palco.add_child(selo)
	var rotulo := UI.capsula("Nota final", UI.NOTA_COR.get(nota, UI.CEU), 13)
	rotulo.position = Vector2(2, 90)
	palco.add_child(rotulo)
	v.add_child(palco)
	UI.pop(selo, 0.3)
	var cumpridos := c.resultados.filter(func(r): return r.objetivo > 0 and r.ok).size()
	var total := c.resultados.filter(func(r): return r.objetivo > 0).size()
	var resumo := UI.capsula("%d de %d objetivos" % [cumpridos, total], UI.PERIGO if c.falhou_objetivo else UI.VERDE, 16)
	resumo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(resumo)
	p.add_child(v)
	if not c.falhou_objetivo:
		p.ready.connect(func():
			await p.get_tree().process_frame
			if is_instance_valid(p):
				UI.confete(p, Vector2(p.size.x / 2.0, p.size.y * 0.4), 80))
	return p


func _painel_objetivos() -> Control:
	var p := UI.painel_titulo("Objetivos da campanha", UI.CEU)
	var corpo: VBoxContainer = p.get_meta("corpo")
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 6)
	for r in c.resultados.filter(func(r): return r.objetivo > 0):
		var h := UI.hbox(8)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pos := "%dº" % r.posicao if r.posicao > 0 else "—"
		var marca := UI.capsula(("✓ " if r.ok else "✗ ") + pos, UI.VERDE if r.ok else UI.PERIGO, 14)
		marca.custom_minimum_size.x = 64
		h.add_child(marca)
		var sem_fama: bool = r.get("meta_fama", true) == false
		var l := UI.label("T%d · %s%s" % [r.turno, r.nome, " · sem a fama da meta" if sem_fama else ""], 14,
			UI.PERIGO if sem_fama or not r.ok else UI.TEXTO)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.tooltip_text = l.text
		h.add_child(l)
		grade.add_child(h)
	corpo.add_child(grade)
	var opcionais := c.resultados.filter(func(r): return r.objetivo == 0)
	var extras := UI.hbox(8)
	if not opcionais.is_empty():
		var vit := opcionais.filter(func(r): return r.posicao == 1).size()
		extras.add_child(UI.capsula("%d opcional(is)" % opcionais.size(), UI.CEU, 13))
		extras.add_child(UI.capsula("%d vitória(s)" % vit, UI.OURO, 13))
	if c.magnitude > 0 and c.venceu_gp():
		extras.add_child(UI.capsula("★ GP final vencido na Magnitude %d" % c.magnitude, UI.OURO, 13))
	if extras.get_child_count() > 0:
		corpo.add_child(extras)
	if not c.titulos.is_empty():
		corpo.add_child(UI.label("Títulos: %s" % ", ".join(c.titulos.map(func(t): return t.nome)), 14, UI.DESTAQUE, true))
	corpo.add_child(UI.label("Semente da carreira: %d" % c.semente, 12, UI.SUAVE))
	return p


func _painel_moeda() -> Control:
	var p := UI.painel(Color("#fff3c4"), 10)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.border_color = UI.OURO
	p.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(10)
	h.add_child(UI.Moeda.new(34))
	var m := c.moeda_total()
	if c.desafio > 0 and perfil and perfil.moeda_desafio(c) == 0:
		h.add_child(UI.label("Nada de moeda desta vez: a do desafio desta semana já foi recebida.", 16, UI.SUAVE, true))
	else:
		var total := UI.label_contorno("+0", 28, Color.WHITE, Color("#b07a00"), 7)
		h.add_child(total)
		UI.contar(total, 0, m.total, "+%d", 1.2)
		var txt_mag := " + %d da Magnitude %d" % [m.magnitude, c.magnitude] if c.magnitude > 0 else ""
		var l := UI.label("%d dos prêmios + %d de bônus por desempenho%s" % [m.corridas, m.bonus, txt_mag], 15, UI.TEXTO, true)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	p.add_child(h)
	return p


## Atributos da versão nova lado a lado com os da salva, em blocos coloridos.
func _comparacao() -> Control:
	var p := UI.painel_titulo("Nova versão × versão salva", UI.VERDE)
	var corpo: VBoxContainer = p.get_meta("corpo")
	var nova := c.versao_salva()
	var linha := UI.hbox(8)
	var ns := UI.vbox(2)
	ns.add_child(UI.SeloNota.new(nova.nota, 46))
	var seta := UI.label("×", 14, UI.SUAVE)
	seta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ns.add_child(seta)
	if salva.is_empty():
		var vazio := UI.label("—", 18, UI.SUAVE)
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ns.add_child(vazio)
	else:
		ns.add_child(UI.SeloNota.new(salva.nota, 34))
	linha.add_child(ns)
	for k in SimCorrida.KEYS:
		linha.add_child(_bloco_comp(k, int(nova.attrs[k]), -1 if salva.is_empty() else int(salva.attrs[k])))
	corpo.add_child(linha)
	return p


func _bloco_comp(k: String, novo: int, antigo: int) -> Control:
	var cor: Color = UI.ATTR_COR[k]
	var p := UI.painel(UI.PAINEL, 6)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
	sb.border_color = cor
	sb.border_width_top = 5
	sb.shadow_size = 3
	p.add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(2)
	var t := UI.hbox(4)
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	t.add_child(UI.Icone.new(k, 18))
	t.add_child(UI.label(Dados.ATTR_CURTO[k], 13, UI.SUAVE))
	v.add_child(t)
	var ln := UI.label_contorno(str(novo), 22, UI.TEXTO, Color.WHITE, 4)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ln)
	var txt := "salva —"
	var cor_d := UI.SUAVE
	if antigo >= 0:
		var d := novo - antigo
		txt = "%d (%+d)" % [antigo, d]
		cor_d = UI.OK if d > 0 else (UI.PERIGO if d < 0 else UI.SUAVE)
	var la := UI.label(txt, 12, cor_d)
	la.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(la)
	p.add_child(v)
	return p


func _fim_desafio(v: VBoxContainer) -> void:
	var placar := Endgame.placar_desafio(c)
	var reg: Dictionary = perfil.registro_desafio(c.desafio) if perfil else {"melhor": {}}
	var recorde := Endgame.placar_melhor(placar, reg.melhor)
	var pd := UI.painel_titulo("Desafio da semana #%d · regra: %s" % [c.desafio, Endgame.regra(c.regra).get("nome", c.regra)], UI.ROXO)
	var dv: VBoxContainer = pd.get_meta("corpo")
	if recorde:
		var rc := UI.faixa("NOVO RECORDE DA SEMANA!", UI.OURO, 20)
		dv.add_child(rc)
		UI.pop(rc, 0.4)
	dv.add_child(UI.label("Resultado: %s" % Endgame.texto_placar(placar), 17, UI.TEXTO, true))
	dv.add_child(UI.label("Melhor até agora: %s" % Endgame.texto_placar(reg.melhor), 15, UI.SUAVE, true))
	dv.add_child(UI.label("No desafio não fica versão salva e a pool não gira. Dá para tentar de novo até a rotação mudar.", 14, UI.SUAVE, true))
	v.add_child(pd)
	v.add_child(UI.botao_principal("Concluir desafio", func(): decidiu.emit(false), 20))
