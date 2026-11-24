extends SceneTree
## Joga carreiras inteiras com um bot aleatório (com semente) e confere, a cada passo, que o
## estado continua válido: atributos entre 0 e o limite, energia 0-100, humor 0-4, turno só
## avança, toda pendência tem saída e a carreira termina. Também confere que a mesma semente
## com as mesmas escolhas dá a mesma carreira, inclusive salvando e carregando no meio.
## Diferente do testes/balanco.gd, o bot aqui não tenta jogar bem: ele explora (sai, descansa,
## treina qualquer coisa, entra em corridas que vai perder) para passar por mais caminhos.
## Uso: Godot --headless --path . --script res://testes/teste_carreira.gd [-- N]
var CarreiraS: GDScript
var dd: Node
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok and falhas.size() < 30:
		falhas.append(txt)


func _invariantes(c, quem: String) -> void:
	for k in c.attrs:
		_checar(c.attrs[k] >= 0.0 and c.attrs[k] <= c.limite, "%s t%d: %s = %.1f fora de [0, %d]" % [quem, c.turno, k, c.attrs[k], c.limite])
	_checar(c.energia >= 0 and c.energia <= 100, "%s t%d: energia %d" % [quem, c.turno, c.energia])
	_checar(c.humor >= 0 and c.humor <= 4, "%s t%d: humor %d" % [quem, c.turno, c.humor])
	_checar(c.amuletos.size() <= c.limite_amuletos(), "%s t%d: amuletos demais" % [quem, c.turno])
	_checar(c.habilidades.size() <= int(dd.habilidades.limite), "%s t%d: habilidades demais" % [quem, c.turno])
	_checar(c.pontos >= 0, "%s t%d: pontos negativos" % [quem, c.turno])
	for colega in c.afinidade:
		_checar(c.afinidade[colega] >= -20 and c.afinidade[colega] <= 100, "%s: afinidade fora da faixa" % quem)


## Um passo do bot. Devolve um texto curto do que fez (para comparar duas carreiras).
func _passo(c, r: RandomNumberGenerator) -> String:
	var p: String = c.pendencia()
	match p:
		"encontro":
			var e: Dictionary = c.encontro_atual()
			_checar(not e.is_empty(), "t%d: encontro pendente sem dados (%s)" % [c.turno, c.encontro_pendente])
			if e.is_empty():
				c.encontro_pendente = {}
				return "?"
			var i: int = r.randi() % e.escolhas.size()
			c.escolher(i)
			return "e%d" % i
		"equipamento":
			var ops: Array = c.opcoes_equipamento()
			c.escolher_equipamento(ops[r.randi() % ops.size()])
			return "q"
		"amuleto":
			var oferta: Array = c.oferta_amuleto
			if r.randf() < 0.15:
				c.descartar_oferta()
				return "a-"
			var id: String = oferta[r.randi() % oferta.size()]
			if c.amuletos.size() < c.limite_amuletos():
				c.escolher_amuleto(id)
			else:
				c.escolher_amuleto(id, c.amuletos[r.randi() % c.amuletos.size()])
			return "a" + id
		"mapa":
			var ops: Array = c.opcoes_mapa()
			var col: int = ops[r.randi() % ops.size()]
			c.escolher_no(col)
			return "m%d" % col
		"ferias":
			var q := "serra" if r.randf() < 0.5 else "praia"
			c.escolher_acampamento(q)
			return q
		"corrida", "objetivo":
			if p == "corrida" and r.randf() < 0.1:
				c.cancelar_corrida()
				return "x"
			var ol: Dictionary = c.olheiro(c.corrida_da_vez())
			_checar(ol.chances.size() == 3 and ol.chance >= 0.0 and ol.chance <= 1.0, "t%d: olheiro inválido" % c.turno)
			var ins: String = ["poupar", "normal", "forcar", ol.sugestao][r.randi() % 4]
			c.escolher_instrucao(ins)
			var corrida: Dictionary = c.montar_corrida(dd.garotas)
			_checar(corrida.field.size() == 12, "t%d: pelotão com %d" % [c.turno, corrida.field.size()])
			var sim := SimCorrida.new(corrida.field, corrida.distancia, corrida.seed, corrida.clima)
			var ordem: Array = sim.rodar_ate_o_fim()
			var pos: int = ordem.find(0) + 1
			c.registrar_corrida(pos, CarreiraS.extra_da_corrida(corrida, ordem, sim.ordem_meio))
			return "c%d" % pos
		"":
			pass
		_:
			_checar(false, "t%d: pendência desconhecida %s" % [c.turno, p])
			return "?"
	for h in dd.habilidades.lista:
		if c.pode_comprar(h.id) and r.randf() < 0.5:
			c.comprar_habilidade(h.id)
	if c.lesionada and r.randf() < 0.7:
		c.enfermaria()
		return "enf"
	var ops: Array = c.corridas_opcionais().filter(func(x): return c.pode_entrar(x))
	if not ops.is_empty() and c.energia >= 35 and r.randf() < 0.45:
		c.escolher_corrida(ops[r.randi() % ops.size()])
		return "opc"
	var x := r.randf()
	if c.energia < 40 and x < 0.7:
		c.descansar()
		return "d"
	if x < 0.1:
		c.sair()
		return "s"
	var t: String = SimCorrida.KEYS[r.randi() % 5]
	c.treinar(t)
	return t


