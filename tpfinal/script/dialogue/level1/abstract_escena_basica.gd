extends Area2D


@export var dialogue_script: Script
@export var esAutomatico: bool = false


func _on_body_entered(body):

	if body.is_in_group("jugador"):

		print("entro al body entered")

		if not esAutomatico:
			body.estado_actual.cambiar_a_automatico()

			await get_tree().create_timer(0.2).timeout

			body.estado_actual.cambiar_a_manual()


		var dialogue: DialogueAbstract = dialogue_script.new()

		if dialogue == null:
			return

		dialogue.esAutomatico = esAutomatico

		dialogue.create_dialogue()

		DialogueManager.start_dialogue(dialogue)
		queue_free()
