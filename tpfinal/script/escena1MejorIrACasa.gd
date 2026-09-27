
extends Area2D

@export var dialogue_script: Script
func _on_body_entered(body):
	
	if body.is_in_group("jugador"):
		print("entro al body entered")
		body.estado_actual.cambiar_a_automatico()
		await get_tree().create_timer(1.1).timeout
		body.estado_actual.cambiar_a_manual()
		var dialogue := dialogue_script.new() as DialogueAbstract


		if dialogue == null:
			return

		dialogue.create_dialogue()

		DialogueManager.start_dialogue(dialogue)
		body.estado_actual.cambiar_a_automatico()
	
		
		body.estado_actual.presionar_derecha()
		await get_tree().create_timer(2.1).timeout
		body.estado_actual.soltar_derecha()
		body.estado_actual.cambiar_a_manual()
		
	
		
