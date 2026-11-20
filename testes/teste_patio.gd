extends SceneTree
## Testa o pátio: turnos de aniversário, eventos do turno, conversas (uma por turno,
## próprias de cada colega, condições de afinidade), reação de quem fala, save e os
## sprites das fichas. Também monta a cena 3D sem tela para pegar erros de script.
## Uso: Godot --headless --path . --script res://testes/teste_patio.gd

var CarreiraS: GDScript
# carregados em tempo de execução: dependem do autoload Dados
var SpritesG: GDScript
var RetratoG: GDScript
var PatioS: GDScript
var falhas := []
var dados: Node


func _conferir(ok: bool, msg: String) -> void:
	if not ok:
		falhas.append(msg)


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	SpritesG = load("res://scripts/sprites_garota.gd")
	RetratoG = load("res://scripts/retrato_garota.gd")
	PatioS = load("res://scripts/patio_3d.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_patio_carreira.json"
	dados = root.get_node("Dados")
	if dados.iniciais.is_empty():
		dados._ready()
	var p: Dictionary = dados.patio

	# aniversários: Mira faz no turno 1 (3/mar), Lira em 2/dez (Dezembro · Início = turno 19)
	_conferir(CarreiraS.turno_do_aniversario([3, 3], 0) == 1, "aniversário da Mira não é o turno 1")
	_conferir(CarreiraS.turno_do_aniversario([2, 12], 0) == 19, "aniversário da Lira não é o turno 19")
	_conferir(CarreiraS.turno_do_aniversario([30, 5], 1) == 24 + 6, "aniversário da Algol no ano 2")
	_conferir(CarreiraS.turno_do_aniversario([3, 1], 2) == 48 + 21, "aniversário em janeiro no ano 3")
	for g in dados.garotas:
		for ano in 3:
			var t: int = CarreiraS.turno_do_aniversario(g.aniversario, ano)
			_conferir(t >= 1 + 24 * ano and t <= 24 * (ano + 1), "%s: aniversário fora do ano %d (%d)" % [g.nome, ano, t])

	# dados: toda conversa tem 2 escolhas com resultado, todo evento aponta para conversa que existe
	var ids := {}
	for cv in p.conversas:
		ids[cv.id] = true
		_conferir(cv.escolhas.size() >= 2, "%s com menos de 2 escolhas" % cv.id)
		for e in cv.escolhas:
			_conferir(e.has("resultado") and e.has("efeitos"), "%s: escolha sem resultado/efeitos" % cv.id)
			_conferir(e.get("reacao", {}).get("expressao", "normal") in SpritesG.EXPRESSOES, "%s: expressão inválida" % cv.id)
			_conferir(e.get("reacao", {}).get("gesto", "") in RetratoG.GESTOS + [""], "%s: gesto inválido" % cv.id)
			_conferir(e.get("reacao", {}).get("emote", "") in RetratoG.EMOTES + [""], "%s: emote inválido" % cv.id)
		_conferir(cv.get("expressao", "normal") in SpritesG.EXPRESSOES, "%s: expressão de abertura inválida" % cv.id)
	for ev in p.eventos:
		var cid: String = p.eventos[ev].conversa
		_conferir(cid == "" or ids.has(cid), "evento %s aponta para conversa inexistente %s" % [ev, cid])
	for colega in dados.encontros.colegas:
		_conferir(p.garotas.has(colega), "%s sem hábito no pátio" % colega)
		_conferir(p.lugares.has(p.garotas[colega].lugar), "%s com lugar inexistente" % colega)
		_conferir(SpritesG.tem(colega), "%s sem sprite da ficha" % colega)
		_conferir(SpritesG.rosto(colega, "feliz") != null, "%s sem atlas de rostos" % colega)
	for rival in ["Polaris", "Algol"]:
		_conferir(SpritesG.tem(rival), "%s sem sprite" % rival)
	for e in dados.encontros.encontros:
		_conferir(e.get("expressao", "normal") in SpritesG.EXPRESSOES, "encontro %s: expressão inválida" % e.id)

	# carreira da Lira: turno 1 é aniversário da Mira (colega)
	var ini: Dictionary = dados.inicial("Lira")
	var c = CarreiraS.new(dados.garota("Lira"), ini, 99)
	c.encontro_pendente = {}
	var ev: Dictionary = c.evento_patio()
	_conferir(ev.id == "aniversario" and ev.outra == "Mira", "turno 1 da Lira não é o aniversário da Mira: %s" % ev)
	_conferir(c.conversa_patio("Mira").get("id", "") == "pat_aniversario", "Mira não tem a conversa de aniversário")
	_conferir(c.conversa_patio("Nashira").get("id", "") != "pat_aniversario", "aniversário da Mira vazou para a Nashira")
	var af0: int = c.afinidade.Mira
	var txt: String = c.escolher_conversa("Mira", 0)
	_conferir(c.afinidade.Mira > af0, "conversa de aniversário não subiu a afinidade")
	_conferir(txt.contains("afinidade com Mira"), "texto do resultado sem os efeitos: " + txt)
	_conferir(c.ultima_reacao.get("quem", "") == "Mira" and c.ultima_reacao.get("expressao", "") == "feliz", "reação errada: %s" % c.ultima_reacao)
	_conferir(c.conversa_patio("Nashira").is_empty(), "segunda conversa no mesmo turno")
	_conferir(not c.pode_conversar_no_patio(), "pode_conversar depois de conversar")

	# conversas próprias: a da afinidade 30+ só aparece depois
	c.turno = 5
	c.encontro_pendente = {}
	c.afinidade.Capela = 0
	var vistas := []
	for i in 12:
		c.turno = 5 + i
		c.conversa_turno = 0
		var cv: Dictionary = c.conversa_patio("Capela")
		vistas.append(cv.get("id", ""))
		if cv.get("garota") == "Capela":
			c.patio_vistos.append(cv.id)
	_conferir("pat_capela" in vistas, "conversa própria da Capela nunca apareceu: %s" % [vistas])
	_conferir(not "pat_capela2" in vistas, "conversa de afinidade 30 apareceu com afinidade 0")
	c.afinidade.Capela = 40
	c.patio_vistos = ["pat_capela"]
	var achou := false
	for i in 12:
		c.turno = 20 + i
		if c.conversa_patio("Capela").get("id", "") == "pat_capela2":
			achou = true
	_conferir(achou, "conversa de afinidade 30 da Capela não apareceu com afinidade 40")

	# vitória e derrota no turno anterior
	c.turno = 30
	c.resultados.append({"turno": 29, "nome": "x", "cat": "aberta", "posicao": 1, "objetivo": 0, "ok": true, "fama": 0})
	_conferir(c.evento_patio().id == "vitoria" or c.faz_aniversario("Lira"), "vitória no turno anterior não vira evento")
	c.resultados[-1].posicao = 7
	var e2: Dictionary = c.evento_patio()
	_conferir(e2.id == "derrota" and c.afinidade[e2.outra] == c.afinidade.values().max(), "derrota sem a amiga mais próxima: %s" % e2)

	# reação padrão
	_conferir(CarreiraS.reacao_da_escolha({}, {"humor": 1}, true).expressao == "feliz", "reação padrão de humor")
	_conferir(CarreiraS.reacao_da_escolha({}, {"vel": 10}, false).expressao == "tonta", "reação padrão de falha")

	# encontro normal guarda a reação de quem falou
	var c2 = CarreiraS.new(dados.garota("Lira"), ini, 7)
	c2.encontro_pendente = {"id": "gen_almoco", "tipo": "encontro", "outra": "Antares"}
	c2.escolher(0)
	_conferir(c2.ultima_reacao.get("quem", "") == "Antares", "encontro genérico sem reação da colega")

	# save guarda a conversa do turno e as vistas
	c.conversa_turno = c.turno
	c.patio_vistos = ["pat_capela", "pat_lira"]
	c.salvar()
	var d = CarreiraS.carregar()
	_conferir(d.conversa_turno == c.conversa_turno and str(d.patio_vistos) == str(c.patio_vistos), "save do pátio")
	CarreiraS.apagar_save()

	# cena 3D monta sem erro em todos os eventos
	for id in p.eventos:
		var pt = PatioS.new(dados.encontros.colegas, {"id": id, "outra": "Mira"}, "estrelas" if id == "estrelas" else "bom", 3)
		root.add_child(pt)
		if pt.gatas.is_empty():
			pt._ready()  # no _initialize o _ready ainda não roda
		for k in 20:
			pt._process(0.5)
		_conferir(pt.gatas.size() == 6, "pátio %s sem as 6 garotas" % id)
		pt.free()
	var prim = PatioS.new(["Altair", "Lira"], {}, "chuva", 1)
	root.add_child(prim)
	if prim.gatas.is_empty():
		prim._ready()
	prim._process(0.1)
	prim.free()

	print("PÁTIO OK" if falhas.is_empty() else "PÁTIO FALHOU:\n- " + "\n- ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
