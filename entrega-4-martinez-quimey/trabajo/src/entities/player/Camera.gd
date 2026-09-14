extends Camera2D

@onready var player: Player = get_parent()

@export var max_offset_h: float
@export var max_offset_y: float
@export var offset_speed: float
@export var min_zoom: Vector2
@export var max_zoom: Vector2
@export var zoom_speed: float

var target_offset: Vector2


## Una camarita con comportamiento propio para mostrar las bondades de
## usar una cámara con zooms y offsets y demás
func _physics_process(delta: float) -> void:
	
	## Como usamos el movimiento del personaje como un factor, primero
	## podemos calcular el porcentaje de velocidad que tiene el player
	## hasta llegar a la velocidad máxima, lo que dará un valor entre 0.0 y 1.0
	var velocity_factor: float = player.velocity.x / player.h_speed_limit
	
	## Acá virtualizamos el offset que vamos a aplicar con un Vector2 que vamos
	## "deslizando" gradualmente usando el "velocity_factor"
	target_offset = target_offset.lerp(
		Vector2(velocity_factor * max_offset_h,
		abs(velocity_factor) * max_offset_y),
		offset_speed * delta
	)
	
	## Y que luego aplicamos al verdadero offset de la cámara con una interpolación
	offset = offset.lerp(target_offset, offset_speed * delta)
	
	## Luego calculamos cuál es el zoom al que vamos a calcular usando de nuevo el
	## absoluto del velocity_factor (asi nos tira positivo y zoomea a cualquier dirección)
	var max_zoom_target: Vector2 = abs(velocity_factor) * max_zoom
	
	## Evaluamos el zoom objetivo que queremos conseguir, poniendo un tope de zoom minimo
	var target_zoom: Vector2 = Vector2.ONE / Vector2(
		max(min_zoom.x, max_zoom_target.x),
		max(min_zoom.y, max_zoom_target.y)
	)
	
	## Y lo aplicamos con una interpolación entre el zoom actual y el objetivo
	zoom = lerp(zoom, target_zoom, zoom_speed * delta)
