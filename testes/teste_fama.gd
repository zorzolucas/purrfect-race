extends SceneTree
## Testa Prestígio, atributos da corrida, metas de fama, equipamento e boosts
## (docs/fama-e-crescimento.md).
## Uso: Godot --headless --path . --script res://testes/teste_fama.gd
var CarreiraS: GDScript
var falhas := []


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


func _nova(dados: Node):
	var c = CarreiraS.new(dados.garota("Lira"), dados.config_carreira("Lira"), 7)
	c.encontro_pendente = {}
	c.humor = 2
	c.lesionada = false
	c.duplas = {}
	return c


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_fama.json"
	var dados: Node = root.get_node("Dados")
	if dados.iniciais.is_empty():
		dados._ready()
	var cfg: Dictionary = dados.calendario.crescimento

	# Prestígio pela fama e multiplicador no treino
	var c = _nova(dados)
	_checar(c.prestigio() == 0 and c.mult_prestigio() == 1.0, "começa no Prestígio 0")
	var g0: float = c.ganho_previsto("vel").vel
	c.fama = int(cfg.prestigio[2].fama)
	_checar(c.prestigio() == 2, "Prestígio 2 com %d de fama" % c.fama)
	var g2: float = c.ganho_previsto("vel").vel
	_checar(absf(g2 / g0 - float(cfg.prestigio[2].mult)) < 0.001, "Prestígio multiplica o treino")
	c.fama = int(cfg.prestigio[5].fama)
	var txt: String = c._checar_prestigio()
	_checar(c.equip_pendente == 2, "Prestígio 3 e 5 dão 2 graus de equipamento (%d)" % c.equip_pendente)
	_checar("Prestígio 5" in txt, "texto do Prestígio novo")
	_checar(c._checar_prestigio() == "" and c.equip_pendente == 2, "recompensa do Prestígio sai uma vez só")
	_checar(c.pendencia() == "equipamento", "pendência de equipamento")

	# equipamento: +ganho, -energia, até o grau 3
	c = _nova(dados)
	var ge: float = c.ganho_previsto("est").est
	var custo0: int = c.custo("est")
	c.equip_pendente = 3
	for i in 3:
		c.escolher_equipamento("est")
	_checar(c.equipamento.est == 3 and c.equip_pendente == 0, "3 graus no mesmo treino")
	_checar(not "est" in c.opcoes_equipamento(), "grau 3 é o máximo")
	_checar(absf(c.ganho_previsto("est").est / ge - (1.0 + float(cfg.equipamento.ganho[3]))) < 0.001, "equipamento no ganho")
	_checar(c.custo("est") == custo0 - int(cfg.equipamento.energia[3]), "equipamento na energia")

	# corrida: atributos pelo perfil, vitória > derrota
	c = _nova(dados)
	var longa := {"cat": "aberta", "dist": "longa", "piso": "grama"}
	var sprint := {"cat": "aberta", "dist": "sprint", "piso": "terra"}
	var gl: Dictionary = c.ganho_corrida(longa, 1)
	var gs: Dictionary = c.ganho_corrida(sprint, 1)
	_checar(gl.est > gl.vel and gs.vel > gs.est, "perfil da distância")
	_checar(gs.pod > c.ganho_corrida({"cat": "aberta", "dist": "sprint", "piso": "grama"}, 1).pod, "Terra puxa Potência")
	var t1 := 0.0
	var t9 := 0.0
	for k in gl:
		t1 += gl[k]
		t9 += c.ganho_corrida(longa, 9)[k]
	_checar(t9 < t1 * 0.5, "perder rende bem menos")
	var gt: Dictionary = c.ganho_previsto("est")
	var treino := 0.0
	for k in gt:
		treino += gt[k]
	_checar(t1 > treino * 0.6 and t1 < treino * 1.4, "vitória rende perto de um treino (%d x %d)" % [t1, treino])

	# boosts: Embalo dura 2 turnos, Lição gasta 1 treino, não acumulam
	c = _nova(dados)
	var base: float = c.ganho_previsto("pod").pod
	c.adicionar_boost("embalo")
	c.adicionar_boost("embalo")
	_checar(c.boosts.size() == 1, "boost do mesmo tipo renova, não acumula")
	_checar(absf(c.ganho_previsto("pod").pod / base - 1.1) < 0.001, "Embalo +10%")
	var t0: int = c.turno
	c._fim_turno()
	c._fim_turno()
	_checar(c.boosts.any(func(b): return b.id == "embalo"), "Embalo ainda vale no 2º turno")
	c._fim_turno()
	_checar(not c.boosts.any(func(b): return b.id == "embalo"), "Embalo acaba depois de 2 turnos (t%d → t%d)" % [t0, c.turno])
	c.encontro_pendente = {}
	var n0: int = c.nivel_efetivo("det")
	c.adicionar_boost("licao", "det")
	_checar(c.nivel_efetivo("det") == mini(5, n0 + 1), "Lição sobe 1 nível")
	c.energia = 100
	c.treinar("det")
	_checar(not c.boosts.any(func(b): return b.id == "licao"), "Lição gasta no treino")

	# meta de fama: sem a fama, a carreira acaba no turno da meta
	c = _nova(dados)
	var meta: Dictionary = cfg.metas_fama[0]
	c.turno = int(meta.turno)
	c.encontro_pendente = {}
	c.fama = 0
	var obj: Dictionary = c.objetivo_do_turno()
	_checar(not obj.is_empty(), "há objetivo no turno da meta %d" % meta.turno)
	var fama_meta: int = int(meta.fama)
	meta.fama = 999999  # a vitória no objetivo já dá fama: a meta sobe só neste caso
	var r: String = c.registrar_corrida(1)
	meta.fama = fama_meta
	_checar(c.terminou and c.falhou_objetivo and "meta de fama" in r, "meta de fama falhada acaba a carreira: " + r)
	c = _nova(dados)
	c.turno = int(meta.turno)
	c.encontro_pendente = {}
	c.fama = int(meta.fama)
	c.registrar_corrida(1)
	_checar(not c.falhou_objetivo, "com a fama da meta, segue")

	# save guarda boosts e equipamento
	c = _nova(dados)
	c.equipamento.int = 2
	c.adicionar_boost("torcida")
	c.salvar()
	var d = CarreiraS.carregar()
	_checar(d != null and d.equipamento.int == 2 and d.boosts.size() == 1 and d.boosts[0].treinos == 1, "save com boosts e equipamento")
	CarreiraS.apagar_save()

	if falhas.is_empty():
		print("FAMA OK")
		quit(0)
	else:
		print("FAMA FALHOU: " + "; ".join(falhas))
		quit(1)
