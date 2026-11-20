class_name TelaFim
extends Control
## Fim da carreira (GDD §4.8): moeda recebida e a escolha entre substituir a versão
## salva da garota ou descartar o resultado. No Desafio da semana não há versão salva:
## mostra o placar e o recorde da semana.

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
	var v := UI.vbox(14)
	var titulo := "Carreira encerrada" if c.falhou_objetivo else "Carreira concluída!"
	v.add_child(UI.label(titulo, 36, UI.PERIGO if c.falhou_objetivo else UI.DESTAQUE))
	if msg != "":
		v.add_child(UI.label(msg, 18, UI.TEXTO, true))
	var final := c.final_da_campanha()
	if not final.is_empty():
		var pf := UI.painel(Color("#2a3150"), 12)
		var fv := UI.vbox(4)
		fv.add_child(UI.label("Final \"%s\" · caminho %s" % [final.titulo, final.caminho], 20, UI.DESTAQUE))
		fv.add_child(UI.label(final.texto, 16, UI.TEXTO, true))
		pf.add_child(fv)
		v.add_child(pf)

	var p := UI.painel()
	var pv := UI.vbox(8)
	var topo := UI.hbox(12)
	topo.add_child(RetratoGarota.new(c.nome, 88, "fechados" if c.falhou_objetivo else "feliz"))
	var nomes := UI.vbox(2)
	nomes.add_child(UI.label(c.nome, 26))
	nomes.add_child(UI.label("Nota final %s" % Dados.nota(c.attrs), 20, UI.DESTAQUE))
	topo.add_child(nomes)
	pv.add_child(topo)
	var opcionais := c.resultados.filter(func(r): return r.objetivo == 0)
	for r in c.resultados.filter(func(r): return r.objetivo > 0):
		var cor := UI.OK if r.ok else UI.PERIGO
		var pos := "%dº" % r.posicao if r.posicao > 0 else "não correu"
		pv.add_child(UI.label("Turno %d · %s: %s" % [r.turno, r.nome, pos], 16, cor))
	if not opcionais.is_empty():
		var vit := opcionais.filter(func(r): return r.posicao == 1).size()
		pv.add_child(UI.label("%d corrida(s) opcional(is), %d vitória(s). Fama final: %d." % [opcionais.size(), vit, c.fama], 16))
	if not c.titulos.is_empty():
		pv.add_child(UI.label("Títulos: %s" % ", ".join(c.titulos.map(func(t): return t.nome)), 16, UI.DESTAQUE, true))
	pv.add_child(UI.label("Semente da carreira: %d" % c.semente, 13, UI.SUAVE))
	var m := c.moeda_total()
	var txt_mag := " + %d da Magnitude %d" % [m.magnitude, c.magnitude] if c.magnitude > 0 else ""
	if c.desafio > 0 and perfil and perfil.moeda_desafio(c) == 0:
		pv.add_child(UI.label("Moeda: nada desta vez, porque a moeda do desafio desta semana já foi recebida.", 18, UI.SUAVE, true))
	else:
		pv.add_child(UI.label("Moeda: %d dos prêmios + %d de bônus por desempenho%s = %d" % [m.corridas, m.bonus, txt_mag, m.total], 18, UI.DESTAQUE, true))
	if c.magnitude > 0 and c.venceu_gp():
		pv.add_child(UI.label("GP final vencido na Magnitude %d!" % c.magnitude, 16, UI.OK))
	p.add_child(pv)
	v.add_child(p)
	if c.desafio > 0:
		_fim_desafio(v)
		return

	# comparação entre a versão salva e a nova
	var comp := UI.painel()
	var grade := GridContainer.new()
	grade.columns = 7
	grade.add_theme_constant_override("h_separation", 22)
	for t in ["", "Nota", "Vel", "Est", "Pod", "Det", "Int"]:
		grade.add_child(UI.label(t, 15, UI.SUAVE))
	var nova := c.versao_salva()
	for linha in [["Nova", nova], ["Salva", salva]]:
		grade.add_child(UI.label(linha[0], 16))
		var d: Dictionary = linha[1]
		if d.is_empty():
			grade.add_child(UI.label("—", 16, UI.SUAVE))
			for k in SimCorrida.KEYS:
				grade.add_child(UI.label("—", 16, UI.SUAVE))
			continue
		grade.add_child(UI.label(d.nota, 16, UI.DESTAQUE))
		for k in SimCorrida.KEYS:
			var val: int = int(d.attrs[k])
			var cor := UI.TEXTO
			if linha[0] == "Nova" and not salva.is_empty():
				cor = UI.OK if val > int(salva.attrs[k]) else (UI.PERIGO if val < int(salva.attrs[k]) else UI.TEXTO)
			grade.add_child(UI.label(str(val), 16, cor))
	comp.add_child(grade)
	v.add_child(comp)

	v.add_child(UI.label("Fica uma versão salva por garota. Ela é a que vai correr nas copas do circuito. A moeda você recebe de qualquer jeito, e a pool gira.", 15, UI.SUAVE, true))
	var botoes := UI.hbox(12)
	botoes.add_child(UI.botao_principal("Substituir a versão salva" if not salva.is_empty() else "Salvar esta versão", func(): decidiu.emit(true), 20))
	botoes.add_child(UI.botao_confirmar("Descartar o resultado", func(): decidiu.emit(false), 20,
		"Descartar esta versão? Clique de novo para confirmar"))
	v.add_child(botoes)
	_montar(v)


func _montar(v: VBoxContainer) -> void:
	# rola se não couber, para os botões de decisão nunca ficarem fora da tela
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(v)
	add_child(UI.margem(rolagem, 32))


func _fim_desafio(v: VBoxContainer) -> void:
	var placar := Endgame.placar_desafio(c)
	var reg: Dictionary = perfil.registro_desafio(c.desafio) if perfil else {"melhor": {}}
	var recorde := Endgame.placar_melhor(placar, reg.melhor)
	var pd := UI.painel(Color("#3a2f55"))
	var dv := UI.vbox(4)
	dv.add_child(UI.label("Desafio da semana #%d · regra: %s" % [c.desafio, Endgame.regra(c.regra).get("nome", c.regra)], 20, UI.DESTAQUE))
	dv.add_child(UI.label("Resultado: %s" % Endgame.texto_placar(placar), 17, UI.TEXTO, true))
	dv.add_child(UI.label("Melhor até agora: %s" % Endgame.texto_placar(reg.melhor), 15, UI.SUAVE, true))
	if recorde:
		dv.add_child(UI.label("Novo recorde da semana!", 17, UI.OK))
	dv.add_child(UI.label("No desafio não fica versão salva e a pool não gira. Dá para tentar de novo até a rotação mudar.", 14, UI.SUAVE, true))
	pd.add_child(dv)
	v.add_child(pd)
	v.add_child(UI.botao("Concluir desafio", func(): decidiu.emit(false), 20))
	_montar(v)
