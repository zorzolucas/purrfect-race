class_name TelaEscolha
extends Control
## Escolha da primeira garota, 1 entre 3 iniciais (GDD §8). Só aparece no começo do jogo.

signal escolheu(inicial: Dictionary)


func _ready() -> void:
	var v := UI.vbox(12)
	var topo := UI.hbox(14)
	topo.add_child(UI.faixa("Nekomusume: Corrida Purrfeita", UI.ROSA, 30))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	var bg := UI.botao("Como jogar", func(): TelaGuia.abrir(self, "jogo"), 18)
	UI.tecla(bg, "F1")
	topo.add_child(bg)
	v.add_child(topo)
	v.add_child(UI.label("Escolha sua primeira garota. As outras você conhece pela pool semanal.", 18, UI.SUAVE))
	var linha := UI.hbox(16)
	linha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var i := 0
	for ini in Dados.iniciais:
		if ini.get("inicial", false):
			var cartao := _cartao(ini)
			linha.add_child(cartao)
			UI.pop(cartao, 0.08 * i)
			i += 1
	v.add_child(linha)
	add_child(UI.margem(v, 24))


func _cartao(ini: Dictionary) -> Control:
	var g := Dados.garota(ini.nome)
	var cor := Color(ini.cor)
	var p := UI.painel(UI.PAINEL, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	var topo := UI.hbox(8)
	topo.add_child(UI.faixa(ini.nome, cor, 24))
	var ap := UI.label("“%s”" % ini.apelido, 14, UI.SUAVE, true)
	ap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(ap)
	v.add_child(topo)
	var palco := UI.Palco.new()
	palco.nome = ini.nome
	palco.cor = cor
	palco.custom_minimum_size = Vector2(0, 190)
	palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var estilo := UI.capsula(Dados.ESTILO_NOME[g.estilo], cor, 13)
	estilo.position = Vector2(4, 4)
	palco.add_child(estilo)
	v.add_child(palco)
	v.add_child(UI.label(ini.descricao, 14, UI.TEXTO, true))
	v.add_child(UI.label("Corrida-alvo: %s (%d m), %s" % [
		Dados.DIST_NOME[ini.distancia], Dados.DISTANCIAS[ini.distancia], ini.piso.capitalize()], 13, UI.SUAVE))
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 3)
	for k in SimCorrida.KEYS:
		var h := UI.hbox(5)
		h.add_child(UI.Icone.new(k, 16))
		var l := UI.label(Dados.ATTR_CURTO[k], 13)
		l.custom_minimum_size.x = 30
		h.add_child(l)
		var b := UI.barra(g.atributos[k], 150, UI.ATTR_COR[k], 80)
		b.custom_minimum_size.y = 10
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		h.add_child(UI.label(str(int(g.atributos[k])), 13, UI.SUAVE))
		grade.add_child(h)
	v.add_child(grade)
	var nat: Array = ini.naturais.map(func(k): return Dados.ATTR_NOME[k])
	v.add_child(UI.label("Treinos naturais: %s" % " e ".join(nat), 13, UI.SUAVE, true))
	var habil: String = SimCorrida.UNICAS[ini.unica].nome
	v.add_child(UI.label("Habilidade única: ★ %s" % habil, 13, UI.DESTAQUE, true))
	v.add_child(UI.botao_principal("Escolher %s" % ini.nome.split(" ")[0], func(): escolheu.emit(ini), 18))
	p.add_child(v)
	return p
