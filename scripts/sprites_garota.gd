class_name SpritesGarota
extends RefCounted
## Sprites 2D tirados das fichas conceituais (tools/recortar_fichas.py): o corpo de frente
## e o atlas com as 6 expressões. Só as 6 garotas do MVP e as 2 rivais têm ficha; as outras
## usam o retrato de círculo e a gata de primitivas.

const PASTA := "res://sprites/garotas/"
## Mesma ordem do atlas do modelo 3D (ModeloGarota.EXPRESSOES) e das fichas.
const EXPRESSOES := ["normal", "fechados", "feliz", "surpresa", "tonta", "piscadinha"]
const LADO_ROSTO := 256

static var _cache := {}


static func tem(nome: String) -> bool:
	return ResourceLoader.exists(_caminho(nome, "corpo"))


static func _caminho(nome: String, parte: String) -> String:
	return PASTA + nome.split(" ")[0].to_lower() + "_" + parte + ".png"


static func _textura(nome: String, parte: String) -> Texture2D:
	var k := nome + "|" + parte
	if not _cache.has(k):
		var cam := _caminho(nome, parte)
		_cache[k] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache[k]


## Corpo inteiro de frente (512 px de altura), ou null.
static func corpo(nome: String) -> Texture2D:
	return _textura(nome, "corpo")


## Rosto com a expressão pedida (256 x 256), ou null. Expressão desconhecida vira "normal".
static func rosto(nome: String, expressao: String = "normal") -> Texture2D:
	var atlas := _textura(nome, "rostos")
	if atlas == null:
		return null
	var i := maxi(0, EXPRESSOES.find(expressao))
	var t := AtlasTexture.new()
	t.atlas = atlas
	t.region = Rect2(i * LADO_ROSTO, 0, LADO_ROSTO, LADO_ROSTO)
	return t


## Expressão que combina com o humor da carreira (0 = Péssimo … 4 = Ótimo).
static func expressao_do_humor(humor: int) -> String:
	return ["tonta", "fechados", "normal", "normal", "feliz"][clampi(humor, 0, 4)]


## Cores da pelagem (cabelo, sombra, claro) do visual do elenco, para as primitivas.
static func paleta(nome: String) -> Array:
	var dd: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	var g: Dictionary = dd.garota(nome)
	if g.is_empty():
		for r in dd.rivais:
			if r.nome == nome:
				g = r
	var p: Array = g.get("visual", {}).get("paleta", [])
	if p.size() >= 3:
		return [Color(p[0]), Color(p[1]), Color(p[2])]
	var c := Color(dd.config_carreira(nome).get("cor", "#b07cc6"))
	return [c, c.darkened(0.3), c.lightened(0.5)]
