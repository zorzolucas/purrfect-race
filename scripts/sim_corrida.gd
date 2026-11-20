class_name SimCorrida
extends RefCounted
## Simulação da corrida, port de tools/sim_corrida.py e visualizador/sim.js.
## A referência das fórmulas é docs/corrida.md (§2–§7). Se mudar uma constante lá,
## mude aqui também. Não depende de tela: roda headless (ver testes/teste_sim.gd).

const V0 := 20.0
const A0 := 0.35
const DT := 0.1
const DT_ESTIMATIVA := 0.25
const K_VEL := 1.2
const K_HP_D := 0.6
const K_HP := 1.5
const K_INT_FINAL := 1.5
const K_DET_SPRINT := 7.0
const K_DET_FINAL := 2.0
const K_HP_SPRINT := 3.0
const BLOCK := 0.015
const SORTE := 0.025
const ESCALA := 0.66
const TETO := [60.0, 65.0]  # km/h com Vel 0 e Vel 1200

const KEYS := ["vel", "est", "pod", "det", "int"]
## Instrução pré-corrida (GDD §5.7): multiplicador do ritmo na Largada e no Meio (fases 0 e 1),
## no Sprint (fase 3) e do gasto de fôlego. Calibrado com testes/instrucao.gd: Forçar rende nas
## corridas curtas, Normal na Média e Poupar na Longa ou com pouca Estamina. (inicial)
static var INSTRUCAO := {
	"poupar": {"ritmo": 0.99, "sprint": 1.04, "folego": 0.94},
	"normal": {"ritmo": 1.0, "sprint": 1.0, "folego": 1.0},
	"forcar": {"ritmo": 1.015, "sprint": 1.0, "folego": 1.12},
}
const INSTRUCAO_NOME := {"poupar": "Poupar", "normal": "Normal", "forcar": "Forçar"}
const PESOS := {
	"pon": {"vel": 1.0, "est": 1.0, "pod": 0.95, "det": 0.95, "int": 1.1},
	"per": {"vel": 1.0, "est": 1.0, "pod": 1.0, "det": 1.0, "int": 1.0},
	"arr": {"vel": 1.0, "est": 1.0, "pod": 1.1, "det": 1.0, "int": 0.9},
	"fec": {"vel": 1.0, "est": 1.0, "pod": 1.05, "det": 1.1, "int": 0.85},
}
const RITMO := {
	"pon": [0.9943, 0.9694, 0.9843, 0.9893],
	"per": [0.9877, 0.9678, 0.9927, 0.9977],
	"arr": [0.9710, 0.9659, 1.0060, 1.0110],
	"fec": [0.9568, 0.9669, 1.0122, 1.0525],
}
## Correção de estilo por nível e distância (corrida.md §8.5): o RITMO acima foi calibrado nos
## níveis 500 a 1000, mas a carreira passa os 2 primeiros anos entre 200 e 600. Ali a Fechadora
## sobrava na Sprint e na Milha (o teto de velocidade quase não corta o sprint dela) e a Ponteira
## na Média e na Longa (todas ficam sem fôlego, e quem está na frente segura). Cada estilo ganha um
## multiplicador nos atributos, que depende do nível médio do pelotão e da distância (interpolado
## na grade; fora dela vale a borda). Calibrado com testes/ajustar_estilo.gd, que deixa a média
## entre a vitória e o top 3 de cada estilo em 25% em cada célula.
static var CORRECAO_ESTILO := {
	"niveis": [200.0, 300.0, 375.0, 450.0, 525.0, 600.0, 700.0, 800.0, 1000.0],
	"dists": [1200.0, 1600.0, 2000.0, 2400.0, 3200.0],
	"pon": [[1.0132, 0.9964, 0.9834, 0.9762, 0.9688], [1.0189, 0.9989, 0.9913, 0.9793, 0.9694], [1.0465, 1.0011, 0.9879, 0.9782, 0.9615], [1.0454, 1.0043, 0.9844, 0.9784, 0.9718], [1.0229, 1.0164, 0.9816, 0.9740, 0.9700], [1.0117, 1.0189, 0.9838, 0.9767, 0.9731], [0.9980, 1.0159, 0.9910, 0.9722, 0.9723], [0.9989, 1.0038, 0.9938, 0.9755, 0.9673], [1.0111, 1.0034, 1.0001, 1.0027, 0.9660]],
	"per": [[1.0157, 1.0073, 0.9886, 0.9871, 0.9856], [1.0099, 1.0046, 1.0028, 0.9883, 0.9880], [1.0128, 1.0004, 0.9993, 0.9980, 0.9897], [1.0118, 0.9988, 0.9980, 0.9961, 0.9902], [1.0064, 1.0016, 0.9951, 0.9989, 0.9903], [0.9948, 0.9982, 0.9958, 0.9926, 0.9916], [0.9927, 0.9881, 0.9908, 0.9936, 0.9917], [0.9893, 0.9923, 0.9905, 0.9876, 0.9905], [0.9959, 0.9936, 0.9939, 0.9897, 0.9896]],
	"arr": [[1.0130, 1.0143, 1.0109, 1.0120, 1.0195], [1.0034, 1.0135, 1.0123, 1.0156, 1.0175], [0.9985, 1.0085, 1.0148, 1.0179, 1.0191], [0.9915, 1.0080, 1.0150, 1.0168, 1.0149], [0.9939, 0.9980, 1.0143, 1.0182, 1.0140], [0.9736, 0.9954, 1.0145, 1.0189, 1.0141], [0.9832, 0.9926, 1.0081, 1.0180, 1.0155], [0.9911, 0.9968, 1.0034, 1.0153, 1.0190], [0.9790, 0.9912, 0.9970, 1.0015, 1.0192]],
	"fec": [[0.9581, 0.9820, 1.0172, 1.0248, 1.0261], [0.9678, 0.9830, 0.9935, 1.0167, 1.0251], [0.9422, 0.9901, 0.9980, 1.0059, 1.0298], [0.9512, 0.9889, 1.0026, 1.0088, 1.0231], [0.9768, 0.9839, 1.0090, 1.0090, 1.0258], [1.0198, 0.9875, 1.0059, 1.0119, 1.0211], [1.0261, 1.0034, 1.0100, 1.0162, 1.0205], [1.0207, 1.0071, 1.0123, 1.0216, 1.0232], [1.0140, 1.0118, 1.0089, 1.0062, 1.0252]],
}


