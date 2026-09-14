extends Area2D

@export var direccion: Vector2 = Vector2.RIGHT
@export var velocidad: float = 300.0


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		body.movimiento_forzado(direccion, velocidad)


func _on_body_exited(body):
	if body.is_in_group("jugador"):
		body.detener_movimiento_forzado()
