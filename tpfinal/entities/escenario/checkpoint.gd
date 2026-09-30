extends Area2D

@export var numero_checkpoint: int = 1

@onready var sprite = $AnimatedSprite2D


func _ready() -> void:
	if Settings.checkpoint >= numero_checkpoint:
		sprite.play("escrito")
	else:
		sprite.play("vacio")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		if numero_checkpoint > Settings.checkpoint:
			Settings.checkpoint = numero_checkpoint
			sprite.play("escrito")