## Fôlego do pelotão (corrida.md §6): acima de `nivel`, cada ponto que o pelotão sobe na média
## tira `fracao` ponto da Estamina que conta no fôlego de todas, porque um pelotão forte corre num
## ritmo que cansa mais. Sem isso, a partir do nível ~550 o fôlego nunca acabava, a Estamina não
## mudava nenhuma colocação e a Velocidade valia mais que tudo (endgame.md §5.2). Com fracao 1,0,
## uma garota com a Estamina igual à média do pelotão tem o mesmo fôlego em qualquer nível acima
## de `nivel`, e quem tem Estamina acima do pelotão continua com a vantagem de antes.
static var FOLEGO_PELOTAO := {"nivel": 350.0, "fracao": 1.0}


## Quanto da Estamina não conta no fôlego num pelotão de nível médio `nivel`.
static func desconto_folego(nivel: float) -> float:
	return float(FOLEGO_PELOTAO.fracao) * maxf(0.0, nivel - float(FOLEGO_PELOTAO.nivel))


## Interpola linearmente numa grade crescente: [índice de baixo, peso do de cima].
static func _na_grade(grade: Array, x: float) -> Array:
	if x <= grade[0]:
		return [0, 0.0]
	for i in range(grade.size() - 1):
		if x <= grade[i + 1]:
			return [i, (x - grade[i]) / (grade[i + 1] - grade[i])]
	return [grade.size() - 2, 1.0]


