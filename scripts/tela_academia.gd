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
	var v := UI.vbox(14)
	var topo := UI.hbox(12)
	var titulo := UI.label("Academia Estelar", 34, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(UI.label("%d moedas" % perfil.moeda, 24, UI.DESTAQUE))
	topo.add_child(UI.botao("Pátio", func(): abrir_patio.emit(), 18))
	topo.add_child(UI.botao("Circuito", func(): abrir_circuito.emit(), 18))
	topo.add_child(UI.botao("Pool semanal", func(): abrir_pool.emit(), 18))
	v.add_child(topo)

	if msg != "":
		var pm := UI.painel(Color("#2a3150"))
		pm.add_child(UI.label(msg, 16, UI.TEXTO, true))
		v.add_child(pm)

	var salvo := Carreira.carregar() if Carreira.tem_save() else null
	if salvo:
		var pc := UI.painel(Color("#25402f"))
		var h := UI.hbox(12)
		var txt := "Carreira em andamento: %s, turno %d de %d." % [salvo.nome, salvo.turno, Carreira.BAL.turnos]
		if salvo.terminou:
			txt = "A carreira de %s terminou. Falta decidir se a nova versão fica salva." % salvo.nome
		var l := UI.label(txt, 18, UI.TEXTO, true)
		h.add_child(l)
		h.add_child(UI.botao("Continuar carreira", func(): continuar.emit(), 18))
		pc.add_child(h)
		v.add_child(pc)

	v.add_child(_painel_desafio())

	v.add_child(UI.label("Elenco (%d)  ·  escolha quem vai treinar%s" % [
		perfil.elenco.size(), ". Começar outra carreira apaga a que está em andamento." if salvo else ""], 16, UI.SUAVE, true))
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grade := GridContainer.new()
	grade.columns = 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for nome in perfil.elenco:
		grade.add_child(_cartao(nome))
	rolagem.add_child(grade)
	v.add_child(rolagem)
	add_child(UI.margem(v, 28))


func _cartao(nome: String) -> Control:
	var info: Dictionary = perfil.elenco[nome]
	var p := CartaoGarota.criar(nome, info.vinculo)
	var v: VBoxContainer = p.get_child(0)
	var salva: Dictionary = info.salva
	if salva.is_empty():
		v.add_child(UI.label("Ainda sem versão salva", 14, UI.SUAVE))
	else:
		var a: Dictionary = salva.attrs
		v.add_child(UI.label("Versão salva: nota %s · %d objetivo(s)" % [salva.nota, salva.objetivos], 14, UI.OK))
		v.add_child(UI.label("Vel %d · Est %d · Pod %d · Det %d · Int %d" % [a.vel, a.est, a.pod, a.det, a.int], 13, UI.SUAVE))
		var tit: Array = salva.get("titulos", [])
		if not tit.is_empty():
			v.add_child(UI.label("Títulos: " + ", ".join(tit), 13, UI.DESTAQUE, true))
	var mag := perfil.magnitude_de(nome)
	if int(mag.vencida) >= 0:
		v.add_child(UI.label("★ GP final vencido na Magnitude %d" % mag.vencida, 13, UI.DESTAQUE))
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
	linha.add_child(UI.botao("Treinar %s" % nome.split(" ")[0], func(): treinar.emit(nome, int(mag_escolhida.get(nome, 0))), 16))
	v.add_child(linha)
	return p


## Desafio da semana: garota, regra e o melhor resultado desta rotação.
func _painel_desafio() -> Control:
	var des := perfil.desafio_atual()
	var reg := perfil.registro_desafio(des.semana)
	var p := UI.painel(Color("#3a2f55"))
	var h := UI.hbox(12)
	var cfg := Dados.config_carreira(des.garota)
	h.add_child(UI.retrato(des.garota, Color(cfg.get("cor", "#999999")), 48))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label("Desafio da semana #%d · %s · regra: %s" % [des.semana, des.garota, des.regra.nome], 18, UI.DESTAQUE))
	tv.add_child(UI.label("%s Semente fixa, vínculo 0 e sem madrinha: a mesma carreira para todo mundo nesta rotação." % des.regra.descricao, 14, UI.TEXTO, true))
	var pago := "A moeda já foi recebida nesta semana; as próximas tentativas só valem o recorde." if reg.pago else "A 1ª tentativa concluída rende a moeda da carreira. O desafio não gira a pool."
	tv.add_child(UI.label("Melhor: %s · %d tentativa(s). %s" % [Endgame.texto_placar(reg.melhor), reg.tentativas, pago], 13, UI.SUAVE, true))
	h.add_child(tv)
	h.add_child(UI.botao("Jogar desafio", func(): jogar_desafio.emit(), 16))
	p.add_child(h)
	return p
