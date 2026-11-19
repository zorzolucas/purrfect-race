extends Control
## Controla o fluxo do jogo:
## primeira garota → academia ⇄ pool; academia → carreira ⇄ corrida → fim → academia.
## A carreira é salva a cada mudança de estado e o perfil (moeda, elenco, pool) a cada
## tiragem e fim de carreira (GDD §10).

var perfil: Perfil
var carreira: Carreira
var tela: Control


func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = UI.FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	perfil = Perfil.carregar()
	if perfil == null:
		mostrar_escolha()
	else:
		mostrar_academia()


func _trocar(nova: Control) -> void:
	if tela:
		tela.queue_free()
	tela = nova
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tela)


func mostrar_escolha() -> void:
	var t := TelaEscolha.new()
	t.escolheu.connect(_primeira_garota)
	_trocar(t)


func _primeira_garota(ini: Dictionary) -> void:
	perfil = Perfil.novo(ini.nome)
	mostrar_academia("%s entrou para a academia! Você tem %d moedas para conhecer outras garotas na pool." % [
		ini.nome, perfil.moeda])


func mostrar_academia(msg: String = "") -> void:
	var t := TelaAcademia.new(perfil, msg)
	t.treinar.connect(_comecar_carreira)
	t.continuar.connect(_continuar_carreira)
	t.abrir_pool.connect(mostrar_pool)
	t.abrir_circuito.connect(mostrar_circuito)
	t.jogar_desafio.connect(_comecar_desafio)
	_trocar(t)


func mostrar_circuito() -> void:
	var t := TelaCircuito.new(perfil)
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t)


func mostrar_pool() -> void:
	var t := TelaPool.new(perfil)
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t)


## Começa a carreira. Se houver garota salva no elenco, antes passa pela escolha da madrinha.
func _comecar_carreira(nome: String, magnitude: int = 0) -> void:
	if TelaMadrinha.candidatas(perfil, nome).is_empty():
		_iniciar(nome, {}, magnitude)
		return
	var t := TelaMadrinha.new(perfil, nome)
	t.escolheu.connect(func(md): _iniciar(nome, md, magnitude))
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t)


## Desafio da semana: semente, garota e regra fixas, vínculo 0 e sem madrinha.
func _comecar_desafio() -> void:
	var des := perfil.desafio_atual()
	carreira = Carreira.new(Dados.garota(des.garota), Dados.config_carreira(des.garota), des.semente, 0, {},
		{"regra": des.regra.id, "desafio": des.semana})
	var extra := ""
	if not carreira.maldicoes.is_empty():
		extra = " Maldições: %s." % ", ".join(carreira.maldicoes.map(func(id): return Dados.amuleto(id).nome))
	mostrar_carreira("Desafio da semana #%d com %s. Regra: %s. %s%s" % [des.semana, des.garota,
		des.regra.nome, des.regra.descricao, extra])


func _iniciar(nome: String, madrinha: Dictionary, magnitude: int = 0) -> void:
	var ini := Dados.config_carreira(nome)
	carreira = Carreira.new(Dados.garota(nome), ini, 0, perfil.elenco[nome].vinculo, madrinha, {"magnitude": magnitude})
	var extra := ""
	if carreira.vinculo > 0:
		extra = " Vínculo %d: +%d em cada atributo e limite de %d." % [
			carreira.vinculo, Carreira.BAL.vinculo_attr * carreira.vinculo, carreira.limite]
	if not madrinha.is_empty():
		var leg := Carreira.bonus_legado(carreira.vinculo, madrinha)
		extra += " Madrinha: %s (bônus inicial de até +%d por atributo)." % [madrinha.nome, roundi(leg.values().max())]
	if carreira.magnitude > 0:
		extra += " Magnitude %d." % carreira.magnitude
		if not carreira.maldicoes.is_empty():
			extra += " Maldições: %s." % ", ".join(carreira.maldicoes.map(func(id): return Dados.amuleto(id).nome))
	mostrar_carreira("Começa a carreira de %s! Três anos, 8 objetivos e um mapa de rotas novo a cada carreira.%s" % [carreira.nome, extra])


func _continuar_carreira() -> void:
	carreira = Carreira.carregar()
	if carreira == null:
		Carreira.apagar_save()
		mostrar_academia("Não consegui ler a carreira salva.")
		return
	mostrar_carreira("Carreira carregada. Bem-vinda de volta, %s!" % carreira.nome.split(" ")[0])


func mostrar_carreira(msg: String = "") -> void:
	carreira.salvar()
	if carreira.terminou:
		mostrar_fim(msg)
		return
	var t := TelaCarreira.new(carreira, msg)
	t.ir_correr.connect(mostrar_corrida)
	t.atualizou.connect(func(m): mostrar_carreira(m))
	_trocar(t)


func mostrar_corrida() -> void:
	var dados := carreira.montar_corrida(Dados.garotas)
	var t := TelaCorrida.new(dados, carreira.cor)
	t.terminou.connect(func(pos): mostrar_carreira(carreira.registrar_corrida(pos,
		Carreira.extra_da_corrida(dados, t.sim.classificacao(), t.sim.ordem_meio))))
	_trocar(t)


func mostrar_fim(msg: String) -> void:
	var salva: Dictionary = perfil.elenco.get(carreira.nome, {}).get("salva", {})
	var t := TelaFim.new(carreira, msg, salva, perfil)
	t.decidiu.connect(_concluir)
	_trocar(t)


func _concluir(substituir: bool) -> void:
	if carreira.desafio > 0:
		var moeda := perfil.moeda_desafio(carreira)
		var placar := Endgame.placar_desafio(carreira)
		perfil.concluir_carreira(carreira, false)
		Carreira.apagar_save()
		var reg := perfil.registro_desafio(carreira.desafio)
		carreira = null
		mostrar_academia("Desafio concluído: %s. Melhor da semana: %s. Você recebeu %d moedas." % [
			Endgame.texto_placar(placar), Endgame.texto_placar(reg.melhor), moeda])
		return
	var m := carreira.moeda_total()
	var mag_antes := int(perfil.magnitude_de(carreira.nome).liberada)
	perfil.concluir_carreira(carreira, substituir)
	Carreira.apagar_save()
	var txt := "Você recebeu %d moedas. " % m.total
	txt += "A nova versão de %s foi salva. " % carreira.nome if substituir else "O resultado foi descartado. "
	var mag_depois := int(perfil.magnitude_de(carreira.nome).liberada)
	if mag_depois > mag_antes:
		txt += "GP final vencido: a Magnitude %d de %s está liberada! " % [mag_depois, carreira.nome]
	txt += "A pool girou: há garotas novas na rotação e as condições do circuito mudaram."
	carreira = null
	mostrar_academia(txt)
