class_name DialogueBox
extends CanvasLayer


@onready var panel: Panel = $Panel
@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/TextContainer/Name
@onready var text_label: RichTextLabel = $Panel/TextContainer/Text


func _ready() -> void:
	print("ready de dialogue box")
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel.visible = false
	portrait.visible = false


func show_line(line: DialogueLine) -> void:
	print("SHOW LINE")
	print("speaker = ", line.speaker)
	print("text = ", line.text)
	print("portrait = ", line.portrait)

	panel.visible = true

	name_label.text = line.speaker
	text_label.text = line.text

	if line.portrait != null:
		portrait.texture = line.portrait
		portrait.visible = true
	else:
		portrait.texture = null
		portrait.visible = false


func hide_dialogue() -> void:
	panel.visible = false