## Multiplicador de estilo para um pelotão de nível médio `nivel` (atributos crus) em `dist` metros.
static func correcao_estilo(estilo: String, nivel: float, dist: float) -> float:
	var t: Dictionary = CORRECAO_ESTILO
	if not t.has(estilo):
		return 1.0
	var a := _na_grade(t.niveis, nivel)
	var b := _na_grade(t.dists, dist)
	var m: Array = t[estilo]
	var i: int = a[0]
	var j: int = b[0]
	var baixo: float = lerpf(m[i][j], m[i][j + 1], b[1])
	var cima: float = lerpf(m[i + 1][j], m[i + 1][j + 1], b[1])
	return lerpf(baixo, cima, a[1])


## Habilidades genéricas de referência (corrida.md §7): [fase, tipo, valor, duração s].
const GENERICAS := [
	[1, "hp", 0.06, 0.0, "Fôlego Extra"],
	[1, "vel", 0.8, 4.0, "Passada Firme"],
	[2, "vel", 0.8, 4.0, "Curva Limpa"],
	[2, "hp", 0.04, 0.0, "Segundo Fôlego"],
	[3, "vel", 1.0, 4.0, "Reta Decisiva"],
]
## Habilidades únicas das iniciais, simplificadas para o protótipo (elenco.md).
## Cada uma tem a fase em que é testada e uma condição de posição.
const UNICAS := {
	"chama": {"nome": "Chama da Largada", "fase": 0, "val": 1.2, "dur": 6.0},
	"leitura": {"nome": "Leitura de Corrida", "fase": 2, "val": 1.2, "dur": 6.0},
	"vento": {"nome": "Vento de Cauda", "fase": 3, "val": 1.0, "dur": 5.0},
	"holofote": {"nome": "Holofote", "fase": 2, "val": 1.1, "dur": 6.0},
	"explosiva": {"nome": "Largada Explosiva", "fase": 0, "val": 1.6, "dur": 4.0},
	"nunca": {"nome": "Nunca Desisto", "fase": 3, "val": 1.2, "dur": 6.0},
}

## As 5 genéricas de referência no formato de habilidade, usadas por quem não tem lista própria.
static var REFERENCIA: Array = GENERICAS.map(func(s): return {"fase": s[0], "tipo": s[1], "val": s[2], "dur": s[3], "nome": s[4]})

var D: float
var t := 0.0
var done := false
var rs: Array = []
var rng := RandomNumberGenerator.new()
var ordem_meio: Array = []  # classificação quando a corredora 0 passa da metade (vitória de virada)
## Clima (calendario.md §4.4): chuva tira 15% da aceleração e aumenta o bloqueio em 50%;
## calor tira 2% do fôlego. Os outros climas não mexem na corrida.
var mult_acel := 1.0
var mult_bloqueio := 1.0
## Modo estimativa (olheiro, calendario.md §7.3): sem sorte, sem bloqueio e com cada habilidade
## aplicada pela chance dela (valor esperado), num passo maior. Uma rodada só dá o tempo
## "esperado" de cada uma; a Carreira sorteia a sorte por cima (Carreira.olheiro).
var estimativa := false
var dt := DT


