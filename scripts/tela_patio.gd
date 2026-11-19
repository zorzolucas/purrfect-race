class_name TelaPatio
extends Control
## Tela do pátio (GDD §11.3): o pátio 3D com as colegas passeando, a garota da carreira
## grande à esquerda e o evento do turno em cima. Clicar numa colega abre uma conversa curta
## (1 por turno, data/patio.json) ou, se já conversou, uma fala solta. Fora da carreira
## (na academia) só há falas soltas e as garotas do elenco no lugar das colegas.

signal voltar(msg: String)

var c: Carreira               # null na academia
var colegas: Array
var patio: Patio3D
var _painel: PanelContainer
var _retrato_dela: RetratoGarota
var _resultado := ""
var _rng := RandomNumberGenerator.new()


func _init(carreira: Carreira, colegas_academia: Array = []) -> void:
	c = carreira
	colegas = c.afinidade.keys() if c else colegas_academia


func _ready() -> void:
	var evento := c.evento_patio() if c else {"id": "habitos", "outra": ""}
	var clima := c.clima() if c else "bom"
	_rng.seed = (c.semente + c.turno) if c else 11
	var raiz := UI.hbox(0)
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# pátio 3D
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	var vp := SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_2X
	vp.own_world_3d = true
	svc.add_child(vp)
	patio = Patio3D.new(colegas, evento, clima, _rng.seed)
	vp.add_child(patio)
	add_child(svc)
	move_child(svc, 0)
	svc.gui_input.connect(_clique.bind(svc, vp))

	var cobre := UI.vbox(10)
	cobre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UI.margem(cobre, 18)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)

	# topo: evento do turno e voltar
	var topo := UI.painel(Color(0.08, 0.1, 0.16, 0.86), 12)
	var ht := UI.hbox(12)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ev: Dictionary = Dados.patio.eventos.get(evento.id, {})
	var titulo := "Pátio da academia"
	if c:
		titulo += " · " + Calendario.data_texto(c.turno)
	tv.add_child(UI.label(titulo, 22, UI.DESTAQUE))
	tv.add_child(UI.label(_texto(ev.get("banner", ""), evento.get("outra", "")), 15, UI.TEXTO, true))
	var dica := "Clique numa colega para conversar (uma conversa por turno)."
	if c == null:
		dica = "Clique numa garota para ouvir o que ela tem a dizer."
	elif not c.pode_conversar_no_patio():
		dica = "Vocês já conversaram neste turno. Clique numa colega para ouvir uma fala."
	tv.add_child(UI.label(dica, 13, UI.SUAVE, true))
	ht.add_child(tv)
	ht.add_child(UI.botao("Voltar", func(): voltar.emit(_resultado), 18))
	topo.add_child(ht)
	cobre.add_child(topo)

	var meio := UI.hbox(12)
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cobre.add_child(meio)
	# a garota da carreira, grande e parada (GDD §11.3)
	if c:
		meio.add_child(_garota_grande())
	var vazio := Control.new()
	vazio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meio.add_child(vazio)
	# painel da conversa (embaixo, à direita)
	_painel = UI.painel(Color(0.11, 0.1, 0.18, 0.93), 16)
	_painel.custom_minimum_size.x = 560
	_painel.size_flags_vertical = Control.SIZE_SHRINK_END
	_painel.visible = false
	meio.add_child(_painel)


func _texto(t: String, outra: String) -> String:
	if c:
		return c.texto_patio(t, outra)
	return t.replace("{outra}", outra)


func _garota_grande() -> Control:
	var v := UI.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_vertical = Control.SIZE_SHRINK_END
	v.custom_minimum_size.x = 250
	var tex := SpritesGarota.corpo(c.nome)
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(250, 400)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
	var p := UI.painel(Color(0.08, 0.1, 0.16, 0.86), 10)
	var h := UI.hbox(10)
	_retrato_dela = RetratoGarota.new(c.nome, 64, SpritesGarota.expressao_do_humor(c.humor))
	h.add_child(_retrato_dela)
	var tv := UI.vbox(2)
	tv.add_child(UI.label(c.nome, 20))
	tv.add_child(UI.label("Humor: %s · Energia %d" % [Carreira.HUMOR_NOME[c.humor], c.energia], 13, UI.SUAVE))
	h.add_child(tv)
	p.add_child(h)
	v.add_child(p)
	return v


func _clique(ev: InputEvent, svc: SubViewportContainer, vp: SubViewport) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	var escala := Vector2(vp.size) / svc.size
	var nome := patio.garota_em(ev.position * escala)
	if nome != "":
		abrir(nome)


## Abre a conversa (ou a fala solta) com uma colega.
func abrir(nome: String) -> void:
	for f in _painel.get_children():
		f.queue_free()
	_painel.visible = true
	var cv: Dictionary = c.conversa_patio(nome) if c else {}
	var v := UI.vbox(10)
	var topo := UI.hbox(12)
	var ret := RetratoGarota.new(nome, 96, cv.get("expressao", "normal"))
	topo.add_child(ret)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inf: Dictionary = Dados.patio.garotas.get(nome, {})
	tv.add_child(UI.label(nome, 14, UI.SUAVE))
	if cv.is_empty():
		var hab: String = inf.get("habito", "passeia pelo pátio")
		tv.add_child(UI.label(hab.left(1).to_upper() + hab.substr(1), 18, UI.DESTAQUE, true))
	else:
		tv.add_child(UI.label(_texto(cv.titulo, nome), 22, UI.DESTAQUE, true))
	if c:
		tv.add_child(UI.label("Afinidade %d" % c.afinidade.get(nome, 0), 13, UI.SUAVE))
	topo.add_child(tv)
	var fechar := UI.botao("×", func(): _painel.visible = false, 18)
	fechar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	topo.add_child(fechar)
	v.add_child(topo)
	if cv.is_empty():
		var falas: Array = inf.get("falas", ["..."])
		v.add_child(UI.label("\"%s\"" % falas[_rng.randi() % falas.size()], 17, UI.TEXTO, true))
		ret.call_deferred("reagir", {"gesto": inf.get("gesto", ""), "emote": inf.get("emote", "")})
		patio.reagir(nome, {"gesto": "aceno", "emote": inf.get("emote", "")})
	else:
		v.add_child(UI.label(_texto(cv.texto, nome), 17, UI.TEXTO, true))
		ret.call_deferred("gesto", cv.get("gesto", ""))
		for i in cv.escolhas.size():
			var idx: int = i
			var b := UI.botao(_texto(cv.escolhas[i].texto, nome), func(): _escolher(nome, idx), 17)
			b.custom_minimum_size.y = 46
			v.add_child(b)
	_painel.add_child(v)


func _escolher(nome: String, i: int) -> void:
	_resultado = c.escolher_conversa(nome, i)
	var reacao := c.ultima_reacao.duplicate()
	c.ultima_reacao = {}
	c.salvar()
	for f in _painel.get_children():
		f.queue_free()
	var v := UI.vbox(10)
	var h := UI.hbox(12)
	var ret := RetratoGarota.new(nome, 96, reacao.get("expressao", "normal"))
	h.add_child(ret)
	h.add_child(UI.label(_resultado, 17, UI.TEXTO, true))
	v.add_child(h)
	v.add_child(UI.botao("Voltar ao turno", func(): voltar.emit(_resultado), 18))
	_painel.add_child(v)
	ret.call_deferred("reagir", reacao)
	patio.reagir(nome, reacao)
	if _retrato_dela:
		_retrato_dela.mudar_expressao(SpritesGarota.expressao_do_humor(c.humor))
