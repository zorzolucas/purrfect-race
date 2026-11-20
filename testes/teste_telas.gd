extends SceneTree
## Teste de fumaça das telas: abre o jogo (cenas/main.tscn) e aperta botões ao acaso, com
## semente, por alguns milhares de passos: escolha da inicial, academia, pool, madrinha,
## carreira (mapa, encontros, amuletos, loja, olheiro), corrida 3D e fim de carreira.
## Falha se qualquer erro de script aparecer no log, ou se o jogo travar numa tela sem botões.
## Usa caminhos de save próprios, então não mexe no perfil nem na carreira de verdade.
## Uso: Godot --headless --path . --script res://testes/teste_telas.gd [-- passos semente]

class ContaErros extends Logger:
	var erros: Array = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		erros.append("%s:%d %s %s" % [file, line, function, rationale if rationale != "" else code])


var logger := ContaErros.new()
var main: Node
var rng := RandomNumberGenerator.new()
var passos := 1200
var passo := 0
var espera := 0
var telas := {}         # nome da classe da tela -> quantas vezes apareceu
var sem_botao := 0
var carreiras := 0
var ultima_tela := ""
var PerfilS: GDScript
var CarreiraS: GDScript


func _initialize() -> void:
	OS.add_logger(logger)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		passos = int(args[0])
	rng.seed = int(args[1]) if args.size() > 1 else 7
	seed(rng.seed)  # o perfil e a carreira sem semente usam randi(): assim a rodada se repete
	PerfilS = load("res://scripts/perfil.gd")
	CarreiraS = load("res://scripts/carreira.gd")
	PerfilS.CAMINHO = "user://teste_telas_perfil.json"
	CarreiraS.CAMINHO_SAVE = "user://teste_telas_carreira.json"
	PerfilS.apagar()
	CarreiraS.apagar_save()
	main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)


func _botoes(n: Node, lista: Array) -> Array:
	if n is CanvasItem and not n.visible:
		return lista
	if n is BaseButton and not n.disabled:
		lista.append(n)
	for f in n.get_children():
		_botoes(f, lista)
	return lista


func _nome_tela() -> String:
	if main.tela == null:
		return "-"
	var s: Script = main.tela.get_script()
	return s.get_global_name() if s else main.tela.get_class()


func _process(_delta: float) -> bool:
	espera += 1
	if espera < 2:
		return false
	espera = 0
	if passo >= passos or not logger.erros.is_empty() or sem_botao > 30:
		_fim()
		return true
	passo += 1
	var nome := _nome_tela()
	telas[nome] = telas.get(nome, 0) + 1
	# na corrida, quase sempre pula direto para a chegada (assistir inteira levaria minutos)
	if nome == "TelaCorrida" and not main.tela.acabou and rng.randf() < 0.8:
		main.tela._pular()
		return false
	if nome == "TelaFim" and nome != ultima_tela:
		carreiras += 1
	ultima_tela = nome
	var bs := _botoes(main.tela if main.tela else main, [])
	if bs.is_empty():
		sem_botao += 1
		return false
	sem_botao = 0
	var b: BaseButton = bs[rng.randi() % bs.size()]
	# "Voltar", "Desistir" e "Academia" fazem o macaco andar em círculos: aperta menos
	if b is Button and (b.text.begins_with("Voltar") or b.text.begins_with("Desistir") or b.text.begins_with("Academia")) and rng.randf() < 0.8:
		b = bs[rng.randi() % bs.size()]
	b.pressed.emit()
	return false


func _fim() -> void:
	var falhas := logger.erros.slice(0, 5)
	if sem_botao > 30:
		falhas.append("tela %s ficou sem botões" % _nome_tela())
	for t in ["TelaEscolha", "TelaAcademia", "TelaCarreira", "TelaCorrida"]:
		if not telas.has(t) and passos >= 600:
			falhas.append("nunca chegou na %s" % t)
	PerfilS.apagar()
	CarreiraS.apagar_save()
	print("TELAS %s  (%d passos, telas: %s, fins de carreira: %d)" % [
		"OK" if falhas.is_empty() else "FALHOU: " + " | ".join(falhas), passo, telas, carreiras])
	OS.remove_logger(logger)
	quit(0 if falhas.is_empty() else 1)
