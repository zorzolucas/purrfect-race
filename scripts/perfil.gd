class_name Perfil
extends RefCounted
## Progresso que passa de uma carreira para outra: moeda, elenco (vínculo e versão salva
## de cada garota) e a pool semanal (GDD §2, §3.5, §4.8 e §6). Salvo em user://perfil.json.

## Os testes trocam o caminho para não mexer no perfil de verdade.
static var CAMINHO := "user://perfil.json"
const BAL := {
	"moeda_inicial": 300,      # dá para 3 tiragens no começo (GDD §8)
	"custo_tiragem": 100,
	"garantia": 10,            # tiragens sem a escolhida até ela vir garantida
	"tamanho_pool": 5,
	"mvp_na_pool": 2,          # quantas garotas completas (com eventos) entram em cada rotação
	"vinculo_max": 5,
}

var moeda := 0
var elenco := {}             # nome -> {vinculo: int, salva: Dictionary (vazio se ainda não correu)}
var pool := []               # nomes da rotação atual
var escolhida := ""          # garota marcada para a garantia
var sem_escolhida := 0       # tiragens seguidas sem a escolhida
var giro := 0                # quantas vezes a pool girou (= carreiras concluídas)
var semente := 0
var tiragens := 0
# endgame (docs/campanhas.md §2.3)
var magnitudes := {}         # nome -> {liberada: maior magnitude que pode escolher, vencida: maior com o GP final vencido (-1 = nenhuma)}
var circuito := {}           # "nivel:evento" -> {vitorias, melhor (pontos), giro_premio (rotação do último prêmio), giro_tentativas e tentativas (nesta rotação)}
var tentativas_circuito := 0
var desafios := {}           # semana (texto) -> {tentativas, melhor: placar, pago: bool}


static func existe() -> bool:
	return FileAccess.file_exists(CAMINHO)


static func novo(inicial: String) -> Perfil:
	var p := Perfil.new()
	p.semente = randi()
	p.moeda = BAL.moeda_inicial
	p.elenco[inicial] = {"vinculo": 0, "salva": {}}
	p.girar_pool(false)
	p.salvar()
	return p


static func carregar() -> Perfil:
	if not existe():
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(CAMINHO))
	if not d is Dictionary:
		return null
	var p := Perfil.new()
	p.moeda = int(d.get("moeda", 0))
	# saves antigos usavam nome e sobrenome ("Lira Alazã"); hoje é só o nome
	var elenco: Dictionary = d.get("elenco", {})
	for n in elenco:
		p.elenco[n.split(" ")[0]] = elenco[n]
	for n in p.elenco:
		p.elenco[n].vinculo = int(p.elenco[n].vinculo)
	p.pool = d.get("pool", []).map(func(n): return n.split(" ")[0])
	p.escolhida = d.get("escolhida", "").split(" ")[0]
	p.sem_escolhida = int(d.get("sem_escolhida", 0))
	p.giro = int(d.get("giro", 0))
	p.semente = int(str(d.get("semente", "0")))
	p.tiragens = int(d.get("tiragens", 0))
	var mags: Dictionary = d.get("magnitudes", {})
	for n in mags:
		p.magnitudes[n] = {"liberada": int(mags[n].get("liberada", 0)), "vencida": int(mags[n].get("vencida", -1))}
	var circ: Dictionary = d.get("circuito", {})
	for k in circ:
		p.circuito[k] = {"vitorias": int(circ[k].get("vitorias", 0)), "melhor": int(circ[k].get("melhor", 0)),
			"giro_premio": int(circ[k].get("giro_premio", -1)), "giro_tentativas": int(circ[k].get("giro_tentativas", -1)),
			"tentativas": int(circ[k].get("tentativas", 0))}
	p.tentativas_circuito = int(d.get("tentativas_circuito", 0))
	var des: Dictionary = d.get("desafios", {})
	for k in des:
		p.desafios[k] = {"tentativas": int(des[k].get("tentativas", 0)), "melhor": des[k].get("melhor", {}),
			"pago": bool(des[k].get("pago", false))}
	return p


