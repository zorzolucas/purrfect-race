class_name Escala
extends RefCounted
## Decide o tamanho lógico da tela (o "canvas" em que as telas são montadas) a partir do
## tamanho real da janela, para o jogo caber em qualquer navegador e celular.
##
## Três modos:
## - "desktop": base 1280x720 (como sempre foi). Se a tela atual pedir mais altura ou largura
##   do que cabe, a base cresce (tudo encolhe um pouco) até caber; passando do limite, rola.
## - "paisagem": celular deitado. Base mais baixa (~480-560) para o texto não ficar minúsculo;
##   o que não couber na altura rola.
## - "retrato": celular em pé. Largura lógica ~460-720 e as telas trocam para o layout em
##   coluna (ver `retrato()`); a altura rola.
##
## O tamanho em px "CSS" (janela ÷ devicePixelRatio) decide o modo: um iPhone 15 em pé tem
## 393 px CSS de largura, mas 1179 px reais.

const BASE_DESKTOP := Vector2(1280, 720)
## Quanto a base pode crescer na altura para caber sem rolar (1,4 = encolher até ~71%).
const CABER_ALTURA := {"desktop": 1.4, "paisagem": 1.12, "retrato": 1.0}

static var modo := "desktop"
static var toque := false
## Tamanho da janela em px CSS (o que o navegador chama de viewport).
static var css := Vector2(1280, 720)
## Para testes e capturas: força o devicePixelRatio e o toque (ESCALA_DPR=3 ESCALA_TOQUE=1).
static var dpr_forcado := 0.0
static var toque_forcado := -1
## Para testes: força o modo sem depender do tamanho da janela (ESCALA_MODO=retrato).
static var modo_forcado := ""


static func retrato() -> bool:
	return modo == "retrato"


static func paisagem() -> bool:
	return modo == "paisagem"


## Celular, em pé ou deitado: alvos de toque maiores, sem plaquinhas de tecla.
static func compacto() -> bool:
	return modo != "desktop"


static func dpr() -> float:
	if dpr_forcado > 0.0:
		return dpr_forcado
	var e := OS.get_environment("ESCALA_DPR")
	if e != "":
		return maxf(0.5, e.to_float())
	if OS.has_feature("web"):
		return maxf(1.0, DisplayServer.screen_get_scale())
	return 1.0


static func tem_toque() -> bool:
	if toque_forcado >= 0:
		return toque_forcado == 1
	var e := OS.get_environment("ESCALA_TOQUE")
	if e != "":
		return e == "1"
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")


## Modo e base para uma janela de `janela` px reais. Função pura (testável).
static func calcular(janela: Vector2, razao: float, com_toque: bool) -> Dictionary:
	var c := janela / maxf(razao, 0.5)
	match modo_forcado if modo_forcado != "" else OS.get_environment("ESCALA_MODO"):
		"retrato":
			return {"modo": "retrato", "base": Vector2(472, 472), "css": c}
		"paisagem":
			return {"modo": "paisagem", "base": Vector2(493, 493), "css": c}
	if c.x < c.y and c.x < 1000.0:
		var w := clampf(roundf(c.x * 1.2), 460.0, 720.0)
		return {"modo": "retrato", "base": Vector2(w, w), "css": c}
	if c.y < 600.0 and (com_toque or c.y < 480.0):
		var h := clampf(roundf(c.y * 1.45), 480.0, 720.0)
		return {"modo": "paisagem", "base": Vector2(h, h), "css": c}
	return {"modo": "desktop", "base": BASE_DESKTOP, "css": c}


## Tamanho lógico que uma base gera numa janela (stretch "canvas_items" + aspect "expand").
static func logico(janela: Vector2, base: Vector2) -> Vector2:
	var s := minf(janela.x / base.x, janela.y / base.y)
	return janela / s


## Base ajustada para a tela que pede `minimo` caber em `janela`: cresce na largura sempre
## (não há rolagem para o lado) e na altura até o limite do modo. Devolve a base nova.
static func caber(janela: Vector2, base: Vector2, minimo: Vector2, m: String) -> Vector2:
	var vis := logico(janela, base)
	var kx := minimo.x / vis.x
	var ky := minf(minimo.y / vis.y, float(CABER_ALTURA.get(m, 1.0)))
	var k := clampf(maxf(kx, ky), 1.0, 2.5)
	return base * k
