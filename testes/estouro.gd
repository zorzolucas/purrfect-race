extends RefCounted
## Procura controles que saem da área visível (texto sem quebra que empurra o painel para fora da tela).
## As capturas chamam isto a cada tela. Imprime "ESTOURO <tela>: ..." para cada caso.
## Dentro de ScrollContainer o conteúdo pode passar da altura visível de propósito (rola), mas
## não da largura: as telas desligam a rolagem horizontal, então o que passa para o lado some.

const FOLGA := 2.0


static func checar(raiz: Window, nome: String) -> int:
	var tela := raiz.get_visible_rect()
	var achados := 0
	for c in _controles(raiz):
		var r := c.get_global_rect()
		if r.size.x <= 0 or r.size.y <= 0:
			continue
		var limite := _limite(c, tela)
		if not _estoura(c, limite.rect, limite.vertical):
			continue
		# Só o mais externo de cada cadeia: se o pai também estoura, o pai já foi contado.
		var pai := c.get_parent() as Control
		if pai != null and _estoura(pai, _limite(pai, tela).rect, _limite(pai, tela).vertical):
			continue
		# Coisas que ficam fora da tela de propósito (animações de entrada, camadas cheias).
		if c.top_level or c.mouse_filter == Control.MOUSE_FILTER_IGNORE and not (c is Container) and not (c is Label):
			continue
		achados += 1
		print("ESTOURO %s: %s %s rect=%s min=%s" % [nome, c.get_class(), _caminho(c), r, c.get_combined_minimum_size()])
		for l in _textos_largos(c):
			print("    texto largo (%d px): %s" % [int(l.get_combined_minimum_size().x), str(l.get("text")).replace("\n", " | ").left(110)])
	return achados


## Área onde o controle tem de caber: a do ScrollContainer mais próximo (só na largura) ou a tela.
static func _limite(c: Control, tela: Rect2) -> Dictionary:
	var n := c.get_parent()
	while n != null and not (n is Window):
		if n is ScrollContainer and n.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			return {"rect": (n as Control).get_global_rect().intersection(tela), "vertical": false}
		n = n.get_parent()
	return {"rect": tela, "vertical": true}


static func _estoura(c: Control, area: Rect2, vertical: bool) -> bool:
	if not c.is_visible_in_tree():
		return false
	var r := c.get_global_rect()
	if r.position.x < area.position.x - FOLGA or r.end.x > area.end.x + FOLGA:
		return true
	return vertical and (r.position.y < area.position.y - FOLGA or r.end.y > area.end.y + FOLGA)


static func _controles(n: Node, saida: Array[Control] = []) -> Array[Control]:
	for f in n.get_children():
		if f is CanvasItem and not f.visible:
			continue
		if f is Control:
			saida.append(f)
		_controles(f, saida)
	return saida


## Labels e botões sem quebra, do mais largo para o mais estreito.
static func _textos_largos(c: Node) -> Array:
	var lista: Array = []
	var pilha: Array = [c]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n is Label and n.autowrap_mode == TextServer.AUTOWRAP_OFF and not n.clip_text:
			lista.append(n)
		elif n is Button and not n.clip_text and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
			lista.append(n)
		elif n is RichTextLabel and n.fit_content and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
			lista.append(n)
		pilha.append_array(n.get_children())
	lista = lista.filter(func(l): return l.get_combined_minimum_size().x > 300)
	lista.sort_custom(func(a, b): return a.get_combined_minimum_size().x > b.get_combined_minimum_size().x)
	return lista.slice(0, 4)


static func _caminho(c: Node) -> String:
	var partes: Array[String] = []
	var n := c
	while n != null and not (n is Window):
		partes.push_front(n.name)
		n = n.get_parent()
	return "/".join(partes).right(90)