## Joga até o fim. Com salvar_em > 0, salva e recarrega quando chega nesse turno.
func _jogar(nome: String, semente: int, vinculo := 0, madrinha := {}, salvar_em := 0) -> Dictionary:
	var c = CarreiraS.new(dd.garota(nome), dd.config_carreira(nome), semente, vinculo, madrinha)
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var log := []
	var guard := 0
	var recarregou := false
	while not c.terminou and guard < 1000:
		guard += 1
		var t0: int = c.turno
		log.append(_passo(c, r))
		_invariantes(c, nome)
		_checar(c.turno >= t0, "%s: turno voltou de %d para %d" % [nome, t0, c.turno])
		if salvar_em > 0 and not recarregou and c.turno >= salvar_em:
			recarregou = true
			c.salvar()
			c = CarreiraS.carregar()
			_checar(c != null, "%s: não carregou o save do turno %d" % [nome, salvar_em])
			if c == null:
				break
	_checar(guard < 1000, "%s (%d): carreira não terminou (turno %d, pendência %s)" % [nome, semente, c.turno, c.pendencia()])
	_checar(c.falhou_objetivo or c.turno > CarreiraS.BAL.turnos, "%s: terminou sem falhar e antes do turno 72" % nome)
	if c.falhou_objetivo:
		_checar(c.resultados[-1].objetivo > 0 and not c.resultados[-1].ok, "%s: falhou sem objetivo perdido" % nome)
	else:
		_checar(c.caminho in ["A", "B"], "%s: chegou ao fim sem caminho" % nome)
		_checar(not c.final_da_campanha().is_empty(), "%s: sem final de campanha" % nome)
	var m: Dictionary = c.moeda_total()
	_checar(m.total == m.corridas + m.bonus and m.total > 0, "%s: moeda inválida" % nome)
	var v: Dictionary = c.versao_salva()
	_checar(v.attrs.size() == 5 and v.nota != "", "%s: versão salva inválida" % nome)
	return {"log": log, "resultados": str(c.resultados), "attrs": str(c.attrs), "turno": c.turno, "c": c}


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_carreira_bot.json"
	dd = root.get_node("Dados")
	if dd.garotas.is_empty():
		dd._ready()
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 1
	var t_ini := Time.get_ticks_msec()
	var finais := 0
	var carreiras := 0
	# as 6 do MVP e 6 do modelo (arquétipos), com conta nova e madura
	var nomes: Array = dd.iniciais.map(func(i): return i.nome)
	for i in range(6, 48, 7):
		nomes.append(dd.garotas[i].nome)
	var madrinha := {"nome": "Madrinha", "attrs": {"vel": 760, "est": 700, "pod": 700, "det": 660, "int": 680},
		"dist": "media", "piso": "terra"}
	for nome in nomes:
		for s in n:
			var semente: int = 1 + absi(hash([nome, s])) % 100000
			var madura: bool = s % 2 == 1
			var res := _jogar(nome, semente, 3 if madura else 0, madrinha if madura else {})
			carreiras += 1
			if not res.c.falhou_objetivo:
				finais += 1
	# carreira forte, para garantir que algumas chegam ao fim (caminho, final, turno 72)
	for s in 3:
		var c = CarreiraS.new(dd.garota("Mira"), dd.config_carreira("Mira"), 500 + s)
		for k in c.attrs:
			c.attrs[k] = 900.0
		c.limite = 1200.0
		var r := RandomNumberGenerator.new()
		r.seed = s
		var guard := 0
		while not c.terminou and guard < 1000:
			guard += 1
			# sempre a instrução e o caminho mais seguros, para ela ir longe
			if c.pendencia() == "" and c.energia < 50:
				c.descansar()
			else:
				_passo(c, r)
			for k in c.attrs:
				c.attrs[k] = maxf(c.attrs[k], 900.0)
		carreiras += 1
		if not c.falhou_objetivo:
			finais += 1
	_checar(finais > 0, "nenhuma carreira chegou ao fim")

	# determinismo: mesma semente e mesmas escolhas, com e sem save no meio
	for nome in ["Lira", nomes[-1]]:
		var a := _jogar(nome, 4242)
		var b := _jogar(nome, 4242)
		_checar(a.log == b.log and a.resultados == b.resultados and a.attrs == b.attrs, "%s: mesma semente, carreiras diferentes" % nome)
		var meio: int = clampi(a.turno / 2, 2, 40)
		var d := _jogar(nome, 4242, 0, {}, meio)
		_checar(a.log == d.log and a.resultados == d.resultados and a.attrs == d.attrs,
			"%s: salvar e carregar no turno %d mudou a carreira" % [nome, meio])
	CarreiraS.apagar_save()

	print("CARREIRA %s  (%d carreiras, %d chegaram ao fim, %.1f s)" % [
		"OK" if falhas.is_empty() else "FALHOU: " + "; ".join(falhas), carreiras, finais,
		(Time.get_ticks_msec() - t_ini) / 1000.0])
	quit(0 if falhas.is_empty() else 1)
