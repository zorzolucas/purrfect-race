extends SceneTree
## Guia do jogo (data/tutorial.json e scripts/tela_guia.gd): todo capítulo tem id, título e
## páginas, todo bloco tem um tipo conhecido, todo número entre chaves existe nos dados, e a
## janela monta todas as páginas sem erro, navegando com as teclas.
## Uso: Godot --headless --path . --script res://testes/teste_guia.gd
# Carregado em tempo de execução: no modo --script os autoloads (Dados) só existem depois
# que este script compila.
var GuiaS: GDScript
var falhas := []
const TIPOS := ["texto", "dica", "itens", "tabela", "atributos", "nos", "climas", "boosts"]
const CORES := ["rosa", "ceu", "verde", "laranja", "roxo", "ouro"]


func _checar(ok: bool, txt: String) -> void:
	if not ok:
		falhas.append(txt)


## Todos os textos de um valor JSON (para conferir as chaves).
func _textos(v, saida: Array) -> Array:
	if v is String:
		saida.append(v)
	elif v is Array:
		for x in v:
			_textos(x, saida)
	elif v is Dictionary:
		for k in v:
			if k != "_doc" and k != "revisar":
				_textos(v[k], saida)
	return saida


func _initialize() -> void:
	var dd: Node = root.get_node("Dados")
	if dd.garotas.is_empty():
		dd._ready()
	GuiaS = load("res://scripts/tela_guia.gd")
	var caps: Array = dd.tutorial.get("capitulos", [])
	_checar(caps.size() >= 5, "poucos capítulos: %d" % caps.size())
	var ids := {}
	var n_paginas := 0
	for c in caps:
		_checar(c.has("id") and c.has("titulo") and c.has("paginas"), "capítulo incompleto: %s" % c.get("id", "?"))
		_checar(not ids.has(c.id), "capítulo repetido: %s" % c.id)
		ids[c.id] = true
		_checar(str(c.get("cor", "ceu")) in CORES, "%s: cor desconhecida" % c.id)
		_checar(not c.paginas.is_empty(), "%s sem páginas" % c.id)
		for p in c.paginas:
			n_paginas += 1
			_checar(p.has("titulo") and not p.get("blocos", []).is_empty(), "%s: página sem título ou blocos" % c.id)
			for b in p.get("blocos", []):
				_checar(str(b.get("tipo", "")) in TIPOS, "%s: bloco de tipo %s" % [c.id, b.get("tipo", "")])
				for it in b.get("itens", []):
					_checar(it.has("titulo"), "%s: item sem título" % c.id)
					_checar(str(it.get("cor", "ceu")) in CORES, "%s: item com cor %s" % [c.id, it.get("cor")])
				if b.get("tipo") == "tabela":
					for l in b.linhas:
						_checar(l.size() == b.colunas.size(), "%s: linha da tabela com %d colunas" % [c.id, l.size()])
	# os capítulos que as telas abrem precisam existir
	for id in ["jogo", "turno", "corridas", "endgame", "academia"]:
		_checar(ids.has(id), "falta o capítulo %s" % id)
	# toda chave {fonte:caminho} tem valor nos dados
	var re := RegEx.create_from_string("\\{(bal|pct|perfil|d|pctd):([A-Za-z0-9_.]+)\\}")
	var resto := RegEx.create_from_string("\\{[^}]*\\}")
	for t in _textos(dd.tutorial, []):
		for m in re.search_all(t):
			_checar(GuiaS.valor(m.get_string(1), m.get_string(2)) != null, "chave sem valor: %s" % m.get_string())
		var p: String = GuiaS.preencher(t)
		_checar(resto.search(p) == null, "chave mal escrita em: %s" % t.left(60))
	_checar(GuiaS.preencher("{bal:descanso}") == str(int(load("res://scripts/carreira.gd").BAL.descanso)), "preencher bal")
	_checar(GuiaS.preencher("{pct:bonus_nivel}%") == "30%", "preencher pct: %s" % GuiaS.preencher("{pct:bonus_nivel}%"))
	_checar(GuiaS.formatar(0.75) == "0,75", "formatar 0,75")
	# monta todas as páginas, avançando com a seta para a direita
	var base := Control.new()
	base.size = Vector2(1600, 900)
	root.add_child(base)
	var g = GuiaS.abrir(base, "jogo")
	_checar(GuiaS.abrir(base, "turno") == g, "F1 com o guia aberto abriu outro")
	g.cap = 0
	g.pag = 0
	g._montar()
	var vistas := 0
	for i in n_paginas:
		vistas += 1
		if i < n_paginas - 1:
			g._proximo()
	_checar(g.cap == caps.size() - 1, "não chegou ao último capítulo")
	_checar(vistas == n_paginas, "páginas vistas %d de %d" % [vistas, n_paginas])
	g._proximo()  # na última página, fecha
	_checar(g.is_queued_for_deletion(), "Pronto! não fechou o guia")
	print("GUIA OK (%d capítulos, %d páginas)" % [caps.size(), n_paginas] if falhas.is_empty() else "GUIA FALHOU (%d): %s" % [falhas.size(), "; ".join(falhas.slice(0, 20))])
	quit(0 if falhas.is_empty() else 1)
