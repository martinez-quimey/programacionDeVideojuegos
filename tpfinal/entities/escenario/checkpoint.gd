extends Area2D

@export var numero_checkpoint: int = 1

@onready var sprite = $AnimatedSprite2D


func _ready() -> void:



	recalcular_estado()

	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):

		if numero_checkpoint > Settings.checkpoint:
			Settings.checkpoint = numero_checkpoint
			recalcular_todos_los_checkpoints()


func recalcular_estado() -> void:
	if Settings.checkpoint >= numero_checkpoint:
		sprite.play("escrito")
	else:
		sprite.play("vacio")


func recalcular_todos_los_checkpoints() -> void:

	var checkpoints = get_parent().get_children()

	for checkpoint in checkpoints:

		if checkpoint.has_method("recalcular_estado"):
			checkpoint.recalcular_estado()
