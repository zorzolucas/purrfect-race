extends SceneTree
## Roda todos os testes/teste_*.gd, cada um no seu próprio processo do Godot, e mostra um
## resumo. Um teste falha se sair com código diferente de 0 ou se imprimir um erro de script.
## Funciona igual no Windows e no Linux (é o que o GitHub roda a cada PR).
## Uso: Godot --headless --path . --script res://testes/rodar_testes.gd [-- filtro]
##   filtro: só os testes cujo nome contém o texto (ex.: "save", "carreira")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var filtro: String = args[0] if args.size() > 0 else ""
	var testes := []
	for f in DirAccess.get_files_at("res://testes"):
		if f.begins_with("teste_") and f.ends_with(".gd") and (filtro == "" or filtro in f):
			testes.append(f)
	testes.sort()
	var falhas := []
	var t_total := Time.get_ticks_msec()
	for f in testes:
		var t0 := Time.get_ticks_msec()
		var saida := []
		var codigo := OS.execute(OS.get_executable_path(),
			["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://testes/" + f],
			saida, true)
		var texto: String = "".join(saida)
		var erro_script := "SCRIPT ERROR" in texto
		var ok := codigo == 0 and not erro_script
		# a última linha não vazia é o resumo do teste ("SAVE OK", "MAPA FALHOU: ...")
		var linhas := Array(texto.strip_edges().split("\n")).filter(func(l): return l.strip_edges() != "")
		var resumo: String = linhas[-1].strip_edges() if not linhas.is_empty() else "(sem saída)"
		print("%s %-22s %5.1f s  %s" % ["ok   " if ok else "FALHA", f.get_basename(),
			(Time.get_ticks_msec() - t0) / 1000.0, resumo.left(160)])
		if not ok:
			falhas.append(f)
			if erro_script or codigo != 0:
				for l in linhas.filter(func(l): return "ERROR" in l or "at:" in l).slice(0, 10):
					print("        ", l.strip_edges())
	print("\n%d de %d testes passaram (%.0f s)." % [testes.size() - falhas.size(), testes.size(),
		(Time.get_ticks_msec() - t_total) / 1000.0])
	if not falhas.is_empty():
		print("Falharam: ", ", ".join(falhas))
	quit(0 if falhas.is_empty() and not testes.is_empty() else 1)
