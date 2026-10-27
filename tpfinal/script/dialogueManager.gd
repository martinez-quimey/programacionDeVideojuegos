
# DialogueManager
extends Node
class_name DialogueManagerScript


var current_dialogue: DialogueAbstract
var current_line := 0

var dialogue_box: DialogueBox

var timer_automatico: Timer

var current_dialogue_es_automatico := false


func _ready() -> void:

	# El DialogueManager sigue funcionando durante la pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

	timer_automatico = Timer.new()
	timer_automatico.wait_time = 3.0
	timer_automatico.one_shot = true
	timer_automatico.timeout.connect(_on_timer_automatico_timeout)

	add_child(timer_automatico)
	Settings.sePuedePausar = false


func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("avanzarDialogo"):

		if current_dialogue != null:

			# Los diálogos automáticos no avanzan manualmente.
			if current_dialogue.esAutomatico:
				return

			next_line()


func start_dialogue(dialogue: DialogueAbstract) -> void:

	if dialogue == null:
		return

	dialogue_box = get_tree().get_first_node_in_group("dialogue_box")

	if dialogue_box == null:
		return

	# Conectar una sola vez la señal de finalización del audio.
	if not dialogue_box.audio_dialogo.finished.is_connected(
		_on_audio_dialogo_finished
	):
		dialogue_box.audio_dialogo.finished.connect(
			_on_audio_dialogo_finished
		)

	# Detener cualquier temporizador o audio anterior.
	timer_automatico.stop()
	dialogue_box.audio_dialogo.stop()

	current_dialogue = dialogue
	current_line = 0

	current_dialogue_es_automatico = dialogue.esAutomatico

	# Solamente los diálogos manuales pausan el juego.
	if not current_dialogue_es_automatico:
		get_tree().paused = true
		Settings.sePuedePausar = false

	show_current_line()


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

	# Mostrar la línea y reproducir su audio si existe.
	dialogue_box.show_line(line)

	if current_dialogue.esAutomatico:

		if line.audio != null:
			# Esperar a que termine el audio.
			timer_automatico.stop()
		else:
			# Sin audio, avanzar después de 3 segundos.
			iniciar_timer_automatico()


func next_line() -> void:

	if current_dialogue == null:
		return

	timer_automatico.stop()

	current_line += 1

	if current_line >= current_dialogue.lines.size():
		end_dialogue()
		return

	show_current_line()


func iniciar_timer_automatico() -> void:

	if timer_automatico == null:
		return

	timer_automatico.start()


func _on_timer_automatico_timeout() -> void:

	if current_dialogue == null:
		return

	if not current_dialogue.esAutomatico:
		return

	next_line()


func _on_audio_dialogo_finished() -> void:

	if current_dialogue == null:
		return

	if not current_dialogue.esAutomatico:
		return

	if current_line < 0 or current_line >= current_dialogue.lines.size():
		return

	var line: DialogueLine = current_dialogue.lines[current_line]

	# Solo avanzar por audio si la línea actual tiene uno.
	if line.audio == null:
		return

	next_line()


func end_dialogue() -> void:

	timer_automatico.stop()

	if dialogue_box != null:
		dialogue_box.hide_dialogue()

	if current_dialogue != null:
		current_dialogue.queue_free()
		current_dialogue = null

	current_line = 0

	# Solamente los diálogos manuales habían pausado el juego.
	if not current_dialogue_es_automatico:
		get_tree().paused = false
		Settings.sePuedePausar = true

	current_dialogue_es_automatico = false
	Settings.sePuedePausar = true
