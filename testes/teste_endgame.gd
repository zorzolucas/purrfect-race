extends SceneTree
## Endgame (docs/campanhas.md §2.3): Magnitude, Desafio da semana e Circuito em níveis.
## Uso: Godot --headless --path . --script res://testes/teste_endgame.gd
# Carregados em tempo de execução: no modo --script, os autoloads (Dados) só existem
# depois que este script compila.
var CarreiraS: GDScript
var PerfilS: GDScript
var EndgameS: GDScript
var dd: Node
var falhas := []


func _conferir(ok: bool, msg: String) -> void:
	if not ok:
		falhas.append(msg)


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	PerfilS = load("res://scripts/perfil.gd")
	EndgameS = load("res://scripts/endgame.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_endgame_carreira.json"
	PerfilS.CAMINHO = "user://teste_endgame_perfil.json"
	dd = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	_magnitude()
	_desafio()
	_perfil_magnitude_e_desafio()
	_circuito()
	CarreiraS.apagar_save()
	PerfilS.apagar()
	if falhas.is_empty():
		print("ENDGAME OK")
	else:
		for f in falhas:
			print("FALHOU: ", f)
	quit(0 if falhas.is_empty() else 1)


func _carreira(mag: int, semente := 77, opcoes := {}):
	var op := opcoes.duplicate()
	if not op.has("magnitude"):
		op.magnitude = mag
	return CarreiraS.new(dd.garota("Lira"), dd.config_carreira("Lira"), semente, 0, {}, op)


func _magnitude() -> void:
	var m0 = _carreira(0)
	var m3 = _carreira(3)
	var m5 = _carreira(5)
	# metas: top 5 vira top 3, top 3 vira vitória, vitória continua vitória
	for i in m0.objetivos.size():
		var a: int = int(m0.objetivos[i].meta)
		var b: int = int(m3.objetivos[i].meta)
		if a > 1:
			_conferir(b == maxi(1, a - 2), "M3: meta %d deveria virar %d (veio %d)" % [a, maxi(1, a - 2), b])
		else:
			_conferir(b == a, "M3: meta %d não deveria mudar" % a)
	var dois_caminhos_ok := true
	for k in m3.campanha.caminhos:
		for i in m3.campanha.caminhos[k].objetivos.size():
			var a: int = int(m0.campanha.caminhos[k].objetivos[i].meta)
			if a > 1 and int(m3.campanha.caminhos[k].objetivos[i].meta) != maxi(1, a - 2):
				dois_caminhos_ok = false
	_conferir(dois_caminhos_ok, "M3: as metas dos 2 caminhos também sobem")
	# a campanha original (sem magnitude) não pode ter sido mexida
	var m0b = _carreira(0)
	_conferir(str(m0.objetivos) == str(m0b.objetivos), "M3 mexeu na campanha de outra carreira")
	# maldições
	_conferir(m0.maldicoes.is_empty() and _carreira(1).maldicoes.is_empty(), "M0/M1 sem maldição")
	_conferir(_carreira(2).maldicoes.size() == 1, "M2: 1 maldição")
	_conferir(m5.maldicoes.size() == 2 and m5.maldicoes[0] != m5.maldicoes[1], "M5: 2 maldições diferentes")
	# força das NPCs
	_conferir(is_equal_approx(m0.mult_npc(), 1.0) and is_equal_approx(_carreira(1).mult_npc(), 1.05) \
		and is_equal_approx(_carreira(4).mult_npc(), 1.10), "força das NPCs por magnitude")
	m0.turno = 40
	m5.turno = 40
	var cr := {"id": "x", "cat": "ouro", "dist": "milha", "piso": "grama", "nome": "Teste", "rival": "Algol"}
	var p0: Dictionary = m0._pelotao(cr, dd.garotas)
	var p5: Dictionary = m5._pelotao(cr, dd.garotas)
	_conferir(is_equal_approx(p5.forca / p0.forca, 1.10), "M5: pelotão +10%")
	var r0 := _soma(p0.field[p0.rival_idx].attrs)
	var r5 := _soma(p5.field[p5.rival_idx].attrs)
	_conferir(absf(r5 / r0 - 1.10 * 1.25 / 1.15) < 0.001, "M5: rival +25%% em vez de +15%% (razão %.3f)" % (r5 / r0))
	# M5: 1 nó de Recuperação a menos em cada trecho
	for t in m0.mapas.size():
		var a := _contar(m0.mapas[t], "recuperacao")
		var b := _contar(m5.mapas[t], "recuperacao")
		_conferir(b == maxi(0, a - 1), "M5: trecho %d tinha %d Recuperações e ficou com %d" % [t, a, b])
	# moeda +20% por nível
	m3.moeda_corridas = 100
	var mt: Dictionary = m3.moeda_total()
	_conferir(mt.total == roundi((mt.corridas + mt.bonus) * 1.6), "M3: moeda +60%")
	# maldições com efeito
	var mc = _carreira(0)
	mc.maldicoes = ["coleira", "insonia", "torcida", "bolso"]
	mc.energia = 100
	_conferir(is_equal_approx(mc.chance_falha("vel"), 0.05), "Coleira Frouxa: 5% de falha com energia cheia")
	var sem = _carreira(0)
	sem.turno = mc.turno
	_conferir(mc.descanso_previsto() == roundi(sem.descanso_previsto() * 0.85), "Insônia: descanso −15%")
	mc.turno = 30
	sem.turno = 30
	var cp := {"id": "x", "cat": "prata", "dist": "milha", "piso": "grama", "nome": "Teste"}
	var ol: Dictionary = sem.olheiro(cp)
	_conferir(mc.fama_prevista(cp, 1, ol.mult) == roundi(sem.fama_prevista(cp, 1, ol.mult) * 0.8), "Torcida Exigente: fama −20%")
	# Nuvem Carregada: chove mais
	var nuvem = _carreira(0, 5)
	nuvem.maldicoes = ["nuvem"]
	var limpa = _carreira(0, 5)
	var chuvas := [0, 0]
	for t in range(1, 73):
		chuvas[0] += 1 if limpa.clima_em(t) == "chuva" else 0
		chuvas[1] += 1 if nuvem.clima_em(t) == "chuva" else 0
		if limpa.clima_em(t) == "chuva":
			_conferir(nuvem.clima_em(t) == "chuva", "Nuvem Carregada nunca tira uma chuva")
	_conferir(chuvas[1] > chuvas[0], "Nuvem Carregada: mais chuva (%d → %d)" % chuvas)
	# save: as opções voltam e repetem maldições e metas
	m5.salvar()
	var lida = CarreiraS.carregar()
	_conferir(lida != null and lida.magnitude == 5 and str(lida.maldicoes) == str(m5.maldicoes) \
		and str(lida.objetivos) == str(m5.objetivos), "save guarda a magnitude")


func _desafio() -> void:
	var d1: Dictionary = EndgameS.desafio_da_semana(3)
	var d1b: Dictionary = EndgameS.desafio_da_semana(3)
	_conferir(str(d1) == str(d1b), "desafio da semana é determinístico")
	# regras giram sem repetir em semanas seguidas e todas aparecem
	var vistas := {}
	var anterior := ""
	var repetiu := false
	for g in 40:
		var d: Dictionary = EndgameS.desafio_da_semana(g)
		vistas[d.regra.id] = true
		if d.regra.id == anterior:
			repetiu = true
		anterior = d.regra.id
	_conferir(not repetiu, "a regra do desafio não repete em semanas seguidas")
	_conferir(vistas.size() == dd.endgame.desafio.regras.size(), "todas as regras aparecem")
	# regras na carreira
	var chuva = _carreira(0, 9, {"regra": "sempre_chove", "desafio": 1})
	_conferir(range(1, 73).all(func(t): return chuva.clima_em(t) == "chuva"), "Sempre chove")
	var pratas = _carreira(0, 9, {"regra": "so_pratas", "desafio": 1})
	var normal = _carreira(0, 9)
	var achou_outra := false
	var so_prata := true
	for t in range(25, 72):
		pratas.turno = t
		normal.turno = t
		for c in normal.corridas_opcionais():
			if c.cat != "prata":
				achou_outra = true
		for c in pratas.corridas_opcionais():
			if c.cat != "prata":
				so_prata = false
	_conferir(so_prata and achou_outra, "Só Pratas filtra as opcionais")
	_conferir(_carreira(0, 9, {"regra": "poucos_amuletos"}).limite_amuletos() == 2, "Bolsa pequena: 2 amuletos")
	_conferir(_carreira(0, 9, {"regra": "amaldicoada"}).maldicoes.size() == 2, "Lua negra: 2 maldições")
	_conferir(is_equal_approx(_carreira(0, 9, {"regra": "elite"}).mult_npc(), 1.10), "Pelotão de elite: +10%")


func _perfil_magnitude_e_desafio() -> void:
	var p = PerfilS.novo("Lira")
	var c = _carreira(0)
	# simula a vitória no GP final
	c.resultados.append({"turno": 72, "nome": "GP", "cat": "gp3", "posicao": 1, "objetivo": 3, "ok": true, "fama": 0})
	c.terminou = true
	p.concluir_carreira(c, true)
	_conferir(p.magnitude_de("Lira").liberada == 1 and p.magnitude_de("Lira").vencida == 0, "vencer o GP na M0 libera a M1")
	# vencer de novo na M0 não libera a M2
	p.concluir_carreira(c, false)
	_conferir(p.magnitude_de("Lira").liberada == 1, "vencer na M0 de novo não libera a M2")
	var c1 = _carreira(1)
	c1.resultados = c.resultados.duplicate(true)
	p.concluir_carreira(c1, false)
	_conferir(p.magnitude_de("Lira").liberada == 2 and p.magnitude_de("Lira").vencida == 1, "vencer na M1 libera a M2")
	# o save guarda as magnitudes
	var lido = PerfilS.carregar()
	_conferir(lido.magnitude_de("Lira").liberada == 2, "perfil salva as magnitudes")
	# desafio: a moeda vem só na 1ª tentativa, a pool não gira e o recorde fica
	var des: Dictionary = p.desafio_atual()
	var giro_antes: int = p.giro
	var cd = CarreiraS.new(dd.garota(des.garota), dd.config_carreira(des.garota), des.semente, 0, {},
		{"regra": des.regra.id, "desafio": des.semana})
	cd.fama = 500
	var moeda_antes: int = p.moeda
	p.concluir_carreira(cd, false)
	_conferir(p.moeda == moeda_antes + cd.moeda_total().total, "1ª tentativa do desafio paga a moeda")
	_conferir(p.giro == giro_antes, "o desafio não gira a pool")
	cd.fama = 900
	moeda_antes = p.moeda
	p.concluir_carreira(cd, false)
	var reg: Dictionary = p.registro_desafio(des.semana)
	_conferir(p.moeda == moeda_antes, "2ª tentativa do desafio não paga")
	_conferir(reg.tentativas == 2 and int(reg.melhor.fama) == 900, "o desafio guarda o melhor placar")
	_conferir(not p.elenco.has(des.garota) or des.garota == "Lira" or p.elenco[des.garota].salva.is_empty(), "o desafio não guarda versão")


func _circuito() -> void:
	var p = PerfilS.novo("Lira")
	# elenco de teste: 6 garotas salvas fortes, de casas diferentes
	var nomes := ["Altair", "Lira", "Alya", "Mira", "Antares", "Deneb"]
	for n in nomes:
		var g: Dictionary = dd.garota(n)
		var a := {}
		var soma := 0.0
		for k in SimCorrida.KEYS:
			soma += g.atributos[k]
		for k in SimCorrida.KEYS:
			a[k] = roundi(g.atributos[k] * 1100.0 * 5.0 / soma)
		p.elenco[n] = {"vinculo": 5, "salva": {"attrs": a, "nota": "S", "habilidades": [], "estilo": g.estilo}}
	_conferir(p.evento_aberto(0, "sprint") and not p.evento_aberto(1, "sprint"), "só o Bronze começa aberto")
	_conferir(not p.evento_aberto(0, "final"), "o Final começa fechado")
	# condições mudam por rotação, iguais para o mesmo giro
	var c1: Array = EndgameS.condicoes(4, "media")
	_conferir(str(c1) == str(EndgameS.condicoes(4, "media")), "condições determinísticas")
	var mudou := false
	for g in range(5, 15):
		if str(EndgameS.condicoes(g, "media")) != str(c1):
			mudou = true
	_conferir(mudou, "as condições mudam com a rotação")
	# corrida: determinística, pontos coerentes
	var esc := [{"nome": "Altair"}, {"nome": "Antares"}, {"nome": "Lira"}]
	var esc_s := esc.map(func(e): return {"nome": e.nome, "salva": p.elenco[e.nome].salva})
	var r1: Dictionary = EndgameS.correr_evento(0, 0, "sprint", esc_s, 123)
	var r2: Dictionary = EndgameS.correr_evento(0, 0, "sprint", esc_s, 123)
	_conferir(str(r1.corridas.map(func(x): return x.ordem)) == str(r2.corridas.map(func(x): return x.ordem)), "copa determinística")
	var soma_pts := 0
	for x in r1.corridas:
		soma_pts += EndgameS.pontos(x.posicao)
		_conferir(x.ordem.size() == 12, "12 corredoras por corrida")
		var nomes_corrida: Array = x.nomes
		_conferir(nomes_corrida.size() == 12 and nomes_corrida.filter(func(n): return nomes_corrida.count(n) > 1).is_empty(), "sem garota repetida no pelotão")
	_conferir(soma_pts == r1.total, "total de pontos")
	# casas não usam as garotas da jogadora nem repetem
	var usadas := []
	for linha in r1.escalacao_casas:
		usadas.append_array(linha)
	_conferir(usadas.filter(func(n): return n in nomes or usadas.count(n) > 1).is_empty(), "casas sem repetir e sem as da jogadora")
	# progresso: força alta vence o Bronze (garotas 1100 contra NPCs 600)
	var vitorias := 0
	for i in 5:
		var r: Dictionary = p.correr_circuito(0, "sprint", esc)
		if r.venceu:
			vitorias += 1
	_conferir(vitorias >= 4, "garotas 1100 deveriam vencer o Bronze quase sempre (%d/5)" % vitorias)
	var reg: Dictionary = p.registro_circuito(0, "sprint")
	_conferir(reg.vitorias == vitorias and p.evento_aberto(1, "sprint"), "vencer o Bronze abre o Prata")
	# prêmio: cheio na 1ª; a repetição paga 1 vez por rotação (e não na mesma rotação da 1ª)
	var esperado: int = 300 + EndgameS.premio(0, "sprint", true)
	_conferir(p.moeda == esperado, "prêmio da 1ª vitória (moeda %d, esperado %d)" % [p.moeda, esperado])
	p.girar_pool()
	var pagas := 0
	for i in 4:
		var r: Dictionary = p.correr_circuito(0, "sprint", esc)
		if r.venceu:
			pagas += 1 if r.premio > 0 else 0
			esperado += r.premio
	_conferir(pagas == 1 and p.moeda == 300 + EndgameS.premio(0, "sprint", true) + EndgameS.premio(0, "sprint", false),
		"repetição paga só 1 vez na rotação nova (moeda %d)" % p.moeda)
	# Final abre com as 5 copas do nível
	for ev in EndgameS.eventos():
		if ev.id != "final":
			p.circuito[EndgameS.chave(0, ev.id)] = {"vitorias": 1, "melhor": 30, "giro_premio": 0}
	_conferir(p.evento_aberto(0, "final") and not p.evento_aberto(1, "final"), "o Final Bronze abre com as 5 copas Bronze")
	# escalação repetida é recusada pela tela (aqui, a sugestão nunca repete)
	var sug: Array = load("res://scripts/tela_circuito.gd").sugerir(p, 0, "final")
	var ns := sug.map(func(e): return e.nome)
	_conferir(ns.size() == 5 and ns.filter(func(n): return ns.count(n) > 1).is_empty(), "sugestão do Final com 5 garotas diferentes")


func _soma(a: Dictionary) -> float:
	var s := 0.0
	for k in a:
		s += float(a[k])
	return s


func _contar(mapa: Array, tipo: String) -> int:
	var n := 0
	for linha in mapa:
		for no in linha:
			if no.tipo == tipo:
				n += 1
	return n
