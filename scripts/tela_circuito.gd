class_name TelaCircuito
extends Control
## Circuito em níveis (GDD §7 e docs/campanhas.md §2.3): 5 copas e o Campeonato Final em
## Bronze, Prata e Ouro. O jogador escala garotas salvas diferentes (3 por copa, 5 no Final)
## e vence somando mais pontos que as 3 casas rivais. Clima e traçado de cada corrida mudam
## a cada rotação da pool, então a melhor escalação muda de semana para semana.

signal voltar

const CLIMA_NOME := {"bom": "Tempo bom", "chuva": "Chuva", "calor": "Calor"}
const CLIMA_ICONE := {"bom": "☀", "chuva": "☂", "calor": "♨"}

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
	var v := UI.vbox(12)
	var topo := UI.hbox(12)
	var titulo := UI.label("Circuito · rotação %d" % (perfil.giro + 1), 30, UI.DESTAQUE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(UI.label("%d moedas" % perfil.moeda, 24, UI.DESTAQUE))
	if evento_id != "":
		topo.add_child(UI.botao("Voltar às copas", func(): _abrir(""), 18))
	topo.add_child(UI.botao("Voltar à academia", func(): voltar.emit(), 18))
	v.add_child(topo)
	if not resultado.is_empty():
		v.add_child(_painel_resultado())
	elif evento_id != "":
		v.add_child(_painel_escalacao())
	else:
		v.add_child(_painel_eventos())
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(v)
	add_child(UI.margem(rolagem, 28))


func _abrir(id: String) -> void:
	evento_id = id
	resultado = {}
	escalacao = sugerir(perfil, nivel, id) if id != "" else []
	_montar()


# ---------- lista de copas ----------

func _painel_eventos() -> Control:
	var v := UI.vbox(10)
	v.add_child(UI.label("Cada copa tem 3 corridas e pede 3 garotas salvas diferentes; o Campeonato Final tem 5 e pede 5. Pontos por colocação: %s. Vence quem somar mais que cada uma das 3 casas rivais (%s). O clima e o traçado de cada corrida mudam a cada rotação da pool." % [
		", ".join(Dados.endgame.circuito.pontos.map(func(x): return str(int(x)))), ", ".join(Dados.endgame.circuito.casas)], 15, UI.SUAVE, true))
	var abas := UI.hbox(8)
	for n in Endgame.niveis().size():
		var nv: Dictionary = Endgame.niveis()[n]
		var b := UI.botao("%s · força %d" % [nv.nome, int(nv.forca)], func(): _trocar_nivel(n), 18)
		b.disabled = n == nivel
		abas.add_child(b)
	v.add_child(abas)
	var aptas := perfil.aptas_circuito()
	if aptas.size() < 3:
		v.add_child(UI.label("Você tem %d garota(s) com versão salva. Para correr uma copa, salve pelo menos 3 no fim das carreiras." % aptas.size(), 16, UI.PERIGO, true))
	var grade := GridContainer.new()
	grade.columns = 2
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
	var p := UI.painel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 520
	var v := UI.vbox(4)
	var reg := perfil.registro_circuito(nivel, ev.id)
	var cab := UI.hbox(8)
	var nome := UI.label("%s %s" % [ev.nome, Endgame.niveis()[nivel].nome], 19, UI.DESTAQUE if ev.id == "final" else UI.TEXTO)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(nome)
	if reg.vitorias > 0:
		cab.add_child(UI.label("✓ vencida %d×" % reg.vitorias, 14, UI.OK))
	v.add_child(cab)
	var conds := Endgame.condicoes(perfil.giro, ev.id)
	for i in ev.corridas.size():
		v.add_child(UI.label(_texto_corrida(ev.corridas[i], conds[i]), 13, UI.SUAVE, true))
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
		info = "Prêmio: %d moedas%s" % [Endgame.premio(nivel, ev.id, primeira),
			" (1ª vitória)" if primeira else (" — já recebido nesta rotação" if ja_pago else " (repetição, 1 vez por rotação)")]
		if reg.melhor > 0:
			info += " · recorde %d pts" % reg.melhor
	var l := UI.label(info, 14, UI.TEXTO if aberto else UI.SUAVE, true)
	linha.add_child(l)
	var b := UI.botao("Escalar", func(): _abrir(ev.id), 16)
	b.disabled = not aberto or n_aptas < precisa
	linha.add_child(b)
	v.add_child(linha)
	p.add_child(v)
	return p


func _texto_corrida(corrida: Dictionary, cond: Dictionary) -> String:
	var t := Endgame.tracado(cond.tracado)
	return "%s %s · %s · %d m · %s · %s" % [CLIMA_ICONE.get(cond.clima, ""), Dados.DIST_NOME[corrida.dist],
		corrida.piso.capitalize(), int(corrida.metros), CLIMA_NOME.get(cond.clima, cond.clima), t.get("nome", "")]


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
	v.add_child(UI.label("%s %s · NPCs com força média %d" % [ev.nome, Endgame.niveis()[nivel].nome, int(Endgame.niveis()[nivel].forca)], 22, UI.DESTAQUE))
	v.add_child(UI.label("Escolha uma garota diferente para cada corrida. A letra mostra a aptidão dela na distância e no piso; o traçado e o clima pesam diferente em cada estilo.", 14, UI.SUAVE, true))
	var conds := Endgame.condicoes(perfil.giro, evento_id)
	var aptas := perfil.aptas_circuito()
	aptas.sort_custom(func(a, b): return a < b)
	var usadas := escalacao.map(func(e): return e.nome)
	for i in ev.corridas.size():
		var corrida: Dictionary = ev.corridas[i]
		var p := UI.painel()
		var pv := UI.vbox(4)
		var t := Endgame.tracado(conds[i].tracado)
		pv.add_child(UI.label("Corrida %d · %s" % [i + 1, _texto_corrida(corrida, conds[i])], 16, UI.TEXTO, true))
		if t.get("descricao", "") != "":
			pv.add_child(UI.label("%s: %s" % [t.nome, t.descricao], 13, UI.SUAVE, true))
		var linha := UI.hbox(8)
		var op := OptionButton.new()
		op.focus_mode = Control.FOCUS_NONE
		op.custom_minimum_size.x = 420
		for j in aptas.size():
			var n: String = aptas[j]
			op.add_item(_rotulo_garota(n, corrida), j)
			if n == escalacao[i].nome:
				op.select(j)
		op.item_selected.connect(func(j): _escolher(i, aptas[j]))
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
			linha.add_child(UI.label("repetida!", 14, UI.PERIGO))
		pv.add_child(linha)
		p.add_child(pv)
		v.add_child(p)
	var valida: bool = usadas.size() == ev.corridas.size() and not usadas.has("") \
		and usadas.all(func(n): return usadas.count(n) == 1)
	var b := UI.botao("Correr %s" % ev.nome, _correr, 20)
	b.disabled = not valida
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
	v.add_child(UI.label(titulo, 26, UI.OK if resultado.venceu else UI.PERIGO))
	for i in resultado.corridas.size():
		var r: Dictionary = resultado.corridas[i]
		var p := UI.painel()
		var pv := UI.vbox(3)
		pv.add_child(UI.label("Corrida %d · %s" % [i + 1, _texto_corrida(r.corrida, r.condicao)], 15, UI.SUAVE, true))
		pv.add_child(UI.label("%s: %dº (%d pts)" % [escalacao[i].nome, r.posicao, Endgame.pontos(r.posicao)], 17,
			UI.OK if r.posicao <= 3 else UI.TEXTO))
		var partes := []
		for c in casas.size():
			var pos: int = r.posicoes_casas[c]
			partes.append("%s (%s): %dº" % [casas[c], resultado.escalacao_casas[i][c], pos])
		pv.add_child(UI.label(" · ".join(partes), 13, UI.SUAVE, true))
		var vencedora: String = r.nomes[r.ordem[0]]
		if r.ordem[0] != 0:
			pv.add_child(UI.label("Vencedora: %s" % vencedora, 13, UI.SUAVE))
		p.add_child(pv)
		v.add_child(p)
	var placar := UI.painel(Color("#2a3150"))
	var pl := UI.vbox(4)
	pl.add_child(UI.label("Você: %d pts" % resultado.total, 20, UI.DESTAQUE))
	for c in casas.size():
		pl.add_child(UI.label("%s: %d pts" % [casas[c], resultado.casas[c]], 16))
	if resultado.premio > 0:
		pl.add_child(UI.label("+%d moedas%s" % [resultado.premio, " (1ª vitória)" if resultado.primeira else ""], 18, UI.OK))
	elif resultado.venceu:
		pl.add_child(UI.label("O prêmio de repetição desta copa já foi recebido nesta rotação.", 15, UI.SUAVE, true))
	placar.add_child(pl)
	v.add_child(placar)
	var botoes := UI.hbox(12)
	botoes.add_child(UI.botao("Tentar de novo com a mesma escalação", func():
		resultado = {}
		_montar(), 18))
	botoes.add_child(UI.botao("Voltar às copas", func(): _abrir(""), 18))
	v.add_child(botoes)
	return v
