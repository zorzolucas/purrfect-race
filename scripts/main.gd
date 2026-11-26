extends Control
## Controla o fluxo do jogo:
## primeira garota → academia ⇄ pool; academia → carreira ⇄ corrida → fim → academia.
## A carreira é salva a cada mudança de estado e o perfil (moeda, elenco, pool) a cada
## tiragem e fim de carreira (GDD §10).

var perfil: Perfil
var carreira: Carreira
var tela: Control
## A tela atual fica dentro desta rolagem: quando não cabe nem encolhendo (celular), rola.
var rolagem: ScrollContainer
## Camada por cima da rolagem para janelas (guia, detalhes): sempre do tamanho da tela visível.
var camada: Control
## Refaz a tela atual (para trocar de layout quando o celular gira).
var _refazer := Callable()
var _base := Escala.BASE_DESKTOP
var _caber_pendente := false
var _refazendo := false
var _toque := ToqueRolagem.new()


func _ready() -> void:
	theme = UI.tema()
	var fundo := UI.Fundo.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	rolagem = ScrollContainer.new()
	rolagem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(rolagem)
	camada = Control.new()
	camada.name = "Camada"
	camada.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camada)
	add_child(_toque)
	get_tree().root.size_changed.connect(_ao_redimensionar)
	_aplicar_escala(false)
	perfil = Perfil.carregar()
	if perfil == null:
		mostrar_escolha()
	else:
		mostrar_academia()


func _trocar(nova: Control, refazer := Callable()) -> void:
	if tela:
		tela.queue_free()
	for f in camada.get_children():
		if not (_refazendo and f is TelaGuia):  # o guia sobrevive ao celular girar
			f.queue_free()
	_refazer = refazer
	tela = nova
	tela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tela.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.add_child(tela)
	# telas que se remontam sozinhas (circuito, pool) trocam os filhos: mede de novo
	tela.child_entered_tree.connect(func(_n): _pedir_caber())
	rolagem.scroll_vertical = 0
	_pedir_caber()
	# transição curta: a tela nova entra com fade e desliza um pouco para cima
	tela.modulate.a = 0.0
	tela.position.y = 10.0
	var tw := tela.create_tween().set_parallel()
	tw.tween_property(tela, "modulate:a", 1.0, 0.18)
	tw.tween_property(tela, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# ---------- escala e layout para cada tamanho de tela ----------

var _janela_antes := Vector2i.ZERO

## size_changed também dispara quando a gente muda a base: só reage se a janela mudou.
func _ao_redimensionar() -> void:
	if get_tree().root.size == _janela_antes:
		return
	_aplicar_escala(true)


## Escolhe o modo (desktop, paisagem, retrato) e a base do canvas para o tamanho da janela.
## Se o modo mudou (o celular girou), refaz a tela atual no layout novo.
func _aplicar_escala(refazer: bool) -> void:
	_janela_antes = get_tree().root.size
	var r := Escala.calcular(Vector2(get_tree().root.size), Escala.dpr(), Escala.tem_toque())
	var mudou: bool = r.modo != Escala.modo
	Escala.modo = r.modo
	Escala.css = r.css
	Escala.toque = Escala.tem_toque() or r.modo != "desktop"
	_base = r.base
	get_tree().root.content_scale_size = Vector2i(_base)
	if mudou and r.modo == "paisagem":
		_dica_girar.call_deferred()
	if mudou and refazer and _refazer.is_valid():
		_refazendo = true
		_refazer.call()
		_refazendo = false
	else:
		_pedir_caber()


static var _girar_mostrada := false

## Celular deitado: avisa uma vez que em pé a tela fica maior (o layout em pé foi feito para o celular).
func _dica_girar() -> void:
	if _girar_mostrada or not is_inside_tree():
		return
	_girar_mostrada = true
	var cap := UI.capsula("Dica: com o celular em pé, o jogo fica maior e mais fácil de tocar.", Color("#2c3550"), 16)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(cap)
	cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	cap.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cap.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cap.position.y -= 16
	UI.pop(cap)
	var tw := cap.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(cap, "modulate:a", 0.0, 0.6)
	tw.tween_callback(cap.queue_free)


func _pedir_caber() -> void:
	if _caber_pendente:
		return
	_caber_pendente = true
	_caber.call_deferred(0)


## Mede quanto a tela atual precisa e aumenta a base até caber (tudo encolhe junto). O que
## passar do limite do modo vira altura mínima da tela e a rolagem cuida do resto.
func _caber(volta: int) -> void:
	_caber_pendente = false
	if not is_instance_valid(tela):
		return
	var precisa := Vector2.ZERO
	for f in tela.get_children():
		if f is Control and f.visible and not f.top_level:
			precisa = precisa.max(f.get_combined_minimum_size())
	for f in tela.get_children():
		if f is Control and not f.minimum_size_changed.is_connected(_pedir_caber):
			f.minimum_size_changed.connect(_pedir_caber)
	var janela := Vector2(get_tree().root.size)
	var nova := Escala.caber(janela, _base, precisa, Escala.modo)
	if not nova.is_equal_approx(Vector2(get_tree().root.content_scale_size)):
		get_tree().root.content_scale_size = Vector2i(nova.ceil())
	var vis := Escala.logico(janela, Vector2(get_tree().root.content_scale_size))
	tela.custom_minimum_size.y = precisa.y if precisa.y > vis.y + 1.0 else 0.0
	# texto com quebra muda de altura quando a largura muda: confere de novo
	if volta < 2:
		_caber.call_deferred(volta + 1)


func mostrar_escolha() -> void:
	var t := TelaEscolha.new()
	t.escolheu.connect(_primeira_garota)
	_trocar(t, mostrar_escolha)


func _primeira_garota(ini: Dictionary) -> void:
	perfil = Perfil.novo(ini.nome)
	mostrar_academia("%s entrou para a academia! Você tem %d moedas para conhecer outras garotas na pool." % [
		ini.nome, perfil.moeda])
	# primeira vez no jogo: o guia abre sozinho no começo
	TelaGuia.abrir(camada, "jogo")


## F1 abre o guia em qualquer tela, no capítulo que tem a ver com ela.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode == KEY_F1 and tela:
		get_viewport().set_input_as_handled()
		TelaGuia.abrir(camada, capitulo_do_guia())


func capitulo_do_guia() -> String:
	if tela is TelaCarreira:
		return "turno"
	if tela is TelaCorrida:
		return "corridas"
	if tela is TelaCircuito:
		return "endgame"
	if tela is TelaPool or tela is TelaAcademia or tela is TelaMadrinha:
		return "academia"
	return "jogo"


func mostrar_academia(msg: String = "") -> void:
	var t := TelaAcademia.new(perfil, msg)
	t.treinar.connect(_comecar_carreira)
	t.continuar.connect(_continuar_carreira)
	t.abrir_pool.connect(mostrar_pool)
	t.abrir_patio.connect(mostrar_patio_academia)
	t.abrir_circuito.connect(mostrar_circuito)
	t.jogar_desafio.connect(_comecar_desafio)
	_trocar(t, mostrar_academia.bind(msg))


func mostrar_circuito() -> void:
	var t := TelaCircuito.new(perfil)
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t, mostrar_circuito)


