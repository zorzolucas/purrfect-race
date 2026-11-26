class_name TelaAcademia
extends Control
## Hub entre carreiras: moeda, elenco (vínculo e versão salva), acesso à pool (GDD §2) e o
## endgame (docs/campanhas.md §2.3): magnitude de cada garota, Circuito e Desafio da semana.

signal treinar(nome: String, magnitude: int)
signal continuar
signal abrir_pool
signal abrir_circuito
signal jogar_desafio
signal abrir_patio

var perfil: Perfil
var msg: String
var mag_escolhida := {}   # nome -> magnitude marcada no cartão


func _init(p: Perfil, mensagem: String = "") -> void:
	perfil = p
	msg = mensagem


func _ready() -> void:
	var v := UI.vbox(12)
	var topo := UI.hbox(10)
	topo.add_child(UI.faixa("Academia Estelar", UI.ROSA, 30))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	topo.add_child(UI.moedas(perfil.moeda))
	var bg := UI.botao("Guia", func(): TelaGuia.abrir(self, "jogo"), 18)
	bg.tooltip_text = "Como o jogo funciona (F1)"
	UI.tecla(bg, "F1")
	topo.add_child(bg)
	topo.add_child(UI.botao_cor("Pátio", func(): abrir_patio.emit(), UI.VERDE, 18))
	topo.add_child(UI.botao_cor("Circuito", func(): abrir_circuito.emit(), UI.LARANJA, 18))
	topo.add_child(UI.botao_cor("Pool semanal", func(): abrir_pool.emit(), UI.ROSA, 18))
	# no navegador, a tela cheia precisa vir de um clique (F11 também funciona)
	if OS.has_feature("web"):
		var bt := UI.botao("Tela cheia", _alternar_tela_cheia, 18)
		bt.tooltip_text = "Joga em tela cheia (Esc ou F11 volta)"
		topo.add_child(bt)
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(UI.PAINEL, 10)
		var hm := UI.hbox(10)
		hm.add_child(UI.capsula("Aviso", UI.CEU, 13))
		hm.add_child(UI.label(msg, 16, UI.TEXTO, true))
		pm.add_child(hm)
		v.add_child(pm)

	var salvo := Carreira.carregar() if Carreira.tem_save() else null
	if salvo:
		var pc := UI.painel_titulo("Carreira em andamento", UI.VERDE)
		var h := UI.hbox(12)
		h.add_child(UI.medalhao(salvo.nome, 56))
		var txt := "%s · turno %d de %d." % [salvo.nome, salvo.turno, Carreira.BAL.turnos]
		if salvo.terminou:
			txt = "A carreira de %s terminou. Falta decidir se a nova versão fica salva." % salvo.nome
		var l := UI.label(txt, 18, UI.TEXTO, true)
		l.add_theme_font_override("font", UI.negrito())
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
		var bc := UI.botao_principal("Continuar carreira", func(): continuar.emit(), 18)
		bc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bc)
		pc.get_meta("corpo").add_child(h)
		v.add_child(pc)

	v.add_child(_painel_desafio())

	var le := UI.hbox(10)
	le.add_child(UI.faixa("Elenco · %d" % perfil.elenco.size(), UI.CEU, 18))
	var dica := UI.label("escolha quem vai treinar%s" % [
		". Começar outra carreira apaga a que está em andamento." if salvo else ""], 14, UI.SUAVE, true)
	dica.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	le.add_child(dica)
	v.add_child(le)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grade := GridContainer.new()
	grade.columns = 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	var i := 0
	for nome in perfil.elenco:
		var cartao := _cartao(nome)
		grade.add_child(cartao)
		UI.pop(cartao, 0.04 * i)
		i += 1
	# margem para a sombra dos cartões não ser cortada pela rolagem
	var mg := MarginContainer.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 6)
	mg.add_child(grade)
	rolagem.add_child(mg)
	v.add_child(rolagem)
	add_child(UI.margem(v, 22))


