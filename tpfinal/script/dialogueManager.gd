# DialogueManager
extends Node
class_name DialogueManagerScript


var current_dialogue: DialogueAbstract
var current_line := 0

var dialogue_box: DialogueBox


func _ready() -> void:
	# El DialogueManager debe seguir funcionando
	# aunque el juego esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	
	var inicio = Time.get_ticks_msec()
	# Comprobar continuamente si el árbol sigue pausado
	# mientras hay un diálogo activo.
	if current_dialogue != null:
		print("DIALOGO ACTIVO | Árbol pausado: ", get_tree().paused)

	if Input.is_action_just_pressed("avanzarDialogo"):
		if current_dialogue != null:
			print("Se presionó avanzarDialogo")
			print("ANTES DE next_line | Árbol pausado: ", get_tree().paused)

			next_line()

			print("DESPUÉS DE next_line | Árbol pausado: ", get_tree().paused)
			var duracion = Time.get_ticks_msec() - inicio

			if duracion >= 50:

				print(
					"⚠️ PROCESS LENTO dialogue manager| ",
					get_path(),
					" | ",
					duracion,
					" ms"
				)

func start_dialogue(dialogue: DialogueAbstract) -> void:
	print("========== START DIALOGUE ==========")

	if dialogue == null:
		print("ERROR: dialogue es null")
		return

	dialogue_box = get_tree().get_first_node_in_group("dialogue_box")

	if dialogue_box == null:
		print("ERROR: no existe DialogueBox")
		return

	current_dialogue = dialogue
	current_line = 0

	print("ANTES DE PAUSAR: ", get_tree().paused)

	get_tree().paused = true

	print("DESPUÉS DE PAUSAR: ", get_tree().paused)

	Settings.sePuedePausar = false

	show_current_line()

	print("FINAL DE start_dialogue: ", get_tree().paused)


func show_current_line() -> void:
	if current_dialogue == null:
		return

	if current_dialogue.lines.is_empty():
		end_dialogue()
		return

	if current_line < 0 or current_line >= current_dialogue.lines.size():
		end_dialogue()
		return

	var line: DialogueLine = current_dialogue.lines[current_line]

	dialogue_box.show_line(line)


func next_line() -> void:
	if current_dialogue == null:
		return

	current_line += 1

	if current_line >= current_dialogue.lines.size():
		end_dialogue()
		return

	show_current_line()


func end_dialogue() -> void:
	print("========== END DIALOGUE ==========")

	print("ANTES DE ocultar diálogo | Árbol pausado: ", get_tree().paused)

	if dialogue_box != null:
		dialogue_box.hide_dialogue()

	print("DESPUÉS DE ocultar diálogo | Árbol pausado: ", get_tree().paused)

	if current_dialogue != null:
		current_dialogue.queue_free()
		current_dialogue = null

	current_line = 0

	print("ANTES DE DESPAUSAR | Árbol pausado: ", get_tree().paused)

	get_tree().paused = false

	print("DESPUÉS DE DESPAUSAR | Árbol pausado: ", get_tree().paused)

	Settings.sePuedePausar = true

	print("Diálogo terminado")