func mostrar_pool() -> void:
	var t := TelaPool.new(perfil)
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t, mostrar_pool)


## Começa a carreira. Se houver garota salva no elenco, antes passa pela escolha da madrinha.
func _comecar_carreira(nome: String, magnitude: int = 0) -> void:
	if TelaMadrinha.candidatas(perfil, nome).is_empty():
		_iniciar(nome, {}, magnitude)
		return
	var t := TelaMadrinha.new(perfil, nome)
	t.escolheu.connect(func(md): _iniciar(nome, md, magnitude))
	t.voltar.connect(func(): mostrar_academia())
	_trocar(t, _comecar_carreira.bind(nome, magnitude))


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
	t.ir_patio.connect(mostrar_patio)
	t.ir_academia.connect(func(): mostrar_academia("Carreira de %s salva no turno %d. Continue quando quiser." % [carreira.nome, carreira.turno]))
	t.atualizou.connect(func(m): mostrar_carreira(m))
	_trocar(t, mostrar_carreira.bind(msg))


func mostrar_patio() -> void:
	var t := TelaPatio.new(carreira)
	t.voltar.connect(func(m): mostrar_carreira(m))
	_trocar(t, mostrar_patio)


## Pátio fora da carreira: as garotas do elenco passeando, só com falas soltas.
func mostrar_patio_academia() -> void:
	var t := TelaPatio.new(null, perfil.elenco.keys())
	t.voltar.connect(func(_m): mostrar_academia())
	_trocar(t, mostrar_patio_academia)


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
	_trocar(t, mostrar_fim.bind(msg))


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
