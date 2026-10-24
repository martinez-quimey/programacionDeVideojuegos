
extends Node2D

@export var duracion: float = 2.0
@export var escala_inicial: float = 6.0
@export var escala_final: float = 12.0
@export var ORDEN_DIBUJO: int = 4096

@onready var sprite: Sprite2D = $Sprite2D

var tween: Tween


func _ready() -> void:
	z_index = ORDEN_DIBUJO
	z_as_relative = false
	sprite.z_index = ORDEN_DIBUJO
	sprite.z_as_relative = false
	hide()


func reproducir() -> void:
	if not is_instance_valid(sprite):
		return

	if tween and tween.is_running():
		tween.kill()

	z_index = ORDEN_DIBUJO
	z_as_relative = false
	sprite.z_index = ORDEN_DIBUJO
	sprite.z_as_relative = false

	show()
	sprite.show()
	sprite.scale = Vector2.ONE * escala_inicial
	sprite.modulate.a = 1.0

	tween = create_tween()

	# Crece rápidamente.
	tween.tween_property(
		sprite,
		"scale",
		Vector2.ONE * escala_final,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Permanece visible.
	tween.tween_interval(0.5)

	# Se desvanece gradualmente.
	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		maxf(duracion - 1.0, 0.1)
	)

	tween.tween_callback(queue_free)
