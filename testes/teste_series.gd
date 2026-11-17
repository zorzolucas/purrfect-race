extends SceneTree
# Carregada em tempo de execução: no modo --script, os autoloads (Dados) só existem
# depois que este script compila, e carreira.gd depende deles.
var CarreiraS: GDScript
## Olheiro, instrução, séries e títulos, madrinha e visual do elenco.
## Uso: Godot --headless --path . --script res://testes/teste_series.gd

var falhas := []


func _conferir(ok: bool, msg: String) -> void:
	if not ok:
		falhas.append(msg)


## Registra uma vitória numa corrida do calendário fixo do turno t.
func _vencer_fixa(c, t: int) -> String:
	c.turno = t
	var f := Calendario.corrida_fixa(t)
	c.escolher_corrida(f)
	c.encontro_pendente = {}
	return c.registrar_corrida(1)


func _initialize() -> void:
	CarreiraS = load("res://scripts/carreira.gd")
	CarreiraS.CAMINHO_SAVE = "user://teste_series.json"
	var dd: Node = root.get_node("Dados")
	if dd.iniciais.is_empty():
		dd._ready()
	var ini: Dictionary = dd.config_carreira("Lira")

	# ---- olheiro: determinístico, etiqueta coerente com a chance, fama com o multiplicador
	var c = CarreiraS.new(dd.garota("Lira"), ini, 11)
	c.turno = 30
	var cr := {"id": "x", "cat": "prata", "dist": "milha", "piso": "grama", "nome": "Teste"}
	var ol: Dictionary = c.olheiro(cr)
	c._cache_olheiro = {}
	_conferir(str(ol) == str(c.olheiro(cr)), "olheiro não é determinístico")
	_conferir(ol.etiqueta == "azarao", "Lira fraca no turno 30 deveria ser Azarão (veio %s)" % ol.etiqueta)
	_conferir(c.fama_prevista(cr) == roundi(400 * 1.5), "fama de Azarão deveria ser ×1,5")
	for k in c.attrs:
		c.attrs[k] = 900.0
	ol = c.olheiro(cr)
	_conferir(ol.etiqueta == "favorita" and ol.chance >= 0.4, "Lira com 900 deveria ser Favorita")
	_conferir(c.fama_prevista(cr) == roundi(400 * 0.75), "fama de Favorita deveria ser ×0,75")
	_conferir(ol.sugestao in ["poupar", "normal", "forcar"], "sugestão inválida")
	# a instrução escolhida vai para a corredora e volta para Normal depois da corrida
	c.escolher_corrida(cr)
	c.escolher_instrucao("forcar")
	_conferir(c.montar_corrida(dd.garotas).field[0].instrucao == "forcar", "instrução não chegou na corrida")
	c.registrar_corrida(2)
	_conferir(c.instrucao == "normal", "instrução não voltou para Normal")
	_conferir(c.resultados[-1].etiqueta == "favorita", "resultado sem etiqueta")

	# ---- séries: Tríplice da casa (Milha Grama: Taça Brisa t31 + Prêmio Cometa t40 e t64)
	c = CarreiraS.new(dd.garota("Lira"), ini, 12)
	_vencer_fixa(c, 31)
	_vencer_fixa(c, 40)
	_conferir(c.titulos.is_empty(), "título cedo demais")
	var fama0: int = c.fama
	var txt := _vencer_fixa(c, 64)
	_conferir(c.tem_titulo("triplice_milha_grama"), "Tríplice da Milha não saiu: " + txt)
	_conferir(c.titulos[0].nome == "Estrela da Milha", "nome do título: %s" % c.titulos[0].nome)
	_conferir(c.fama - fama0 >= 500, "Tríplice deveria dar +500 de fama")
	_conferir(c.oferta_amuleto.size() == 4, "Tríplice deveria oferecer 4 amuletos")
	c.oferta_amuleto = []
	# Coroa Dupla da Milha: falta a Ouro de Milha Terra (Prêmio Duna, turno do ano 17 = t65)
	var terra0: String = c.aptidao.terra
	_vencer_fixa(c, 65)
	_conferir(c.tem_titulo("coroa_milha"), "Coroa Dupla da Milha não saiu")
	_conferir(c.aptidao.terra != terra0 or terra0 == "X", "Coroa Dupla deveria subir a aptidão em Terra")
	# Volta ao Céu: Ouros de Sprint (Trovão t62), Média (Equinócio t61) e Longa (Via Láctea t63)
	_vencer_fixa(c, 61)
	_vencer_fixa(c, 62)
	_conferir(not c.tem_titulo("volta"), "Volta ao Céu cedo demais")
	_vencer_fixa(c, 63)
	_conferir(c.tem_titulo("volta"), "Volta ao Céu não saiu")
	_conferir(c.limite_amuletos() == int(dd.amuletos.limite) + 1, "Volta ao Céu deveria dar +1 amuleto")
	# derrota não conta
	var n_tit: int = c.titulos.size()
	c.turno = 59
	c.escolher_corrida(Calendario.corrida_fixa(59))
	c.registrar_corrida(2)
	_conferir(c.titulos.size() == n_tit, "derrota completou série")
	# títulos passam para a versão salva e sobrevivem ao save
	_conferir(c.versao_salva().titulos.size() == c.titulos.size(), "títulos fora da versão salva")
	c.salvar()
	var d = CarreiraS.carregar()
	_conferir(d != null and str(d.titulos) == str(c.titulos), "títulos não sobreviveram ao save")
	CarreiraS.apagar_save()

	# ---- madrinha: bônus com teto de +25 por atributo (vínculo + madrinha)
	var forte := {"nome": "X", "attrs": {"vel": 1000, "est": 1000, "pod": 1000, "det": 1000, "int": 1000}, "dist": "media", "piso": "terra"}
	var b: Dictionary = CarreiraS.bonus_legado(0, forte)
	_conferir(b.vel == 20.0, "madrinha sozinha deveria parar em +20 (veio %s)" % b.vel)
	b = CarreiraS.bonus_legado(3, forte)
	_conferir(b.vel == 25.0, "vínculo 3 + madrinha deveria parar em +25 (veio %s)" % b.vel)
	var fraca := {"nome": "Y", "attrs": {"vel": 400, "est": 400, "pod": 400, "det": 400, "int": 400}, "dist": "media", "piso": "terra"}
	_conferir(CarreiraS.bonus_legado(0, fraca).vel == 12.0, "madrinha de 400 deveria dar +12")
	var g: Dictionary = dd.garota("Lira")
	c = CarreiraS.new(g, ini, 13, 3, forte)
	_conferir(c.attrs.vel == g.atributos.vel + 25.0, "carreira não aplicou o bônus da madrinha")
	# Perfil e TelaMadrinha também dependem dos autoloads
	var p = load("res://scripts/perfil.gd").new()
	var TelaM: GDScript = load("res://scripts/tela_madrinha.gd")
	p.elenco = {"Lira": {"vinculo": 0, "salva": {}}, "Mira": {"vinculo": 1, "salva": {"attrs": forte.attrs, "nota": "S"}},
		"Capela": {"vinculo": 0, "salva": {}}}
	_conferir(TelaM.candidatas(p, "Lira") == ["Mira"], "candidatas a madrinha erradas")
	_conferir(TelaM.candidatas(p, "Mira").is_empty(), "a própria garota não pode ser madrinha")
	var md: Dictionary = CarreiraS.madrinha_de("Mira", p.elenco.Mira.salva)
	_conferir(md.dist == "longa" and md.piso == "grama", "madrinha sem a casa dela")

	# ---- visual do elenco (docs/visual-elenco.md)
	var signos := {}
	for x in dd.garotas:
		_conferir(x.has("signo") and x.has("aniversario") and x.has("visual"), "%s sem visual" % x.nome)
		signos[x.signo] = signos.get(x.signo, 0) + 1
		for k in ["pelagem", "paleta", "marca", "altura", "porte", "orelhas", "rabo"]:
			_conferir(x.visual.has(k), "%s sem %s" % [x.nome, k])
	_conferir(signos.size() == 12 and signos.values().all(func(n): return n == 4), "signos fora de 4 por signo")
	_conferir(dd.garota("Lira").visual.pelagem == "laranja_rajada", "pelagem da Lira")
	for r in dd.rivais:
		_conferir(r.has("visual"), "%s sem visual" % r.nome)

	print("SERIES OK" if falhas.is_empty() else "SERIES FALHOU: " + "; ".join(falhas))
	quit(0 if falhas.is_empty() else 1)
