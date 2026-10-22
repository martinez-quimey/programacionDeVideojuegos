
extends Node2D

@export var duracion: float = 1.2
@export var escala_inicial: float = 0.7
@export var escala_final: float = 1.15

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.scale = Vector2.ONE * escala_inicial
	sprite.modulate.a = 1.0

	var tween = create_tween()

	# Crece rápidamente al aparecer.
	tween.tween_property(
		sprite,
		"scale",
		Vector2.ONE * escala_final,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Se mantiene un instante.
	tween.tween_interval(0.25)

	# Se desvanece al final.
	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		maxf(duracion - 0.6, 0.1)
	)

	tween.tween_callback(queue_free)
