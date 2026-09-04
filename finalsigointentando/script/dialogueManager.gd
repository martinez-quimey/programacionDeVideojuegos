#dialogueMAnager
extends Node


var current_dialogue: Dialogue
var current_line := 0

var dialogue_box: DialogueBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("avanzarDialogo"):
		if current_dialogue != null:
			next_line()


func start_dialogue(dialogue: Dialogue) -> void:
	print("start dialogue de dialogue manager")

	if dialogue == null:
		return

	dialogue_box = get_tree().get_first_node_in_group("dialogue_box")

	if dialogue_box == null:
		push_error("No se encontró DialogueBox.")
		return

	current_dialogue = dialogue
	current_line = 0

	get_tree().paused = true

	print("Diálogo iniciado")
	print("Cantidad de líneas: ", current_dialogue.lines.size())
	Settings.sePuedePausar = false

	show_current_line()


func show_current_line() -> void:
	if current_dialogue.lines.is_empty():
		end_dialogue()
		return

	var line: DialogueLine = current_dialogue.lines[current_line]

	dialogue_box.show_line(line)


func next_line() -> void:
	current_line += 1

	if current_line >= current_dialogue.lines.size():
		end_dialogue()
		return

	show_current_line()


func end_dialogue() -> void:
	dialogue_box.hide_dialogue()

	current_dialogue.free()
	current_dialogue = null

	get_tree().paused = false
	Settings.sePuedePausar = true
