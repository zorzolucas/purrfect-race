class_name ToqueRolagem
extends Node
## Toque no celular: arrastar o dedo rola a lista que está embaixo dele (mesmo começando em
## cima de um botão) e segurar o dedo num controle mostra a dica dele (no lugar do tooltip do
## mouse, que no toque não existe).
##
## O Godot transforma toque em clique de mouse com `device == DEVICE_ID_EMULATION`; só esses
## eventos passam por aqui, então mouse e touchpad de verdade seguem como sempre.
## O ScrollContainer do Godot só rola pelo toque se o dedo começa num espaço vazio: um botão
## embaixo do dedo fica com o evento.

const ZONA_MORTA := 12.0
const SEGURAR := 0.5
const ATRITO := 5.0

var _alvo: ScrollContainer
var _ini := Vector2.ZERO
var _ini_scroll := Vector2.ZERO
var _arrastando := false
var _apertado := false
var _tempo := 0.0
var _vel := Vector2.ZERO
var _ultimo := Vector2.ZERO
var _inercia: ScrollContainer
var _dica: CanvasLayer
## Evento de soltar que a gente mesmo injeta para o botão desistir do clique.
var _injetando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(ev: InputEvent) -> void:
	if _injetando or ev.device != InputEvent.DEVICE_ID_EMULATION:
		return
	var mb := ev as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if _dica != null:  # o toque que fecha a dica não clica em nada
				_fechar_dica()
				get_viewport().set_input_as_handled()
				return
			_inercia = null
			_apertado = true
			_arrastando = false
			_tempo = 0.0
			_ini = mb.position
			_ultimo = mb.position
			_vel = Vector2.ZERO
			_alvo = rolavel_em(get_tree().root, mb.position)
			if _alvo:
				_ini_scroll = Vector2(_alvo.scroll_horizontal, _alvo.scroll_vertical)
		else:
			_apertado = false
			if _arrastando:
				get_viewport().set_input_as_handled()
				_arrastando = false
				if _vel.length() > 60.0 and is_instance_valid(_alvo):
					_inercia = _alvo
			elif _dica != null:
				get_viewport().set_input_as_handled()
			_alvo = null
		return
	var mm := ev as InputEventMouseMotion
	if mm and _apertado and is_instance_valid(_alvo):
		var d := mm.position - _ini
		if not _arrastando and d.length() > ZONA_MORTA:
			_arrastando = true
			_cancelar_clique()
		if _arrastando:
			get_viewport().set_input_as_handled()
			_rolar(_alvo, _ini_scroll - d)
			var dt := maxf(get_process_delta_time(), 0.001)
			_vel = _vel.lerp((_ultimo - mm.position) / dt, 0.5)
			_ultimo = mm.position


func _process(delta: float) -> void:
	if _apertado and not _arrastando and _dica == null:
		_tempo += delta
		if _tempo >= SEGURAR:
			_mostrar_dica(_ini)
	if is_instance_valid(_inercia):
		var atual := Vector2(_inercia.scroll_horizontal, _inercia.scroll_vertical)
		_rolar(_inercia, atual + _vel * delta)
		_vel = _vel.lerp(Vector2.ZERO, clampf(ATRITO * delta, 0.0, 1.0))
		if _vel.length() < 20.0:
			_inercia = null


func _rolar(s: ScrollContainer, alvo: Vector2) -> void:
	if s.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		s.scroll_vertical = int(alvo.y)
	if s.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		s.scroll_horizontal = int(alvo.x)


## Solta o botão longe dele: o botão volta ao normal sem disparar.
func _cancelar_clique() -> void:
	var solta := InputEventMouseButton.new()
	solta.button_index = MOUSE_BUTTON_LEFT
	solta.pressed = false
	solta.position = Vector2(-10000, -10000)
	solta.global_position = solta.position
	solta.device = InputEvent.DEVICE_ID_EMULATION
	_injetando = true
	get_viewport().push_input(solta, true)
	_injetando = false


## A lista mais interna sob o ponto que ainda tem para onde rolar.
static func rolavel_em(n: Node, p: Vector2) -> ScrollContainer:
	var achado: ScrollContainer = null
	for f in n.get_children():
		if f is CanvasItem and not f.visible:
			continue
		if f is ScrollContainer and f.get_global_rect().has_point(p) and _pode_rolar(f):
			achado = f
		var dentro := rolavel_em(f, p)
		if dentro:
			achado = dentro
	return achado


static func _pode_rolar(s: ScrollContainer) -> bool:
	var v := s.get_v_scroll_bar()
	var h := s.get_h_scroll_bar()
	return (s.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and v.max_value - v.page > 1.0) \
		or (s.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and h.max_value - h.page > 1.0)


# ---------- dica ao segurar o dedo ----------

func _mostrar_dica(p: Vector2) -> void:
	var texto := ""
	var c := get_viewport().gui_get_hovered_control()
	while c != null and texto == "":
		texto = c.tooltip_text
		c = c.get_parent() as Control
	if texto == "":
		_tempo = -999.0  # nada a mostrar: não tenta de novo até soltar
		return
	_cancelar_clique()
	var camada := CanvasLayer.new()
	camada.layer = 50
	var p_ := UI.painel(Color("#2c3550"), 10)
	p_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(texto, 15, Color.WHITE, true)
	l.custom_minimum_size.x = 260
	p_.add_child(l)
	camada.add_child(p_)
	add_child(camada)
	_dica = camada
	await get_tree().process_frame
	if not is_instance_valid(p_):
		return
	var vis := get_viewport().get_visible_rect().size
	var tam := p_.get_combined_minimum_size()
	p_.size = tam
	var pos := p + Vector2(-tam.x * 0.5, -tam.y - 36.0)
	if pos.y < 8.0:
		pos.y = p.y + 36.0
	p_.position = pos.clamp(Vector2(8, 8), vis - tam - Vector2(8, 8))
	UI.pop(p_)


func _fechar_dica() -> void:
	if is_instance_valid(_dica):
		_dica.queue_free()
	_dica = null
