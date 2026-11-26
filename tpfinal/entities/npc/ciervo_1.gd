
extends AbstractNPC
class_name Ciervo1

@export var dialogue_script: Script

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super._ready()

	if sprite.sprite_frames != null:
		sprite.play("default")


func interact() -> void:
	var dialogue = dialogue_script.new()

	if dialogue == null:
		return

	dialogue.create_dialogue()

	DialogueManager.start_dialogue(dialogue)
