class_name DialogueBox
extends CanvasLayer

@onready var panel: Panel = $MarginContainer/Panel
@onready var portrait_container: Control = $MarginContainer/Panel/Portrait
@onready var portrait: TextureRect = $MarginContainer/Panel/Portrait/marcointerior/marcointerior/Portrait
@onready var name_label: Label = $MarginContainer/Panel/TextContainer/Name
@onready var text_label: RichTextLabel = $MarginContainer/Panel/TextContainer/Text


func _ready() -> void:
	print("ready de dialogue box")
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel.visible = false
	portrait_container.visible = false


func show_line(line: DialogueLine) -> void:
	print("SHOW LINE")
	print("speaker = ", line.speaker)
	print("text = ", line.text)
	print("portrait = ", line.portrait)

	panel.visible = true

	name_label.text = line.speaker
	text_label.text = line.text

	portrait.texture = line.portrait
	portrait_container.visible = line.portrait != null


func hide_dialogue() -> void:
	panel.visible = false