func _cartao(nome: String) -> Control:
	var info: Dictionary = perfil.elenco[nome]
	var p := CartaoGarota.criar(nome, info.vinculo)
	var v: VBoxContainer = p.get_child(0)
	var salva: Dictionary = info.salva
	if salva.is_empty():
		var pv := UI.painel(Color("#eef2f7"), 8)
		pv.add_child(UI.label("Ainda sem versão salva: termine uma carreira com ela.", 13, UI.SUAVE, true))
		v.add_child(pv)
	else:
		var a: Dictionary = salva.attrs
		var hs := UI.hbox(8)
		hs.add_child(UI.SeloNota.new(salva.nota, 40))
		var sv := UI.vbox(2)
		sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sv.add_child(UI.label("Versão salva · %d/8 objetivos" % salva.objetivos, 14, UI.OK))
		sv.add_child(UI.linha_attrs(a, 13))
		hs.add_child(sv)
		v.add_child(hs)
		var tit: Array = salva.get("titulos", [])
		if not tit.is_empty():
			v.add_child(UI.label("Títulos: " + ", ".join(tit), 13, UI.DESTAQUE, true))
	var mag := perfil.magnitude_de(nome)
	if int(mag.vencida) >= 0:
		var cg := UI.capsula("★ GP final vencido na Magnitude %d" % mag.vencida, UI.OURO, 12)
		cg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		v.add_child(cg)
	var linha := UI.hbox(8)
	if int(mag.liberada) > 0:
		var op := OptionButton.new()
		op.focus_mode = Control.FOCUS_NONE
		for m in range(int(mag.liberada) + 1):
			op.add_item("Magnitude %d" % m, m)
		op.select(int(mag.liberada))
		mag_escolhida[nome] = int(mag.liberada)
		op.tooltip_text = Endgame.resumo_magnitude(int(mag.liberada))
		op.item_selected.connect(func(i):
			mag_escolhida[nome] = i
			op.tooltip_text = Endgame.resumo_magnitude(i))
		linha.add_child(op)
	var acao := func(): treinar.emit(nome, int(mag_escolhida.get(nome, 0)))
	var bt: Button
	if Carreira.tem_save():
		# começar outra carreira apaga a que está em andamento
		bt = UI.botao_confirmar("Treinar %s" % nome.split(" ")[0], acao, 16,
			"Apagar a carreira atual? Clique de novo")
	else:
		bt = UI.botao_principal("Treinar %s" % nome.split(" ")[0], acao, 16)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(bt)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	v.add_child(linha)
	return p


## Desafio da semana: garota, regra e o melhor resultado desta rotação.
func _painel_desafio() -> Control:
	var des := perfil.desafio_atual()
	var reg := perfil.registro_desafio(des.semana)
	var p := UI.painel_titulo("Desafio da semana #%d" % des.semana, UI.ROXO)
	var h := UI.hbox(12)
	h.add_child(UI.medalhao(des.garota, 60))
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var linha := UI.hbox(8)
	linha.add_child(UI.label(des.garota, 18))
	linha.add_child(UI.capsula("Regra: %s" % des.regra.nome, UI.ROXO, 13))
	linha.get_child(0).add_theme_font_override("font", UI.negrito())
	tv.add_child(linha)
	tv.add_child(UI.label("%s Semente fixa, vínculo 0 e sem madrinha: a mesma carreira para todo mundo nesta rotação." % des.regra.descricao, 14, UI.TEXTO, true))
	var pago := "A moeda já foi recebida nesta semana; as próximas tentativas só valem o recorde." if reg.pago else "A 1ª tentativa concluída rende a moeda da carreira. O desafio não gira a pool."
	tv.add_child(UI.label("Melhor: %s · %d tentativa(s). %s" % [Endgame.texto_placar(reg.melhor), reg.tentativas, pago], 13, UI.SUAVE, true))
	h.add_child(tv)
	var bj := UI.botao_cor("Jogar desafio", func(): jogar_desafio.emit(), UI.ROXO, 17)
	bj.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bj)
	p.get_meta("corpo").add_child(h)
	return p


func _alternar_tela_cheia() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
