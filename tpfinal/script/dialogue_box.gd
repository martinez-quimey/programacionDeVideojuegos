
class_name DialogueBox
extends CanvasLayer


@onready var panel: Panel = $MarginContainer/Panel
@onready var portrait_container: Control = $MarginContainer/Panel/Portrait
@onready var portrait: TextureRect = $MarginContainer/Panel/Portrait/marcointerior/marcointerior/Portrait
@onready var name_label: Label = $MarginContainer/Panel/TextContainer/Name
@onready var text_label: RichTextLabel = $MarginContainer/Panel/TextContainer/Text
@onready var audio_dialogo: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:

	process_mode = Node.PROCESS_MODE_ALWAYS

	panel.visible = false
	portrait_container.visible = false


func show_line(line: DialogueLine) -> void:

	panel.visible = true

	name_label.text = line.speaker
	text_label.text = line.text

	portrait.texture = line.portrait
	portrait_container.visible = line.portrait != null

	# Detener el audio de la línea anterior.
	audio_dialogo.stop()
	audio_dialogo.stream = line.audio

	# Reproducir solamente si esta línea tiene audio.
	if line.audio != null:
		audio_dialogo.play()


func hide_dialogue() -> void:

	panel.visible = false
	audio_dialogo.stop()