## field: lista de Dictionary {nome, estilo, attrs: {vel..int}, mult, unica?, habilidades?, amuletos?}.
## habilidades: lista de {nome, fase, tipo, val, dur, cond?} (data/habilidades.json). Sem ela,
## a corredora usa as 5 genéricas de referência. amuletos: efeitos de corrida da jogadora
## ("lenco", "espora", "bussola", "trevo"; calendario.md §5.2).
func _init(field: Array, distancia: float, seed: int = 0, clima: String = "", estimativa_: bool = false) -> void:
	D = distancia
	estimativa = estimativa_
	if estimativa:
		dt = DT_ESTIMATIVA
	if clima == "chuva":
		mult_acel = 0.85
		mult_bloqueio = 1.5
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	var k := ESCALA
	var nivel := 0.0
	for g in field:
		for key in KEYS:
			nivel += float(g.attrs[key])
	nivel /= maxf(1.0, 5.0 * field.size())
	var desconto := desconto_folego(nivel)
	for idx in field.size():
		var g: Dictionary = field[idx]
		var st: String = g.estilo
		var corr := correcao_estilo(st, nivel, D)
		var e := {}
		for key in KEYS:
			e[key] = float(g.attrs[key]) * PESOS[st][key] * float(g.get("mult", 1.0)) * corr
		var hpmax: float = (K_HP_D * D + K_HP * maxf(e.est - desconto, 0.0)) * (0.98 if clima == "calor" else 1.0)
		var noise := 0.0 if estimativa else rng.randfn(0.0, SORTE * (1.0 - e.int / 2400.0))
		var chance := minf(0.9, e.int / 1000.0)
		var vmax: float = (TETO[0] + (TETO[1] - TETO[0]) * clampf(e.vel, 0.0, 1200.0) / 1200.0) / 3.6
		rs.append({
			"idx": idx, "st": st, "e": e, "hp": hpmax, "hpmax": hpmax, "vmax": vmax,
			"v": 3.0 * k, "x": 0.0, "t": -1.0, "blk": 0.0, "noise": noise,
			"chance": chance, "ph": -1, "buff": 0.0, "buff_t": 0.0,
			"unica": g.get("unica", ""),
			"skills": g.get("habilidades", REFERENCIA),
			"amuletos": g.get("amuletos", []),
			"ins": INSTRUCAO[g.get("instrucao", "normal")],
		})


## Condição de uma habilidade: posição (pos 0 = 1º lugar) ou distância mínima.
func _condicao_ok(cond: Dictionary, pos: int) -> bool:
	if cond.has("pos_max") and pos + 1 > int(cond.pos_max):
		return false
	if cond.has("pos_min") and pos + 1 < int(cond.pos_min):
		return false
	if cond.has("dist_min") and D < float(cond.dist_min):
		return false
	return true


static func fase(x: float, dist: float) -> int:
	if x < dist / 6.0:
		return 0
	if x < 0.6 * dist:
		return 1
	if x < dist - 400.0:
		return 2
	return 3


func _por_posicao() -> Array:
	var order := rs.duplicate()
	order.sort_custom(func(a, b): return a.x > b.x)
	return order


func _tenta_unica(r: Dictionary, p: int, pos: int, n: int, ev: Array) -> void:
	if r.unica == "" or not UNICAS.has(r.unica):
		return
	var u: Dictionary = UNICAS[r.unica]
	if u.fase != p:
		return
	var ok := false
	var val: float = u.val
	match r.unica:
		"chama": ok = pos == 0
		"leitura": ok = pos >= 1 and pos <= 3
		"vento":
			ok = pos >= n / 2
			val += 0.1 * pos
		"holofote": ok = pos >= 2           # precisa ter quem passar
		"explosiva": ok = true
		"nunca": ok = r.hp < 0.3 * r.hpmax
	var chance := minf(0.95, r.chance + 0.2)
	if estimativa and ok:
		val *= chance  # valor esperado
	if ok and (estimativa or rng.randf() < chance):
		r.buff = val * ESCALA
		r.buff_t = u.dur / ESCALA
		if r.unica == "explosiva" and D <= 1400.0:
			r.buff_t *= 1.5  # na Sprint o efeito dura mais
		ev.append({"idx": r.idx, "nome": u.nome, "unica": true})


