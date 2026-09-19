extends StaticBody2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var destruida: bool = false


func _ready() -> void:

	animated_sprite.play("default")


func romper_por_tornado() -> void:
	print ("roca destruida")
	if destruida:
		return

	destruida = true

	# Desactivar la colisión inmediatamente
	collision_shape.set_deferred(
		"disabled",
		true
	)

	# Reproducir la animación de explosión
	animated_sprite.play("explosion")

	await get_tree().create_timer(0.5).timeout
	# Eliminar la roca
	queue_free()
