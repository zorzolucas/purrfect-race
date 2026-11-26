class_name TelaMadrinha
extends Control
## Escolha da madrinha no começo da carreira (GDD §3.6): uma garota salva do elenco, que não
## pode ser a própria. Mostra o bônus que cada uma dá, já com o teto de +25 por atributo
## (vínculo + madrinha), e a aptidão que ela pode inspirar nos turnos 25 e 49.

signal escolheu(madrinha: Dictionary)   # {} = sem madrinha
signal voltar

var perfil: Perfil
var nome: String
var vinculo: int


func _init(p: Perfil, nome_: String) -> void:
	perfil = p
	nome = nome_
	vinculo = int(p.elenco[nome].vinculo)


## Garotas do elenco que podem ser madrinha: têm versão salva e não são a da carreira.
static func candidatas(p: Perfil, nome_: String) -> Array:
	var lista := []
	for n in p.elenco:
		if n != nome_ and not p.elenco[n].salva.is_empty():
			lista.append(n)
	lista.sort_custom(func(a, b): return _soma(p.elenco[a].salva.attrs) > _soma(p.elenco[b].salva.attrs))
	return lista


static func _soma(a: Dictionary) -> float:
	var s := 0.0
	for k in a:
		s += float(a[k])
	return s


func _ready() -> void:
	var em_pe := UI.em_pe()
	var v := UI.vbox(10 if em_pe else 12)
	var topo := UI.hbox(8 if em_pe else 12)
	topo.add_child(UI.medalhao(nome, 44 if em_pe else 56))
	topo.add_child(UI.faixa(("Madrinha de %s" if em_pe else "Escolha a madrinha de %s") % nome, UI.ROSA, 20 if em_pe else 28))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	topo.add_child(UI.botao("Voltar", func(): voltar.emit(), 16))
	v.add_child(topo)
	var b := Carreira.BAL
	v.add_child(UI.label(("A madrinha dá +%d%% dos atributos finais dela no começo da carreira (até +%d por atributo). " +
		"Somado ao vínculo, o bônus para em +%d. Nos turnos 25 e 49 ela aparece para inspirar: chance de " +
		"atributos e de subir a aptidão da distância e do piso da casa dela.") % [
		roundi(b.madrinha_pct * 100), b.madrinha_teto, b.legado_teto], 15, UI.SUAVE, true))
	if vinculo > 0:
		v.add_child(UI.label("Vínculo %d: já dá +%d em cada atributo, então sobra até +%d para a madrinha." % [
			vinculo, b.vinculo_attr * vinculo, maxf(0.0, b.legado_teto - b.vinculo_attr * vinculo)], 15, UI.TEXTO, true))

	var grade := GridContainer.new()
	grade.columns = 1 if em_pe else 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	grade.add_child(_cartao_sem())
	for n in candidatas(perfil, nome):
		grade.add_child(_cartao(n))
	v.add_child(UI.rolavel(grade))
	add_child(UI.margem(v, 10 if em_pe else 28))


func _cartao_sem() -> Control:
	var p := UI.painel(UI.PAINEL, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(8)
	v.add_child(UI.faixa("Sem madrinha", Color("#8a96ad"), 20))
	var leg := Carreira.bonus_legado(vinculo, {})
	v.add_child(UI.label("Só o bônus do vínculo: +%d em cada atributo." % leg.vel if vinculo > 0
		else "Começa só com os atributos dela.", 14, UI.SUAVE, true))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	var bs := UI.botao("Começar sem madrinha", func(): escolheu.emit({}), 16)
	v.add_child(bs)
	p.add_child(v)
	return p


func _cartao(n: String) -> Control:
	var salva: Dictionary = perfil.elenco[n].salva
	var md := Carreira.madrinha_de(n, salva)
	var p := CartaoGarota.criar(n, perfil.elenco[n].vinculo)
	var v: VBoxContainer = p.get_child(0)
	var a: Dictionary = salva.attrs
	var hs := UI.hbox(8)
	hs.add_child(UI.SeloNota.new(str(salva.get("nota", "G")), 40))
	var sv := UI.vbox(2)
	sv.add_child(UI.label("Versão salva · %d/8 objetivos" % int(salva.get("objetivos", 0)), 14, UI.OK))
	sv.add_child(UI.linha_attrs(a, 13))
	hs.add_child(sv)
	v.add_child(hs)
	var leg := Carreira.bonus_legado(vinculo, md)
	var no_teto := false
	var bonus := {}
	for k in SimCorrida.KEYS:
		bonus[k] = roundi(leg[k])
		no_teto = no_teto or leg[k] >= Carreira.BAL.legado_teto
	var pb := UI.painel(Color("#fff3c4"), 8)
	var bv := UI.vbox(4)
	bv.add_child(UI.label("Bônus inicial%s" % (" (no teto)" if no_teto else ""), 13, UI.DESTAQUE))
	var lb := UI.hbox(10)
	for k in SimCorrida.KEYS:
		var hk := UI.hbox(3)
		hk.add_child(UI.Icone.new(k, 16))
		hk.add_child(UI.label_contorno("+%d" % bonus[k], 14, UI.ATTR_COR[k], Color.WHITE, 4))
		lb.add_child(hk)
	bv.add_child(lb)
	pb.add_child(bv)
	v.add_child(pb)
	if md.dist != "":
		v.add_child(UI.label("Pode inspirar: %s e %s" % [Dados.DIST_NOME[md.dist], md.piso.capitalize()], 13, UI.SUAVE, true))
	var tit: Array = salva.get("titulos", [])
	if not tit.is_empty():
		v.add_child(UI.label("Títulos: " + ", ".join(tit), 13, UI.DESTAQUE, true))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	v.add_child(UI.botao_principal("Escolher %s" % n, func(): escolheu.emit(md), 16))
	return p