func salvar() -> void:
	var d := {"versao": 1, "moeda": moeda, "elenco": elenco, "pool": pool, "escolhida": escolhida,
		"sem_escolhida": sem_escolhida, "giro": giro, "semente": str(semente), "tiragens": tiragens,
		"magnitudes": magnitudes, "circuito": circuito, "tentativas_circuito": tentativas_circuito,
		"desafios": desafios}
	var f := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  ", false))


static func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO))


func _dados() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Dados")


# ---------- pool (GDD §6) ----------

## Sorteia a rotação nova: algumas garotas completas do MVP e o resto do elenco só-dados.
## A semana gira a cada carreira concluída, não pelo relógio real.
func girar_pool(contar := true) -> void:
	if contar:
		giro += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([semente, giro])
	var dados := _dados()
	var mvp := []
	var outras := []
	for g in dados.garotas:
		(mvp if g.get("mvp", false) else outras).append(g.nome)
	var nova := []
	for lista in [[mvp, BAL.mvp_na_pool], [outras, BAL.tamanho_pool - BAL.mvp_na_pool]]:
		var nomes: Array = lista[0].duplicate()
		for i in lista[1]:
			if nomes.is_empty():
				break
			nova.append(nomes.pop_at(rng.randi() % nomes.size()))
	pool = nova
	if not escolhida in pool:
		escolhida = pool[0]
		sem_escolhida = 0


func escolher(nome: String) -> void:
	if nome in pool and nome != escolhida:
		escolhida = nome
		sem_escolhida = 0
		salvar()


## Chances visíveis (GDD §6): todas iguais.
func chance(_nome: String) -> float:
	return 1.0 / max(1, pool.size())


func faltam_para_garantia() -> int:
	return BAL.garantia - sem_escolhida


func pode_tirar() -> bool:
	return moeda >= BAL.custo_tiragem and not pool.is_empty()


## Uma tiragem. Devolve {nome, nova: bool, vinculo, garantida: bool, vinculo_max: bool}.
func tirar() -> Dictionary:
	if not pode_tirar():
		return {}
	moeda -= BAL.custo_tiragem
	tiragens += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([semente, giro, tiragens])
	var garantida := sem_escolhida + 1 >= BAL.garantia
	var nome: String = escolhida if garantida else pool[rng.randi() % pool.size()]
	if nome == escolhida:
		sem_escolhida = 0
	else:
		sem_escolhida += 1
	var r := {"nome": nome, "garantida": garantida, "nova": false, "vinculo_max": false}
	if not elenco.has(nome):
		elenco[nome] = {"vinculo": 0, "salva": {}}
		r.nova = true
	elif elenco[nome].vinculo < BAL.vinculo_max:
		elenco[nome].vinculo += 1
	else:
		# vínculo já no máximo: devolve metade da moeda
		moeda += BAL.custo_tiragem / 2
		r.vinculo_max = true
	r.vinculo = elenco[nome].vinculo
	salvar()
	return r


# ---------- fim de carreira (GDD §4.8) ----------

## Recebe a moeda da carreira, guarda (ou não) a nova versão, libera a próxima magnitude
## (vencendo o GP final na maior liberada) e gira a pool. O desafio da semana tem regras próprias.
func concluir_carreira(c: Carreira, substituir: bool) -> void:
	if c.desafio > 0:
		concluir_desafio(c)
		return
	moeda += c.moeda_total().total
	if substituir and elenco.has(c.nome):
		elenco[c.nome].salva = c.versao_salva()
	if c.venceu_gp():
		var m := magnitude_de(c.nome)
		m.vencida = maxi(int(m.vencida), c.magnitude)
		if c.magnitude >= int(m.liberada):
			m.liberada = mini(Endgame.mag_max(), c.magnitude + 1)
		magnitudes[c.nome] = m
	girar_pool()
	salvar()


# ---------- Magnitude (calendario.md §10) ----------

func magnitude_de(nome: String) -> Dictionary:
	return magnitudes.get(nome, {"liberada": 0, "vencida": -1}).duplicate()


# ---------- Desafio da semana ----------

