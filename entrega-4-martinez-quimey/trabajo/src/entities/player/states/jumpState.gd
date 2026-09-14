extends PlayerState

func enter() -> void:
	character.velocity.x = 0
	character.velocity.y -= character.jump_speed
	character._play_animation("jump")
func exit() -> void:
	return
	
	
func handle_input(event: InputEvent) -> void:
	pass
	


# En esta función vamos a manejar las acciones apropiadas para este estado
func update(delta: float) -> void:
	character._apply_movement(delta)
	if character.is_on_floor_raycasted():
		finished.emit(&"idle")
	

func _on_animation_finished(anim_name: StringName) -> void:
	return
	

# En este callback manejamos, por el momento, solo los impactos
func handle_event(event: StringName, value = null) -> void:
	match event:
		&"hit":
			character._handle_hit(value)
			if character.dead:
				finished.emit(&"dead")
