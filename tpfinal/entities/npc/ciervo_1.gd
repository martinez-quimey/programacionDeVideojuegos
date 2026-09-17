extends AbstractNPC
class_name Ciervo1


@export var dialogue_script: Script


func interact() -> void:
	var dialogue = dialogue_script.new()

	if dialogue == null:
		return

	dialogue.create_dialogue()

	DialogueManager.start_dialogue(dialogue)