func desafio_atual() -> Dictionary:
	return Endgame.desafio_da_semana(giro)


func registro_desafio(semana: int) -> Dictionary:
	return desafios.get(str(semana), {"tentativas": 0, "melhor": {}, "pago": false}).duplicate(true)


## Moeda que a carreira de desafio vai render: só a 1ª tentativa concluída da semana paga.
func moeda_desafio(c: Carreira) -> int:
	return 0 if registro_desafio(c.desafio).pago else c.moeda_total().total


## O desafio não gira a pool nem guarda versão: registra a tentativa e o melhor placar.
func concluir_desafio(c: Carreira) -> void:
	var reg := registro_desafio(c.desafio)
	moeda += moeda_desafio(c)
	reg.pago = true
	reg.tentativas += 1
	var placar := Endgame.placar_desafio(c)
	if Endgame.placar_melhor(placar, reg.melhor):
		reg.melhor = placar
	desafios[str(c.desafio)] = reg
	salvar()


# ---------- Circuito (GDD §7) ----------

func registro_circuito(nivel: int, id: String) -> Dictionary:
	return circuito.get(Endgame.chave(nivel, id), {"vitorias": 0, "melhor": 0, "giro_premio": -1,
		"giro_tentativas": -1, "tentativas": 0}).duplicate()


## Tentativas que ainda restam nesta rotação. O limite faz a força do elenco e as condições
## da semana pesarem: sem ele, bastava repetir até a sorte ajudar.
func tentativas_restantes(nivel: int, id: String) -> int:
	var reg := registro_circuito(nivel, id)
	var usadas: int = int(reg.get("tentativas", 0)) if int(reg.get("giro_tentativas", -1)) == giro else 0
	return maxi(0, int(Dados.endgame.circuito.tentativas_por_rotacao) - usadas)


func venceu_evento(nivel: int, id: String) -> bool:
	return registro_circuito(nivel, id).vitorias > 0


## Bronze sempre aberto; Prata e Ouro de uma copa abrem com o nível anterior dela vencido.
## O Campeonato Final de um nível abre com as 5 copas daquele nível vencidas.
func evento_aberto(nivel: int, id: String) -> bool:
	if id == "final":
		for ev in Endgame.eventos():
			if ev.id != "final" and not venceu_evento(nivel, ev.id):
				return false
		return nivel == 0 or venceu_evento(nivel - 1, "final")
	return nivel == 0 or venceu_evento(nivel - 1, id)


## Garotas do elenco que podem correr no circuito (precisam de versão salva).
func aptas_circuito() -> Array:
	return elenco.keys().filter(func(n): return not elenco[n].salva.is_empty())


## Corre um evento com a escalação [{nome, instrucao}] e paga o prêmio. Devolve o resultado
## de Endgame.correr_evento com {premio, primeira}.
func correr_circuito(nivel: int, id: String, escalacao: Array) -> Dictionary:
	if not evento_aberto(nivel, id) or tentativas_restantes(nivel, id) <= 0:
		return {}
	var esc := []
	for e in escalacao:
		esc.append({"nome": e.nome, "salva": elenco[e.nome].salva, "instrucao": e.get("instrucao", "normal")})
	tentativas_circuito += 1
	var r := Endgame.correr_evento(nivel, giro, id, esc, hash([semente, "circuito", tentativas_circuito]))
	var reg := registro_circuito(nivel, id)
	if int(reg.get("giro_tentativas", -1)) != giro:
		reg.giro_tentativas = giro
		reg.tentativas = 0
	reg.tentativas = int(reg.tentativas) + 1
	reg.melhor = maxi(int(reg.melhor), int(r.total))
	r.primeira = r.venceu and reg.vitorias == 0
	r.premio = 0
	if r.venceu:
		# prêmio cheio na 1ª vitória; depois, uma fração, uma vez por rotação da pool
		if r.primeira or int(reg.giro_premio) != giro:
			r.premio = Endgame.premio(nivel, id, r.primeira)
			reg.giro_premio = giro
		reg.vitorias += 1
	moeda += r.premio
	circuito[Endgame.chave(nivel, id)] = reg
	salvar()
	return r
