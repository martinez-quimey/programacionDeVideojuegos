extends AbstractNPC
class_name Ciervo1



@export var dialogue_scene: PackedScene


func interact() -> void:
	var dialogue := dialogue_scene.instantiate() as Dialogue

	if dialogue == null:
		return

	dialogue.create_dialogue()

	DialogueManager.start_dialogue(dialogue)