## Avança um passo de DT. Retorna as habilidades disparadas: [{idx, nome, unica}].
func step() -> Array:
	var ev := []
	t += dt
	var k := ESCALA
	var v0 := V0 * k
	var order := _por_posicao()
	for i in order.size():
		var r: Dictionary = order[i]
		if r.t >= 0.0:
			continue
		var e: Dictionary = r.e
		var p := fase(r.x, D)
		if p != r.ph:
			r.ph = p
			for s in r.skills:
				if int(s.fase) != p or not _condicao_ok(s.get("cond", {}), i):
					continue
				var chance: float = r.chance
				if p == 2 and "trevo" in r.amuletos:
					chance += 0.15
				var forca := 1.0
				if estimativa:
					forca = minf(1.0, chance)  # valor esperado
				if estimativa or rng.randf() < chance:
					if s.tipo == "hp":
						r.hp += float(s.val) * forca * r.hpmax
					else:
						r.buff = float(s.val) * forca * k
						r.buff_t = float(s.dur) / k
					ev.append({"idx": r.idx, "nome": s.nome, "unica": false})
			_tenta_unica(r, p, i, order.size(), ev)
		var ins: Dictionary = r.ins
		var ritmo: float = RITMO[r.st][p] * (ins.ritmo if p <= 1 else (ins.sprint if p == 3 else 1.0))
		var vt: float = (V0 + K_VEL * e.vel / 1000.0) * k * ritmo * (1.0 + r.noise)
		if p == 2:
			vt += k * (K_DET_FINAL * e.det + K_INT_FINAL * e.int) / 1000.0
		if p == 3:
			var hp := maxf(r.hp, 0.0)
			var bonus: float = k * (K_DET_SPRINT * e.det / 1000.0 + K_HP_SPRINT * hp / r.hpmax)
			var vf := vt + bonus
			var need: float = 20.0 * k * pow(vf / v0, 2) * (1.1 - e.det / 2000.0) * (D - r.x) / vf
			vt += bonus * minf(1.0, hp / need)
		if r.hp <= 0.0:
			vt = v0 * (0.80 + 0.15 * e.det / 1000.0)
		if r.buff_t > 0.0:
			vt += r.buff
			r.buff_t -= dt
		if p == 0 and i < 3 and "lenco" in r.amuletos:
			vt *= 1.05
		if i > 0 and p >= 1:
			var f: Dictionary = order[i - 1]
			var gap: float = f.x - r.x
			if gap > 0.0 and gap < 2.0 and f.v < vt and r.blk <= 0.0 and not estimativa:
				var bloq: float = k * BLOCK * mult_bloqueio * (1.0 - e.pod / 1500.0) * (1.0 - e.int / 2000.0)
				if "bussola" in r.amuletos:
					bloq *= 0.7
				if rng.randf() < bloq:
					r.blk = 1.0 / k
			if r.blk > 0.0:
				vt = minf(vt, f.v)
				r.blk -= dt
		vt = minf(vt, r.vmax)
		var a: float = A0 * k * k * (0.8 + e.pod / 1000.0) * (5.0 if p == 0 else 1.0) * mult_acel
		if r.v < vt:
			r.v = minf(vt, r.v + a * dt)
		else:
			r.v = maxf(vt, r.v - 0.8 * k * k * dt)
		var cost: float = 20.0 * k * pow(r.v / v0, 2) * ins.folego
		if p == 1:
			cost *= 1.2 - e.int / 1500.0
		if p == 3:
			cost *= 1.1 - e.det / 2000.0
			if "espora" in r.amuletos:
				cost *= 0.9
		r.hp -= cost * dt
		var x0: float = r.x
		r.x += r.v * dt
		if r.x >= D:
			# interpola o instante exato da chegada (importa no passo maior da estimativa)
			r.t = t - dt + dt * (D - x0) / maxf(0.001, r.x - x0)
	done = rs.all(func(r): return r.t >= 0.0)
	if ordem_meio.is_empty() and rs[0].x >= D * 0.5:
		ordem_meio = classificacao()
	return ev


## Ordem atual: chegadas primeiro (por tempo), depois quem ainda corre (por distância).
func classificacao() -> Array:
	var order := rs.duplicate()
	order.sort_custom(func(a, b):
		if a.t >= 0.0 and b.t >= 0.0:
			return a.t < b.t
		if a.t >= 0.0 or b.t >= 0.0:
			return a.t >= 0.0
		return a.x > b.x)
	return order.map(func(r): return r.idx)


func rodar_ate_o_fim() -> Array:
	while not done:
		step()
	return classificacao()
