class_name CartaoGarota
extends RefCounted
## Cartão de uma garota (medalhão com o rosto, faixa com o nome, cápsulas de estilo,
## distância e piso, e as estrelas de vínculo), usado na academia, na pool e na madrinha.
## O VBox de conteúdo é o primeiro filho do painel devolvido, para quem chama acrescentar
## linhas e botões.


static func criar(nome: String, vinculo: int = -1) -> PanelContainer:
	var dados: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Dados")
	var g: Dictionary = dados.garota(nome)
	var cfg: Dictionary = dados.config_carreira(nome)
	var cor := UI.cor_garota(nome)
	var p := UI.painel(UI.PAINEL, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 340
	var v := UI.vbox(8)
	p.add_child(v)
	var topo := UI.hbox(12)
	var med := UI.medalhao(nome, 76)
	med.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	topo.add_child(med)
	var tv := UI.vbox(5)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.faixa(nome, cor, 20))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 4)
	chips.add_theme_constant_override("v_separation", 4)
	chips.add_child(UI.capsula(dados.ESTILO_NOME[g.estilo], UI.ESTILO_COR.get(g.estilo, UI.CEU), 12))
	chips.add_child(UI.capsula(dados.DIST_NOME[cfg.distancia], UI.DIST_COR.get(cfg.distancia, UI.CEU), 12))
	chips.add_child(UI.capsula(str(cfg.piso).capitalize(), UI.PISO_COR.get(cfg.piso, UI.VERDE), 12))
	if g.get("mvp", false):
		var ev := UI.capsula("♥ história", UI.ROSA, 12)
		ev.tooltip_text = "Tem encontros e eventos de história escritos"
		chips.add_child(ev)
	tv.add_child(chips)
	if vinculo >= 0:
		var hv := UI.hbox(6)
		hv.add_child(UI.label("Vínculo", 13, UI.SUAVE))
		hv.add_child(UI.Estrelas.new(vinculo, Perfil.BAL.vinculo_max, 16))
		tv.add_child(hv)
	topo.add_child(tv)
	v.add_child(topo)
	return p
