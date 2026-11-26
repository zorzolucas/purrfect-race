extends SceneTree
## Testa a escala da tela (scripts/escala.gd): o modo e a base escolhidos para os aparelhos
## de 2023 em diante e para os navegadores de desktop, e se as telas montadas no celular em
## pé cabem na largura (nada pode pedir mais largura do que a tela tem: lá não rola de lado).
## Uso: Godot --headless --path . --script res://testes/teste_escala.gd

var falhas := []
var main: Node
var passo := 0
var espera := 0
var EscalaS: GDScript


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _initialize() -> void:
	EscalaS = load("res://scripts/escala.gd")
	# [nome, viewport CSS, devicePixelRatio, toque, modo esperado]
	var casos := [
		["1366x768 (Chrome)", Vector2(1366, 657), 1.0, false, "desktop"],
		["1920x1080 (Chrome)", Vector2(1920, 969), 1.0, false, "desktop"],
		["1440x900 (Safari)", Vector2(1440, 789), 2.0, false, "desktop"],
		["1920x1080 a 125%", Vector2(1536, 739), 1.25, false, "desktop"],
		["1920x1080 a 150%", Vector2(1280, 595), 1.5, false, "desktop"],
		["iPhone 15 em pé", Vector2(393, 659), 3.0, true, "retrato"],
		["iPhone 16 Pro Max em pé", Vector2(440, 760), 3.0, true, "retrato"],
		["Galaxy S24 em pé", Vector2(360, 660), 3.0, true, "retrato"],
		["Pixel 8 em pé", Vector2(412, 780), 2.625, true, "retrato"],
		["Galaxy A54 em pé", Vector2(412, 760), 2.625, true, "retrato"],
		["iPad em pé", Vector2(820, 1100), 2.0, true, "retrato"],
		["iPhone 15 deitado", Vector2(760, 340), 3.0, true, "paisagem"],
		["Galaxy S24 deitado", Vector2(740, 300), 3.0, true, "paisagem"],
		["iPad deitado", Vector2(1180, 760), 2.0, true, "desktop"],
	]
	for cs in casos:
		var r: Dictionary = EscalaS.calcular(cs[1] * cs[2], cs[2], cs[3])
		_checar(r.modo == cs[4], "%s: modo %s, esperava %s" % [cs[0], r.modo, cs[4]])
		var log: Vector2 = EscalaS.logico(cs[1] * cs[2], r.base)
		# o texto do corpo (16 px lógicos) não pode ficar menor que ~11 px CSS no celular em pé
		var px_css: float = 16.0 * cs[1].x / log.x
		if r.modo == "retrato":
			_checar(px_css >= 11.5, "%s: corpo com %.1f px CSS" % [cs[0], px_css])
			_checar(log.x >= 460.0 and log.x <= 721.0, "%s: largura lógica %d" % [cs[0], log.x])
		if r.modo == "desktop":
			_checar(log.y >= 719.0, "%s: altura lógica %d < 720" % [cs[0], log.y])
	# caber: cresce na largura sempre e na altura até o limite do modo
	var j := Vector2(1600, 770)
	var b := Vector2(1280, 720)
	var nova: Vector2 = EscalaS.caber(j, b, Vector2(1060, 760), "desktop")
	_checar(EscalaS.logico(j, nova).y >= 759.0, "desktop: a tela de 760 px de altura tem de caber (veio %s)" % EscalaS.logico(j, nova))
	nova = EscalaS.caber(j, b, Vector2(1060, 2000), "desktop")
	_checar(EscalaS.logico(j, nova).y < 1100.0, "desktop: encolher tem limite (o resto rola)")
	nova = EscalaS.caber(Vector2(1179, 1977), Vector2(472, 472), Vector2(600, 3000), "retrato")
	_checar(absf(EscalaS.logico(Vector2(1179, 1977), nova).x - 600.0) < 1.0, "retrato: largura cresce até caber")

	# telas no celular em pé
	EscalaS.modo_forcado = "retrato"
	var perfil_s: GDScript = load("res://scripts/perfil.gd")
	var carreira_s: GDScript = load("res://scripts/carreira.gd")
	perfil_s.CAMINHO = "user://teste_escala_perfil.json"
	carreira_s.CAMINHO_SAVE = "user://teste_escala_carreira.json"
	perfil_s.apagar()
	carreira_s.apagar_save()
	root.size = Vector2i(472, 900)
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)


var roteiro := [
	func(): main._primeira_garota(root.get_node("Dados").iniciais[0]),
	func(): main.mostrar_pool(),
	func(): main._comecar_carreira("Lira"),
	func(): main.carreira.encontro_pendente = {}; main.mostrar_carreira("Teste."),
	func(): main.carreira.terminou = true; main.mostrar_carreira("Fim de teste."),
	func(): main.mostrar_circuito(),
]
var nomes := ["academia", "pool", "carreira (madrinha ou turno)", "turno", "fim", "circuito"]


func _process(_d: float) -> bool:
	espera += 1
	if espera < 4:
		return false
	espera = 0
	if passo > 0:
		var precisa := 0.0
		for f in main.tela.get_children():
			if f is Control and f.visible:
				precisa = maxf(precisa, f.get_combined_minimum_size().x)
		_checar(precisa <= 473.0, "em pé, %s pede %d px de largura (tela tem 472)" % [nomes[passo - 1], precisa])
	if passo >= roteiro.size():
		load("res://scripts/perfil.gd").apagar()
		load("res://scripts/carreira.gd").apagar_save()
		if falhas.is_empty():
			print("ESCALA OK")
		else:
			for f in falhas:
				print("  ", f)
			print("ESCALA FALHOU: %d problema(s)" % falhas.size())
		quit(0 if falhas.is_empty() else 1)
		return true
	roteiro[passo].call()
	passo += 1
	return false
