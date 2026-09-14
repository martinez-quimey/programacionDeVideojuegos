extends PlayerState


# Al entrar se activa primero la animación "walk"
func enter() -> void:
	character._play_animation(&"walk")


func exit() -> void:
	return


func handle_input(event: InputEvent) -> void:
	# Aquí se podría manejar, por ejemplo, transiciones a estados como Jump
	if event.is_action_pressed("jump") && character.is_on_floor():
		emit_signal("finished", "jump")


# En esta función vamos a manejar las acciones apropiadas para este estado
func update(delta: float) -> void:
	# Vamos a querer que se pueda disparar
	character._handle_weapon_actions()
	
	# Vamos a manejar los inputs de movimiento
	character._handle_move_input(delta)
	# Aplicar ese movimiento, sin desacelerar
	character._apply_movement(delta)
	
	# Y luego chequeamos si se quedó quieto el personaje
	if character.h_movement_direction == 0:
		# Y cambiamos el estado a idle
		finished.emit(&"idle")
	else:
		# O aplicamos la animación que corresponde
		if character.is_on_floor():
			character._play_animation(&"walk")
		else:
			if character.velocity.y > 0:
				character._play_animation(&"fall")
			else:
				character._play_animation(&"jump")


func _on_animation_finished(anim_name: StringName) -> void:
	return


# En este callback manejamos, por el momento, solo los impactos
func handle_event(event: StringName, value = null) -> void:
	match event:
		&"hit":
			character._handle_hit(value)
			if character.dead:
				finished.emit(&"dead")
