extends PlayerState


# Al ser un estado de finalización (es decir, no se sale
# a ningun otro estado), vamos a procesar todo lo necesario
# en el enter
func enter() -> void:
	character.died.emit()
	character._play_animation(&"die")


func exit() -> void:
	return


## Y en update solo manejamos la fricción y movimiento
## para que no sea un cubo de hielo al morir
func update(delta: float) -> void:
	character._handle_deacceleration(delta)
	character._apply_movement(delta)


func handle_input(_event: InputEvent) -> void:
	return


func handle_event(_event: StringName, _value = null) -> void:
	return

## Para este punto solo hay una animación reproduciendose
## por lo que podemos extraer el llamado a _remove desde la
## animación a esta función
func _on_animation_finished(_anim_name: StringName) -> void:
	character._remove()
