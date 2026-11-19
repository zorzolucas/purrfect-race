extends SceneTree
## Testa a simulação da corrida (scripts/sim_corrida.gd) sem tela: mesma semente dá o mesmo
## resultado, todas chegam, a classificação é válida, quem é mais forte vence mais, a chuva
## deixa a corrida mais lenta e o modo estimativa (olheiro) é determinístico.
## Uso: Godot --headless --path . --script res://testes/teste_sim.gd
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _corredora(nome: String, estilo: String, media: float, extra := {}) -> Dictionary:
	var a := {}
	for k in SimCorrida.KEYS:
		a[k] = media
	var g := {"nome": nome, "estilo": estilo, "attrs": a, "mult": 1.0}
	g.merge(extra, true)
	return g


func _pelotao(media_0: float, media_resto: float) -> Array:
	var estilos := ["pon", "per", "arr", "fec"]
	var field := [_corredora("J", "per", media_0)]
	for i in 11:
		field.append(_corredora("N%d" % i, estilos[i % 4], media_resto))
	return field


func _tempos(sim: SimCorrida) -> Array:
	return sim.rs.map(func(r): return snappedf(r.t, 0.0001))


func _initialize() -> void:
	# 1. determinismo: mesma semente, mesma chegada
	for dist in [1200.0, 2000.0, 3200.0]:
		var a := SimCorrida.new(_pelotao(500, 500), dist, 77)
		var b := SimCorrida.new(_pelotao(500, 500), dist, 77)
		var oa := a.rodar_ate_o_fim()
		var ob := b.rodar_ate_o_fim()
		_checar(oa == ob, "mesma semente, ordem diferente (%d m)" % dist)
		_checar(_tempos(a) == _tempos(b), "mesma semente, tempos diferentes (%d m)" % dist)

	# 2. todas chegam, a classificação é uma permutação e segue os tempos
	for s in 20:
		var sim := SimCorrida.new(_pelotao(400 + 20 * s, 500), 1600.0 + 100 * (s % 5), s + 1)
		var passos := 0
		while not sim.done and passos < 20000:
			sim.step()
			passos += 1
		_checar(sim.done, "corrida %d não terminou" % s)
		var ordem := sim.classificacao()
		var ids := ordem.duplicate()
		ids.sort()
		_checar(ids == range(12), "classificação não é permutação: %s" % [ordem])
		for i in range(1, ordem.size()):
			_checar(sim.rs[ordem[i - 1]].t <= sim.rs[ordem[i]].t, "classificação fora da ordem dos tempos")
		for r in sim.rs:
			_checar(r.t > 0.0 and r.t < 400.0, "tempo absurdo: %s" % r.t)
		_checar(not sim.ordem_meio.is_empty(), "sem classificação da metade")

	# 3. força: com +150 de média ela vence muito mais que 1 em 12 (a sorte pesa, então a margem é larga)
	var vit := 0
	for s in 40:
		var sim := SimCorrida.new(_pelotao(650, 500), 2000.0, 1000 + s)
		if sim.rodar_ate_o_fim()[0] == 0:
			vit += 1
	_checar(vit >= 16, "a mais forte venceu só %d de 40" % vit)
	var vit_fraca := 0
	for s in 40:
		var sim := SimCorrida.new(_pelotao(350, 500), 2000.0, 2000 + s)
		if sim.rodar_ate_o_fim()[0] == 0:
			vit_fraca += 1
	_checar(vit_fraca <= 2, "a mais fraca venceu %d de 40" % vit_fraca)

	# 4. clima: na chuva, a média dos tempos sobe
	var seco := 0.0
	var chuva := 0.0
	for s in 10:
		var a := SimCorrida.new(_pelotao(500, 500), 2000.0, 3000 + s)
		a.rodar_ate_o_fim()
		var b := SimCorrida.new(_pelotao(500, 500), 2000.0, 3000 + s, "chuva")
		b.rodar_ate_o_fim()
		for r in a.rs:
			seco += r.t
		for r in b.rs:
			chuva += r.t
	_checar(chuva > seco, "chuva não deixou a corrida mais lenta (%.1f x %.1f)" % [chuva, seco])

	# 5. estimativa: sem sorte, não depende da semente, e o tempo fica perto do da simulação real
	var e1 := SimCorrida.new(_pelotao(520, 500), 2000.0, 1, "", true)
	var e2 := SimCorrida.new(_pelotao(520, 500), 2000.0, 999, "", true)
	e1.rodar_ate_o_fim()
	e2.rodar_ate_o_fim()
	_checar(_tempos(e1) == _tempos(e2), "estimativa depende da semente")
	var real := 0.0
	for s in 20:
		var sim := SimCorrida.new(_pelotao(520, 500), 2000.0, 4000 + s)
		sim.rodar_ate_o_fim()
		real += sim.rs[0].t
	real /= 20.0
	_checar(absf(e1.rs[0].t - real) / real < 0.02, "estimativa longe da média real: %.2f x %.2f" % [e1.rs[0].t, real])

	# 6. instrução e habilidades: a corredora aceita instrucao, habilidades próprias e amuletos
	var field := _pelotao(500, 500)
	field[0].instrucao = "forcar"
	field[0].habilidades = []
	field[0].amuletos = ["lenco", "espora", "bussola", "trevo"]
	field[0].unica = "chama"
	var sim := SimCorrida.new(field, 1600.0, 5)
	_checar(sim.rs[0].ins == SimCorrida.INSTRUCAO.forcar, "instrução não aplicada")
	_checar(sim.rodar_ate_o_fim().size() == 12, "corrida com amuletos não terminou")

	print("SIM OK" if falhas.is_empty() else "SIM FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
